import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

import '../constants/cv_sections.dart';
import 'storage_service.dart';
import 'transcription_service.dart';
import 'ai_analyzer_service.dart';
import 'cv_data_service.dart';

class CVProcessingService {
  final StorageService _storageService;
  final TranscriptionService _transcriptionService;
  final AIAnalyzerService _aiAnalyzerService;
  final CVDataService _cvDataService;

  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  CVProcessingService(
    this._storageService,
    this._transcriptionService,
    this._aiAnalyzerService,
    this._cvDataService,
  );

  Future<Map<String, dynamic>> processAudios(
    Map<String, String> audioUrls,
  ) async {
    if (audioUrls.isEmpty)
      throw Exception("No se encontraron grabaciones de audio para procesar.");

    final cvId = DateTime.now().millisecondsSinceEpoch.toString();
    Map<String, String> transcriptions = {};
    Map<String, String> processedAudioUrls = {};

    int totalSections = audioUrls.length;
    int processedSections = 0;

    try {
      for (var section in cvSections) {
        if (!audioUrls.containsKey(section.id)) continue;

        final audioPath = audioUrls[section.id]!;
        processedSections++;
        _updateStatus(
          "🎧 Procesando ${section.title} ($processedSections/$totalSections)",
        );

        // 1️⃣ Descarga los bytes
        final Uint8List audioBytes = await _getAudioBytes(audioPath);

        // 2️⃣ Sube los bytes a Supabase
        _updateStatus("☁️ Subiendo ${section.title}...");
        final publicUrl = await _storageService.uploadAudioBytes(
          audioBytes,
          cvId,
          section.id,
        );
        processedAudioUrls[section.title] = publicUrl;

        // 3️⃣ Transcribe
        _updateStatus("✍️ Transcribiendo ${section.title}...");
        final transcription = await _transcriptionService.transcribeAudio(
          publicUrl,
        );
        transcriptions[section.title] = transcription;
      }

      // 4️⃣ Analiza con IA
      _updateStatus("🤖 Analizando transcripciones...");
      final combinedText = _combineTranscriptions(transcriptions);
      final analyzedData = await _aiAnalyzerService.analyzeTranscription(
        combinedText,
      );

      // 5️⃣ Guarda en Supabase
      _updateStatus("💾 Guardando datos...");
      final recordId = await _cvDataService.saveCVData(
        cvId: cvId,
        transcriptions: transcriptions,
        audioUrls: processedAudioUrls,
        analyzedData: analyzedData,
      );

      _updateStatus("✅ Proceso completado.");
      return {'recordId': recordId, 'analyzedData': analyzedData};
    } catch (e) {
      _updateStatus("❌ Error durante el procesamiento: $e");
      rethrow;
    }
  }

  Future<Uint8List> _getAudioBytes(String url) async {
    if (kIsWeb) {
      final completer = Completer<Uint8List>();
      final xhr = html.HttpRequest();
      xhr.open('GET', url);
      xhr.responseType = 'blob';

      xhr.onLoad.listen((event) {
        if (xhr.status == 200) {
          final blob = xhr.response as html.Blob;
          final reader = html.FileReader();
          reader.onLoadEnd.listen((_) {
            completer.complete(reader.result as Uint8List);
          });
          reader.readAsArrayBuffer(blob);
        } else {
          completer.completeError(
            "Error al obtener audio: código ${xhr.status}",
          );
        }
      });

      xhr.onError.listen((_) => completer.completeError("Error de red"));
      xhr.send();
      return completer.future;
    } else {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
      throw Exception("Error HTTP ${response.statusCode}");
    }
  }

  String _combineTranscriptions(Map<String, String> transcriptions) {
    final buffer = StringBuffer();
    for (var section in cvSections) {
      if (transcriptions.containsKey(section.title)) {
        buffer.writeln("### ${section.title.toUpperCase()} ###");
        buffer.writeln(transcriptions[section.title]);
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  void _updateStatus(String message) {
    _statusController.add(message);
    debugPrint(message);
  }

  void dispose() => _statusController.close();
}

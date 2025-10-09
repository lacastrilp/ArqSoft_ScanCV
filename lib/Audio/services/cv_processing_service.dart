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

  CVProcessingService(this._storageService, this._transcriptionService, this._aiAnalyzerService, this._cvDataService);

  StreamController<String> _processingStatusController = StreamController<String>.broadcast();
  Stream<String> get processingStatusStream => _processingStatusController.stream;

  Future<Map<String, dynamic>> processAudios(Map<String, String> audioUrls) async {
    if (audioUrls.isEmpty) {
      throw Exception("No se encontraron grabaciones de audio para procesar.");
    }

    final cvId = DateTime.now().millisecondsSinceEpoch.toString();
    Map<String, String> transcriptions = {};
    Map<String, String> processedAudioUrls = {};
    int totalSections = audioUrls.length;
    int processedSections = 0;

    try {
      for (var section in cvSections) {
        if (audioUrls.containsKey(section.id)) {
          final audioPath = audioUrls[section.id]!;
          processedSections++;

          _updateStatus('Procesando audio ${processedSections}/$totalSections: ${section.title}');

          // 1. Get audio bytes from URL
          final Uint8List audioBytes = await _getAudioBytes(audioPath);

          // 2. Upload bytes to get a stable URL for transcription
          _updateStatus('Subiendo a Supabase (${processedSections}/$totalSections)...');
          final publicUrl = await _storageService.uploadAudioBytes(audioBytes, cvId, section.id);
          processedAudioUrls[section.title] = publicUrl;

          // 3. Transcribe audio
          _updateStatus('Transcribiendo (${processedSections}/$totalSections): ${section.title}');
          final transcription = await _transcriptionService.transcribeAudio(publicUrl);
          transcriptions[section.title] = transcription;
        }
      }

      // 4. Combine and analyze transcriptions
      _updateStatus('Analizando transcripción con IA...');
      final combinedTranscription = _combineTranscriptions(transcriptions);
      final analyzedData = await _aiAnalyzerService.analyzeTranscription(combinedTranscription);

      // 5. Save everything to the database
      _updateStatus('Guardando información en la base de datos...');
      final recordId = await _cvDataService.saveCVData(
        cvId: cvId,
        transcriptions: transcriptions,
        audioUrls: processedAudioUrls,
        analyzedData: analyzedData,
      );

      _updateStatus('¡Proceso completado!');

      return {
        'recordId': recordId,
        'analyzedData': analyzedData,
      };

    } catch (e) {
      _updateStatus('Error: $e');
      print("Error en el procesamiento de CV: $e");
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
          completer.completeError('Error al obtener el audio: código ${xhr.status}');
        }
      });

      xhr.onError.listen((_) {
        completer.completeError('Error de red al obtener el audio');
      });

      xhr.send();
      return completer.future;
    } else {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download audio file: ${response.statusCode}');
      }
    }
  }

  String _combineTranscriptions(Map<String, String> transcriptions) {
    StringBuffer combined = StringBuffer();
    for (var section in cvSections) {
      if (transcriptions.containsKey(section.title)) {
        combined.writeln("### section.title.toUpperCase() ###");
        combined.writeln(transcriptions[section.title]);
        combined.writeln("\n");
      }
    }
    return combined.toString();
  }

  void _updateStatus(String status) {
    _processingStatusController.add(status);
    print(status);
  }

  void dispose() {
    _processingStatusController.close();
  }
}

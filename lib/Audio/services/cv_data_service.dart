// lib/services/cv_data_service.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/cv_sections.dart';
import '../../supabase_singleton.dart';

class CVDataService {
  final SupabaseClient _supabase = SupabaseManager.instance.client;

  CVDataService();

  Future<String> saveCVData({
    required String cvId,
    required Map<String, String> transcriptions,
    required Map<String, String> audioUrls,
    required Map<String, dynamic> analyzedData,
  }) async {
    try {
      final now = DateTime.now();

      StringBuffer combinedTranscription = StringBuffer();
      for (var section in cvSections) {
        if (transcriptions.containsKey(section.title)) {
          combinedTranscription.writeln("### <strong><em><span style=\"color: #000000;\"></span></em></strong>${section.title.toUpperCase()} ###");
          combinedTranscription.writeln(transcriptions[section.title]);
          combinedTranscription.writeln("\n");
        }
      }

      Map<String, dynamic> sectionsInfo = {};
      for (var section in cvSections) {
        if (transcriptions.containsKey(section.title)) {
          sectionsInfo[section.title] = {
            'id': section.id,
            'descripcion': section.description,
            'enlace_audio': audioUrls[section.title]
          };
        }
      }

      final record = {
        'transcripcion': combinedTranscription.toString(),
        'enlace_audio': '',
        'transcripcion_organizada_json': analyzedData,
        'informacion_audios': jsonEncode({
          'cv_id': cvId,
          'timestamp': now.toIso8601String(),
          'secciones': sectionsInfo
        }),
      };

      print("Guardando registro combinado en la base de datos...");

      final response = await _supabase
          .from('audio_transcrito')
          .insert(record)
          .select('id');

      if (response.isNotEmpty) {
        final recordId = response[0]['id'].toString();
        print("✅ Información guardada correctamente. ID del registro: $recordId");
        return recordId;
      } else {
        throw Exception("No se pudo obtener el ID del registro guardado.");
      }
    } catch (e) {
      print("❌ Error al guardar en la base de datos: $e");
      rethrow;
    }
  }
}

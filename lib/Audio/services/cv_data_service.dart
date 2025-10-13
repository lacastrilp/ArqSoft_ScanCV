// lib/Audio/services/cv_data_service.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/cv_sections.dart';
import '../../setting/supabase_singleton.dart';
import '../models/cv_model.dart';
import '../models/cv_section_model.dart';
import '../models/cv_field_model.dart';

/// 🔹 Nuevo repositorio para separar acceso a datos (Patrón Repository)
class CVRepository {
  final SupabaseClient client;
  CVRepository(this.client);

  Future<Map<String, dynamic>> insertAudioTranscrito(Map<String, dynamic> data) async {
    final response = await client.from('audio_transcrito').insert(data).select('id');
    return (response.isNotEmpty) ? response[0] : {};
  }

  Future<List<Map<String, dynamic>>> getAudioTranscritos() async {
    final response = await client.from('audio_transcrito').select();
    return List<Map<String, dynamic>>.from(response);
  }
}

/// 🔹 Servicio principal que usa el repositorio
class CVDataService {
  final SupabaseClient _supabase = SupabaseManager.instance.client;
  late final CVRepository _repository;

  CVDataService() {
    _repository = CVRepository(_supabase);
  }

  Future<String> saveCVData({
    required String cvId,
    required Map<String, String> transcriptions,
    required Map<String, String> audioUrls,
    required Map<String, dynamic> analyzedData,
  }) async {
    try {
      final now = DateTime.now();

      // 🔸 Combinamos las transcripciones por sección
      StringBuffer combinedTranscription = StringBuffer();
      for (var section in cvSections) {
        if (transcriptions.containsKey(section.title)) {
          combinedTranscription.writeln(
              "### <strong><em><span style=\"color: #000000;\"></span></em></strong>${section.title.toUpperCase()} ###");
          combinedTranscription.writeln(transcriptions[section.title]);
          combinedTranscription.writeln("\n");
        }
      }

      // 🔸 Construimos la info detallada de cada sección
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

      final inserted = await _repository.insertAudioTranscrito(record);
      if (inserted.isNotEmpty) {
        final recordId = inserted['id'].toString();
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

  /// 🔸 Ejemplo extra: obtener todos los CV guardados
  Future<List<Map<String, dynamic>>> getAllCVRecords() async {
    return await _repository.getAudioTranscritos();
  }
}

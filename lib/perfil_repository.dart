import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_singleton.dart';

/// Repositorio centralizado para manejar la lógica CRUD
/// de las tablas `perfil_information` y `audio_transcrito`.
class PerfilRepository {
  final SupabaseClient _client = SupabaseManager.instance.client;

  /// 🔹 Inserta o actualiza un perfil basándose en el correo electrónico
  Future<int?> insertarOActualizarPerfilPorCorreo(
    Map<String, dynamic> perfilData,
  ) async {
    try {
      final data = _sanitizePerfilData(perfilData);
      final correo = data['correo']?.toString().trim().toLowerCase();

      if (correo == null || correo.isEmpty) {
        throw Exception(
          'El campo "correo" es obligatorio para guardar el perfil.',
        );
      }

      // 🔍 1️⃣ Buscar si ya existe un perfil con este correo
      final existe =
          await _client
              .from('perfil_information')
              .select('id')
              .eq('correo', correo)
              .maybeSingle();

      if (existe != null && existe['id'] != null) {
        final existingId = existe['id'];
        print(
          "🔄 Perfil existente encontrado con correo $correo (ID: $existingId). Actualizando...",
        );

        await _client
            .from('perfil_information')
            .update({
              ...data,
              'ultima_accion':
                  'Actualización de perfil existente desde CV Scanner',
              'detalle_accion':
                  'El usuario actualizó su perfil según su correo.',
              'fecha_actualizacion': DateTime.now().toIso8601String(),
            })
            .eq('id', existingId);

        print("✅ Perfil actualizado correctamente (ID: $existingId)");
        return existingId;
      } else {
        print("🆕 No existe perfil con correo $correo. Creando nuevo...");

        final response = await _client
            .from('perfil_information')
            .insert({
              ...data,
              'ultima_accion': 'Creación de perfil desde CV Scanner',
              'detalle_accion':
                  'El usuario creó un nuevo perfil con su correo.',
              'fecha_actualizacion': DateTime.now().toIso8601String(),
            })
            .select('id');

        if (response.isNotEmpty) {
          final newId = response.first['id'];
          print("✅ Nuevo perfil creado correctamente (ID: $newId)");
          return newId;
        } else {
          print("⚠️ Insert realizado pero no se devolvió ID.");
          return null;
        }
      }
    } catch (e) {
      print("❌ Error al insertar o actualizar perfil por correo: $e");
      rethrow;
    }
  }

  /// 🔹 Actualiza un perfil existente directamente por ID
  Future<void> actualizarPerfil(
    String id,
    Map<String, dynamic> perfilData,
  ) async {
    try {
      final data = _sanitizePerfilData(perfilData);

      final result = await _client
          .from('perfil_information')
          .update({
            ...data,
            'ultima_accion': 'Actualización desde app CV Scanner',
            'detalle_accion': 'El usuario editó su información manualmente.',
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select('id');

      if (result.isNotEmpty) {
        print("✅ Perfil actualizado correctamente (ID: $id)");
      } else {
        print("⚠️ No se encontró perfil con ID: $id");
      }
    } catch (e) {
      print("❌ Error al actualizar perfil: $e");
      rethrow;
    }
  }

  /// 🔹 Inserta o actualiza los datos en `audio_transcrito`
  Future<void> insertarOActualizarAudioTranscrito(
    String recordId,
    Map<String, dynamic> data,
  ) async {
    try {
      final existe =
          await _client
              .from('audio_transcrito')
              .select('id')
              .eq('id', recordId)
              .maybeSingle();

      if (existe != null) {
        await _client
            .from('audio_transcrito')
            .update({'informacion_organizada_usuario': data})
            .eq('id', recordId);

        print("🔄 Actualizado en audio_transcrito (ID: $recordId)");
      } else {
        await _client.from('audio_transcrito').insert({
          'id': recordId,
          'informacion_organizada_usuario': data,
          'created_at': DateTime.now().toIso8601String(),
        });

        print(
          "🆕 Nuevo registro insertado en audio_transcrito (ID: $recordId)",
        );
      }
    } catch (e) {
      print("❌ Error al insertar/actualizar audio_transcrito: $e");
      rethrow;
    }
  }

  /// Limpieza básica de datos nulos
  Map<String, dynamic> _sanitizePerfilData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    for (final entry in data.entries) {
      sanitized[entry.key] = entry.value ?? '';
    }
    return sanitized;
  }
}

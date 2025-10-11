// lib/services/storage_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../supabase_singleton.dart';
import 'dart:io';
import 'dart:html' as html;


class StorageService {
  final SupabaseClient _supabase = SupabaseManager.instance.client;

  StorageService();

  Future<String> uploadAudio(String path, String sectionId) async {
    try {
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = 'audios/$fileName';

      Uint8List bytes;

      if (kIsWeb) {
        final blob = await html.HttpRequest.request(path, responseType: 'blob');
        final reader = html.FileReader();
        final completer = Completer<Uint8List>();
        reader.readAsArrayBuffer(blob.response);
        reader.onLoadEnd.listen((_) {
          completer.complete(reader.result as Uint8List);
        });
        bytes = await completer.future;
      } else {
        bytes = await File(path).readAsBytes();
      }

      await _supabase.storage.from('audios').uploadBinary(storagePath, bytes);
      final publicUrl = _supabase.storage.from('audios').getPublicUrl(storagePath);

      print("✅ Audio subido correctamente: $publicUrl");
      return publicUrl;
    } catch (e) {
      print("❌ Error al subir audio a Supabase: $e");
      rethrow;
    }
  }

  Future<String> uploadAudioBytes(Uint8List audioBytes, String cvId, String sectionId) async {
    final fileName = 'cv_${cvId}_${sectionId}_${DateTime.now().millisecondsSinceEpoch}.webm';
    await _supabase.storage.from('Audios').uploadBinary(
          fileName,
          audioBytes,
          fileOptions: const FileOptions(contentType: 'audio/webm'),
        );
    final publicUrl = _supabase.storage.from('Audios').getPublicUrl(fileName);
    print("✅ Audio (bytes) subido correctamente: $publicUrl");
    return publicUrl;
  }
}

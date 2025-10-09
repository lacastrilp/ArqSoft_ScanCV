import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io' show File;
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

// Inicializa Supabase
final supabase = Supabase.instance.client;

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({Key? key}) : super(key: key);

  @override
  _AudioRecorderScreenState createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isUploading = false;
  String? _filePath;
  String? _uploadedUrl;
  String _status = "Presiona el botón para grabar";

  // ==== Inicializa audio y permisos ====
  Future<void> _initializeAudioHandlers() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      bool hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos de micrófono no concedidos.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() => _isPlaying = false);
      });

      print("🎧 AudioRecorder y AudioPlayer inicializados correctamente");
    } catch (e) {
      print("❌ Error inicializando audio: $e");
    }
  }

  // ==== Iniciar grabación ====
  Future<void> _startRecording() async {
    try {
      await _initializeAudioHandlers();

      String? path;
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = p.join(dir.path, 'grabacion_${DateTime.now().millisecondsSinceEpoch}.m4a');

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
      } else {
        // En web, no se usa path
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ), path: '',
        );
      }

      setState(() {
        _isRecording = true;
        _status = "🎙 Grabando...";
      });

      print("✅ Grabación iniciada correctamente");
    } catch (e, s) {
      print("❌ Error al iniciar grabación: $e\n$s");
      setState(() => _isRecording = false);
    }
  }

  // ==== Detener grabación ====
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path == null) {
        setState(() {
          _status = "⚠️ No se obtuvo archivo de grabación";
        });
        return;
      }

      setState(() {
        _filePath = path;
        _isRecording = false;
        _status = "🎙 Grabación detenida. Subiendo a Supabase...";
        _isUploading = true;
      });

      final uploadedUrl = await _uploadAudioToSupabase(path);

      if (uploadedUrl != null) {
        setState(() {
          _uploadedUrl = uploadedUrl;
          _status = "✅ Audio subido correctamente";
        });
        print("✅ Audio disponible en: $_uploadedUrl");
      } else {
        setState(() {
          _status = "❌ Error al subir el audio";
        });
      }

      setState(() => _isUploading = false);
    } catch (e) {
      print("❌ Error al detener grabación: $e");
      setState(() {
        _isRecording = false;
        _isUploading = false;
        _status = "❌ Error al detener grabación";
      });
    }
  }

  // ==== Subir a Supabase ====
  Future<String?> _uploadAudioToSupabase(String path) async {
    try {
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = 'audios/$fileName';
      Uint8List bytes;

      if (kIsWeb) {
        final response = await html.HttpRequest.request(path, responseType: 'blob');
        final reader = html.FileReader();
        final completer = Completer<Uint8List>();
        reader.readAsArrayBuffer(response.response);
        reader.onLoadEnd.listen((_) {
          completer.complete(reader.result as Uint8List);
        });
        bytes = await completer.future;
      } else {
        bytes = await File(path).readAsBytes();
      }

      await supabase.storage.from('audios').uploadBinary(storagePath, bytes);
      final publicUrl = supabase.storage.from('audios').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e, s) {
      print("❌ Error al subir audio a Supabase: $e\n$s");
      return null;
    }
  }

  // ==== Reproducir grabación ====
  Future<void> _playRecording() async {
    try {
      if (_uploadedUrl != null) {
        await _audioPlayer.play(UrlSource(_uploadedUrl!));
      } else if (_filePath != null) {
        await _audioPlayer.play(DeviceFileSource(_filePath!));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay audio disponible')),
        );
        return;
      }

      setState(() => _isPlaying = true);

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() => _isPlaying = false);
      });
    } catch (e) {
      print("❌ Error al reproducir: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reproducir: $e')),
      );
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF00FF7F);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grabar Audio'),
        backgroundColor: primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: _isRecording ? Colors.red : Colors.grey,
                size: 100,
              ),
              const SizedBox(height: 20),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording ? 'Detener' : 'Grabar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed:
                    !_isPlaying && (_filePath != null || _uploadedUrl != null)
                        ? _playRecording
                        : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Reproducir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_isUploading) ...[
                const SizedBox(height: 30),
                const CircularProgressIndicator(),
              ],
              if (_uploadedUrl != null) ...[
                const SizedBox(height: 20),
                SelectableText(
                  "🌐 URL pública:\n$_uploadedUrl",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

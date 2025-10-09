import 'dart:async';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AudioManager {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Function(bool)? onIsPlayingChanged;

  AudioManager({this.onIsPlayingChanged}) {
    _audioPlayer.onPlayerComplete.listen((event) {
      onIsPlayingChanged?.call(false);
    });
  }

  Future<bool> requestPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }

    if (!await requestPermission()) {
      throw Exception('Microphone permissions are required.');
    }

    String? path;
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      path = p.join(dir.path, 'grabacion_${DateTime.now().millisecondsSinceEpoch}.m4a');
    }

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path ?? '',
    );
  }

  Future<String?> stopRecording() async {
    if (!await _audioRecorder.isRecording()) return null;
    return await _audioRecorder.stop();
  }

  Future<void> playRecording(String audioUrl) async {
    if (_audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.stop();
      onIsPlayingChanged?.call(false);
      return;
    }

    if (audioUrl.isNotEmpty) {
      await _audioPlayer.play(UrlSource(audioUrl));
      onIsPlayingChanged?.call(true);
    } else {
      throw Exception('No audio available to play for this section.');
    }
  }

  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
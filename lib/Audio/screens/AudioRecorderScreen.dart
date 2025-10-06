import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:html' as html;

import '../../WidgetBarra.dart';

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({Key? key}) : super(key: key);

  @override
  _AudioRecorderScreenState createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  final Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _filePath;
// Recording funciones
  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      await _audioRecorder.start();
      setState(() {
        _isRecording = true;
      });
    }
  }
  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _filePath = path;
    });
  }
  Future<void> _playRecording() async {
    if (_filePath != null) {
      await _audioPlayer.play(DeviceFileSource(_filePath!));
      setState(() {
        _isPlaying = true;
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlaying = false;
        });
      });
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
    return Scaffold(
      appBar: const CustomAppBar(title: 'Grabar Audios'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Detener' : 'Grabar'),

            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _filePath != null && !_isPlaying ? _playRecording : null,
              child: Text('Reproducir'),
            ),
          ],
        ),
      ),
    );
  }
}

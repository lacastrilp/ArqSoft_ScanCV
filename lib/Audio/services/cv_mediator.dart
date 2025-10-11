import 'package:flutter/material.dart';
import '../services/audio_manager.dart';
import '../services/storage_service.dart';
import '../services/cv_processing_service.dart';
import '../constants/cv_sections.dart';

/// Mediador que coordina la interacción entre los servicios de CV
class CVMediator {
  final AudioManager audioManager;
  final StorageService storageService;
  final CVProcessingService processingService;

  bool isRecording = false;
  bool isPlaying = false;

  CVMediator({
    required this.audioManager,
    required this.storageService,
    required this.processingService,
  });

  /// Inicia la grabación
  Future<void> startRecording() async {
    await audioManager.startRecording();
    isRecording = true;

  }

  /// Detiene la grabación y sube el audio
  Future<String?> stopRecording(String sectionId) async {
    final path = await audioManager.stopRecording();
    isRecording = false;

    if (path != null) {
      final publicUrl = await storageService.uploadAudio(path, sectionId);
      return publicUrl;
    }
    return null;
  }

  /// Reproduce un audio grabado
  Future<void> playRecording(String audioUrl) async {
    await audioManager.playRecording(audioUrl);
  }

  /// Procesa todos los audios usando CVProcessingService
  Future<Map<String, dynamic>> processAllAudios(Map<String, String> audioUrls) async {
    return await processingService.processAudios(audioUrls);
  }

  void dispose() {
    audioManager.dispose();
    processingService.dispose();
  }
}
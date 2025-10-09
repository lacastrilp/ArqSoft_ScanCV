import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Formulario/cv_form_unified.dart';
import '../constants/cv_sections.dart';
import '../models/cv_section_model.dart';
import '../presentation/cv_section_card.dart';
import '../widgets/info_edit_form.dart';
import '../services/audio_manager.dart';
import '../services/storage_service.dart';
import '../services/cv_processing_service.dart';
import '../services/transcription_service.dart';
import '../services/ai_analyzer_service.dart';
import '../services/cv_data_service.dart';

final supabase = Supabase.instance.client;

class CVGenerator extends StatefulWidget {
  const CVGenerator({Key? key}) : super(key: key);

  @override
  _CVGeneratorState createState() => _CVGeneratorState();
}

class _CVGeneratorState extends State<CVGenerator> {
  // Services
  late final AudioManager _audioManager;
  late final StorageService _storageService;
  late final CVProcessingService _cvProcessingService;

  // UI State
  int _currentSectionIndex = 0;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _isComplete = false;
  String _processingStatus = '';

  // Data
  final Map<String, String> _audioUrls = {};
  Map<String, dynamic> _editableInfo = {};
  String _recordId = '';

  // Controllers
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Initialize services
    _audioManager = AudioManager(onIsPlayingChanged: (isPlaying) {
      if (mounted) setState(() => _isPlaying = isPlaying);
    });
    _storageService = StorageService(supabase);
    final transcriptionService = TranscriptionService();
    final aiAnalyzerService = AIAnalyzerService();
    final cvDataService = CVDataService(supabase);
    _cvProcessingService = CVProcessingService(
      _storageService,
      transcriptionService,
      aiAnalyzerService,
      cvDataService,
    );

    // Listen to processing status updates
    _cvProcessingService.processingStatusStream.listen((status) {
      if (mounted) setState(() => _processingStatus = status);
    });
  }

  Future<void> _startRecording() async {
    try {
      await _audioManager.startRecording();
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioManager.stopRecording();
      if (mounted) setState(() => _isRecording = false);

      if (path != null) {
        _processingStatus = 'Subiendo audio...';
        final sectionId = cvSections[_currentSectionIndex].id;
        final publicUrl = await _storageService.uploadAudio(path, sectionId);
        if (mounted) {
          setState(() {
            _audioUrls[sectionId] = publicUrl;
            _processingStatus = '';
          });
        }
        print("✅ Audio subido a Supabase: $publicUrl");
      }
    } catch (e) {
      _showErrorSnackBar('Error al detener la grabación: $e');
    }
  }

  Future<void> _playRecording() async {
    final sectionId = cvSections[_currentSectionIndex].id;
    final audioUrl = _audioUrls[sectionId];
    if (audioUrl != null) {
      try {
        await _audioManager.playRecording(audioUrl);
      } catch (e) {
        _showErrorSnackBar(e.toString());
      }
    } else {
      _showErrorSnackBar('No hay audio para reproducir en esta sección.');
    }
  }

  void _nextSection() {
    if (_currentSectionIndex < cvSections.length - 1) {
      _pageController.animateToPage(
        ++_currentSectionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showConfirmationDialog();
    }
  }

  void _previousSection() {
    if (_currentSectionIndex > 0) {
      _pageController.animateToPage(
        --_currentSectionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar y procesar'),
        content: const Text(
            '¿Has terminado de grabar todas las secciones? Al continuar, se procesarán todos los audios para generar tu hoja de vida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processAllAudios();
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _processAllAudios() async {
    if (mounted) {
      setState(() {
        _isProcessing = true;
        _processingStatus = 'Iniciando proceso...';
      });
    }

    try {
      final result = await _cvProcessingService.processAudios(_audioUrls);
      if (mounted) {
        setState(() {
          _recordId = result['recordId'];
          _editableInfo = result['analyzedData'];
          _isComplete = true;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStatus = 'Error: $e';
        });
      }
      _showErrorSnackBar('Ocurrió un error durante el procesamiento: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _audioManager.dispose();
    _cvProcessingService.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing || _isComplete) {
      return _buildProcessingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Generador de Hojas de Vida'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: LinearProgressIndicator(
              value: (_currentSectionIndex + 1) / cvSections.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF7F)),
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paso ${_currentSectionIndex + 1} de ${cvSections.length}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                Text(
                  cvSections[_currentSectionIndex].title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00FF7F)),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cvSections.length,
              onPageChanged: (index) {
                if (mounted) setState(() => _currentSectionIndex = index);
              },
              itemBuilder: (context, index) {
                final section = cvSections[index];
                return CVSectionCard(
                  section: section,
                  isRecording: _isRecording,
                  isPlaying: _isPlaying,
                  hasAudio: _audioUrls.containsKey(section.id),
                  transcription: '', // Transcription is handled by services now
                  onStartRecording: _startRecording,
                  onStopRecording: _stopRecording,
                  onPlayRecording: _playRecording,
                  onUpdateTranscription: (text) {},
                  onNext: _nextSection,
                  onPrevious: _previousSection,
                  isFirstSection: index == 0,
                  isLastSection: index == cvSections.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingScreen() {
    const primaryGreen = Color(0xFF00FF7F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isComplete ? 'Revisar Información' : 'Procesando'),
        backgroundColor: primaryGreen,
        automaticallyImplyLeading: _isComplete, // Show back button only when complete
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                Column(
                  children: [
                    const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryGreen)),
                    const SizedBox(height: 20),
                    Text(_processingStatus, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                  ],
                )
                else if (_isComplete)
                  Expanded(
                    child: CVFormUnified(
                      initialData: _editableInfo,
                      recordId: _recordId,
                      isEditing: true,
                    ),
                  )
                else // Error state
                  Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60.0),
                      const SizedBox(height: 20),
                      Text(
                        'Error: $_processingStatus',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

            ],
          ),
        ),
      ),
    );
  }
}
// lib/Audio/cv_generator.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../form/cv_form_unified.dart';
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
import '../../supabase_singleton.dart'; 
import '../services/cv_mediator.dart';

class CVGenerator extends StatefulWidget {
  const CVGenerator({Key? key}) : super(key: key);

  @override
  _CVGeneratorState createState() => _CVGeneratorState();
}

class _CVGeneratorState extends State<CVGenerator> {
  late final CVMediator _mediator;
  late final CVProcessingService _processingService;

  int _currentSectionIndex = 0;
  bool _isProcessing = false;
  bool _isComplete = false;
  String _processingStatus = '';

  final Map<String, String> _audioUrls = {};
  Map<String, dynamic> _editableInfo = {};
  String _recordId = '';
  final PageController _pageController = PageController();

  bool get _isRecording => _mediator.isRecording;
  bool get _isPlaying => _mediator.isPlaying;


  @override
  void initState() {
    super.initState();

    final supabase = SupabaseManager.instance.client;
    final storageService = StorageService();
    final transcriptionService = TranscriptionService();
    final aiAnalyzerService = AIAnalyzerService();
    final cvDataService = CVDataService();

    _processingService = CVProcessingService(
      storageService,
      transcriptionService,
      aiAnalyzerService,
      cvDataService,
    );

    _mediator = CVMediator(
      audioManager: AudioManager(),
      storageService: storageService,
      processingService: _processingService,
    );

    _processingService.statusStream.listen((status) {
      if (mounted) setState(() => _processingStatus = status);
    });

  }

  Future<void> _startRecording() async {
    await _mediator.startRecording();
    setState(() {});
  }

  Future<void> _stopRecording() async {
    final sectionId = cvSections[_currentSectionIndex].id;
    final publicUrl = await _mediator.stopRecording(sectionId);
    if (publicUrl != null) {
      setState(() => _audioUrls[sectionId] = publicUrl);
    }
  }

  Future<void> _playRecording() async {
    final sectionId = cvSections[_currentSectionIndex].id;
    final audioUrl = _audioUrls[sectionId];
    if (audioUrl != null) await _mediator.playRecording(audioUrl);
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
      builder:
          (context) => AlertDialog(
            title: const Text('Finalizar y procesar'),
            content: const Text(
              '¿Has terminado de grabar todas las secciones? Se procesarán todos los audios para generar tu hoja de vida.',
            ),
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
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Iniciando proceso...';
    });

    try {
      final result = await _mediator.processAllAudios(_audioUrls);
      setState(() {
        _recordId = result['recordId'];
        _editableInfo = result['analyzedData'];
        _isComplete = true;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ CV guardado correctamente en Supabase')),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processingStatus = 'Error: $e';
      });
    }
  }


  Future<void> _showErrorSnackBar(String message) async {
    await _mediator.startRecording();
    setState(() {});
  }

  @override
  void dispose() {
    _mediator.dispose();
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
      body: _buildMainContent(),
    );

    

  }

  Widget _buildMainContent() {
    return Column(
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                cvSections[_currentSectionIndex].title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00FF7F),
                ),
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
                transcription: '',
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
    );
  }

  Widget _buildProcessingScreen() {
    const primaryGreen = Color(0xFF00FF7F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isComplete ? 'Revisar Información' : 'Procesando'),
        backgroundColor: primaryGreen,
        automaticallyImplyLeading: _isComplete,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child:
              _isProcessing
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _processingStatus,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                  : _isComplete
                  ? CVFormUnified(
                    initialData: _editableInfo,
                    recordId: _recordId,
                    isEditing: true,
                  )
                  : Text(
                    'Error: $_processingStatus',
                    style: const TextStyle(color: Colors.red),
                  ),
        ),
      ),
    );
  }
}

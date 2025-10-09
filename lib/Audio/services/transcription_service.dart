import 'dart:convert';
import 'package:http/http.dart' as http;

class TranscriptionService {
  final String _apiKey = '61caf9b1c241438e9202ec2dc3fd88d3'; // Consider moving to a secure config
  final String _apiBaseUrl = 'https://api.assemblyai.com/v2';

  Future<String> transcribeAudio(String audioUrl) async {
    print("Iniciando transcripción para URL: $audioUrl");

    try {
      // 1. Enviar la URL para transcripción
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/transcript'),
        headers: {
          'authorization': _apiKey,
          'content-type': 'application/json',
        },
        body: json.encode({
          'audio_url': audioUrl,
          'language_code': 'es',
        }),
      );

      final responseJson = json.decode(response.body);

      if (response.statusCode != 200) {
        throw Exception('Error al iniciar la transcripción: ${response.statusCode} - ${responseJson['error']}');
      }

      final transcriptId = responseJson['id'];
      print("ID de transcripción: $transcriptId");

      // 2. Consultar el estado hasta que se complete
      return await _pollForCompletion(transcriptId);

    } catch (e) {
      print("Error en la transcripción: $e");
      return "Error en la transcripción: $e";
    }
  }

  Future<String> _pollForCompletion(String transcriptId) async {
    const maxAttempts = 60;
    int attempts = 0;

    while (attempts < maxAttempts) {
      attempts++;
      await Future.delayed(const Duration(seconds: 3));
      print("Intento $attempts: Esperando transcripción...");

      try {
        final response = await http.get(
          Uri.parse('$_apiBaseUrl/transcript/$transcriptId'),
          headers: {'authorization': _apiKey},
        );

        final pollingJson = json.decode(response.body);
        final status = pollingJson['status'];

        print("Estado de transcripción: $status");

        if (status == 'completed') {
          print("Transcripción obtenida: ${pollingJson['text']}");
          return pollingJson['text'];
        } else if (status == 'error') {
          throw Exception('Error en la transcripción: ${pollingJson['error']}');
        }

      } catch (e) {
        print("Error al consultar estado de transcripción: $e");
        // Continue polling
      }
    }

    throw Exception('Tiempo de espera agotado. La transcripción está tomando demasiado tiempo.');
  }
}
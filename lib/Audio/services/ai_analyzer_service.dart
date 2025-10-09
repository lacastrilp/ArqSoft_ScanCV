import 'dart:convert';
import 'package:http/http.dart' as http;

class AIAnalyzerService {
  final String _apiKey = 'sk-or-v1-4786de42076f4ea466fc9dca4886a532738103229732b06134754ef974eba04_1'; // Consider moving to a secure config
  final Uri _openRouterUrl = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

  Future<Map<String, dynamic>> analyzeTranscription(String transcription) async {
    try {
      final sanitizedTranscription = _sanitizeText(transcription);
      final prompt = _buildPrompt(sanitizedTranscription);

      final payload = {
        "model": "openai/gpt-4.1-mini",
        "messages": [
          {
            "role": "user",
            "content": [
              {"type": "text", "text": prompt}
            ]
          }
        ],
        "max_tokens": 2000,
        "temperature": 0.3,
      };

      final response = await http.post(
        _openRouterUrl,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'http://localhost:8080', // Required by OpenRouter
          'X-Title': 'Scanner Personal', // Required by OpenRouter
        },
        body: json.encode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);
        final content = jsonResponse['choices'][0]['message']['content'] as String;

        print("🧠 Respuesta bruta del modelo (análisis) $content");

        return _parseAndCleanJson(content);
      } else {
        print('❌ Error OpenRouter: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al analizar transcripción: $e');
      return {"error": e.toString()};
    }
  }

  String _sanitizeText(String text) {
    return text
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // Remove non-ASCII characters
        .replaceAll(RegExp(r'\s+'), ' ')       // Normalize whitespace
        .trim();
  }

  String _buildPrompt(String sanitizedTranscription) {
    return '''
Analiza la siguiente transcripción de audio y extrae toda la información relevante para un CV (hoja de vida).

Devuelve SOLO un objeto JSON con la información extraída, sin comentarios ni texto adicional.

Transcripción: "$sanitizedTranscription"

IMPORTANTE: Tu respuesta debe ser ÚNICAMENTE un JSON válido que contenga EXACTAMENTE los siguientes campos (deja vacíos los que no se mencionan):
{
  "nombres": "",
  "apellidos": "",
  "direccion": "",
  "telefono": "",
  "correo": "",
  "nacionalidad": "",
  "fecha_nacimiento": "",
  "estado_civil": "",
  "linkedin": "",
  "github": "",
  "portafolio": "",
  "perfil_profesional": "",
  "objetivos_profesionales": "",
  "experiencia_laboral": "",
  "educacion": "",
  "habilidades": "",
  "idiomas": "",
  "certificaciones": "",
  "proyectos": "",
  "publicaciones": "",
  "premios": "",
  "voluntariados": "",
  "referencias": "",
  "expectativas_laborales": "",
  "experiencia_internacional": "",
  "permisos_documentacion": "",
  "vehiculo_licencias": "",
  "contacto_emergencia": "",
  "disponibilidad_entrevistas": ""
}
''';
  }

  Map<String, dynamic> _parseAndCleanJson(String content) {
    String cleanedContent = content
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll("’", "'")
        .replaceAll("`", "")
        .trim();

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleanedContent);
    if (match == null) throw Exception("❌ No se encontró un bloque JSON válido en la respuesta de la IA.");

    String jsonStr = match.group(0)!;
    final closingIndex = jsonStr.lastIndexOf('}');
    if (closingIndex != -1) jsonStr = jsonStr.substring(0, closingIndex + 1);
    jsonStr = jsonStr.replaceAll(RegExp(r'[^\x00-\x7F]'), ''); // Final sanitization

    print("🧹 JSON limpiado (análisis): $jsonStr");

    final parsed = json.decode(jsonStr);
    return parsed.cast<String, dynamic>();
  }
}
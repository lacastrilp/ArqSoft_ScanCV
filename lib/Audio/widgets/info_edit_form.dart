import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/helpers.dart';

final supabase = Supabase.instance.client;

class InfoEditForm extends StatefulWidget {
  final Map<String, dynamic> initialInfo;
  final String recordId;

  const InfoEditForm({
    Key? key,
    required this.initialInfo,
    required this.recordId,
  }) : super(key: key);

  @override
  _InfoEditFormState createState() => _InfoEditFormState();
}

class _InfoEditFormState extends State<InfoEditForm> {
  late Map<String, dynamic> _editableInfo;
  bool _isFormLoading = false;
  String _formError = '';

  @override
  void initState() {
    super.initState();
    _editableInfo = Map<String, dynamic>.from(widget.initialInfo);
    _asegurarTiposDeDatos();
  }

  void _asegurarTiposDeDatos() {
    try {
      Map<String, dynamic> temp = {};
      _editableInfo.forEach((key, value) {
        if (value is List) {
          temp[key] = value.join(", ");
        } else if (value is Map) {
          temp[key] = json.encode(value);
        } else if (value == null) {
          temp[key] = "";
        } else {
          temp[key] = value.toString();
        }
      });
      setState(() {
        _editableInfo = temp;
      });
      print("✅ DEPURANDO: Tipos de datos asegurados correctamente para el formulario");
    } catch (e) {
      print("❌ DEPURANDO: Error al asegurar tipos de datos para el formulario: $e");
    }
  }

  Future<void> _uploadPhotoToSupabase() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() {
        _isFormLoading = true;
        _formError = 'Subiendo fotografía...';
      });

      final bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';

      await supabase.storage
          .from('fotografias_cv')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final publicUrl = supabase.storage
          .from('fotografias_cv')
          .getPublicUrl(fileName);

      setState(() {
        _editableInfo['fotografia'] = publicUrl;
        _isFormLoading = false;
        _formError = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotografía subida correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("❌ Error al subir fotografía: $e");
      setState(() {
        _isFormLoading = false;
        _formError = 'Error al subir fotografía: $e';
      });
    }
  }

  Future<void> _saveEditedInfo() async {
    setState(() {
      _isFormLoading = true;
      _formError = '';
    });

    try {
      Map<String, dynamic> editableInfoParaGuardar = Map.from(_editableInfo);
      _asegurarTiposDeDatos();

      setState(() {
        _formError = 'Validando información...';
      });

      final bool isValid = await _validateInfoWithAI();

      if (!isValid) {
        setState(() {
          _isFormLoading = false;
        });
        return;
      }

      Map<String, dynamic> infoParaGuardar = {};
      editableInfoParaGuardar.forEach((key, value) {
        if (value is String) {
          infoParaGuardar[key] = normalizarTexto(value);
        } else {
          infoParaGuardar[key] = value;
        }
      });

      final camposRequeridos = [
        'nombres', 'apellidos', 'direccion', 'telefono', 'correo',
        'nacionalidad', 'fecha_nacimiento', 'estado_civil', 'linkedin', 'github',
        'portafolio', 'perfil_profesional', 'objetivos_profesionales',
        'experiencia_laboral', 'educacion', 'habilidades', 'idiomas',
        'certificaciones', 'proyectos', 'publicaciones', 'premios',
        'voluntariados', 'referencias', 'expectativas_laborales',
        'experiencia_internacional', 'permisos_documentacion',
        'vehiculo_licencias', 'contacto_emergencia', 'disponibilidad_entrevistas',
        'fotografia'
      ];

      for (var campo in camposRequeridos) {
        if (!infoParaGuardar.containsKey(campo)) {
          infoParaGuardar[campo] = "";
        }
      }

      await supabase.from('perfil_information').insert({
        ...infoParaGuardar,
        'ultima_accion': 'Actualización desde app CV Scanner',
        'detalle_accion': 'El usuario editó y guardó su información procesada.',
        'fecha_actualizacion': DateTime.now().toIso8601String(),
      });

      await supabase
          .from('audio_transcrito')
          .update({'informacion_organizada_usuario': infoParaGuardar})
          .eq('id', widget.recordId);

      setState(() {
        _isFormLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();

    } catch (e) {
      print("❌ DEPURANDO: Error general en _saveEditedInfo: $e");
      setState(() {
        _isFormLoading = false;
        _formError = 'Error al guardar: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _validateInfoWithAI() async {
    try {
      final openRouterApiKey = 'sk-or-v1-4786de42076f4ea466fc9dca4886a532738103229732b06134754ef974eba04_1';
      final openRouterUrl = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

      final sanitizedInfo = json.encode(_editableInfo).replaceAll(RegExp(r'[^\x00-\x7F]'), '');

      final prompt = '''
Eres un asistente que valida información de hojas de vida. 

INSTRUCCIONES:
- Analiza la información, pero **NO rechaces ni bloquees** el CV por campos vacíos o menores. 
- Solo devuelve errores graves (ej: JSON roto, tipo de dato incorrecto, texto ininteligible).
- Si el texto parece razonable aunque falten datos, márcalo como válido.
- Devuelve SOLO un JSON válido con esta estructura exacta:

Estructura esperada:
  {
    "esValido": true,
    "errores": []
  }

Ejemplo:
Si falta la dirección o el LinkedIn, no lo consideres un error grave.
Si el correo no tiene formato o la fecha no parece válida, puedes sugerirlo en "errores".

Información a validar:
  $sanitizedInfo
  ''';

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
        "temperature": 0.1,
      };

      final response = await http.post(
        openRouterUrl,
        headers: {
          'Authorization': 'Bearer $openRouterApiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'http://localhost:8080',
          'X-Title': 'ScanCV',
        },
        body: json.encode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);
        final content = jsonResponse['choices'][0]['message']['content'] as String;

        String cleaned = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
        if (match == null) throw Exception("No se encontró un bloque JSON válido en la respuesta del modelo.");

        String jsonStr = match.group(0)!;
        final result = json.decode(jsonStr);
        final esValido = result['esValido'] == true;
        final errores = List<String>.from(result['errores'] ?? []);

        if (!esValido) {
          _mostrarErroresValidacion(errores);
          return false;
        } else {
          if (errores.isNotEmpty) {
            _mostrarErroresValidacion(errores);
          } else {
            setState(() => _formError = '');
          }
          return true;
        }
      } else {
        throw Exception('Error en la API de validación');
      }
    } catch (e) {
      setState(() {
        _formError = 'Error al validar información: $e';
      });
      return false;
    }
  }

  void _mostrarErroresValidacion(List<dynamic> errores) {
    if (errores.isEmpty) return;
    String errorMessage = 'Se encontraron problemas en la información:\n\n';
    for (var error in errores) {
      if (error is Map) {
        String campo = error['campo']?.toString() ?? 'campo desconocido';
        String problema = error['problema']?.toString() ?? 'error no especificado';
        errorMessage += '- $campo: $problema\n';
      } else if (error is String) {
        errorMessage += '- $error\n';
      }
    }
    setState(() {
      _formError = errorMessage;
    });
  }

 @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF00FF7F);
    if (_editableInfo.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    Map<String, dynamic> safeInfo = {};
    _editableInfo.forEach((key, value) {
      safeInfo[key] = value.toString();
    });

    final fieldLabels = {
      'nombres': 'Nombres', 'apellidos': 'Apellidos', 'direccion': 'Dirección',
      'telefono': 'Teléfono', 'correo': 'Correo electrónico', 'nacionalidad': 'Nacionalidad',
      'fecha_nacimiento': 'Fecha de nacimiento', 'estado_civil': 'Estado civil',
      'linkedin': 'LinkedIn', 'github': 'GitHub', 'portafolio': 'Portafolio',
      'perfil_profesional': 'Perfil profesional', 'objetivos_profesionales': 'Objetivos profesionales',
      'experiencia_laboral': 'Experiencia laboral', 'educacion': 'Educación',
      'habilidades': 'Habilidades', 'idiomas': 'Idiomas', 'certificaciones': 'Certificaciones',
      'proyectos': 'Proyectos', 'publicaciones': 'Publicaciones', 'premios': 'Premios',
      'voluntariados': 'Voluntariados', 'referencias': 'Referencias',
      'expectativas_laborales': 'Expectativas laborales', 'experiencia_internacional': 'Experiencia internacional',
      'permisos_documentacion': 'Permisos y documentación', 'vehiculo_licencias': 'Vehículo y licencias',
      'contacto_emergencia': 'Contacto de emergencia', 'disponibilidad_entrevistas': 'Disponibilidad para entrevistas',
    };

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Text(
                'Revisa y edita la información extraída',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_formError.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _formError.contains('Validando') ? Colors.blue.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_formError, style: TextStyle(color: _formError.contains('Validando') ? Colors.blue.shade800 : Colors.red.shade800)),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fotografía', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          if ((safeInfo['fotografia'] ?? '').isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.network(safeInfo['fotografia'], height: 120, width: 120, fit: BoxFit.cover),
                            )
                          else
                            CircleAvatar(radius: 60, backgroundColor: Colors.grey[300], child: Icon(Icons.person, size: 60, color: Colors.white)),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _isFormLoading ? null : _uploadPhotoToSupabase,
                            icon: const Icon(Icons.upload),
                            label: const Text('Subir fotografía'),
                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ...fieldLabels.entries.map((entry) {
                final fieldName = entry.key;
                final fieldLabel = entry.value;
                final isLongText = ['perfil_profesional', 'objetivos_profesionales', 'educacion', 'experiencia_laboral', 'habilidades'].contains(fieldName);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: TextFormField(
                    initialValue: safeInfo[fieldName] ?? '',
                    maxLines: isLongText ? 4 : 1,
                    decoration: InputDecoration(
                      labelText: fieldLabel,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _editableInfo[fieldName] = value;
                      });
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
              ElevatedButton(
                onPressed: _isFormLoading ? null : _saveEditedInfo,
                child: _isFormLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar información'),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

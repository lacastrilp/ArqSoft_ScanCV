import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../WidgetBarra.dart';

class CVFormEditor extends StatefulWidget {
  const CVFormEditor({Key? key}) : super(key: key);

  @override
  State<CVFormEditor> createState() => _CVFormEditorState();
}

class _CVFormEditorState extends State<CVFormEditor> {
  final supabase = Supabase.instance.client;

  int? _perfilId;
  bool _isFormLoading = true;
  String _formError = '';
  Map<String, dynamic> _formData = {};

  // Campos del formulario
  final Map<String, String> fieldLabels = {
    'nombres': 'Nombres',
    'apellidos': 'Apellidos',
    'direccion': 'Dirección',
    'telefono': 'Teléfono',
    'correo': 'Correo electrónico',
    'nacionalidad': 'Nacionalidad',
    'fecha_nacimiento': 'Fecha de nacimiento',
    'estado_civil': 'Estado civil',
    'linkedin': 'LinkedIn',
    'github': 'GitHub',
    'portafolio': 'Portafolio',
    'perfil_profesional': 'Perfil profesional',
    'objetivos_profesionales': 'Objetivos profesionales',
    'experiencia_laboral': 'Experiencia laboral',
    'educacion': 'Educación',
    'habilidades': 'Habilidades',
    'idiomas': 'Idiomas',
    'certificaciones': 'Certificaciones',
    'proyectos': 'Proyectos',
    'publicaciones': 'Publicaciones',
    'premios': 'Premios',
    'voluntariados': 'Voluntariados',
    'referencias': 'Referencias',
    'expectativas_laborales': 'Expectativas laborales',
    'experiencia_internacional': 'Experiencia internacional',
    'permisos_documentacion': 'Permisos / Documentación',
    'vehiculo_licencias': 'Vehículo / Licencias',
    'contacto_emergencia': 'Contacto de emergencia',
    'disponibilidad_entrevistas': 'Disponibilidad para entrevistas',
  };

  @override
  void initState() {
    super.initState();
    _loadPerfil();
  }

  /// Carga el perfil si existe (por correo)
  Future<void> _loadPerfil() async {
    setState(() {
      _isFormLoading = true;
      _formError = '';
    });

    try {
      // Simulamos usuario logueado con correo
      const userEmail = "usuario3@email.com";

      final response = await supabase
          .from('perfil_information')
          .select()
          .eq('correo', userEmail)
          .maybeSingle();

      if (response != null) {
        _perfilId = response['id'];
        _formData = Map<String, dynamic>.from(response);
      } else {
        // Si no existe, inicializamos vacío
        _formData = {
          'correo': userEmail,
          'nombres': '',
          'apellidos': '',
          'telefono': '',
        };
      }

      _asegurarCampos();
    } catch (e) {
      _formError = 'Error: $e';
    } finally {
      setState(() {
        _isFormLoading = false;
      });
    }
  }

  void _asegurarCampos() {
    for (var key in fieldLabels.keys) {
      _formData[key] ??= '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Llenar formulario'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff9ee4b8),
        icon: const Icon(Icons.save, color: Color(0xFF090467)),
        label: Text(
          'Guardar',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF090467),
          ),
        ),
        onPressed: _saveForm,
      ),
      body: _isFormLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text(
                    'Completa la información',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF090467),
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  if (_formError.isNotEmpty)
                    Text(_formError, style: const TextStyle(color: Colors.red)),
                  ...fieldLabels.entries.map((entry) {
                    final key = entry.key;
                    final label = entry.value;
                    final isLongText = [
                      'perfil_profesional',
                      'objetivos_profesionales',
                      'experiencia_laboral',
                      'educacion',
                      'habilidades'
                    ].contains(key);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF090467))),
                          const SizedBox(height: 5),
                          TextFormField(
                            initialValue: _formData[key]?.toString() ?? '',
                            maxLines: isLongText ? 4 : 1,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF090467)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF090467), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xff9ee4b8), width: 2),
                              ),
                              hintText: 'Ingrese $label',
                            ),
                            onChanged: (value) {
                              _formData[key] = value;
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Future<void> _saveForm() async {
    setState(() {
      _isFormLoading = true;
      _formError = '';
    });

    try {
      // Validaciones mínimas requeridas
      if ((_formData['nombres'] ?? '').isEmpty ||
          (_formData['apellidos'] ?? '').isEmpty ||
          (_formData['telefono'] ?? '').isEmpty ||
          (_formData['correo'] ?? '').isEmpty) {
        throw Exception(
            'Por favor completa los campos obligatorios: nombres, apellidos, teléfono y correo.');
      }

      final updateData = Map<String, dynamic>.from(_formData)
        ..remove('id');

      if (_perfilId == null) {
        // No existe, crear nuevo
        final insertResponse = await supabase
            .from('perfil_information')
            .insert(updateData)
            .select()
            .single();
        _perfilId = insertResponse['id'];
      } else {
        // Actualizar existente
        await supabase
            .from('perfil_information')
            .update(updateData)
            .eq('id', _perfilId!);
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '✅ Información guardada correctamente',
          style: GoogleFonts.poppins(
              color: const Color(0xFF090467),
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff9ee4b8),
      ));
    } catch (e) {
      setState(() {
        _formError = 'Error al guardar: $e';
      });
    } finally {
      setState(() {
        _isFormLoading = false;
      });
    }
  }
}

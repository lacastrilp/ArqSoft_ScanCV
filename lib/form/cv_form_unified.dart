import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Audio/utils/helpers.dart';
import '../WidgetBarra.dart';
import '../supabase_singleton.dart';
import '../perfil_repository.dart';



class CVFormUnified extends StatefulWidget {
  final Map<String, dynamic>? initialData; // datos iniciales (para edición)
  final bool isEditing; // modo creación o edición
  final String? recordId; // id si viene de audio_transcrito, opcional

  const CVFormUnified({
    Key? key,
    this.initialData,
    this.isEditing = false,
    this.recordId,
  }) : super(key: key);

  @override
  State<CVFormUnified> createState() => _CVFormUnifiedState();
}

class _CVFormUnifiedState extends State<CVFormUnified> {
  final supabase = SupabaseManager.instance.client;
  bool _isFormLoading = false;
  String _formError = '';
  late Map<String, dynamic> _formData;

  final Map<String, String> fieldLabels = const {
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
    'fotografia': 'Fotografía'
  };

  @override
  void initState() {
    super.initState();
    _formData = Map<String, dynamic>.from(widget.initialData ?? {});
    for (var key in fieldLabels.keys) {
      _formData[key] ??= '';
    }
  }

  Future<void> _uploadPhotoToSupabase() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isFormLoading = true;
        _formError = 'Subiendo fotografía...';
      });

      final bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';

      await supabase.storage
          .from('fotografias_cv')
          .uploadBinary(fileName, bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'));

      final publicUrl =
          supabase.storage.from('fotografias_cv').getPublicUrl(fileName);

      setState(() {
        _formData['fotografia'] = publicUrl;
        _formError = '';
      });
    } catch (e) {
      setState(() => _formError = 'Error al subir fotografía: $e');
    } finally {
      setState(() => _isFormLoading = false);
    }
  }



final _perfilRepo = PerfilRepository();

Future<void> _saveForm() async {
  setState(() {
    _isFormLoading = true;
    _formError = '';
  });

  try {
    // 🧩 Validar campos obligatorios
    if ((_formData['nombres'] ?? '').isEmpty ||
        (_formData['apellidos'] ?? '').isEmpty ||
        (_formData['correo'] ?? '').isEmpty) {
      throw Exception(
        'Por favor completa los campos obligatorios: nombres, apellidos y correo.',
      );
    }

    // 🧹 Limpiar y preparar los datos
    final data = Map<String, dynamic>.from(_formData)..remove('id');

    // ✅ Guardar o actualizar según el correo
    final perfilId = await _perfilRepo.insertarOActualizarPerfilPorCorreo(data);

    print("✅ Perfil sincronizado correctamente. ID final: $perfilId");

    // 🎉 Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Información guardada correctamente (ID: $perfilId)'),
        backgroundColor: Colors.green,
      ),
    );

    // 🔙 Volver a la pantalla anterior
    Navigator.pop(context);
  } catch (e) {
    print("❌ Error al guardar formulario: $e");
    setState(() => _formError = 'Error al guardar: $e');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al guardar: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isFormLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF090467);
    final accentColor = const Color(0xff9ee4b8);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isEditing ? 'Editar CV' : 'Crear CV',
      ),
      body: _isFormLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text(
                    widget.isEditing
                        ? 'Edita tu información'
                        : 'Completa la información',
                    style: GoogleFonts.poppins(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_formError.isNotEmpty)
                    Text(_formError, style: const TextStyle(color: Colors.red)),

                  // Fotografía
                  Center(
                    child: Column(
                      children: [
                        if ((_formData['fotografia'] ?? '').isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.network(_formData['fotografia'],
                                height: 120, width: 120, fit: BoxFit.cover),
                          )
                        else
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            child: const Icon(Icons.person,
                                size: 60, color: Colors.white),
                          ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _isFormLoading
                              ? null
                              : _uploadPhotoToSupabase,
                          icon: const Icon(Icons.upload),
                          label: const Text('Subir fotografía'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campos
                  ...fieldLabels.entries.map((entry) {
                    final key = entry.key;
                    if (key == 'fotografia') return const SizedBox();
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
                      child: TextFormField(
                        initialValue: _formData[key]?.toString() ?? '',
                        maxLines: isLongText ? 4 : 1,
                        decoration: InputDecoration(
                          labelText: label,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (val) => _formData[key] = val,
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isFormLoading ? null : _saveForm,
                    icon: const Icon(Icons.save),
                    label: Text(
                      'Guardar información',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditProfileScreen({required this.userId, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  final Map<String, String> fieldMapping = {
    "Nombres": "nombres",
    "Apellidos": "apellidos",
    "Dirección": "direccion",
    "Teléfono": "telefono",
    "Correo electrónico": "correo",
    "Nacionalidad": "nacionalidad",
    "Fecha de nacimiento": "fecha_nacimiento",
    "Estado civil": "estado_civil",
    "LinkedIn": "linkedin",
    "GitHub": "github",
    "Portafolio": "portafolio",
    "Perfil profesional": "perfil_profesional",
    "Objetivos Profesionales": "objetivos_profesionales",
    "Experiencia Laboral": "experiencia_laboral",
    "Expectativas Laborales": "expectativas_laborales",
    "Experiencia Internacional": "experiencia_internacional",
    "Educación": "educacion",
    "Habilidades": "habilidades",
    "Idiomas": "idiomas",
    "Certificaciones": "certificaciones",
    "Participación en Proyectos": "proyectos",
    "Publicaciones": "publicaciones",
    "Premios": "premios",
    "Voluntariados": "voluntariados",
    "Referencias": "referencias",
    "Permisos y Documentación": "permisos_documentacion",
    "Vehículo y Licencias": "vehiculo_licencias",
    "Contacto de Emergencia": "contacto_emergencia",
    "Disponibilidad para Entrevistas": "disponibilidad_entrevistas",
  };

  final Set<String> _nonEditableFields = {
    "Nombres",
    "Apellidos",
    "Fecha de nacimiento",
    "Nacionalidad",
    "Dirección",
  };

  @override
  void initState() {
    super.initState();
    fieldMapping.forEach((label, key) {
      final value = _getValueByKey(label);
      _controllers[label] = TextEditingController(text: value);
    });
  }

  String _getValueByKey(String label) {
    for (var section in widget.userData.values) {
      if (section is Map && section.containsKey(label)) {
        return section[label] ?? '';
      }
    }
    return '';
  }

  Future<void> _saveChanges() async {
    final updates = <String, dynamic>{};
    fieldMapping.forEach((label, key) {
      if (!_nonEditableFields.contains(label)) {
        updates[key] = _controllers[label]?.text ?? '';
      }
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('perfil_information').update(updates).eq('id', widget.userId);
      Navigator.pop(context, true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar los cambios.')),
      );
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Editar Perfil',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          TextButton.icon(
            onPressed: _saveChanges,
            icon: Icon(Icons.save, color: Color(0xFF25AD4C)),
            label: Text(
              'Guardar',
              style: GoogleFonts.poppins(
                color: Color(0xFF25AD4C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ...fieldMapping.keys.map((label) {
                final isDisabled = _nonEditableFields.contains(label);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _controllers[label],
                    enabled: !isDisabled,
                    style: GoogleFonts.poppins(
                      color: isDisabled ? Colors.grey  : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDisabled ? Colors.grey.shade200 : Colors.grey.shade100,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
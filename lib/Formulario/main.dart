import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:io';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://utvbtdxeseokumaosali.supabase.co', // ← reemplaza con tu URL real
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV0dmJ0ZHhlc2Vva3VtYW9zYWxpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTg1Mzg1OSwiZXhwIjoyMDc1NDI5ODU5fQ.JiQBPoa_BvGtHOzANxDMsdIPzgc1aufu1rCQ2MiXB8Q', // ← reemplaza con tu clave real
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Analizador de Hojas de Vida',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PantallaSubirCV(),
    );
  }
}

class PantallaSubirCV extends StatefulWidget {
  final String? initialAction;
  PantallaSubirCV({this.initialAction});

  @override
  PantallaSubirCVState createState() => PantallaSubirCVState();
}

class PantallaSubirCVState extends State<PantallaSubirCV> {
  String? filePath;
  Map<String, String> datosCV = {
    'Nombre': 'Pedro',
    'Apellido': 'Pérez',
    'Teléfono': '23902945',
    'Email': 'pedro_123@gmail.com',
    'Experiencia': '6 años en desarrollo de videojuegos',
    'Educación': 'Ingeniería en Sistemas - Universidad Eafit',
    'Habilidades': 'Liderazgo, comunicación',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final action = widget.initialAction;
      if (action == 'foto') {
        tomarFoto();
      } else if (action == 'pdf') {
        subirPDF();
      } else if (action == 'formulario') {
        analizarCV();
      } else {
        debugPrint('Acción desconocida: $action');
      }
    });
  }

  Future<void> subirArchivo(
    Uint8List archivoBytes,
    String nombreArchivo,
  ) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.storage
          .from('cv')
          .uploadBinary('archivos/$nombreArchivo', archivoBytes);

      if (response.isEmpty) {
        throw Exception('No se pudo obtener la URL del archivo');
      }

      setState(() {
        filePath = nombreArchivo;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Archivo subido exitosamente')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir archivo: $e')));
    }
  }

  Future<void> tomarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      final bytes = await foto.readAsBytes();
      final nombreArchivo = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await subirArchivo(bytes, nombreArchivo);
    }
  }

  Future<void> subirPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      final archivo = result.files.first;
      Uint8List? archivoBytes = archivo.bytes;
      if (archivoBytes == null && archivo.path != null) {
        archivoBytes = await File(archivo.path!).readAsBytes();
      }
      if (archivoBytes != null) {
        final nombreArchivo = archivo.name;
        await subirArchivo(archivoBytes, nombreArchivo);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo leer el archivo')));
      }
    }
  }

  void analizarCV() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PantallaAnalizarCV(
              extractedData: datosCV,
              archivoSubido: filePath,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Análisis de Hojas de Vida',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 4,
          shadowColor: Colors.black54,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, size: 100, color: Colors.blue),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: tomarFoto,
                  icon: Icon(Icons.camera_alt),
                  label: Text('Tomar foto de hoja de vida'),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: subirPDF,
                  icon: Icon(Icons.upload_file),
                  label: Text('Subir archivo PDF'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: analizarCV,
                  child: Text('Completar formulario manual'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PantallaAnalizarCV extends StatefulWidget {
  final Map<String, String> extractedData;
  final String? archivoSubido;

  PantallaAnalizarCV({required this.extractedData, this.archivoSubido});

  @override
  PantallaAnalizarCVState createState() => PantallaAnalizarCVState();
}

class PantallaAnalizarCVState extends State<PantallaAnalizarCV> {
  late Map<String, TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = widget.extractedData.map(
      (key, value) => MapEntry(key, TextEditingController(text: value)),
    );
  }

Future<void> guardarEnSupabase() async {
  final supabase = Supabase.instance.client;

  try {
    // Inserta los datos directamente
    await supabase.from('cv_analizados').insert({
      'nombre': controllers['Nombre']?.text ?? '',
      'apellido': controllers['Apellido']?.text ?? '',
      'telefono': controllers['Teléfono']?.text ?? '',
      'email': controllers['Email']?.text ?? '',
      'experiencia': controllers['Experiencia']?.text ?? '',
      'educacion': controllers['Educación']?.text ?? '',
      'habilidades': controllers['Habilidades']?.text ?? '',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Datos guardados correctamente')),
    );
    Navigator.pop(context);
  } catch (error, stack) {
    print('Flutter error: $error');
    print('Stack trace: $stack');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error al guardar los datos: $error'))
    );
  }
}
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Resultado del Análisis')),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children:
                      controllers.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            controller: entry.value,
                            decoration: InputDecoration(
                              labelText: entry.key,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: guardarEnSupabase,
                child: Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

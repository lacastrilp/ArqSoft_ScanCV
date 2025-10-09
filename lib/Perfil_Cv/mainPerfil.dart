import 'package:flutter/material.dart';
import 'package:scanner_personal/Perfil_Cv/perfill.dart'; // Importamos el archivo con la pantalla de perfil
import 'package:supabase_flutter/supabase_flutter.dart';

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
      home: ProfileScreen(), // Llamamos a la pantalla de perfil
    );
  }
}

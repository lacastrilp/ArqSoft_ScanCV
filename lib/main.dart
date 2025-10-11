import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Home/home.dart';
import 'supabase_singleton.dart';

// 🔧 Supabase configuración
const supabaseUrl = 'https://utvbtdxeseokumaosali.supabase.co'; // ⚠️ reemplázala con tu real
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV0dmJ0ZHhlc2Vva3VtYW9zYWxpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTg1Mzg1OSwiZXhwIjoyMDc1NDI5ODU5fQ.JiQBPoa_BvGtHOzANxDMsdIPzgc1aufu1rCQ2MiXB8Q'; // ⚠️ reemplázala con tu real

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase una sola vez
  await SupabaseManager.instance.init(
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scanner Personal',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cv_generator.dart';

// Constante para la API key
const String ASSEMBLY_API_KEY = '127d118f76c446a0ad8dce63a120336d';
const int MAX_MONTHLY_TRANSCRIPTIONS = 25000; // ~416 horas = 25,000 minutos
const double COST_PER_MINUTE = 0.002; // $0.12 por hora = $0.002 por minuto

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://zpprbzujtziokfyyhlfa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwcHJienVqdHppb2tmeXlobGZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA3ODAyNzgsImV4cCI6MjA1NjM1NjI3OH0.cVRK3Ffrkjk7M4peHsiPPpv_cmXwpX859Ii49hohSLk',
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AppSelectionScreen(),
  ));
}

final supabase = Supabase.instance.client;

class AppSelectionScreen extends StatelessWidget {
  const AppSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Herramientas Disponibles',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tarjeta para el generador de CV
            _buildSelectionCard(
              context,
              title: 'Generador de Hojas de Vida',
              description: 'Crea tu CV paso a paso usando audio',
              iconData: Icons.description,
              color: Color(0xFF4B9EFA),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CVGenerator()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData iconData,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          width: double.infinity,
          child: Column(
            children: [
              Icon(
                iconData,
                size: 60,
                color: color,
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

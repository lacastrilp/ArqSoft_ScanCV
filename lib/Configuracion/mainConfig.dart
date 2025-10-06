import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanner_personal/WidgetBarra.dart';
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zpprbzujtziokfyyhlfa.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwcHJienVqdHppb2tmeXlobGZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA3ODAyNzgsImV4cCI6MjA1NjM1NjI3OH0.cVRK3Ffrkjk7M4peHsiPPpv_cmXwpX859Ii49hohSLk',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Configuraciones',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}
//1.CUENTA
class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: const CustomAppBar(title: 'Cuenta'),
      body: ListView(

        children: [
          // Opciones al ingresar a cuenta
          HoverableListTile(icon: Icons.person, text: "Perfil", onTap: () {
            Navigator.pushNamed(context, '/perfil');
          },),
          HoverableListTile(icon: Icons.lock, text: "Cambiar contraseña", onTap: () {
            Navigator.push(context,MaterialPageRoute(
              builder: (context) => ChangeCredentialScreen(tipo: 'CONTRASEÑA'),),);
          },),
        ],
      ),
    );
  }
}


//1.2 Cambiar contraseña/correo

class ChangeCredentialScreen extends StatelessWidget {
  final String tipo;

  const ChangeCredentialScreen({super.key, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    return Scaffold(
      appBar: const CustomAppBar(title: "Cambiar Contraseña"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: currentController,
              obscureText: tipo == 'CONTRASEÑA',
              decoration: InputDecoration(
                labelText: '$tipo actual',
                labelStyle: GoogleFonts.poppins(color: Color(0xFF090467)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: newController,
              obscureText: tipo == 'CONTRASEÑA',
              decoration: InputDecoration(
                labelText: 'Nuevo $tipo',
                labelStyle: GoogleFonts.poppins(color: Color(0xFF090467)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmController,
              obscureText: tipo == 'CONTRASEÑA',
              decoration: InputDecoration(
                labelText: 'Confirmar $tipo',
                labelStyle: GoogleFonts.poppins(color: Color(0xFF090467)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff9ee4b8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.save, color: Color(0xFF090467)),
                label: Text(
                  'Guardar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF090467),
                  ),
                ),
                onPressed: () {
                  if (newController.text == confirmController.text &&
                      newController.text.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$tipo cambiado con éxito.', style: GoogleFonts.poppins())),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('El $tipo no coincide.', style: GoogleFonts.poppins())),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


//3. NOTIFICACIONES
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}
class _NotificationsScreenState extends State<NotificationsScreen> {
  bool notificationsEnabled = true;
  bool sms = false;
  bool email = true;
  bool whatsapp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Notificaciones'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Permitir notificaciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Permitir notificaciones',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF090467),
                ),),
              Switch(
                value: notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    notificationsEnabled = value;

                    if (value) {
                      // Si se activan notificaciones, se activa Email
                      email = true;
                    } else {
                      // Si se desactivan notificaciones, se apagan todas las preferencias
                      sms = false;
                      email = false;
                      whatsapp = false;
                    }
                  });
                },
                activeColor: Colors.deepPurpleAccent,
                inactiveThumbColor: Colors.deepPurple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sección Preferencias
          Text('Preferencias',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF090467),
            ),),
          const Divider(),
          SwitchListTile(
            title: Text('SMS',style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF090467),
            ),),
            value: sms,
            activeColor: Color(0xff9ee4b8),
            inactiveThumbColor: Colors.grey,
            onChanged: notificationsEnabled
                ? (value) => setState(() => sms = value)
                : null, // Desactiva el switch si notificaciones están apagadas
          ),
          SwitchListTile(
            title: Text('Email',style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF090467),
            ),),
            value: email,
            activeColor: Color(0xff9ee4b8),
            inactiveThumbColor: Colors.grey,
            onChanged: notificationsEnabled
                ? (value) => setState(() => email = value)
                : null,
          ),
          SwitchListTile(
            title:  Text('WhatsApp',style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF090467),
            ),),
            value: whatsapp,
            activeColor: Color(0xff9ee4b8),
            inactiveThumbColor: Colors.grey,
            onChanged: notificationsEnabled
                ? (value) => setState(() => whatsapp = value)
                : null,
          ),
          const SizedBox(height: 24),

          // Sección Actualizaciones
          Text('Actualizaciones', style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF090467),
          ),),
          const Divider(),
           Text('Scanner ya está actualizada',style : GoogleFonts.poppins()),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                // Acción de reporte
              },
              icon: Icon(Icons.report,color: const Color.fromARGB(255, 103, 35, 118), size: 20),
              label: Text(
                'Reportar',
                style: TextStyle(color: Color(0xFF090467)),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//4.IDIOMA
class LanguageScreen extends StatefulWidget {
  @override
  _LanguageScreenState createState() => _LanguageScreenState();
}
class _LanguageScreenState extends State<LanguageScreen> {
  final List<String> languages = [
    'Alemán',
    'Español',
    'Francés',
    'Inglés',
    'Portugués'
  ];
  List<String> filteredLanguages = [];

  @override
  void initState() {
    super.initState();
    filteredLanguages = List.from(languages)..sort();
  }

  void filterLanguages(String query) {
    setState(() {
      filteredLanguages = languages
          .where((lang) =>
          lang.toLowerCase().contains(query.toLowerCase()))
          .toList()
        ..sort();
    });
  }

  void changeLanguage(String lang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_getChangingText(lang))),
    );
  }

  String _getChangingText(String lang) {
    switch (lang) {
      case 'Español':
        return 'Cambiando idioma...';
      case 'Inglés':
        return 'Changing language...';
      case 'Francés':
        return 'Changement de langue...';
      case 'Portugués':
        return 'Mudando idioma...';
      case 'Alemán':
        return 'Sprache ändern...';
      default:
        return 'Cambiando idioma...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Idioma')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterLanguages,
              decoration: InputDecoration(
                hintText: 'Buscar idioma...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredLanguages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.language),
                  title: Text(filteredLanguages[index]),
                  onTap: () => changeLanguage(filteredLanguages[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//5.Ayuda
class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});
   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Ayuda'),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Usar nuestra aplicacion es muy sencillo, para escanear o cargar un hoja de vida debes seleccionar la opcio de "Escanear"....',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(),
            )
          ],
        ),
      ),
    );
  }
}

//Cerrar sesion
class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Cerrar sesión?'),
        content: Text('¿Estás seguro que deseas salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              exit(0); // cierra completamente la app pero en emulador
            },
            child: Text('Sí, salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cerrar sesión')),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.logout),
          label: Text('Cerrar sesión'),
          onPressed: () => _confirmLogout(context),
        ),
      ),
    );
  }
}

// Clases para las opciones laterales del menu
class HoverableListTile extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const HoverableListTile({
    Key ? key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.iconColor = const Color(0xFF787a80),
    this.textColor = const Color(0xFF090467),
    this.backgroundColor = const Color(0xfff5f5fa),
    this.borderColor = const Color(0xFF090467),
  }) : super(key: key);

  @override
  _HoverableListTileState createState() => _HoverableListTileState();
}
class _HoverableListTileState extends State<HoverableListTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isHovering ? Color(0xff9ee4b8) : Color(0xFFeff8ff),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isHovering
              ? [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]
              : [],
        ),
        child: ListTile(
          leading: Icon(widget.icon, color: _isHovering ? Color(0xFF090467) : Color(0xFF787a80),),
          title: Text(
            widget.text,
            style: GoogleFonts.poppins(
              color: widget.textColor,
              fontWeight: FontWeight.bold, // 👈 Esto hace el texto en negrita
            ),
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanner_personal/Formulario/main.dart';
import 'package:scanner_personal/Login/data_base/database_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanner_personal/Configuracion/mainConfig.dart';
import 'package:scanner_personal/WidgetBarra.dart';
import '../Audio/screens/AudioRecorderScreen.dart';
import '../Audio/screens/cv_generator.dart';
import '../Formulario/cv_form.dart';
final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      //Donde dice Menu en el sidebar ->
      drawer: Drawer(
        backgroundColor: Color(0xfff5f5fa),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 70,
              child: DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFFeff8ff)),
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 12),
                    child: Text(
                      'Menú',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF090467),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),


            HoverableListTile(icon: Icons.person, text: "Cuenta", onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountScreen()),
              );
            },),
            HoverableListTile(icon: Icons.notifications, text: "Notificaciones",onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },),
            HoverableListTile(icon: Icons.help, text: "Ayuda", onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AcercaDeScreen()),
              );
            },),
            // Pendiente mirar los colores de este coso para cerrar sesion !

            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text("Cerrar sesión", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // cerrar el drawer primero
                Future.delayed(const Duration(milliseconds: 300), () {
                  final parentContext = scaffoldKey.currentContext!;
                  showDialog(
                    context: parentContext,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('¿Cerrar sesión?',selectionColor: Color(0xFF090467),),
                      content: const Text('¿Estás seguro que deseas salir de la aplicación?'),titleTextStyle: GoogleFonts.poppins() ,
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            scaffoldKey.currentState?.openDrawer();
                          },
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () async{
                            Navigator.pop(dialogContext);

                            // Mostrar SnackBar
                            scaffoldMessengerKey.currentState?.showSnackBar(
                              const SnackBar(
                                content: Text('Cerrando sesión...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            await DatabaseHelper.instance.cerrarSesion();

                            await Future.delayed(const Duration(seconds: 2));

                            if (!parentContext.mounted) return;

                            Navigator.of(parentContext).pushNamedAndRemoveUntil(
                              '/login',
                                  (route) => false,
                            );
                          },
                          child: const Text('Sí, salir'),
                        ),
                      ],
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
      appBar: const CustomAppBar(title: ''), // appBar

      // Este es el body, donde están las funcionalidades
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xffffffff),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecciona una opción',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount;
                    double width = constraints.maxWidth;

                    if (width >= 1000) {
                      crossAxisCount = 4;
                    } else if (width >= 600) {
                      crossAxisCount = 3;
                    } else {
                      crossAxisCount = 2;
                    }

                    return AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: GridView.count(
                        key: ValueKey(crossAxisCount),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1,
                        // Llamo a la clase para generar las diferentes cards de funciones
                        children: [
                          CustomCard(
                            text: 'Escanear Documento',
                            icon: Icons.camera_alt,
                            onTap: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? foto = await picker.pickImage(source: ImageSource.camera);

                              if (foto != null) {
                                final bytes = await foto.readAsBytes();
                                final supabase = Supabase.instance.client;
                                final nombreArchivo = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';

                                await supabase.storage.from('cv').uploadBinary('archivos/$nombreArchivo', bytes);

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Foto subida exitosamente')),
                                );
                              }
                            },
                          ),
                          CustomCard(
                            text: 'Grabar Audio',
                            icon: Icons.mic,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CVGenerator()),
                              );
                            },
                          ),
                          CustomCard(
                            text: 'Llenar Formulario',
                            icon: Icons.newspaper_rounded,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CVFormEditor(),
                                ),
                              );
                            },
                          ),

                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Clase para confirmar Logout
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

// Clases para las opciones de menu principal
class CustomCard extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap; // 👈 Agregado

  CustomCard({
    required this.text,
    required this.icon,
    this.onTap, // 👈 Agregado
  });

  @override
  _CustomCardState createState() => _CustomCardState();
}
class _CustomCardState extends State<CustomCard> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(_controller);
  }

  void _onHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
      if (isHovering) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: 50, // 👈 Ancho fijo
          height: 50, // 👈 Alto fijo
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _isHovering ? Color(0xff9ee4b8) : Color(0xfff5f5fa),
              borderRadius: BorderRadius.circular(12), // 👈 Bordes redondeado
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF787a80).withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(12), // 👈 Padding reducido
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: 46, color: _isHovering ? Color(0xFF090467) : Color(0xFF787a80),), // 👈 Icono más pequeño
                    SizedBox(height: 6),

                    Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18, // 👈 Texto más pequeño
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF090467),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          color: _isHovering ? Color(0xff9ee4b8) : Color(0xfff5f5fa),
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

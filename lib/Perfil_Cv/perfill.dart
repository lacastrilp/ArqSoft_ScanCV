import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanner_personal/Perfil_Cv/edit_Profile_Screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanner_personal/WidgetBarra.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _expandedIndex;
  int? _hoverIndex;
  Map<String, dynamic> userData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }
// Funcion para los datos de la base de datos Check
  Future<void> fetchUserData() async {
    final supabase = Supabase.instance.client;
    final userId = '3';

    try {
      final response = await supabase
          .from('perfil_information')
          .select()
          .eq('id', userId)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        setState(() {
          userData = {
            "Información Personal": {
              "Nombres": response['nombres'] ?? '',
              "Apellidos": response['apellidos'] ?? '',
              "Fotografía": response['fotografia'] ?? '',
              "Dirección": response['direccion'] ?? '',
              "Teléfono": response['telefono'] ?? '',
              "Correo electrónico": response['correo'] ?? '',
              "Nacionalidad": response['nacionalidad'] ?? '',
              "Fecha de nacimiento": response['fecha_nacimiento'] ?? '',
              "Estado civil": response['estado_civil'] ?? '',
            },
            "Redes y Portafolio": {
              "LinkedIn": response['linkedin'] ?? '',
              "GitHub": response['github'] ?? '',
              "Portafolio": response['portafolio'] ?? '',
            },
            "Experiencia Laboral": {
              "Perfil profesional": response['perfil_profesional'] ?? '',
              "Objetivos Profesionales": response['objetivos_profesionales'] ??
                  '',
              "Experiencia Laboral": response['experiencia_laboral'] ?? '',
              "Expectativas Laborales": response['expectativas_laborales'] ??
                  '',
              "Experiencia Internacional": response['experiencia_internacional'] ??
                  '',
            },
            "Educación y Conocimientos": {
              "Educación": response['educacion'] ?? '',
              "Habilidades": response['habilidades'] ?? '',
              "Idiomas": response['idiomas'] ?? '',
              "Certificaciones": response['certificaciones'] ?? '',
              "Participación en Proyectos": response['proyectos'] ?? '',
              "Publicaciones": response['publicaciones'] ?? '',
              "Premios": response['premios'] ?? '',
              "Voluntariados": response['voluntariados'] ?? '',
            },
            "Otros": {
              "Referencias": response['referencias'] ?? '',
              "Permisos y Documentación": response['permisos_documentacion'] ??
                  '',
              "Vehículo y Licencias": response['vehiculo_licencias'] ?? '',
              "Disponibilidad para Entrevistas": response['disponibilidad_entrevistas'] ??
                  '',
            }
          };
        });
      } else {
        setState(() {
          userData = {};
        });
      }
    } catch (error) {
      print("Error al obtener los datos: $error");
      setState(() {
        userData = {};
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final infoPersonal = userData["Información Personal"] ?? {};
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: const CustomAppBar(title: 'Informacion Personal'), // App Bar general con el tituli
      floatingActionButton:userData.isNotEmpty?
          // Está el boton flotante de editar el perfil
      Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0, top: 20),
          child: FloatingActionButton.extended(
            backgroundColor: Color(0xff9ee4b8),
            icon: Icon(Icons.edit, color: Color(0xFF090467)),
            label: Text(
              'Editar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF090467),
              ),
            ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        userId: '3', // cambiar por el user autenticado
                        userData: userData,
                      ),
                    ),
                  );
                  if (result == true) await fetchUserData();
                },
              ),
            ),
          )
          : null,

      // Boby lit solo es para presentar la info
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userData.isEmpty
          ? Center(child: Text("No hay datos de perfil disponibles."))
          : SingleChildScrollView(

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Alineación a la izquierda
            children: [
              _buildProfileHeader(),
              // Usar un Row para la foto y el texto
              SizedBox(height: 20),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  iconTheme: IconThemeData(
                    color: Color(0xFF090467),
                  ),
                ),
                child: ExpansionPanelList(
                  animationDuration: Duration(milliseconds: 400),
                  expansionCallback: (index, _) {
                    setState(() {
                      _expandedIndex = (_expandedIndex == index) ? null : index;
                    });
                  },
                  children: _buildPanels(),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // Acá es donde se presentan las secciones
  List<ExpansionPanel> _buildPanels() {
    List<String> categories = userData.keys.toList();
    return List.generate(categories.length, (index) {
      String category = categories[index];
      var content = userData[category];

      return ExpansionPanel(
        canTapOnHeader: true,
        backgroundColor: Color(0xffffffff),
        // Titulos de cada seccion
        headerBuilder: (context, isExpanded) {
          return Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.all(12),
            child: Text(
              category,
              style: GoogleFonts.poppins(fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF090467)),
            ),
          );
        },
        body: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildContent(content),
            ),
          ),
        ),
        isExpanded: _expandedIndex == index,
      );
    });
  }

// Carta del centro de la pantalla con la info basica
  Widget _buildProfileHeader() {
    final photoUrl = userData["Información Personal"]?["Fotografía"] ?? "";
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : AssetImage("assets/avatar.png") as ImageProvider,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.camera_alt, color: Color(0xFF090467)),
            ),
          ),
          SizedBox(height: 10),
          _buildBasicInfoCard(),
        ],
      ),
    );
  }
  Widget _buildBasicInfoCard() {
    final info = userData["Información Personal"];
    if (info == null) return SizedBox.shrink();

    return Card(
      color: Color(0xffd2e8fc),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Información Básica",style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF090467), // Opcional, para asegurar color de texto
              ),),
            SizedBox(height: 8),
            Text("Nombre: ${info['Nombres']} ${info['Apellidos']}", style: GoogleFonts.poppins(fontSize: 16, color: Color(0xFF000000)),),
            Text("Correo: ${info['Correo electrónico']}",style: GoogleFonts.poppins(fontSize: 16, color: Color(0xFF000000)),),
            Text("Teléfono: ${info['Teléfono']}",style: GoogleFonts.poppins(fontSize: 16, color: Color(0xFF000000)),),
            Text("Dirección: ${info['Dirección']}",style: GoogleFonts.poppins(fontSize: 16, color: Color(0xFF000000)),),
          ],
        ),
      ),
    );
  }
// Estilo de la info de las secciones
  List<Widget> _buildContent(dynamic content) {
    if (content is Map) {
      return content.entries.map((entry) {
        if (entry.key == "Fotografía") return SizedBox();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text("${entry.key}: ${entry.value}",
              style: GoogleFonts.poppins(fontSize: 16, color: Color(0xFF000000), fontWeight: FontWeight.w400)),
        );
      }).toList();
    }
    return [
      Text("No hay información disponible", style: GoogleFonts.poppins(fontSize: 20, color: Color(0xFF000000))),
    ];
  }
}
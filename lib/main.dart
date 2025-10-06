import 'package:flutter/material.dart';
import 'package:scanner_personal/Perfil_Cv/perfill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scanner_personal/Login/screens/auth_router.dart';
import 'package:scanner_personal/Login/screens/change_password_screen.dart';
import 'package:scanner_personal/Login/screens/login_screen.dart';
import 'package:scanner_personal/Login/screens/registro_screen.dart';
import 'package:scanner_personal/Home/home.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Configuracion/mainConfig.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
//5:52
  usePathUrlStrategy();

  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: 'https://zpprbzujtziokfyyhlfa.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwcHJienVqdHppb2tmeXlobGZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA3ODAyNzgsImV4cCI6MjA1NjM1NjI3OH0.cVRK3Ffrkjk7M4peHsiPPpv_cmXwpX859Ii49hohSLk'
  );
  runApp(MyApp());
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: '/home',
      routes: {
        '/': (_) => const AuthRouter(),
        //'/login': (_) => const LoginScreen(),
        '/registro': (_) => RegistroScreen(),
        '/home': (_) => HomeScreen(),
        '/change-password': (_) => CambiarPasswordScreen(), //
        '/perfil': (_) => ProfileScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/cv_generator.dart';

Future<void> main() async {

  await dotenv.load();

  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Generador de CV',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const CVGenerator(),
    );
  }
}
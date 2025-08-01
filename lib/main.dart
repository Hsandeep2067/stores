import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:newuser/loginpage.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth',
      home: LoginPage(), // first page
      debugShowCheckedModeBanner: false,
    );
  }
}

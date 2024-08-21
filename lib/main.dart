// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:global_chat_app/firebase_options.dart';
import 'package:global_chat_app/provider/userprovider.dart';
import 'package:global_chat_app/screen/splace_screen.dart';
// ignore: unused_import
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ChangeNotifierProvider(
      create: (context) => UserProvider(), child: MyApp()));
}

// void initialiseApp({required options}) {}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          brightness: Brightness.light,
          useMaterial3: true,
          fontFamily: "poppins"),
      debugShowCheckedModeBanner: false,
      home: SplaceScreen(),
    );
  }
}

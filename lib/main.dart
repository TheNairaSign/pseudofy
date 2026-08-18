import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pseudofy/screens/home_screen.dart';

void main() {
  dotenv.load();
  runApp(const ProviderScope(child: PseudofyApp()));
}

class PseudofyApp extends StatelessWidget {
  const PseudofyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pseudofy',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      // darkTheme: ThemeData.dark().copyWith(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const HomeScreen(),
    );
  }
}

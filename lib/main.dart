import 'package:dent_bul_hospital_app/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  //supabase setup
  await Supabase.initialize(
    url: "https://jwvgwwtneobvssnnbfmk.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3dmd3d3RuZW9idnNzbm5iZm1rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NTQwNjQsImV4cCI6MjA3NTEzMDA2NH0.jrB-1Aq1nREzWqDa8uxDM4Gp8Sv1yDvDJP7xU4tUpbI",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dent Bul Hospital',
      home: const LoginPage(),
    );
  }
}

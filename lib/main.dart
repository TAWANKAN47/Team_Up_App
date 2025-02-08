import 'package:flutter/material.dart';
import 'package:team_up/screens/welcome_screen.dart'; // นำเข้า WelcomeScreen
import 'package:team_up/screens/signin_screen.dart'; // นำเข้า SignInScreen
import 'package:team_up/screens/signup_screen.dart'; // นำเข้า SignUpScreen
import 'package:team_up/screens/profile_page.dart';
import 'package:team_up/configserver/cf.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(
            color: Colors.white, //สีicon
          ),
          backgroundColor: Colors.transparent, // AppBar โปร่งใส
          elevation: 0,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

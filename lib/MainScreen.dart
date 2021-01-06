import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'LoadingScreen.dart';
import 'AuthScreen.dart';
import 'ChatScreen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<void> starapp() async {
    await Firebase.initializeApp();
    await FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: starapp(),
      builder: (context, data) {
        if (data.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        } else
          return StreamBuilder<User>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ChatScreen();
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return LoadingScreen();
              } else
                return LoginScreen();
            },
          );
      },
    );
  }
}

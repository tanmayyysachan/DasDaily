import 'package:dasdaily/authentication/login_page.dart';
import 'package:dasdaily/screens/landing_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dasdaily/services/firebase_options.dart';
import 'package:flutter/material.dart';

// Usually this main block always there when firebase is there for authentication
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // So MyApp inherits everything from StatelessWidget, which has a built-in constructor that accepts an optional Key.
  const MyApp({super.key}); // This is a constructor for the MyApp class

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DasDaily',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Still checking the auth state
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            // User is logged in
            return const LandingPage();
          } else {
            // User is NOT logged in
            return const LoginPage();
          }
        },
      ),
      // home: const SignupPage(),
    );
  }
}
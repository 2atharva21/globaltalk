import 'package:flutter/material.dart';
import 'package:global_chat_app/provider/userprovider.dart';
import 'package:global_chat_app/screen/dashboard_screen.dart';
import 'package:global_chat_app/screen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class SplaceScreen extends StatefulWidget {
  const SplaceScreen({super.key});

  @override
  State<SplaceScreen> createState() => _SplaceScreenState();
}

class _SplaceScreenState extends State<SplaceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); // Repeat animation

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Check authentication status after animation setup
    checkAuthStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void checkAuthStatus() async {
    // Wait for the animation to complete
    await Future.delayed(Duration(seconds: 2));

    var user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      openLogin();
    } else {
      Provider.of<UserProvider>(context, listen: false).getUserDetails();
      openDashboard();
    }
  }

  void openDashboard() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return DashboardScreen();
    }));
  }

  void openLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return LoginScreen();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SizedBox(
            height: 100,
            width: 100,
            child: Image.asset("assets/images/logo.png"),
          ),
        ),
      ),
    );
  }
}

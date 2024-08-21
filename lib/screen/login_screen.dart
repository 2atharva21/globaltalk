import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:global_chat_app/screen/signup_screen.dart';
import 'package:global_chat_app/screen/splace_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> createAccount() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );

      // Show the custom success dialog
      showDialog(
        context: context,
        barrierDismissible:
            false, // Prevent closing the dialog by tapping outside
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title: const Text(
              'Welcome Back!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Successfully logged in to GlobeTalk!'),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SplaceScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);

                        return SlideTransition(
                            position: offsetAnimation, child: child);
                      },
                    ),
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      print('Account logged in successfully');
    } catch (e) {
      final SnackBar messageSnackbar = SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(e.toString()),
      );
      ScaffoldMessenger.of(context).showSnackBar(messageSnackbar);
      print(e);
    }
  }

  final GlobalKey<FormState> userForm = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme.apply(
          fontFamily: 'Poppins',
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('GlobeTalk'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: userForm,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Image.asset("assets/images/logo.png"),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please log in to continue',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: email,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Colors.blueGrey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: password,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.blueGrey[50],
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: _animation,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          shadowColor: Colors.blueAccent.withOpacity(0.5),
                          elevation: 5,
                        ),
                        onPressed: () async {
                          FocusScope.of(context).unfocus();

                          setState(() {
                            isLoading = true;
                          });
                          _animationController.forward().then((_) {
                            if (userForm.currentState!.validate()) {
                              createAccount();
                            }
                            _animationController.reverse();
                          });
                          setState(() {
                            isLoading = false;
                          });
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text('Login',
                                style: TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have an account?',
                        style: textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (context) {
                          return const SignupScreen();
                        }));
                      },
                      child: Text(
                        'Sign up here',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

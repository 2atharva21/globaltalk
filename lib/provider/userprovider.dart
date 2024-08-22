import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String userName = "";
  String userEmail = "";
  String userId = "";
  final FirebaseFirestore db = FirebaseFirestore.instance;
  User? autoUser;

  UserProvider() {
    // Initialize user details on provider creation
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        autoUser = user;
        getUserDetails();
      } else {
        // Handle user not signed in
        autoUser = null;
        userName = "";
        userEmail = "";
        userId = "";
        notifyListeners();
      }
    });
  }

  Future<void> getUserDetails() async {
    try {
      if (autoUser == null) {
        throw Exception("User not authenticated");
      }

      DocumentSnapshot dataSnapshot =
          await db.collection("users").doc(autoUser!.uid).get();

      if (dataSnapshot.exists) {
        Map<String, dynamic>? data =
            dataSnapshot.data() as Map<String, dynamic>?;
        userName = data?['name'] ?? "Unnamed User";
        userEmail = data?['email'] ?? "No Email";
        userId = autoUser!.uid;
      } else {
        throw Exception("User document does not exist in Firestore");
      }

      notifyListeners();
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  // Optional: Method to update user details manually
  void setUser(User user) {
    autoUser = user;
    getUserDetails();
  }

  // Optional: Sign out the user and clear details
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    autoUser = null;
    userName = "";
    userEmail = "";
    userId = "";
    notifyListeners();
  }
}

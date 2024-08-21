import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String userName = " hello";
  String userEmail = "hello";
  String userId = "hello";
  final FirebaseFirestore db = FirebaseFirestore.instance;
  User? autoUser;

  UserProvider() {
    if (autoUser != null) {
      getUserDetails();
    }
  }

  Future<void> getUserDetails() async {
    autoUser = FirebaseAuth.instance.currentUser;
    try {
      if (autoUser == null) {
        throw "User not authenticated";
      }

      DocumentSnapshot dataSnapshot =
          await db.collection("users").doc(autoUser!.uid).get();

      if (dataSnapshot.exists) {
        Map<String, dynamic>? data =
            dataSnapshot.data() as Map<String, dynamic>?;
        userName = data?['name'] ?? "";
        userEmail = data?['email'] ?? "";
        userId = data?['Id'] ?? "";
      } else {
        throw "Document does not exist";
      }

      notifyListeners();
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  void setUser(User user) {
    autoUser = user;
    getUserDetails();
  }
}

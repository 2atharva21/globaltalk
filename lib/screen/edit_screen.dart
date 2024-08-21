import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:global_chat_app/provider/userprovider.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _nameText = TextEditingController();
  final GlobalKey<FormState> _editProfileForm = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameText.text = userProvider.userName;
  }

  @override
  void dispose() {
    _nameText.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String userId = userProvider.userId;

      if (userId.isEmpty) {
        throw "User ID is null or empty";
      }

      String updatedName = _nameText.text.trim();
      if (updatedName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name cannot be empty')),
        );
        return;
      }

      Map<String, dynamic> dataToUpdate = {
        "name": updatedName,
      };

      await _db.collection('users').doc(userId).update(dataToUpdate);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
    } catch (e) {
      print("Error updating name: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_editProfileForm.currentState!.validate()) {
                _updateName(); // Call function to update name only
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _editProfileForm,
          child: Column(
            children: [
              TextFormField(
                controller: _nameText,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Name cannot be empty";
                  }
                  return null;
                },
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

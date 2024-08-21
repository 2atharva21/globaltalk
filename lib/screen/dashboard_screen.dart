import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:global_chat_app/provider/userprovider.dart';
import 'package:global_chat_app/screen/chatroom_screen.dart';
import 'package:global_chat_app/screen/profile.dart';
import 'package:global_chat_app/screen/splace_screen.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _chatroomsList = [];
  List<String> _chatroomsIds = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getChatrooms();
    _searchController.addListener(() {
      _searchChatrooms(_searchController.text);
    });

    // Show welcome back message after the widget is built
    Future.delayed(Duration.zero, () {
      _showWelcomeBackMessage();
    });
  }

  Future<void> _getChatrooms() async {
    try {
      var querySnapshot = await _db.collection("chatrooms").get();
      List<Map<String, dynamic>> tempChatroomsList = [];
      List<String> tempChatroomsIds = [];

      for (var doc in querySnapshot.docs) {
        var chatroomData = doc.data();
        var chatroomId = doc.id;
        int messageCount = await _getMessageCount(chatroomId);

        chatroomData['message_count'] =
            messageCount; // Add message count to chatroom data
        tempChatroomsList.add(chatroomData);
        tempChatroomsIds.add(chatroomId);
      }

      setState(() {
        _chatroomsList = tempChatroomsList;
        _chatroomsIds = tempChatroomsIds;
      });
    } catch (e) {
      print("Error fetching chatrooms: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load chatrooms. Please try again later.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<int> _getMessageCount(String chatroomId) async {
    try {
      var querySnapshot = await _db
          .collection("chatrooms")
          .doc(chatroomId)
          .collection("messages")
          .get();
      return querySnapshot.size;
    } catch (e) {
      print("Error fetching message count: $e");
      return 0;
    }
  }

  Future<void> _refreshChatrooms() async {
    await _getChatrooms();
  }

  void _searchChatrooms(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _showWelcomeBackMessage() {
    var userProvider = Provider.of<UserProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Welcome back, ${userProvider.userName}!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            // Optional: Add dismiss action if needed
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _searchQuery.isEmpty
            ? const Text('GlobeTalk',
                style: TextStyle(fontWeight: FontWeight.bold))
            : TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _searchChatrooms,
                decoration: InputDecoration(
                  hintText: 'Search Chatrooms',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchChatrooms('');
                    },
                  ),
                ),
              ),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: CircleAvatar(
            backgroundColor: Colors.blueGrey[600],
            foregroundColor: Colors.white,
            child: Text(userProvider.userName.isNotEmpty
                ? userProvider.userName[0]
                : '?'),
          ),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              color: Colors.blueAccent,
              padding:
                  const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    radius: 40,
                    child: Text(
                      userProvider.userName.isNotEmpty
                          ? userProvider.userName[0]
                          : '?',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProvider.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userProvider.userEmail,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
              leading: Icon(Icons.person, color: Colors.blueGrey[800]),
              title: const Text('Profile'),
              tileColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            ListTile(
              onTap: () async {
                await _auth.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SplaceScreen()),
                  (route) => false,
                );
              },
              leading: Icon(Icons.logout, color: Colors.blueGrey[800]),
              title: const Text('Logout'),
              tileColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Spacer(), // This will push the last item to the bottom
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Made by Atharva Zare',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshChatrooms,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // The search bar is now part of the AppBar
              Expanded(
                child: ListView.builder(
                  itemCount: _chatroomsList.length,
                  itemBuilder: (BuildContext context, int index) {
                    var chatroom = _chatroomsList[index];
                    String chatroomName =
                        chatroom["chatroom_name"] ?? "Unnamed Chatroom";
                    int messageCount = chatroom['message_count'] ?? 0;

                    if (!_searchQuery.isEmpty &&
                        !chatroomName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase())) {
                      return SizedBox
                          .shrink(); // Skip this item if it doesn't match the search query
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatroomScreen(
                                chatroomName: chatroomName,
                                chatroomId: _chatroomsIds[index],
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          child: Text(
                              chatroomName.isNotEmpty ? chatroomName[0] : "?"),
                        ),
                        title: Text(
                          chatroomName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '${chatroom['desc'] ?? "No Description"} | Messages: $messageCount',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

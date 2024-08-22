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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _chatroomsList = [];
  List<String> _chatroomsIds = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _borderAnimation;
  bool _isAnimatingBorder = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _borderAnimation = Tween<double>(begin: 2.0, end: 4.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _getChatrooms();
    _searchController.addListener(() {
      _searchChatrooms(_searchController.text);
    });

    // Show welcome back message after the widget is built
    Future.delayed(Duration.zero, () {
      _showWelcomeBackMessage();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
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
        int unreadCount = await _getUnreadCount(chatroomId);

        chatroomData['message_count'] = messageCount;
        chatroomData['unread_count'] =
            unreadCount; // Add unread count to chatroom data
        tempChatroomsList.add(chatroomData);
        tempChatroomsIds.add(chatroomId);
      }

      setState(() {
        _chatroomsList = tempChatroomsList;
        _chatroomsIds = tempChatroomsIds;
        _startBorderAnimation();
      });
    } catch (e) {
      print("Error fetching chatrooms: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load chatrooms. Please try again later.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 3),
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

  Future<int> _getUnreadCount(String chatroomId) async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;
      var querySnapshot = await _db
          .collection("chatrooms")
          .doc(chatroomId)
          .collection("messages")
          .where("read_by", isNotEqualTo: user.uid)
          .get();
      return querySnapshot.size;
    } catch (e) {
      print("Error fetching unread message count: $e");
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

  void _startBorderAnimation() {
    setState(() {
      _isAnimatingBorder = true;
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    });
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
          icon: AnimatedBuilder(
            animation: _borderAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blueAccent,
                    width: _borderAnimation.value,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  child: Text(userProvider.userName.isNotEmpty
                      ? userProvider.userName[0]
                      : '?'),
                ),
              );
            },
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
                  AnimatedBuilder(
                    animation: _borderAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blueAccent,
                            width: _borderAnimation.value,
                          ),
                        ),
                        child: CircleAvatar(
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
                      );
                    },
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
                            fontSize: 18,
                          ),
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
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SplaceScreen()),
                );
              },
              leading: const Icon(Icons.info),
              title: const Text('Splace Screen'),
            ),
            ListTile(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SplaceScreen()),
                );
              },
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshChatrooms,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_chatroomsList.isEmpty)
                const Center(
                  child: Text(
                    'No chatrooms available.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _chatroomsList.length,
                  itemBuilder: (context, index) {
                    var chatroom = _chatroomsList[index];
                    String chatroomName =
                        chatroom["chatroom_name"] ?? "Unnamed Chatroom";
                    int messageCount = chatroom['message_count'] ?? 0;
                    int unreadCount = chatroom['unread_count'] ?? 0;

                    if (!_searchQuery.isEmpty &&
                        !chatroomName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase())) {
                      return SizedBox
                          .shrink(); // Skip this item if it doesn't match the search query
                    }

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatroomScreen(
                                chatroomName: chatroomName,
                                chatroomId: _chatroomsIds[index],
                                receiverName: '',
                              ),
                            ),
                          );
                        },
                        leading: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blueAccent,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            child: Text(chatroomName.isNotEmpty
                                ? chatroomName[0]
                                : "?"),
                          ),
                        ),
                        title: Text(
                          chatroomName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${chatroom['desc'] ?? "No Description"}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

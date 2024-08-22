import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:global_chat_app/provider/userprovider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ChatroomScreen extends StatefulWidget {
  final String chatroomName;
  final String chatroomId;

  ChatroomScreen({
    super.key,
    required this.chatroomName,
    required this.chatroomId,
    required receiverName,
  });

  @override
  State<ChatroomScreen> createState() => _ChatroomScreenState();
}

class _ChatroomScreenState extends State<ChatroomScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final TextEditingController messageText = TextEditingController();
  FocusNode focusNode = FocusNode();
  bool _isSending = false;
  String? _replyToMessageId;
  Map<String, dynamic>? _replyMessageData;

  Future<void> sendMessage({String? replyToMessageId}) async {
    if (messageText.text.trim().isNotEmpty) {
      setState(() {
        _isSending = true;
      });

      Map<String, dynamic> messageToSend = {
        'text': messageText.text,
        'sender_name':
            Provider.of<UserProvider>(context, listen: false).userName,
        'chatroom_id': widget.chatroomId,
        'timestamp': FieldValue.serverTimestamp(),
        'reply_to': replyToMessageId,
      };

      try {
        await db.collection("messages").add(messageToSend);
        messageText.clear();
      } catch (e) {
        print('Failed to send message: $e');
      } finally {
        setState(() {
          _isSending = false;
        });
        FocusScope.of(context).unfocus();
      }
    }
  }

  void _setReplyMessage(Map<String, dynamic> messageData) {
    setState(() {
      _replyToMessageId = messageData['id'];
      _replyMessageData = messageData;
    });
  }

  void _clearReply() {
    setState(() {
      _replyToMessageId = null;
      _replyMessageData = null;
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    messageText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserName = userProvider.userName;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatroomName),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              radius: 20,
              child: Text(
                currentUserName.isNotEmpty
                    ? currentUserName[0].toUpperCase()
                    : '',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection("messages")
                  .where("chatroom_id", isEqualTo: widget.chatroomId)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("An error has occurred"),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages found"));
                }

                var allMessages = snapshot.data!.docs;
                DateTime? lastMessageDate;

                return ListView.builder(
                  reverse: true,
                  itemCount: allMessages.length,
                  itemBuilder: (BuildContext context, int index) {
                    var messageData =
                        allMessages[index].data() as Map<String, dynamic>?;
                    var messageId = allMessages[index].id;

                    if (messageData == null ||
                        !messageData.containsKey("text")) {
                      return const SizedBox.shrink();
                    }

                    bool isSentByCurrentUser =
                        messageData["sender_name"] == currentUserName;
                    String? replyToMessageId = messageData["reply_to"];
                    Timestamp timestamp = messageData["timestamp"] as Timestamp;
                    DateTime messageDate = timestamp.toDate();
                    String formattedTime =
                        DateFormat('h:mm a').format(messageDate);

                    // Show date separator if date has changed
                    bool showDateSeparator = lastMessageDate == null ||
                        messageDate.day != lastMessageDate?.day ||
                        messageDate.month != lastMessageDate?.month ||
                        messageDate.year != lastMessageDate?.year;

                    if (showDateSeparator) {
                      lastMessageDate = messageDate;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateSeparator)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: Text(
                              DateFormat('MMMM d, yyyy').format(messageDate),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onDoubleTap: () {
                            _setReplyMessage({
                              'id': messageId,
                              'text': messageData['text'],
                              'sender_name': messageData['sender_name']
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 12.0),
                            child: Column(
                              crossAxisAlignment: isSentByCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (replyToMessageId != null) ...[
                                  FutureBuilder<DocumentSnapshot>(
                                    future: db
                                        .collection('messages')
                                        .doc(replyToMessageId)
                                        .get(),
                                    builder: (context, replySnapshot) {
                                      if (!replySnapshot.hasData ||
                                          !replySnapshot.data!.exists) {
                                        return SizedBox.shrink();
                                      }

                                      var replyMessageData = replySnapshot.data!
                                          .data() as Map<String, dynamic>;

                                      return AnimatedOpacity(
                                        opacity: 1.0,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.reply,
                                                color: Colors.blueAccent,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Replying to:",
                                                      style: TextStyle(
                                                        color:
                                                            Colors.blueAccent,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      replyMessageData['text'],
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.visible,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                Row(
                                  mainAxisAlignment: isSentByCurrentUser
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    if (!isSentByCurrentUser) ...[
                                      CircleAvatar(
                                        backgroundColor: Colors.grey[600],
                                        foregroundColor: Colors.white,
                                        radius: 16,
                                        child: Text(
                                          messageData["sender_name"]!.isNotEmpty
                                              ? messageData["sender_name"]![0]
                                                  .toUpperCase()
                                              : '',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isSentByCurrentUser
                                            ? Colors.blueAccent
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: isSentByCurrentUser
                                              ? const Radius.circular(16)
                                              : Radius.zero,
                                          bottomRight: isSentByCurrentUser
                                              ? Radius.zero
                                              : const Radius.circular(16),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0, horizontal: 16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (!isSentByCurrentUser)
                                            Text(
                                              messageData["sender_name"] ??
                                                  "Unknown",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            messageData["text"],
                                            style: TextStyle(
                                              color: isSentByCurrentUser
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedTime,
                                            style: TextStyle(
                                              color: isSentByCurrentUser
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSentByCurrentUser) ...[
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        backgroundColor: Colors.grey[600],
                                        foregroundColor: Colors.white,
                                        radius: 16,
                                        child: Text(
                                          messageData["sender_name"]!.isNotEmpty
                                              ? messageData["sender_name"]![0]
                                                  .toUpperCase()
                                              : '',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        color: Colors.blueGrey[50],
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            if (_replyMessageData != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Replying to: ${_replyMessageData!['text']}",
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.red),
                      onPressed: _clearReply,
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageText,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? CircularProgressIndicator()
                      : Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () {
                    if (!_isSending) {
                      sendMessage(replyToMessageId: _replyToMessageId);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

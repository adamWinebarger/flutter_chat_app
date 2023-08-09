import 'package:chat_app/widgets/chat_messages.dart';
import 'package:chat_app/widgets/new_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  void _setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    final token = fcm.getToken();
    print(token); //needed to be able to get our push notifs.
  }

  @override
  void initState() {
    super.initState();
    _setupPushNotifications();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FlutterChat"),
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut(); //log out functionality
            },
            icon: Icon(
                Icons.logout,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        ],
      ),
      body: const Center(
        child: Column(
          children: [
            Expanded(child: ChatMessages()),
            NewMessage()
          ],
        ),
      ),
    );
  }
}
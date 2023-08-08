import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  Widget _noMessagesWidget() {
    return const Center(
      child: Text('No messages found'),
    );
  }

  @override
  Widget build(context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('chat').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
          return _noMessagesWidget();
        }

        if (chatSnapshot.hasError) {
          return Center(
            child: Text(chatSnapshot.error.toString()),
          );
        }

        final loadedMessages = chatSnapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 40, left: 13, right: 13),
          reverse: true, //Apparently this makes our messages rise up from the bottom
          itemCount: loadedMessages.length,
          itemBuilder: (context, index) {
            final chatMessage = loadedMessages[index].data();
            final nextChatMessage = index + 1 < loadedMessages.length ?
                loadedMessages[index+1].data() : null;
            final currentMessageUserID = chatMessage['senderID'];

            if (nextChatMessage != null && nextChatMessage['senderID'] == currentMessageUserID) {
              return MessageBubble.next(
                message: chatMessage['text'],
                isMe:  chatMessage['senderID'] == authenticatedUser.uid
              );
            } else {
              return MessageBubble.first(
                userImage: chatMessage['userImage'],
                username: chatMessage['username'],
                message: chatMessage['text'],
                isMe: authenticatedUser.uid == currentMessageUserID
              );
            }

          },
        );
      },
    );

    return const Center(
      child: Text('No messages found'),
    );
  }

}
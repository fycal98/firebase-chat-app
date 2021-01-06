import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.login),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              var m = FirebaseMessaging();
              await m.unsubscribeFromTopic('all');
            },
          )
        ],
        title: Text('Chat'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ChatSpace(
              size: size,
            ),
          ),
          SendMessage(
            size: size,
          ),
        ],
      ),
    );
  }
}

class ChatSpace extends StatefulWidget {
  var size;
  ChatSpace({this.size});
  @override
  _ChatSpaceState createState() => _ChatSpaceState();
}

class _ChatSpaceState extends State<ChatSpace> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('message')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) => ListView.builder(
          reverse: true,
          itemCount: snapshot.data == null ? 0 : snapshot.data.size,
          itemBuilder: (context, i) {
            final size = widget.size;
            final String email = snapshot.data.docs[i].data()['email'];
            final String message = snapshot.data.docs[i].data()['message'];
            final String uid = snapshot.data.docs[i].data()['uid'];
            final String image = snapshot.data.docs[i].data()['image'];
            return Message(
              size: size,
              email: email,
              message: message,
              uid: uid,
              imagurl: image,
            );
          }),
    );
  }
}

class SendMessage extends StatelessWidget {
  var messagecontroller = TextEditingController();
  var size;
  SendMessage({this.size});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
            padding: EdgeInsets.all(size.width * 0.02),
            child: Container(
              width: size.width * 0.8,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: messagecontroller,
                  decoration: InputDecoration(
                      labelText: 'Enter Message Here',
                      border: InputBorder.none),
                ),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: Colors.grey.withOpacity(0.1),
              ),
            )),
        IconButton(
          icon: Icon(
            Icons.send,
            color: Colors.pinkAccent,
          ),
          onPressed: () async {
            if (messagecontroller.value.text == null) {
              return;
            }

            FocusScope.of(context).unfocus();
            var imageurl = await FirebaseFirestore.instance
                .collection('user')
                .doc(FirebaseAuth.instance.currentUser.uid)
                .get();
            await FirebaseFirestore.instance.collection('message').add({
              'message': messagecontroller.value.text,
              'uid': FirebaseAuth.instance.currentUser.uid,
              'date': Timestamp.now(),
              'email': FirebaseAuth.instance.currentUser.email,
              'image': imageurl.data()['image'],
            });

            var repoce = await http.post('https://fcm.googleapis.com/fcm/send',
                body: jsonEncode({
                  "to": "/topics/all",
                  "collapse_key": "type_a",
                  "notification": {
                    "body": "${messagecontroller.value.text}",
                    "title":
                        "${FirebaseAuth.instance.currentUser.email.substring(0, 5)}"
                  },
                }),
                headers: {
                  'Content-Type': "application/json",
                  'Authorization':
                      'key=AAAAXxwhYJA:APA91bHtEEaxUy9J0eLznug21tdYeWHu4q4rNGdImpVPAY67H8FA5DB2E2-38rTSBs8765kCH_GbDEMAus7JrjBuntbXLj7NG8OU1qGdBP_vmXISFeqIjZGieln-GD11Z4_b_CNJsO5a'
                });
            messagecontroller.clear();
          },
        ),
      ],
    );
  }
}

class Message extends StatelessWidget {
  final String message;
  final String uid;
  final String email;
  final String imagurl;
  Future<ImageProvider> getimage() async {
    var url = await FirebaseStorage.instance
        .ref('images/$uid/profile.jpg')
        .getDownloadURL();

    return NetworkImage(
      url,
    );
  }

  final size;
  const Message({this.message, this.uid, this.size, this.email, this.imagurl});
  @override
  Widget build(BuildContext context) {
    final bool sender =
        FirebaseAuth.instance.currentUser.uid == uid ? true : false;
    return Row(
      mainAxisAlignment:
          sender ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(size.width * 0.03),
          child: Stack(overflow: Overflow.visible, children: [
            Container(
              //alignment: Alignment.topLeft,
              width: size.width * 0.35,
              decoration: BoxDecoration(
                  color:
                      sender ? Colors.grey.shade300 : Colors.deepPurpleAccent,
                  borderRadius: sender
                      ? BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(0),
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10))
                      : BorderRadius.only(
                          bottomLeft: Radius.circular(0),
                          bottomRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10))),
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.02),
                child: Column(
                  crossAxisAlignment: sender
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      email.substring(0, 5),
                      style: TextStyle(
                          color: sender ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(message,
                        style: TextStyle(
                          color: sender ? Colors.black : Colors.white,
                        )),
                  ],
                ),
              ),
            ),
            Positioned(
              left: sender ? -size.width * 0.3 : 0,
              top: -size.width * 0.04,
              right: sender ? 0 : -size.width * 0.3,
              child: FutureBuilder<ImageProvider>(
                future: getimage(),
                builder: (context, data) {
                  if (data.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      backgroundColor: Colors.grey,
                    );
                  } else
                    return Container(
                      width: size.width * 0.1,
                      height: size.width * 0.1,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            alignment: Alignment.center,
                            image: data.data,
                            fit: BoxFit.fitHeight,
                          )),
                    );
                },
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

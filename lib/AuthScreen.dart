import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat/ChatScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

enum auth { login, signin }

class LoginScreen extends StatelessWidget {
  static const String route = 'LoginScreen';
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    bool islandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(children: [
          Container(
            width: size.width,
            height: islandscape ? size.height * 1.3 : size.height,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.pink, Colors.pinkAccent])),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                top: islandscape ? size.height * 0.1 : size.height * 0.2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AuthCard(size: size),
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }
}

class AuthCard extends StatefulWidget {
  const AuthCard({
    Key key,
    @required this.size,
  }) : super(key: key);

  final Size size;

  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> with TickerProviderStateMixin {
  Future<void> authenticate() async {
    if (form.currentState.validate()) {
      if (authe == auth.login) {
        var reponce = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailcontroller.value.text,
            password: passwordcontroller.value.text);
      } else {
        var reponce = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailcontroller.value.text,
                password: passwordcontroller.value.text);
        var reponce1 = await FirebaseStorage.instance
            .ref('images/${FirebaseAuth.instance.currentUser.uid}/profile.jpg')
            .putFile(image);
        var apppath = await FirebaseStorage.instance.bucket;

        var reponce2 = await FirebaseFirestore.instance
            .collection('user')
            .doc(FirebaseAuth.instance.currentUser.uid)
            .set({
          'email': FirebaseAuth.instance.currentUser.email,
          'image': '$apppath/${reponce1.ref.fullPath}'
        });
      }
    }
    var m = FirebaseMessaging();
    await m.subscribeToTopic('all');
    // Navigator.pushReplacement(
    //     context, MaterialPageRoute(builder: (context) => ChatScreen()));
  }

  File image;
  var authe = auth.login;
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController confirmcontroller = TextEditingController();
  var form = GlobalKey<FormState>();

  AnimationController confirmcontroler;
  Animation<double> confirmanimation;
  @override
  void dispose() {
    // TODO: implement dispose
    confirmcontroler.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // TODO: implement initState
    confirmcontroler = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    confirmanimation = CurvedAnimation(
      parent: confirmcontroler,
      curve: Curves.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool islandscap =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      height: authe == auth.login
          ? islandscap
              ? widget.size.height * 0.6
              : widget.size.height * 0.35
          : islandscap
              ? widget.size.height * 0.8
              : widget.size.height * 0.6,
      child: Padding(
        padding: EdgeInsets.all(widget.size.width * 0.04),
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              //crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (authe == auth.signin)
                  Card(
                    shape: CircleBorder(),
                    child: ClipOval(
                      child: image == null
                          ? null
                          : Image.file(
                              image,
                              fit: BoxFit.contain,
                              width: islandscap
                                  ? widget.size.height * 0.4
                                  : widget.size.height * 0.13,
                              height: islandscap
                                  ? widget.size.height * 0.4
                                  : widget.size.height * 0.13,
                            ),
                    ),
                  ),
                if (authe == auth.signin)
                  TextButton.icon(
                    onPressed: () async {
                      final _picker = ImagePicker();
                      var pikedimage = await _picker.getImage(
                          source: ImageSource.camera,
                          maxHeight: 200,
                          maxWidth: 200,
                          imageQuality: 100);
                      image = File(pikedimage.path);
                      setState(() {});
                    },
                    icon: Icon(
                      Icons.photo,
                      color: Colors.pinkAccent,
                    ),
                    label: Text(
                      'Take Picture',
                      style: TextStyle(color: Colors.pinkAccent),
                    ),
                  ),
                TextFormField(
                  controller: emailcontroller,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (!value.contains('@')) {
                      return 'Enter a valid Email';
                    }
                    return null;
                  },
                  decoration: InputDecoration(labelText: 'E-Mail'),
                ),
                TextFormField(
                  controller: passwordcontroller,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value.length < 6) {
                      return 'Enter a strong Password';
                    }
                    return null;
                  },
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
                authe == auth.login
                    ? SizedBox()
                    : SizeTransition(
                        sizeFactor: confirmanimation,
                        child: Container(
                          child: TextFormField(
                            controller: confirmcontroller,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (confirmcontroller.value.text !=
                                  passwordcontroller.value.text) {
                                return 'Invalid Password';
                              }
                              return null;
                            },
                            obscureText: true,
                            decoration:
                                InputDecoration(labelText: 'Confirm Password'),
                          ),
                        ),
                      ),
                SizedBox(
                  height: widget.size.height * 0.02,
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: widget.size.width * 0.2),
                  child: RaisedButton(
                    onPressed: authenticate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    color: Colors.pinkAccent,
                    elevation: 5,
                    child: Text(
                      authe == auth.login ? 'LOGIN' : 'SIGN UP',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (authe == auth.login) {
                        confirmcontroler.forward();
                      } else
                        confirmcontroler.reverse();
                      authe = authe == auth.login ? auth.signin : auth.login;
                    });
                  },
                  child: Text(
                    authe == auth.login ? 'SIGN IN INSTEAD' : 'LOGIN INSTEAD',
                    style: TextStyle(color: Colors.pinkAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      margin: EdgeInsets.only(
        top: widget.size.height * 0.05,
      ),
      // height: size.height * 0.5,
      width: widget.size.width * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black26,
            offset: Offset(0, 2),
          )
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/user_image_picker.dart';
import 'dart:io';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AuthScreenState();
  }

}

class _AuthScreenState extends State<AuthScreen> {

  final _formKey = GlobalKey<FormState>();

  var _enteredEmail = '', _enteredPassword = '', _enteredUsername = '';
  var _isLogin = true, _isAuthenticating = false;

  File? _selectedImage;

  void _submit() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid || (!_isLogin && _selectedImage == null)) {
      //show error message?
      return;
    }

    // if (isValid) {
    //   _formKey.currentState!.save(); //Apparently we need to use this save function for onSaved... explains why we had to use onchanged before
    //   print(_enteredEmail);
    //   print(_enteredPassword);
    // }

    _formKey.currentState!.save(); //Apparently we need to use this save function for onSaved... explains why we had to use onchanged before

    try {
      setState(() {
        _isAuthenticating = true;
      });

      if (_isLogin) {
        final userCreds = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
        //print(userCreds);

      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword
          (email: _enteredEmail, password: _enteredPassword);
        //print(userCredentials);

        //upload image for user
        final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${userCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageURL = await storageRef.getDownloadURL();
        //print(imageURL);

        //this stores our user data in a cloud firestore database
        await FirebaseFirestore.instance.collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username' : _enteredUsername,
          'email' : _enteredEmail,
          'imageURL' : imageURL
        });

      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {

      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.message ?? "Authentication Failed")
          )
      );
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin) UserImagePicker(onPickImage: (pickedImage) {
                            _selectedImage = pickedImage;
                          },),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Email"
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty || !EmailValidator.validate(value)) {
                                return 'Invalid email input';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          if (!_isLogin)
                            TextFormField(
                              decoration: const InputDecoration(labelText: "Username"),
                              enableSuggestions: false,
                              validator: (value) {
                                if (value == null || value.isEmpty || value.trim().length < 4) {
                                  return "Invalid username value";
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredUsername = value!;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                                labelText: "Password"
                            ),
                            autocorrect: false,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return "Password must be at least 6 characters long";
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(

                            ),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer
                              ),
                              child: Text(_isLogin ? "Login" : 'Sign up'),
                            ),
                          if (!_isAuthenticating)
                            TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(_isLogin ? 'Create an account' : "I already have an account")
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

}
import 'package:drawgrim/GameRoom.dart';
import 'package:flutter/material.dart';
import 'package:drawgrim/ChatPage.dart'; // ChatPage import 추가
import 'package:drawgrim/RegisterPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Loginpage extends StatelessWidget {
  const Loginpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: LoginForm(),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool saving = false;
  final _authentication = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: saving,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (value) {
                  email = value;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                onChanged: (value) {
                  password = value;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                  onPressed: () async {
                    try {
                      setState(() {
                        saving = true;
                      });
                      // Firebase 로그인 시도
                      final currentUser = await _authentication
                          .signInWithEmailAndPassword(email: email, password: password);

                      if (currentUser.user != null) {
                        _formKey.currentState!.reset();
                        setState(() {
                          saving = false;
                        });

                        // 로그인 성공 시 ChatPage로 이동
                        if (!mounted) return;
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GameRoom()));  // ChatPage로 이동
                      }
                    } catch (e) {
                      setState(() {
                        saving = false;
                      });
                      print(e);
                      // 예외 처리: 오류 메시지 또는 알림 표시
                    }
                  },
                  child: Text('Enter')),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('If you did not register, '),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Registerpage()));
                      },
                      child: Text('Register your email'))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
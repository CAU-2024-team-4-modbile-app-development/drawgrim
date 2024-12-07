import 'package:flutter/material.dart';
import 'package:drawgrim/GameRoom.dart';
import 'package:drawgrim/RegisterPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Loginpage extends StatelessWidget {
  const Loginpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
        backgroundColor: Colors.blueAccent.withOpacity(0.4), // 게임 테마에 맞는 어두운 색상
        centerTitle: true,
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
              // 이메일 입력 필드
              TextFormField(
                decoration: InputDecoration(
                  labelText: '이메일',
                  labelStyle: TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.blueAccent.withOpacity(0.2), // 배경을 어두운 색으로
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.black), // 텍스트 색상
                onChanged: (value) {
                  email = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              // 비밀번호 입력 필드
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  labelStyle: TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.blueAccent.withOpacity(0.2), // 배경을 어두운 색으로
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.black), // 텍스트 색상
                onChanged: (value) {
                  password = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              // 로그인 버튼
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
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

                        // 로그인 성공 시 GameRoom으로 이동
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => GameRoom()),
                        );
                      }
                    } catch (e) {
                      setState(() {
                        saving = false;
                      });
                      print(e);
                      // 예외 처리: 오류 메시지 또는 알림 표시
                    }
                  }
                },
                child: Text(
                  '로그인',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: Colors.blueAccent, // 게임 스타일에 맞는 색상
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              // 회원가입 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    '계정이 없으신가요? ',
                    style: TextStyle(fontSize: 22, color: Colors.black),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Registerpage(),
                        ),
                      );
                    },
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

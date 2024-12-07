import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drawgrim/SuccessRegister.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Registerpage extends StatelessWidget {
  const Registerpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입',),
        backgroundColor: Colors.blueAccent.withOpacity(0.4), // 게임 테마에 맞는 어두운 색상
        centerTitle: true,
      ),
      body: RegisterForm(),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  bool saving = false;
  final _authentication = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String username = '';

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
                style: TextStyle(color: Colors.black),
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
                style: TextStyle(color: Colors.white),
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
              // 사용자 이름 입력 필드
              TextFormField(
                decoration: InputDecoration(
                  labelText: '사용자 이름',
                  labelStyle: TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.blueAccent.withOpacity(0.2), // 배경을 어두운 색으로
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (value) {
                  username = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '사용자 이름을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              // 회원가입 버튼
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      setState(() {
                        saving = true;
                      });
                      final newUser = await _authentication
                          .createUserWithEmailAndPassword(email: email, password: password);
                      await FirebaseFirestore.instance.collection('user').doc(newUser.user!.uid).set(
                        {
                          'userName': username,
                          'email': email,
                        },
                      );
                      if (newUser.user != null) {
                        _formKey.currentState!.reset();
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SuccessRegisterPage(),
                          ),
                        );
                        setState(() {
                          saving = false;
                        });
                      }
                    } catch (e) {
                      print(e);
                    }
                  }
                },
                child: const Text(
                  '회원가입',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.white),

                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // 게임 스타일에 맞는 색상

                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              // 로그인 화면으로 이동하는 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    '이미 계정이 있나요? ',
                    style: TextStyle(fontSize: 22, color: Colors.black),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '로그인',
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

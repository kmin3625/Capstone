import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupScreen> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  String _gender = '남성';
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static String? _token;


  void initState() {
    super.initState();
    initFCMToken();
  }

  Future<void> initFCMToken() async {
    _token = await _firebaseMessaging.getToken();
    print("디바이스 토큰: $_token");

  }
  Future<http.Response> sendNotification(String partyID, String token) async {
    final url = Uri.parse('http://10.0.2.2:3000/notification/deadLineNotification');
    return http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'PartyID': partyID,
        'Token': token, // FCM 토큰 값 추가
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입"),backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),),
      body: Container(
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Form(
            key: _key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  emailInput(),
                  const SizedBox(height: 16),
                  passwordInput(),
                  const SizedBox(height: 16),
                  ageInput(),
                  const SizedBox(height: 16),
                  nicknameInput(),
                  const SizedBox(height: 16),
                  studentIdInput(),
                  const SizedBox(height: 16),
                  genderInput(),
                  const SizedBox(height: 32),
                  submitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget emailInput() {
    return TextFormField(
      controller: _emailController,
      validator: (val) {
        if (val!.isEmpty) {
          return '이메일을 입력해주세요.';
        } else if (!val.endsWith('@gm.hannam.ac.kr')) {
          return '@gm.hannam.ac.kr의 학교 메일을 이용해주세요.';
        } else {
          final emailLocalPart = val.split('@')[0];
          final studentId = int.tryParse(emailLocalPart);
          if (studentId == null || studentId < 20150001 || studentId > 20249999) {
            return '유효한 이메일을 입력해주세요. (20150001 ~ 20249999)';
          }
        }
        return null;
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: '학교 이메일을 입력해주세요.',
        labelText: '이메일',
      ),
    );
  }

  Widget passwordInput() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      validator: (val) => val!.isEmpty ? '비밀번호를 입력해주세요.' : null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: '비밀번호를 입력해주세요.',
        labelText: '비밀번호',
      ),
    );
  }

  Widget ageInput() {
    return TextFormField(
      controller: _ageController,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value!.isEmpty) {
          return '나이를 입력해주세요.';
        }
        final age = int.tryParse(value);
        if (age == null || age < 18 || age > 30) {
          return '올바른 나이(18~30)를 입력해주세요.';
        }
        return null;
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: '나이를 입력해주세요.',
        labelText: '나이',
      ),
    );
  }

  Widget nicknameInput() {
    return TextFormField(
      controller: _nicknameController,
      validator: (value) {
        if (value!.isEmpty) {
          return '닉네임을 입력해주세요.';
        }
        return null;
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: '닉네임을 입력해주세요.',
        labelText: '닉네임',
      ),
    );
  }

  Widget studentIdInput() {
    return TextFormField(
      controller: _studentIdController,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value!.isEmpty) {
          return '학번을 입력해주세요.';
        }
        final studentId = int.tryParse(value);
        if (studentId == null || studentId < 20150001 || studentId > 20249999) {
          return '유효한 학번을 입력해주세요. (20150001 ~ 20249999)';
        }
        return null;
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: '학번을 입력해주세요.',
        labelText: '학번',
      ),
    );
  }

  Widget genderInput() {
    return DropdownButtonFormField(
      value: _gender,
      onChanged: (String? newValue) {
        setState(() {
          _gender = newValue!;
        });
      },
      items: <String>['남성', '여성']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: '성별',
      ),
    );
  }

  Widget submitButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_key.currentState!.validate()) {
          await registerUser();
        }
      },
      child: const Text('회원가입'),
    );
  }

  Future<void> registerUser() async {
    if (!isEmailStudentIdMatching()) {
      showFeedback(context, '이메일과 학번이 일치하지 않습니다.');
      return;
    }

    if (await isNicknameTaken()) {
      showFeedback(context, '이미 사용중인 닉네임입니다.');
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('user').doc(uid).set({
        'Email': _emailController.text,
        'NickName': _nicknameController.text,
        'Age': int.tryParse(_ageController.text) ?? 0,
        'Gender': _gender,
        'StudentId': _studentIdController.text,
      });

      await userCredential.user!.sendEmailVerification();

      final response = await sendUserDataToServer(uid);
      if (response.statusCode == 201) {
        showVerificationDialog(context);
      } else {
        showFeedback(context, 'Registration failed: ${response.body}');
      }
    } on FirebaseAuthException catch (e) {
      showFeedback(context, 'Firebase Auth Error: ${e.message}');
    } catch (e) {
      showFeedback(context, 'Error: $e');
    }
  }

  Future<bool> isNicknameTaken() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('NickName', isEqualTo: _nicknameController.text)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  bool isEmailStudentIdMatching() {
    final emailLocalPart = _emailController.text.split('@')[0];
    final studentId = _studentIdController.text;
    return emailLocalPart == studentId;
  }

  Future<http.Response> sendUserDataToServer(String uid) async {
    final url = Uri.parse('http://10.0.2.2:3000/user/signup');
    return http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'StudentID': _studentIdController.text,
        'NickName': _nicknameController.text,
        'UID': uid,
        'Email': _emailController.text,
        'Gender': _gender,
        'Age': _ageController.text,
        'Password': _passwordController.text, // Note: In real apps, do not send plain passwords like this
        'Token': _token, // FCM 토큰 값 추가
      }),
    );
  }

  void showFeedback(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registration Feedback'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('이메일 인증 필요'),
          content: const Text('인증메일을 보냈습니다. 이메일을 확인하고 인증 후 로그인 해주세요.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}

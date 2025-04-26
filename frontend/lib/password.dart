import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordScreen extends StatefulWidget {
  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _emailIsValid = false;
  bool _passwordIsValid = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> resetPassword(String email) async {
    if (!_emailIsValid) {
      _showAlertDialog('입력 오류', '유효한 이메일 주소를 입력해주세요.');
      return;
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _showAlertDialog('이메일 발송 성공', '비밀번호 재설정 링크가 포함된 메일이 발송되었습니다. 메일을 확인해주세요.');
    } on FirebaseAuthException catch (e) {
      _showAlertDialog('오류 발생', '오류가 발생했습니다: ${e.message}');
    }
  }

  Future<void> resendVerificationEmail(String email, String password) async {
    if (!_emailIsValid || !_passwordIsValid) {
      _showAlertDialog('입력 오류', '유효한 이메일 주소와 비밀번호를 입력해주세요.');
      return;
    }

    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _showAlertDialog('이메일 발송 성공', '인증 이메일이 발송되었습니다. 메일을 확인해주세요.');
      } else {
        _showAlertDialog('오류 발생', '이미 인증된 이메일 주소이거나 유효하지 않은 이메일 주소입니다.');
      }
    } on FirebaseAuthException catch (e) {
      _showAlertDialog('오류 발생', '오류가 발생했습니다: ${e.message}');
    }
  }

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _validateEmail(String email) {
    setState(() {
      _emailIsValid = email.isNotEmpty && email.contains('@');
    });
  }

  void _validatePassword(String password) {
    setState(() {
      _passwordIsValid = password.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
        title: Text("로그인 문제 해결"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '이메일',
                hintText: '비밀번호 재설정을 위한 이메일 주소를 입력하세요.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: _validateEmail,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '비밀번호',
                hintText: '비밀번호를 입력하세요.',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: _validatePassword,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => resetPassword(_emailController.text),
              child: Text('비밀번호 재설정 이메일 보내기'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => resendVerificationEmail(_emailController.text, _passwordController.text),
              child: Text('인증 메일 재발송'),
            ),
            const SizedBox(height: 20),
            Text('비밀번호 재설정은 이메일을 입력 후에 이용하실 수 있습니다.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              '인증 메일 재발송은 이메일과 비밀번호를 모두 입력 후에 이용하실 수 있습니다.\n이미 인증되어 있는 계정은 재인증 할 수 없습니다.',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              '비밀번호를 변경하였을 경우 자동으로 이메일 인증이 완료됩니다.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

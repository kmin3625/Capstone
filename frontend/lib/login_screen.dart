import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginScreen> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  bool _isAutoLogin = false;
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static String? _token;

  @override
  void initState() {
    super.initState();
    initFCMToken();
    _checkAutoLogin();
  }
  Future<void> initFCMToken() async {
    _token = await _firebaseMessaging.getToken();
    print("디바이스 토큰: $_token");

  }

  String appendDomain(String email) {
    if (email.isEmpty) {
      return '';
    }
    if (!email.contains('@')) {
      return email + '@gm.hannam.ac.kr';
    }
    return email;
  }

  Future<void> _checkAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');

    if (email != null && password != null) {
      _emailController.text = email;
      _pwdController.text = password;
      await _login();
    }
  }

  Future<void> fetchUserData(String uid, String? token) async {
    if (token == null) {
      throw Exception('Token is required');
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/user/uid?uid=$uid'),
        headers: {
          'Authorization': '$token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Provider.of<UserProvider>(context, listen: false).setUser(data['StudentID'], data['Nickname']);
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      throw Exception('Failed to load user data');
    }
  }

  Future<void> _login() async {
    if (_key.currentState!.validate()) {
      String email = appendDomain(_emailController.text);
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: _pwdController.text);

        User user = userCredential.user!;

        if (user.emailVerified) {
          String uid = user.uid;

          await fetchUserData(uid, _token);

          if (_isAutoLogin) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString('email', email);
            prefs.setString('password', _pwdController.text);
          }

          if (mounted) {
            Navigator.pushReplacementNamed(context, "/mainscreen");
          }
        } else {
          await FirebaseAuth.instance.signOut();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('이메일 인증 필요'),
              content: const Text('이메일 인증을 먼저 해주세요'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('로그인 오류'),
            content: const Text('이메일과 비밀번호를 확인해주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('알 수 없는 오류'),
            content: const Text('예기치 않은 오류가 발생했습니다. 다시 시도해주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("로그인"),
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),),
      body: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  logo(),
                  const SizedBox(height: 30),
                  emailInput(),
                  const SizedBox(height: 20),
                  passwordInput(),
                  const SizedBox(height: 20),
                  autoLoginCheckbox(),
                  const SizedBox(height: 20),
                  loginButton(),
                  const SizedBox(height: 20),
                  additionalOptions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget logo() {
    return Image.asset(
      'assets/ddip_logo.png',
      height: 100,
      width: 100,
    );
  }

  Widget emailInput() {
    return TextFormField(
      controller: _emailController,
      validator: (val) => val!.isEmpty ? '입력하세요.' : null,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        hintText: '학번이나 이메일을 입력하세요.',
        labelText: 'ID',
        prefixIcon: Icon(Icons.email),
      ),
    );
  }

  Widget passwordInput() {
    return TextFormField(
      controller: _pwdController,
      obscureText: true,
      validator: (val) => val!.isEmpty ? '입력하세요.' : null,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        hintText: '비밀번호를 입력하세요.',
        labelText: '비밀번호',
        prefixIcon: Icon(Icons.lock),
      ),
    );
  }

  Widget autoLoginCheckbox() {
    return CheckboxListTile(
      title: const Text("자동 로그인"),
      value: _isAutoLogin,
      onChanged: (bool? value) {
        setState(() {
          _isAutoLogin = value ?? false;
        });
      },
    );
  }

  Widget loginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _login,
        child: const Text(
          "로그인",
          style: TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget additionalOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/signup'),
          child: const Text(
            "회원가입",
            style: TextStyle(fontSize: 16),
          ),
        ),
        Text(' | ', style: TextStyle(color: Colors.grey)),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/password'),
          child: const Text(
            "로그인 문제",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
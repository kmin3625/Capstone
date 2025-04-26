import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'user_provider.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'join_party.dart';
import 'party_chat.dart';
import 'setting.dart';
import 'my_info.dart';
import 'signup_screen.dart';
import 'password.dart';
import 'package:firebase_core/firebase_core.dart';
import 'notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();  // NotificationService 초기화
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: '띱',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          home: SplashScreen(),
          navigatorKey: NotificationService.navigatorKey, // navigatorKey 설정
          initialRoute: '/',
          debugShowCheckedModeBanner: false, // 디버그 배지 제거
          routes: {
            '/login': (context) => LoginScreen(),
            '/mainscreen': (context) => MainScreen(),
            '/partychat': (context) => PartyChat(),
            '/joinparty': (context) => JoinParty(),
            '/signup': (context) => SignupScreen(),
            '/setting': (context) => Setting(),
            '/myinfo': (context) => MyInfo(),
            '/password': (context) => PasswordScreen(),
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 2초 후에 로그인 화면으로 이동합니다.
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Image.asset(
          'assets/ddip_logo.png', // 이미지 경로
          width: 100, // 적절한 크기로 조정
          height: 100,
        ),
      ),
    );
  }
}

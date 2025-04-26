import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'user_provider.dart';
import 'theme_provider.dart';
import 'package:ddip/app_push.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Setting extends StatefulWidget {
  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    fetchNotiState(context); // fetchNotiState 호출
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      Navigator.pushReplacementNamed(context, getRouteName(index)).then((_) {
        setState(() {
          _currentIndex = index;
        });
      });
    }
  }

  String getRouteName(int index) {
    switch (index) {
      case 0:
        return '/myinfo';
      case 1:
        return '/joinparty';
      case 2:
        return '/mainscreen';
      case 3:
        return '/partychat';
      case 4:
        return '/setting';
      default:
        return '/setting';
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? lastPressed;

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrSnackbarHasBeenClosed = lastPressed == null || now.difference(lastPressed!) > Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrSnackbarHasBeenClosed) {
          lastPressed = DateTime.now();
          final snackBar = SnackBar(
            content: Text('\'뒤로\' 버튼을 한번 더 누르시면 종료됩니다.'),
            duration: Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('환경설정'),
          backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
        ),
        body: ListView(
          children: [
            _buildInfoTile('계정설정', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountSettingsScreen()),
              );
            }),
            Divider(thickness: 5, height: 5, color: Color(0xffD3D3D3)),
            _buildInfoTile('알림설정', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppPush()),
              );
            }),
            Divider(thickness: 5, height: 5, color: Color(0xffD3D3D3)),
            _buildInfoTile('고객센터', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CustomerServiceScreen()),
              );
            }),
            Divider(thickness: 5, height: 5, color: Color(0xffD3D3D3)),
            _buildInfoTile('회원탈퇴', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WithdrawalScreen()),
              );
            }),
            Divider(thickness: 5, height: 5, color: Color(0xffD3D3D3)),
            _buildInfoTile('로그아웃', () async {
              await _logout(context);
            }),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: _onTabTapped,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.account_box),
              label: '나의 정보',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add_alt_1),
              label: '파티 가입',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: '채팅',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '환경 설정',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Firebase에서 로그아웃
      await FirebaseAuth.instance.signOut();

      // SharedPreferences에서 자동 로그인 정보 삭제
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');

      // 로그아웃 메시지 표시 및 로그인 화면으로 이동
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('알림'),
            content: Text('로그아웃 되었습니다.'),
            actions: <Widget>[
              TextButton(
                child: Text('확인'),
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  ); // 로그아웃 후 로그인 화면으로 이동
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Logout Error: $e'); // 로그아웃 오류 로그 출력
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('오류'),
            content: Text('로그아웃 중 오류가 발생했습니다. 다시 시도해주세요.'),
            actions: <Widget>[
              TextButton(
                child: Text('확인'),
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildInfoTile(String title, Function() onTap) {
    return ListTile(
      title: Container(
        padding: EdgeInsets.all(8.0),
        child: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
      ),
      onTap: onTap,
    );
  }
}

class AccountSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
        title: Text('계정 설정'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text('비밀번호 변경'),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pushNamed('/password');
              },
            ),
            Divider(),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: Text('다크 모드'),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.setTheme(value ? ThemeMode.dark : ThemeMode.light);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerServiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
        title: Text('고객센터'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text('문의하기'),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InquiryScreen()),
                );
              },
            ),
            Divider(),
            ListTile(
              title: Text('자주하는 질문'),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FAQScreen()),
                );
              },
            ),
            Divider(),
            ListTile(
              title: Text('공지사항'),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NoticeScreen()),
                );
              },
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}

class InquiryScreen extends StatelessWidget {
  final TextEditingController _inquiryController = TextEditingController();

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'capstone.hannam@gmail.com',
      queryParameters: {'subject': '문의사항', 'body': _inquiryController.text},
    );

    try {
      await launch(emailLaunchUri.toString());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이메일 앱을 열 수 없습니다.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
        title: Text('문의하기'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '문의 내용을 입력해주세요:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _inquiryController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '문의할 내용을 자세히 입력해주세요.',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if (_inquiryController.text.isNotEmpty) {
                  _sendEmail(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('문의 내용을 입력해주세요.'),
                    ),
                  );
                }
              },
              child: Text('문의하기'),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQScreen extends StatelessWidget {
  final List<Map<String, String>> faqList = [
    {
      'question': '앱을 다운로드하는 방법은 무엇인가요?',
      'answer': '앱 스토어나 구글 플레이 스토어에서 "앱이름"을 검색하여 다운로드할 수 있습니다.',
    },
    {
      'question': '비밀번호를 잊어버렸어요. 어떻게 해야 하나요?',
      'answer': '비밀번호 찾기 기능을 이용하여 이메일을 통해 재설정할 수 있습니다. 혹은 관리자에게 문의하여 재설정할 수 있습니다.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
        title: Text('자주하는 질문'),
      ),
      body: ListView.builder(
        itemCount: faqList.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(faqList[index]['question'] ?? ''),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(faqList[index]['answer'] ?? ''),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NoticeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future<List<Map<String, dynamic>>> fetchNotices() async {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/user/getallnotices'));

      if (response.statusCode == 200) {
        List<dynamic> notices = json.decode(response.body);
        return notices.map((notice) => {
          'title': notice['Title'],
          'date': notice['NoticeDate'],
          'content': notice['Content'],
        }).toList();
      } else {
        throw Exception('공지사항을 불러오는 데 실패했습니다.');
      }
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
        title: Text('공지사항'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchNotices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다. 다시 시도해주세요.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('공지사항이 없습니다.'));
          } else {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: snapshot.data!.map((notice) {
                  return Column(
                    children: [
                      _buildNotice(
                        title: notice['title'],
                        date: notice['date'],
                        content: notice['content'],
                      ),
                      SizedBox(height: 16.0), // 공지사항 간의 간격을 설정합니다.
                    ],
                  );
                }).toList(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildNotice({required String title, required String date, required String content}) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.all(0.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              '$date',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8.0),
            Text(content),
          ],
        ),
      ),
    );
  }
}

class WithdrawalScreen extends StatefulWidget {
  @override
  _WithdrawalScreenState createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _withdrawUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: _passwordController.text,
      );

      try {
        await currentUser.reauthenticateWithCredential(credential);

        // Firestore에서 사용자 문서를 쿼리하여 삭제
        String studentEmailPrefix = currentUser.email!.split('@')[0];
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('studentId', isEqualTo: studentEmailPrefix)
            .get();

        for (var doc in userSnapshot.docs) {
          await doc.reference.delete();
        }

        // Firebase Auth에서 사용자 삭제
        await currentUser.delete();

        // 필요시 백엔드 서버에서 사용자 데이터 삭제
        final response = await http.post(
          Uri.parse('http://10.0.2.2:3000/user/withdraw'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'studentID': userProvider.studentId.toString(),
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('회원 탈퇴'),
                content: Text('회원 탈퇴가 완료되었습니다.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text('확인'),
                  ),
                ],
              );
            },
          );
        } else {
          _showErrorDialog('회원 탈퇴 중 오류가 발생했습니다. 다시 시도해주세요.');
        }
      } catch (e) {
        _showErrorDialog('회원 탈퇴 중 오류가 발생했습니다. 다시 시도해주세요.');
      }
    } else {
      _showErrorDialog('로그인 상태를 확인할 수 없습니다. 다시 로그인해주세요.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('회원 탈퇴 실패'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
        title: Text('회원 탈퇴'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '패스워드',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: '패스워드 입력',
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '패스워드 확인',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                hintText: '패스워드 확인',
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '탈퇴 이유',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: '탈퇴 이유를 간단히 입력해주세요.',
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('알림'),
                        content: Text('모든 칸을 입력해주세요.'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('확인'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else if (_passwordController.text != _confirmPasswordController.text) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('알림'),
                        content: Text('패스워드와 패스워드 확인이 일치하지 않습니다.'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('확인'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  _withdrawUser();
                }
              },
              child: Text('회원 탈퇴'),
            ),
          ],
        ),
      ),
    );
  }
}

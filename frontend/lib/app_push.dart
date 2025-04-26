import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'user_provider.dart';

// 전역 변수로 _isSwitched 선언
List<bool> _isSwitched = [true, true];

Future<void> fetchNotiState(BuildContext context) async {
  final studentID = Provider.of<UserProvider>(context, listen: false).studentId;
  final url = Uri.parse('http://10.0.2.2:3000/user/getnotistate?StudentID=$studentID');

  final response = await http.get(url);

  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final notiState = data['NotiState'];
    if (notiState == 0) {
      _isSwitched = [true, true];
    } else if (notiState == 1) {
      _isSwitched = [true, false];
    } else if (notiState == 2) {
      _isSwitched = [false, true];
    } else if (notiState == 3) {
      _isSwitched = [false, false];
    }
  } else {
    print('Failed to load NotiState');
  }
}

class AppPush extends StatefulWidget {
  @override
  _AppPushPageState createState() => _AppPushPageState();
}

class _AppPushPageState extends State<AppPush> {
  List<String> _pushTitles = [
    '채팅 알람 설정',
    '모집 마감 알람 설정'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchNotiState(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('알림 설정'),
      ),
      body: ListView.builder(
        itemCount: _pushTitles.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              _pushTitles[index],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Switch(
              value: _isSwitched[index],
              onChanged: (value) {
                setState(() {
                  _isSwitched[index] = value;
                  _updateNotiState(); // 알림 설정이 변경될 때 AlertNum 업데이트
                });
              },
            ),
          );
        },
      ),
    );
  }

  void _updateNotiState() {
    int notiState = 3;

    if (_isSwitched[0]) {
      notiState -= 2; // 채팅 알림 설정
    }
    if (_isSwitched[1]) {
      notiState -= 1; // 모집 마감 알림 설정
    }

    print('NotiState: $notiState');

    // 서버에 데이터를 전송하는 함수 호출
    updateNotiStateOnServer(notiState);
  }

  Future<http.Response> updateNotiStateOnServer(int notiState) async {
    final url = Uri.parse('http://10.0.2.2:3000/user/updatenotiState');
    return http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'StudentID': Provider.of<UserProvider>(context, listen: false).studentId,
        'NotiState': notiState
      }),
    );
  }
}
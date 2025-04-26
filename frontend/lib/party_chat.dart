import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';//1
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:path_provider/path_provider.dart';
import 'user_provider.dart';
import 'notification.dart';
import 'dart:io'; // File 관련 패키지 import 추가

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp(
        title: 'Join Party App',
        home: PartyChat(),
      ),
    ),
  );
}

class PartyChat extends StatefulWidget {
  @override
  _PartyChatState createState() => _PartyChatState();
}

class ReportDialog extends StatefulWidget {
  final int partyID;
  final List<String> participants;

  ReportDialog({required this.partyID, required this.participants});

  @override
  _ReportDialogState createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedCategory;
  String? _selectedParticipant;
  final TextEditingController _reportController = TextEditingController();
  final Map<String, int> _categoryMap = {
    '음란성 채팅': 0,
    '불법 정보 공유': 1,
    '도배/욕설 채팅': 2,
    '기타': 3
  };

  @override
  Widget build(BuildContext context) {
    final String currentUserNickName = Provider.of<UserProvider>(context, listen: false).nickname;

    List<String> filteredParticipants = widget.participants.where((participant) => participant != currentUserNickName).toList();

    return AlertDialog(
      title: Text('신고'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            hint: Text('신고 카테고리 선택'),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
            items: _categoryMap.keys.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          DropdownButtonFormField<String>(
            value: _selectedParticipant,
            hint: Text('신고 대상 닉네임 선택'),
            onChanged: (String? newValue) {
              setState(() {
                _selectedParticipant = newValue;
              });
            },
            items: filteredParticipants.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          TextField(
            controller: _reportController,
            decoration: InputDecoration(labelText: '신고 내용 입력'),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('취소'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('예'),
          onPressed: () {
            if (_selectedCategory != null && _reportController.text.isNotEmpty && _selectedParticipant != null) {
              _reportChat(widget.partyID, _selectedCategory!, _reportController.text, _selectedParticipant!);
              Navigator.of(context).pop();
            } else {
              // 에러 메시지 표시
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('카테고리와 신고 내용을 입력하세요')),
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> _reportChat(int partyID, String category, String content, String reportedNickName) async {
    final String studentID = Provider.of<UserProvider>(context, listen: false).studentId;
    final int reportCategory = _categoryMap[category] ?? 3; // category를 0~3으로 변환

    final Map<String, dynamic> reportData = {
      'ChatID_R': partyID,
      'StudentID': studentID,
      'ReportCa': reportCategory, // 0~3으로 변환된 ReportCa
      'ReportCo': content,
      'NickName': reportedNickName,
    };
    print(reportData);
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/chat/reportChat'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(reportData),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('신고가 접수되었습니다')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('신고 접수에 실패했습니다')),
      );
    }
  }
}

class _PartyChatState extends State<PartyChat> {
  int _currentIndex = 3;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _chatRooms = [];
  List<String> _participants = [];
  bool _showAppBarAndBottomNavigationBar = true;
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String nickName = '';
  IO.Socket? _socket;
  int? _connectedPartyID;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _fetchChatRooms(Provider.of<UserProvider>(context, listen: false).studentId);
  }

  void _initializeSocket() {
    _socket = IO.io('http://10.0.2.2:3000', IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect() // 자동 연결 활성화
        .setReconnectionAttempts(10) // 재연결 시도 횟수 설정
        .setReconnectionDelay(2000) // 재연결 시도 간격 설정 (2초)
        .setTimeout(5000) // 연결 타임아웃 설정 (5초)
        .build());

    _socket?.connect();

    _socket?.on('connect', (_) {
      print('connected to socket');
      if (_connectedPartyID != null) {
        _socket?.emit('join room', _connectedPartyID);
      }
    });

    _socket?.on('reconnect', (attempt) {
      print('Socket reconnected: $attempt');
      if (_connectedPartyID != null) {
        _socket?.emit('join room', _connectedPartyID);
      }
    });

    _socket?.on('reconnect_attempt', (attempt) {
      print('Reconnecting attempt: $attempt');
    });

    _socket?.on('connect_error', (error) {
      print('Socket connection error: $error');
    });

    _socket?.on('connect_timeout', (_) {
      print('Socket connection timeout');
    });

    _socket?.on('error', (error) {
      print('Socket error: $error');
    });

    _socket?.on('disconnect', (_) {
      print('Socket disconnected');
    });

    _socket?.on('chat message', (data) {
      print('Received chat message: $data');
      _handleNewMessage(data);
    });

    // Listen for refresh chat rooms event
    _socket?.on('refresh chat rooms', (_) {
      _fetchChatRooms(Provider.of<UserProvider>(context, listen: false).studentId);
    });
  }

  void _connectSocket(int partyID) {
    if (_connectedPartyID == partyID) {
      return; // 이미 연결된 소켓이 있는 경우 재연결하지 않음
    }

    _socket?.emit('join room', partyID);
    _connectedPartyID = partyID;
    NotificationSettings.shouldReceiveNotifications = false; // 채팅방 선택 시 알림 비활성화
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    final partyID = data['ChatID'];
    final newMessage = {
      'sender': data['sender'],
      'content': data['content'],
      'time': data['time'],
    };

    setState(() {
      // 메시지를 해당 채팅방에 추가
      if (_connectedPartyID == partyID) {
        _messages.add(newMessage);
        _scrollToBottom();
      }

      // 채팅방 목록의 마지막 메시지 업데이트
      final chatRoomIndex = _chatRooms.indexWhere((room) => room['partyID'] == partyID);
      if (chatRoomIndex != -1) {
        _chatRooms[chatRoomIndex]['lastMessage'] = newMessage['content'];
      }
    });

    // 모든 클라이언트에게 채팅방 목록을 최신화하라고 알림
    _socket?.emit('refresh chat rooms');
  }

  Future<int?> _fetchJoinID(int partyID, String studentID) async {
    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:3000/chat/getJoinID?partyID=$partyID&studentID=$studentID'),
    );
    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Failed to fetch JoinID');
    }
  }

  Future<void> _fetchChatRooms(String studentID) async {
    final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/chat/getChatList?studentID=$studentID'));
    if (response.statusCode == 200) {
      final List<dynamic>? data = json.decode(response.body);
      if (data != null) {
        setState(() {
          _chatRooms = data.map((room) =>
          {
            'partyID': room['PartyID'],
            'roomName': room['PartyTitle'],
            'participantCount': room['ParticipantCount'],
            'lastMessage': room['LastMessage'],
            'partyCa': room['PartyCa'],
          }).toList();
        });
      } else {
        setState(() {
          _chatRooms = [];
        });
      }
    } else {
      throw Exception('Failed to load chat rooms');
    }
  }

  Future<void> _fetchChatMessages(int partyID) async {
    final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/chat/getMessage?ChatID=$partyID'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _messages = data.map((message) {
          // 메시지 시간을 로컬 시간으로 변환
          final utcTime = DateTime.parse(message['ChatTime']);
          final localTime = utcTime.toLocal();
          return {
            'sender': message['NickName'],
            'content': message['ChatData'],
            'time': localTime.toString(), // 로컬 시간으로 변환된 시간을 사용
          };
        }).toList();
      });
      _scrollToBottom();
    } else {
      throw Exception('Failed to load chat messages');
    }
  }

  Future<void> _fetchChatRoomParticipants(int partyID) async {
    final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/chat/participants/$partyID'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _participants =
            data.map((participant) => participant['NickName'] as String)
                .toList();
      });
    } else {
      throw Exception('Failed to load chat room participants');
    }
  }

  void _sendMessage(String message, int partyID) async {
    String studentID = Provider.of<UserProvider>(context, listen: false).studentId;
    String nickName = Provider.of<UserProvider>(context, listen: false).nickname;
    final joinID = await _fetchJoinID(partyID, studentID);
    if (joinID != null) {
      final Map<String, dynamic> messageData = {
        'ChatID': partyID,
        'studentID': studentID,
        'joinID': joinID,
        'chatData': message,
        'nickName': nickName,
      };

      _socket?.emit('chat message', messageData);

      _textEditingController.clear();
      _scrollToBottom();
    } else {
      _showErrorDialog('Failed to fetch JoinID');
    }
  }

  Future<void> _deleteChat(int partyID, String studentID) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/chat/deletechat'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'PartyID': partyID.toString(),
        'StudentID': studentID,
      }),
    );

    if (response.statusCode == 200) {
      await _fetchChatRooms(studentID); // 채팅방 목록 새로고침
      setState(() {
        _currentIndex = 3; // 채팅방 목록 화면으로 이동
        _showAppBarAndBottomNavigationBar = true;
        NotificationSettings.shouldReceiveNotifications = true; // 채팅방 나갈 시 알림 활성화
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방을 나갔습니다')),
      );
    } else {
      _showErrorDialog('채팅방 나가기 오류');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onChatRoomSelected(int index) {
    setState(() {
      _currentIndex = index;
      _showAppBarAndBottomNavigationBar = false;
      _fetchChatMessages(_chatRooms[index]['partyID']);
      _fetchChatRoomParticipants(_chatRooms[index]['partyID']);
    });
    _connectSocket(_chatRooms[index]['partyID']);
  }

  void _onChatRoomLongPressed(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('채팅방 나가기'),
          content: Text('정말 이 "${_chatRooms[index]['roomName']}" 채팅방을 나가시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('나가기'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteChat(_chatRooms[index]['partyID'], Provider.of<UserProvider>(context, listen: false).studentId);
              },
            ),
          ],
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _chatRooms.length,
      itemBuilder: (BuildContext context, int index) {
        Color chatRoomColor;
        switch (_chatRooms[index]['partyCa']) {
          case 0:
            chatRoomColor = Colors.blue.shade400;
            break;
          case 1:
            chatRoomColor = Colors.purple.shade300;
            break;
          case 2:
            chatRoomColor = Colors.pink.shade400;
            break;
          default:
            chatRoomColor = Colors.grey;
        }

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // 컨테이너 간의 여백 설정
          decoration: BoxDecoration(
            color: chatRoomColor, // 배경 색상을 partyCa에 따라 설정
            borderRadius: BorderRadius.circular(12.0), // 모서리를 둥글게 설정
          ),
          child: ListTile(
            title: Text(
              _chatRooms[index]['roomName'],
              style: TextStyle(color: Colors.white), // 글씨 색상을 흰색으로 변경
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '참여 인원수: ${_chatRooms[index]['participantCount']}',
                  style: TextStyle(color: Colors.white), // 글씨 색상을 흰색으로 변경
                ),
                Text(
                  '최근 메세지: ${_chatRooms[index]['lastMessage'] ?? '최근 메세지가 없습니다.'}',
                  style: TextStyle(color: Colors.white), // 글씨 색상을 흰색으로 변경
                ),
              ],
            ),
            onTap: () {
              _onChatRoomSelected(index);
            },
            onLongPress: () {
              _onChatRoomLongPressed(index);
            },
          ),
        );
      },
    );
  }

  Widget _buildChatRoom() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _chatRooms[_currentIndex]['roomName'],
              style: TextStyle(fontSize: 18),
            ),
            Row(
              children: [
                Icon(Icons.person, size: 16,),
                SizedBox(width: 4),
                Text(
                  '${_participants.length}',
                  style: TextStyle(fontSize: 14,),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.people),
            onPressed: () {
              _showChatRoomParticipants();
            },
          ),
          IconButton(
            icon: Icon(Icons.warning_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ReportDialog(partyID: _chatRooms[_currentIndex]['partyID'], participants: _participants);
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              _socket?.emit('leave room', _chatRooms[_currentIndex]['partyID']);
              _connectedPartyID = null;
              setState(() {
                _currentIndex = 3;
                _showAppBarAndBottomNavigationBar = true;
                NotificationSettings.shouldReceiveNotifications = true; // 채팅방 나갈 시 알림 활성화
              });
              _fetchChatRooms(Provider.of<UserProvider>(context, listen: false).studentId); // 채팅방 목록 새로고침
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (BuildContext context, int index) {
                final message = _messages[index];
                final content = message['content'] ?? 'Unknown content';
                final sender = message['sender'] ?? 'Unknown sender';
                final time = message['time'] ?? 'Unknown time';
                final isCurrentUser = sender == Provider.of<UserProvider>(context, listen: false).nickname;
                final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(time));

                return Column(
                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: isCurrentUser ? 0 : 12.0, right: isCurrentUser ? 12.0 : 0),
                      child: Text(
                        sender,
                        style: TextStyle(

                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                    Align(
                      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              content,
                              style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: isCurrentUser ? Colors.white70 : Colors.black54,
                                fontSize: 10.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textEditingController,
                  decoration: InputDecoration(labelText: '메세지를 입력하세요.'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  _sendMessage(_textEditingController.text, _chatRooms[_currentIndex]['partyID']);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      // 페이지 전환 후 상태 변경
      Navigator.pushReplacementNamed(context, getRouteName(index)).then((_) {
        setState(() {
          _currentIndex = index;
        });
      });
    }
  }

// 경로 이름을 반환하는 함수
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
        return '/partychat';
    }
  }

  void _showChatRoomParticipants() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('인원'),
          content: Container(
            width: double.maxFinite,
            height: 200,
            child: ListView.builder(
              itemCount: _participants.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_participants[index]),
                  leading: FutureBuilder<ImageProvider?>(
                    future: _getProfileImage(_chatRooms[_currentIndex]['partyID'], _participants[index]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return CircleAvatar(
                          backgroundImage: snapshot.data,
                        );
                      } else {
                        return CircleAvatar(
                          child: Icon(Icons.person),
                        );
                      }
                    },
                  ),
                  onTap: () {
                    _fetchParticipantDetails(
                        _chatRooms[_currentIndex]['partyID'],
                        _participants[index]);
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchParticipantDetails(int partyID, String nickname) async {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2:3000/chat/participantdetail/$partyID/$nickname'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      data['PartyID'] = partyID; // PartyID를 추가합니다.
      _showParticipantDetailsDialog(data);
    } else {
      throw Exception('Failed to load participant details');
    }
  }

  Future<ImageProvider?> _getProfileImage(int partyID, String nickName) async {
    try {
      final url = Uri.parse('http://10.0.2.2:3000/chat/getchatpeopleprofile?PartyID=$partyID&NickName=$nickName');
      final response = await http.post(url);

      if (response.statusCode == 200) {
        final imageDataBase64 = response.body;
        // 이미지 데이터가 유효한지 확인
        if (imageDataBase64.isEmpty) {
          print('Image data is empty for NickName: $nickName');
          return null; // 기본 프로필 이미지
        }
        final Uint8List imageDataBytes = base64Decode(imageDataBase64);

        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${nickName}_profile.png');
        await tempFile.writeAsBytes(imageDataBytes);

        return FileImage(tempFile);
      } else {
        print('Failed to get image for NickName: $nickName. Status code: ${response.statusCode}');
        return null; // 기본 프로필 이미지
      }
    } catch (error) {
      print('Error fetching image for NickName: $nickName. Error: $error');
      return null; // 기본 프로필 이미지
    }
  }

  void _showParticipantDetailsDialog(Map<String, dynamic> participantDetails) async {
    // 프로필 이미지 파일 생성
    ImageProvider? profileImage = await _getProfileImage(participantDetails['PartyID'], participantDetails['NickName']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('상세정보'), // 제목을 가운데 정렬
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Row 안의 내용 가운데 정렬
                children: [
                  CircleAvatar(
                    backgroundImage: profileImage,
                    radius: 50,
                    child: profileImage == null
                        ? Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey[600],
                    )
                        : null,
                  ),
                ],
              ),
              SizedBox(height: 8), // 프로필 이미지와 텍스트 사이의 간격 조절
              Text(
                '닉네임: ${participantDetails['NickName'] ?? '닉네임이 없습니다'}',
                textAlign: TextAlign.center,
              ),
              Text(
                '성별: ${participantDetails['Gender'] ?? '성별 정보가 없습니다'}',
                textAlign: TextAlign.center,
              ),
              Text(
                '나이: ${participantDetails['Age'] ?? '나이 정보가 없습니다'}',
                textAlign: TextAlign.center,
              ),
              Text(
                '전공: ${participantDetails['Major'] ?? '전공 정보가 없습니다'}',
                textAlign: TextAlign.center,
              ),
              Text(
                '소개: ${participantDetails['Introduce'] ?? '소개글이 없습니다'}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  @override
  @override
  void dispose() {
    _socket?.emit('leave room', _connectedPartyID); // 현재 방을 나갑니다.
    _socket?.off('chat message'); // 이벤트 리스너를 제거합니다.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime? lastPressed;

    return WillPopScope(
      onWillPop: () async {
        if (!_showAppBarAndBottomNavigationBar) {
          // 현재 채팅방에 있는 경우, 채팅방 목록으로 돌아가도록 설정
          setState(() {
            _currentIndex = 3;
            _showAppBarAndBottomNavigationBar = true;
          });
          _socket?.emit('leave room', _chatRooms[_currentIndex]['partyID']);
          _connectedPartyID = null;
          NotificationSettings.shouldReceiveNotifications = true;
          return false;
        } else {
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
        }
      },
      child: Scaffold(
        appBar: _showAppBarAndBottomNavigationBar
            ? AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
          title: Text('채팅'),
        )
            : null,
        body: (_currentIndex != 3 || !_showAppBarAndBottomNavigationBar)
            ? _buildChatRoom()
            : _buildChatList(),
        bottomNavigationBar: _showAppBarAndBottomNavigationBar
            ? BottomNavigationBar(
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
        )
            : null,
      ),
    );
  }
}

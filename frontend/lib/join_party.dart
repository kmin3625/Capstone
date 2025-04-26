import 'package:flutter/material.dart';
import 'package:ddip/party_chat.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'theme_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'login_screen.dart';
import 'main_screen.dart';
import 'my_info.dart';
import 'setting.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: JoinParty(),
    ),
  );
}

class JoinParty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Join Party App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      home: PartyPage(selectedBuildNum: 0),
      debugShowCheckedModeBanner: false,
      routes: {
        '/main': (context) => MainScreen(),
        '/login': (context) => LoginScreen(),
        '/mainscreen': (context) => MainScreen(),
        '/partychat': (context) => PartyChat(),
        '/joinparty': (context) => JoinParty(),
        '/myinfo': (context) => MyInfo(),
        '/setting': (context) => Setting(),
      },
    );
  }
}

class Party {
  final int partyID;
  final String partyTitle;
  final String partyContent;
  final int curPeople;
  final int people;
  final DateTime startTime;
  final DateTime endTime;
  final int partyCa;
  final int partyState;

  Party({
    required this.partyID,
    required this.partyTitle,
    required this.partyContent,
    required this.curPeople,
    required this.people,
    required this.startTime,
    required this.endTime,
    required this.partyCa,
    required this.partyState,
  });

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      partyID: json['PartyID'] ?? 0,
      partyTitle: json['PartyTitle'] ?? '',
      partyContent: json['PartyContent'] ?? '',
      curPeople: json['CurPeople'] ?? 0,
      people: json['People'] ?? 0,
      startTime: DateTime.parse(json['StartTime']),
      endTime: DateTime.parse(json['EndTime']),
      partyCa: json['PartyCa'] ?? 0,
      partyState: json['PartyState'] ?? 0,
    );
  }

  bool isFull() {
    return curPeople >= people;
  }
}

class PartyPage extends StatefulWidget {
  final int selectedBuildNum;

  PartyPage({Key? key, required this.selectedBuildNum}) : super(key: key);
  @override
  _PartyPageState createState() => _PartyPageState(selectedBuildNum);
}

class CreatePartyPage extends StatefulWidget {
  final int buildNum;

  CreatePartyPage({required this.buildNum});

  @override
  _CreatePartyPageState createState() => _CreatePartyPageState();
}

class _PartyPageState extends State<PartyPage> {
  int _currentIndex = 1;
  List<Party> partyData = [];
  int selectedBuildNum;
  DateTime? _lastPressed;

  _PartyPageState(this.selectedBuildNum);

  Map<int, bool> filters = {
    0: true,
    1: true,
    2: true,
  };

  final List<String> buildNums = [
    '평생교육원', '정문', '56주년기념관', '조형예술대학', '학교도서관', '쪽문', '경상대학', '한남XR센터',
    '인돈학술원', '문과대학', '법과대학', '11번건물', '탈메이지기념관', '북문', '성지관', '이과대학', '공과대학',
    '미술교육관', '창업지원단', '학군단', '대학본부', '학생회관(동아리실)', '사범대학', '종합운동장', '대덕정문',
    '진리관', '자유관', '생명나노과학대학'
  ];

  @override
  void initState() {
    super.initState();
    fetchPartyData(selectedBuildNum);
  }

  Future<void> _refreshPartyData(int buildNum) async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:3000/party/getparty?BuildNum=$buildNum"));
      if (response.statusCode == 200) {
        List<dynamic> responseData = jsonDecode(response.body);
        List<Party> parties = responseData.map((json) => Party.fromJson(json)).toList();

        parties = parties.where((party) => party.partyState != 0 && party.endTime.isAfter(DateTime.now())).toList();
        setState(() {
          partyData = parties;
        });
      } else {
        print("Failed to fetch party data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching party data: $e");
    }
  }

  Future<void> fetchPartyData(int buildNum) async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:3000/party/getparty?BuildNum=$buildNum"));
      if (response.statusCode == 200) {
        List<dynamic> responseData = jsonDecode(response.body);
        List<Party> parties = responseData.map((json) => Party.fromJson(json)).toList();

        parties = parties.where((party) => party.partyState != 0 && party.endTime.isAfter(DateTime.now())).toList();
        setState(() {
          partyData = parties;
        });
      } else {
        print("Failed to fetch party data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching party data: $e");
    }
  }

  List<Party> applyFilters() {
    return partyData.where((party) {
      if (filters[party.partyCa] == true) {
        if (party.endTime.isAfter(DateTime.now())) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  Color getCategoryColor(int category) {
    switch (category) {
      case 0:
        return Colors.blue.shade400;
      case 1:
        return Colors.purple.shade300;
      case 2:
        return Colors.pink.shade400;
      default:
        return Colors.grey;
    }
  }

  void navigateToPartyDetail(Party party) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PartyDetailPage(party: party)),
    );
  }

  void navigateToCreateParty(int buildNum) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePartyPage(buildNum: buildNum)),
    ).then((result) {
      if (result == true) {
        fetchPartyData(buildNum);  // 결과가 true일 때 파티 목록 갱신
      }
    });
  }

  String getTimeDifference(DateTime endTime) {
    Duration difference = endTime.difference(DateTime.now());
    if (difference.isNegative) {
      return '마감';
    }

    int hours = difference.inHours;
    int minutes = difference.inMinutes.remainder(60);

    return '${hours}시간 ${minutes}분';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrSnackbarHasBeenClosed = _lastPressed == null || now.difference(_lastPressed!) > Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrSnackbarHasBeenClosed) {
          _lastPressed = DateTime.now();
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
          backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
          title: Row(
            children: [
              Text("파티"),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => _refreshPartyData(selectedBuildNum),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<int>(
                value: selectedBuildNum,
                items: buildNums.asMap().entries.map((entry) {
                  int index = entry.key;
                  String value = entry.value;
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedBuildNum = newValue;
                    });
                    fetchPartyData(newValue);
                  }
                },
              ),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                direction: Axis.horizontal,
                alignment: WrapAlignment.center,
                children: filters.keys.map((int type) {
                  Color chipColor = getCategoryColor(type);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text(type == 0 ? '놀이' : type == 1 ? '식사' : '도움'),
                      selected: filters[type]!,
                      onSelected: (bool selected) {
                        setState(() {
                          filters[type] = selected;
                        });
                      },
                      selectedColor: chipColor,
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: applyFilters().length,
                itemBuilder: (BuildContext context, int index) {
                  Color cardColor = getCategoryColor(applyFilters()[index].partyCa);
                  return GestureDetector(
                    onTap: () => navigateToPartyDetail(applyFilters()[index]),
                    child: Card(
                      color: cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${applyFilters()[index].partyTitle}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text("인원: ${applyFilters()[index].curPeople}/${applyFilters()[index].people}", style: TextStyle(color: Colors.white)),
                            Text(
                              "모집기간: ${getTimeDifference(applyFilters()[index].endTime)} 남음",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => navigateToCreateParty(selectedBuildNum),
          tooltip: '새 파티 만들기',
          child: Icon(Icons.add),
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
        return '/mainscreen';
    }
  }
}

class PartyDetailPage extends StatefulWidget {
  final Party party;

  PartyDetailPage({required this.party});

  @override
  _PartyDetailPageState createState() => _PartyDetailPageState();
}

class _PartyDetailPageState extends State<PartyDetailPage> {
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    fetchPartyMembers(widget.party);
  }

  Future<void> fetchPartyMembers(Party party) async {
    try {
      final url = 'http://10.0.2.2:3000/party/getpartypeople?PartyID=${party.partyID}';
      print('Fetching party members from: $url'); // URL 확인을 위한 디버깅 메시지
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> responseData = jsonDecode(response.body);
        setState(() {
          members = responseData.map((json) => Map<String, dynamic>.from(json)).toList();
        });
        print('Members: $members'); // 디버깅을 위해 추가

        await fetchProfileImages(party);
        await fetchNicknames();
      } else {
        print('Failed to load members: ${response.statusCode}');
        // 에러 핸들링
      }
    } catch (e) {
      print('Error loading members: $e');
      // 예외 처리
    }
  }

  Future<void> fetchProfileImages(Party party) async {
    for (var member in members) {
      try {
        final url = Uri.parse('http://10.0.2.2:3000/party/getpartypeopleprofile?PartyID=${party.partyID}&StudentID=${member['StudentID']}');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'PartyID': party.partyID.toString(),
            'StudentID': member['StudentID'],
          }),
        );

        if (response.statusCode == 200) {
          // 서버로부터 받아온 데이터를 Base64 문자열로 변환
          final imageDataBase64 = response.body;
          final Uint8List imageDataBytes = base64Decode(imageDataBase64);
          // Base64 문자열을 디코딩하여 이미지 데이터로 변환
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/${member['StudentID']}_profile.png');
          await tempFile.writeAsBytes(imageDataBytes);

          // 프로필 이미지를 members 리스트에 추가
          member['ProfileImage'] = FileImage(tempFile);
        } else {
          print('Failed to get image for StudentID: ${member['StudentID']}. Status code: ${response.statusCode}');
          member['ProfileImage'] = null; // 기본 아이콘 사용
        }
      } catch (error) {
        print('Error fetching image for StudentID: ${member['StudentID']}. Error: $error');
        member['ProfileImage'] = null; // 기본 아이콘 사용
      }
    }

    setState(() {});
  }

  Future<void> fetchNicknames() async {
    for (var member in members) {
      final nickname = member['Nickname'] ?? 'Unknown';
      // 닉네임을 members 리스트에 추가
      member['DisplayName'] = nickname;
    }

    setState(() {});
  }

  void showMemberDetails(BuildContext context, Map<String, dynamic> member) async {
    try {
      Map<String, dynamic> userDetails = await fetchUserDetails(member['StudentID']);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(''),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundImage: member['ProfileImage'] is FileImage
                      ? member['ProfileImage']
                      : null,
                  radius: 50,
                  child: member['ProfileImage'] == null
                      ? Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey[600],
                  )
                      : null,
                ),
                SizedBox(height: 16),
                Text('${member['Nickname'] ?? 'Unknown'}'),
                Text('성별: ${userDetails['Gender'] ?? ' '}'),
                Text('나이: ${userDetails['Age'] ?? ' '}'),
                Text('전공: ${userDetails['Major'] ?? ' '}'),
                Text('소개:'),
                Text('${userDetails['Introduce'] ?? ' '}'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to load user details'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  img.Image processImage(img.Image image, int maxSize) {
    int width = image.width;
    int height = image.height;

    // 이미지 크기 조정
    if (width > height) {
      if (width > maxSize) {
        height = (height * maxSize / width).round();
        width = maxSize;
      }
    } else {
      if (height > maxSize) {
        width = (width * maxSize / height).round();
        height = maxSize;
      }
    }

    // 이미지 압축
    img.Image resizedImage = img.copyResize(image, width: width, height: height);

    // 이미지 원형으로 자르기
    int radius = maxSize ~/ 2;
    img.Image circleImage = img.Image(radius * 2, radius * 2);
    for (int y = 0; y < radius * 2; y++) {
      for (int x = 0; x < radius * 2; x++) {
        int dx = radius - x;
        int dy = radius - y;
        if ((dx * dx + dy * dy) <= (radius * radius)) {
          circleImage.setPixel(x, y, resizedImage.getPixel(x, y));
        }
      }
    }

    return circleImage;
  }

  Future<Map<String, dynamic>> fetchUserDetails(String studentId) async {
    final url = Uri.parse('http://10.0.2.2:3000/party/getuserinfo?StudentID=$studentId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user details');
    }
  }

  Future<void> closeParty(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/party/partydeadline'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'PartyID': widget.party.partyID,
          'StudentID': userProvider.studentId,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파티가 성공적으로 마감되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파티는 만든 사람만 마감할 수 있습니다. ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _joinParty(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/party/joinparty'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'PartyID': widget.party.partyID,
          'StudentID': userProvider.studentId,
          'NickName': userProvider.nickname,
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PartyChat()),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('파티 참여 실패'),
              content: Text('파티에 참여할 수 없습니다.'),
              actions: [
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
    } catch (e) {
      print('Error joining party: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('파티 참여 실패'),
            content: Text('파티 참여 중에 오류가 발생했습니다. 다시 시도해주세요.'),
            actions: [
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
  }

  @override
  Widget build(BuildContext context) {
    Color appBarColor = getCategoryColor(widget.party.partyCa);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.party.partyTitle),
        backgroundColor: appBarColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                "파티 내용:",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: 150,
              width: double.infinity,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.party.partyContent,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "현재 인원: ${widget.party.curPeople}/${widget.party.people}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
              ),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final profileImage = member['ProfileImage'];
                final nickname = member['Nickname'];

                return GestureDetector(
                  onTap: () => showMemberDetails(context, member),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: profileImage is FileImage
                            ? Image(
                          image: profileImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: Icon(Icons.person, size: 30, color: Colors.grey[600]),
                            );
                          },
                        )
                            : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: Icon(Icons.person, size: 30, color: Colors.grey[600]),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(nickname ?? 'Unknown', textAlign: TextAlign.center),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 30),
            SizedBox(height: 16),
            Text(
              "마감 시간:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "${widget.party.endTime.year}-${widget.party.endTime.month.toString().padLeft(2, '0')}-${widget.party.endTime.day.toString().padLeft(2, '0')} ${widget.party.endTime.hour.toString().padLeft(2, '0')}:${widget.party.endTime.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (widget.party.isFull()) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('파티 참여 불가'),
                          content: Text('파티의 인원이 초과되었습니다.'),
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
                  } else {
                    _joinParty(context);
                  }
                },
                child: Text('파티 참여하기'),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () => closeParty(context),
                child: Text('파티 마감하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getCategoryColor(int category) {
    switch (category) {
      case 0:
        return Colors.blue.shade400;
      case 1:
        return Colors.purple.shade300;
      case 2:
        return Colors.pink.shade400;
      default:
        return Colors.grey;
    }
  }
}

class _CreatePartyPageState extends State<CreatePartyPage> {

  String partyTitle = '';
  String partyType = '놀이';
  String partyContent = '';
  int recruitPeople = 2;
  int duration = 5;

  final List<String> partyTypes = ['놀이', '식사', '도움'];
  final List<int> recruitPeopleOptions = [2, 3, 4, 5, 6, 7, 8, 9];
  final List<int> durationOptions = [5, 10, 30, 45, 60, 90, 120];

  Future<void> createParty() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      DateTime now = DateTime.now();
      DateTime endTime = now.add(Duration(minutes: duration));

      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/party/makeparty'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'PartyCa': partyTypes.indexOf(partyType),
          'EndTime': endTime.toIso8601String(),
          'PartyTitle': partyTitle,
          'PartyContent': partyContent,
          'People': recruitPeople,
          'BuildNum': widget.buildNum,
          'StudentID': userProvider.studentId,
          'NickName': userProvider.nickname,
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pop(context, true);  // 성공 시 true 전달
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('파티 생성 실패'),
              content: Text('서버에서 파티를 만들지 못했습니다. 다시 시도해주세요.'),
              actions: [
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
    } catch (e) {
      print('Error creating party: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('파티 생성 실패'),
            content: Text('파티 생성 중에 오류가 발생했습니다. 다시 시도해주세요.'),
            actions: [
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
        title: Text("새 파티 만들기"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: '파티 제목',
                  counterText: '',
                ),
                maxLength: 50,
                onChanged: (value) {
                  setState(() {
                    partyTitle = value;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: partyType,
                items: partyTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    partyType = value!;
                  });
                },
                decoration: InputDecoration(labelText: '파티 종류'),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: '파티 내용',
                  counterText: '',
                ),
                maxLength: 50,
                onChanged: (value) {
                  setState(() {
                    partyContent = value;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: recruitPeople,
                items: recruitPeopleOptions.map((int option) {
                  return DropdownMenuItem<int>(
                    value: option,
                    child: Text(option.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    recruitPeople = value!;
                  });
                },
                decoration: InputDecoration(labelText: '모집할 인원'),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: duration,
                items: durationOptions.map((int option) {
                  return DropdownMenuItem<int>(
                    value: option,
                    child: Text('$option 분'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    duration = value!;
                  });
                },
                decoration: InputDecoration(labelText: '파티 진행 시간'),
              ),
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (partyTitle.isNotEmpty && partyContent.isNotEmpty && partyTitle.length <= 50 && partyContent.length <= 50) {
                      createParty();
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('파티 생성 실패'),
                            content: Text('파티 제목과 내용은 각각 최대 50자까지 입력할 수 있습니다.'),
                            actions: [
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
                  },
                  child: Text('파티 만들기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
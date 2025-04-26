import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'user_provider.dart';
import 'login_screen.dart';

class MyInfo extends StatefulWidget {
  @override
  _MyInfoScreenState createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfo> {
  String nickname = '닉네임';
  int age = 20;
  String gender = '남성';
  String introduction = '안녕하세요! 자기소개를 입력해주세요';
  String email = '';
  String password = '';
  String major = '';
  String profile = '';
  String Newnickname = '10';
  File? _image;
  bool _loading = false;

  int _currentIndex = 0;

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
        return '/mainscreen';
    }
  }

  @override
  void initState() {
    super.initState();
    getUserInfo();
    _getImageFromServer();
  }

  String combineEmail(String studentId) {
    return '$studentId@gm.hannam.ac.kr';
  }

  Future<void> _saveUserName() async {
    final url = Uri.parse('http://10.0.2.2:3000/user/saveusername');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'studentID': Provider.of<UserProvider>(context, listen: false).studentId,
          'nickname': nickname,
          'age': age,
          'gender': gender,
          'password': password,
          'email': combineEmail(Provider.of<UserProvider>(context, listen: false).studentId),
          'Newnickname': Newnickname,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('User info saved successfully');
        // 닉네임 변경 후 계정 설정 화면으로 이동하여 로그아웃
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('닉네임이 성공적으로 변경되었습니다. 다시 로그인해주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else if (response.statusCode == 500) {
        // 서버에서 500 상태 코드를 반환할 때 중복된 닉네임 메시지 출력
        getUserInfo();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('중복된 닉네임입니다.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        print('Failed to save user info. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> _saveUserAge() async {
    final url = Uri.parse('http://10.0.2.2:3000/user/saveuserage');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'studentID': Provider.of<UserProvider>(context, listen: false).studentId,
          'nickname': nickname,
          'age': age,
          'gender': gender,
          'password': password,
          'email': combineEmail(Provider.of<UserProvider>(context, listen: false).studentId),
          'Newnickname': Newnickname,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('User info saved successfully!');
        _showSaveMessage();
      } else {
        print('Failed to save user info. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> _saveUserGender() async {
    final url = Uri.parse('http://10.0.2.2:3000/user/saveusergender');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'studentID': Provider.of<UserProvider>(context, listen: false).studentId,
          'nickname': nickname,
          'age': age,
          'gender': gender,
          'email': combineEmail(Provider.of<UserProvider>(context, listen: false).studentId),
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('User info saved successfully.');
        setState(() {
          this.gender = gender; // 상태 갱신
        });
        _showSaveMessage();
      } else {
        print('Failed to save user info. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> _saveUserIntro() async {
    final url = Uri.parse('http://10.0.2.2:3000/user/saveuserintro');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'studentID': Provider.of<UserProvider>(context, listen: false).studentId,
          'nickname': nickname,
          'age': age,
          'gender': gender,
          'password': password,
          'email': combineEmail(Provider.of<UserProvider>(context, listen: false).studentId),
          'introduce': introduction,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('User info saved successfully.');
        _showSaveMessage();
      } else {
        print('Failed to save user info. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> _uploadImageToServer(File image) async {
    final url = Uri.parse('http://10.0.2.2:3000/user/uploadprofile');

    try {
      final compressedImage = await _resizeAndCompressImage(image);

      final response = await http.post(
        url,
        body: {
          'studentID': Provider.of<UserProvider>(context, listen: false).studentId.toString(),
          'imageData': base64Encode(compressedImage.readAsBytesSync()),
        },
      );

      if (response.statusCode == 200) {
        print('Image uploaded successfully.');
        await _getImageFromServer();  // Refresh the image from the server
        _showSaveMessage();
      } else if (response.statusCode == 413) {
        _showImageSizeErrorMessage();
      } else {
        print('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> _getImageFromServer() async {
    final url = Uri.parse('http://10.0.2.2:3000/user/getprofile');
    setState(() {
      _loading = true; // 시작할 때 로딩 상태로 설정
    });

    try {
      final response = await http.post(
        url,
        body: {'studentID': Provider.of<UserProvider>(context, listen: false).studentId.toString()},
      );

      if (response.statusCode == 200) {
        final imageDataBase64 = response.body;
        final Uint8List imageDataBytes = base64Decode(imageDataBase64);

        if (imageDataBytes.isNotEmpty) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_image.png');
          await tempFile.writeAsBytes(imageDataBytes);

          if (await tempFile.length() > 0) {
            setState(() {
              _image = tempFile;
              _loading = false; // 이미지 로드 완료 후 로딩 상태 해제
            });
          } else {
            print('Error: The downloaded image file is empty');
            setState(() {
              _loading = false; // 에러 발생 시 로딩 상태 해제
            });
          }
        } else {
          print('Error: Image data bytes are empty.');
          setState(() {
            _loading = false; // 에러 발생 시 로딩 상태 해제
          });
        }
      } else {
        print('Failed to get image. Status code: ${response.statusCode}');
        setState(() {
          _loading = false; // 에러 발생 시 로딩 상태 해제
        });
      }
    } catch (error) {
      print('Error: $error');
      setState(() {
        _loading = false; // 에러 발생 시 로딩 상태 해제
      });
    }
  }

  Future<void> getUserInfo() async {
    final url = Uri.parse('http://10.0.2.2:3000/user/userinfo');

    try {
      final response = await http.post(
        url,
        body: {'studentID': Provider.of<UserProvider>(context, listen: false).studentId.toString()},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String defaultNickname = '닉네임';
        final int defaultAge = 25;
        final String defaultGender = '남성';
        final String defaultIntroduction = '안녕하세요 자기소개를 입력해주세요.';
        final String defaultMajor = '없음';

        setState(() {
          nickname = data['nickname'] ?? defaultNickname;
          age = data['age'] ?? defaultAge;
          gender = data['gender'] ?? defaultGender;
          introduction = data['introduce'] ?? defaultIntroduction;
          major = data['major'] ?? defaultMajor;
        });
      } else {
        print('Failed to get user info.');
        print(response.statusCode);
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void _showSaveMessage() {
    final snackBar = SnackBar(
      content: Text('저장되었습니다.'),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<File> _fixImageOrientation(File imageFile) async {
    return await Future.microtask(() async {
      try {
        final bytes = await imageFile.readAsBytes();
        final data = await readExifFromBytes(bytes);

        img.Image? image = img.decodeImage(bytes);
        if (image == null) {
          return imageFile;
        }

        print('Original Decode Size: ${image.width} x ${image.height}');

        if (data != null && data.isNotEmpty) {
          final orientation = data['Image Orientation']?.printable;
          switch (orientation) {
            case 'Rotated 90 CW':
              image = img.copyRotate(image, 90);
              break;
            case 'Rotated 180':
              image = img.copyRotate(image, 180);
              break;
            case 'Rotated 270 CW':
              image = img.copyRotate(image, -90);
              break;
          }
        }

        final tempDir = await getTemporaryDirectory();
        final fixedFile = File('${tempDir.path}/fixed_image.jpg')
          ..writeAsBytesSync(img.encodeJpg(image, quality: 85));

        return fixedFile;
      } catch (e) {
        print('Error fixing image orientation: $e');
        return imageFile;
      }
    });
  }

  Future<File> _resizeAndCompressImage(File imageFile) async {
    return await Future.microtask(() async {
      try {
        final bytes = await imageFile.readAsBytes();
        img.Image? image = img.decodeImage(bytes);

        if (image != null) {
          print('Original Decode Size: ${image.width} x ${image.height}');
          final resizedImage = img.copyResize(image, width: 300, height: 200); // Resize to width of 800px, 여기 줄이면 이미지 용량 줄어듬
          print('Resized Decode Size: ${resizedImage.width} x ${resizedImage.height}');
          final tempDir = await getTemporaryDirectory();
          final resizedFile = File('${tempDir.path}/resized_image.jpg')
            ..writeAsBytesSync(img.encodeJpg(resizedImage, quality: 40)); // Compress with quality 85

          print('Resized Image Size: ${await resizedFile.length()} bytes');
          return resizedFile;
        } else {
          print('Error decoding image for resizing');
          return imageFile;
        }
      } catch (e) {
        print('Error resizing image: $e');
        return imageFile;
      }
    });
  }

  Future _getImageFromGallery() async {
    final picker = ImagePicker();
    final pickedImage = await picker.getImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      File imageFile = File(pickedImage.path);
      imageFile = await _fixImageOrientation(imageFile);

      print('Original Image Size: ${await imageFile.length()} bytes');
      if (await imageFile.length() > 5 * 1024 * 1024) {
        imageFile = await _resizeImage(imageFile);
        print('Resized Image Size: ${await imageFile.length()} bytes');
        if (await imageFile.length() > 5 * 1024 * 1024) {
          _showImageSizeErrorMessage();
          return;
        }
      }

      // Set the temporary image file only if the size is valid
      setState(() {
        _image = imageFile;
      });

      await _uploadImageToServer(_image!); // Ensure this operation completes
    }
  }

  Future<File> _resizeImage(File imageFile) async {
    return await Future.microtask(() async {
      try {
        final bytes = await imageFile.readAsBytes();
        img.Image? image = img.decodeImage(bytes);

        if (image != null) {
          print('Original Decode Size: ${image.width} x ${image.height}');
          final resizedImage = img.copyResize(image, width: 300, height: 200);
          print('Resized Decode Size: ${resizedImage.width} x ${resizedImage.height}');
          final tempDir = await getTemporaryDirectory();
          final resizedFile = File('${tempDir.path}/resized_image.jpg')
            ..writeAsBytesSync(img.encodeJpg(resizedImage, quality: 85));

          print('Resized Image Size: ${await resizedFile.length()} bytes');
          return resizedFile;
        } else {
          print('Error decoding image for resizing');
          return imageFile;
        }
      } catch (e) {
        print('Error resizing image: $e');
        return imageFile;
      }
    });
  }

  void _showImageSizeErrorMessage() {
    final snackBar = SnackBar(
      content: Text('프로필이미지는 5MB 이하의 사진만 설정 가능합니다.'),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // Reset the image picker to avoid displaying the too-large image
    _getImageFromServer();
  }

  @override
  Widget build(BuildContext context) {
    DateTime? lastPressed;

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
          title: Text('마이페이지'),
          backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: _onTabTapped,
          currentIndex: 0,
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      _getImageFromGallery();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30.0),
                      child: _buildProfileImage(),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildInfoRow('닉네임', nickname, isDarkMode)),
                          SizedBox(width: 16),
                          Expanded(child: _buildInfoRow('나이', age.toString(), isDarkMode)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildInfoRow('성별', gender, isDarkMode)),
                          SizedBox(width: 16),
                          Expanded(child: _buildInfoRow('학과', major, isDarkMode)),
                        ],
                      ),
                      SizedBox(height: 8),
                      _buildIntroductionSection(isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return CircleAvatar(
      radius: 80,
      backgroundColor: Colors.grey,
      child: _loading
          ? CircularProgressIndicator() // 로딩 중일 때 로딩 인디케이터를 표시
          : _image == null
          ? Icon(Icons.person, size: 160, color: Colors.white)
          : ClipOval(
        child: Image.file(
          _image!,
          cacheHeight: 160,
          height: 160,
          cacheWidth: 160,
          width: 160,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              textBaseline: TextBaseline.alphabetic,
            ),
          ),
          SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (label == '닉네임')
                if (label == '나이')
                  if (label == '성별')
                    if (label == '학과')
                      SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 12,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                ),
              ),
              _buildChangeButton(label),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntroductionSection(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자기소개',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              textBaseline: TextBaseline.alphabetic,
            ),
          ),
          SizedBox(height: 4),
          TextField(
            controller: TextEditingController(text: introduction),
            onChanged: (value) {
              introduction = value;
            },
            maxLines: null, // 여러 줄 입력 가능
            decoration: InputDecoration(
              hintText: '자기소개를 입력하세요',
              hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
              border: InputBorder.none,
            ),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
              textBaseline: TextBaseline.alphabetic,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  _saveUserIntro();
                },
                icon: Icon(
                  Icons.save_as,
                  color: isDarkMode ? Colors.deepPurpleAccent : Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeButton(String label) {
    return IconButton(
      onPressed: () {
        if (label == '성별') {
          _showGenderChangeDialog();
        } else if (label == '자기소개') {
          _showIntroductionChangeDialog();
        } else if (label == '학과') {
          _showMajorChangeDialog();
        } else {
          _showInfoChangeDialog(label);
        }
      },
      icon: Icon(
        Icons.drive_file_rename_outline,
        color: Colors.deepPurpleAccent,
      ),
      padding: EdgeInsets.all(8.0),
    );
  }

  void _showMajorChangeDialog() {
    String selectedCollege = '';
    String selectedDepartment = '';
    List<String> colleges = [
      '문과대학',
      '사범대학',
      '공과대학',
      '스마트융합대학',
      '경상대학',
      '사회과학대학',
      '생명나노과학대학',
      '아트&디자인테크놀로지대학'
    ];
    Map<String, List<String>> departments = {
      '문과대학': [
        '국어국문학과',
        '영어영문학과',
        '응용영어콘텐츠학과',
        '일어일문학전공',
        '프랑스어문학전공',
        '문헌정보학과',
        '사학과',
        '기독교학과'
      ],
      '사범대학': [
        '국어교육과',
        '영어교육과',
        '교육학과',
        '역사교육과',
        '미술교육과',
        '수학교육과'
      ],
      '공과대학': [
        '정보통신공학과',
        '전기전자공학과',
        '멀티미디어공학과',
        '건축학과',
        '건축공학전공',
        '토목환경공학전공',
        '기계공학과',
        '화학공학과'
      ],
      '스마트융합대학': ['신소재공학과', '컴퓨터공학과', '산업경영공학과', 'AI융합학과'],
      '경상대학': ['경영학과', '경제학과', '무역물류학과', '중국경제통상학과', '회계학과'],
      '사회과학대학': ['행정학과', '경찰학과', '정치언론학과', '사회복지학과', '아동복지학과'],
      '생명나노과학대학': [
        '생명시스템과학과',
        '식품영양학과',
        '화학과',
        '간호학과',
        '바이오제약공학과'
      ],
      '아트&디자인테크놀로지대학': [
        '회화과',
        '패션디자인학과',
        '미디어영상학과',
        '디자인학과',
        '광고홍보학과'
      ],
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('학과 변경', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCollege.isNotEmpty ? selectedCollege : null,
                    hint: Text('대학 선택', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                    items: colleges.map((String college) {
                      return DropdownMenuItem<String>(
                        value: college,
                        child: Text(college, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedCollege = value!;
                        selectedDepartment = '';
                      });
                    },
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDepartment.isNotEmpty ? selectedDepartment : null,
                    hint: Text('학과 선택', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                    items: selectedCollege.isNotEmpty
                        ? departments[selectedCollege]!.map((String department) {
                      return DropdownMenuItem<String>(
                        value: department,
                        child: Text(department, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                      );
                    }).toList()
                        : [],
                    onChanged: (String? value) {
                      setState(() {
                        selectedDepartment = value!;
                      });
                    },
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('취소', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedDepartment.isNotEmpty) {
                      setState(() {
                        major = selectedDepartment;
                        _saveUserMajor();
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: Text('저장', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveUserMajor() async {
    final url = Uri.parse('http://10.0.2.2:3000/user/saveusermajor');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'studentID': Provider.of<UserProvider>(context, listen: false).studentId,
          'major': major,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('User major saved successfully');
        _showSaveMessage();
        setState(() {});
      } else {
        print('Failed to save user major. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void _showInfoChangeDialog(String label) {
    String newValue = label == '닉네임' ? nickname : label == '나이' ? age.toString() : gender.toString();
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("$label 변경", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
          content: TextField(
            onChanged: (value) {
              newValue = value;
            },
            decoration: InputDecoration(labelText: "새로운 $label", labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("취소", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (label == '닉네임') {
                    Newnickname = newValue;
                    nickname = newValue;
                    _saveUserName();
                  } else if (label == '나이') {
                    age = int.parse(newValue);
                    _saveUserAge();
                  } else if (label == '성별') {
                    gender = newValue;
                    _saveUserGender();
                  }
                });
                Navigator.pop(context);
              },
              child: Text("저장", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _showGenderChangeDialog() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('성별 변경', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGenderDropdown(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderDropdown() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String? selectedGender = gender;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return DropdownButton<String>(
          value: selectedGender,
          onChanged: (String? newValue) {
            setState(() {
              selectedGender = newValue;
            });
            if (newValue != null) {
              setState(() {
                gender = newValue;
                _saveUserGender();
              });
              Navigator.pop(context);
            }
          },
          items: <String>['남성', '여성']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            );
          }).toList(),
          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
        );
      },
    );
  }

  void _showIntroductionChangeDialog() {
    String newIntroduction = introduction;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("자기소개 변경", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
          content: TextField(
            onChanged: (value) {
              newIntroduction = value;
            },
            decoration: InputDecoration(labelText: "새로운 자기소개", labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("취소", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  introduction = newIntroduction;
                  _saveUserIntro();
                });
                Navigator.pop(context);
              },
              child: Text("저장", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            ),
          ],
        );
      },
    );
  }
}

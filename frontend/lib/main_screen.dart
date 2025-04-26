import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'join_party.dart';

class MainScreen extends StatefulWidget {
  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 2;
  String _selectedActivityCategory = '오정 캠퍼스';
  String _selectedLocationCategory = '전체';
  late GoogleMapController _mapController;
  Completer<GoogleMapController> _controllerCompleter = Completer();
  late CameraPosition _initialCameraPosition;
  Set<Marker> _markers = {};
  LatLng? _currentPosition; // 현재 위치 저장
  StreamSubscription<Position>? _positionStreamSubscription; // 위치 스트림 구독
  final double _minZoom = 10.0; // 최소 줌 레벨
  final double _maxZoom = 20.0; // 최대 줌 레벨

  final Map<String, LatLngBounds> _mapBounds = {
    '오정 캠퍼스': LatLngBounds(
      southwest: LatLng(36.35116, 127.4177), // 오정 지역의 남서쪽 경계
      northeast: LatLng(36.35669, 127.4266), // 오정 지역의 북동쪽 경계
    ),
    '대덕 캠퍼스': LatLngBounds(
      southwest: LatLng(36.39834, 127.3898), // 대덕 지역의 남서쪽 경계
      northeast: LatLng(36.40032, 127.3934), // 대덕 지역의 북동쪽 경계
    ),
  };

  final Map<String, CameraPosition> _mapPositions = {
    '오정 캠퍼스': CameraPosition(
      target: LatLng(36.35298, 127.4215), // 오정 캠퍼스
      zoom: 18.0,
    ),
    '대덕 캠퍼스': CameraPosition(
      target: LatLng(36.39922330219257, 127.3921811533066), // 대전의 위치로 가정
      zoom: 18.0,
    ),
  };

  final Map<String, List<Marker>> _categoryMarkers = {
    '오정 캠퍼스': [
      Marker(
        markerId: MarkerId('평생교육원'),
        position: LatLng(36.35129, 127.4223),
        infoWindow: InfoWindow(title: '평생교육원'),
      ),
      Marker(
        markerId: MarkerId('정문'),
        position: LatLng(36.35198, 127.4215),
        infoWindow: InfoWindow(title: '정문'),
      ),
      Marker(
        markerId: MarkerId('56주년기념관'),
        position: LatLng(36.35186, 127.4223),
        infoWindow: InfoWindow(title: '56주년기념관'),
      ),
      Marker(
        markerId: MarkerId('조형예술대학'),
        position: LatLng(36.35184, 127.4235),
        infoWindow: InfoWindow(title: '조형예술대학'),
      ),
      Marker(
        markerId: MarkerId('학교도서관'),
        position: LatLng(36.35267, 127.4234),
        infoWindow: InfoWindow(title: '학교도서관'),
      ),
      Marker(
        markerId: MarkerId('쪽문'),
        position: LatLng(36.35268, 127.4243),
        infoWindow: InfoWindow(title: '쪽문'),
      ),
      Marker(
        markerId: MarkerId('경상대학'),
        position: LatLng(36.35369, 127.4240),
        infoWindow: InfoWindow(title: '경상대학'),
      ),
      Marker(
        markerId: MarkerId('한남XR센터'),
        position: LatLng(36.35317, 127.4247),
        infoWindow: InfoWindow(title: '한남XR센터'),
      ),
      Marker(
        markerId: MarkerId('인돈학술원'),
        position: LatLng(36.35369, 127.4240),
        infoWindow: InfoWindow(title: '인돈학술원'),
      ),
      Marker(
        markerId: MarkerId('문과대학'),
        position: LatLng(36.35520, 127.4230),
        infoWindow: InfoWindow(title: '문과대학'),
      ),
      Marker(
        markerId: MarkerId('법과대학'),
        position: LatLng(36.35481, 127.4229),
        infoWindow: InfoWindow(title: '법과대학'),
      ),
      Marker(
        markerId: MarkerId('11번건물'),
        position: LatLng(36.35480, 127.4220),
        infoWindow: InfoWindow(title: '11번건물'),
      ),
      Marker(
        markerId: MarkerId('탈메이지기념관'),
        position: LatLng(36.35595, 127.4224),
        infoWindow: InfoWindow(title: '탈메이지기념관'),
      ),
      Marker(
        markerId: MarkerId('북문'),
        position: LatLng(36.35701, 127.4235),
        infoWindow: InfoWindow(title: '북문'),
      ),
      Marker(
        markerId: MarkerId('성지관'),
        position: LatLng(36.35629, 127.4214),
        infoWindow: InfoWindow(title: '성지관'),
      ),
      Marker(
        markerId: MarkerId('이과대학'),
        position: LatLng(36.35647, 127.4203),
        infoWindow: InfoWindow(title: '이과대학'),
      ),
      Marker(
        markerId: MarkerId('공과대학'),
        position: LatLng(36.35642, 127.4197),
        infoWindow: InfoWindow(title: '공과대학'),
      ),
      Marker(
        markerId: MarkerId('미술교육관'),
        position: LatLng(36.35545, 127.4201),
        infoWindow: InfoWindow(title: '미술교육관'),
      ),
      Marker(
        markerId: MarkerId('창업지원단'),
        position: LatLng(36.35544, 127.4186),
        infoWindow: InfoWindow(title: '창업지원단'),
      ),
      Marker(
        markerId: MarkerId('학군단'),
        position: LatLng(36.35494, 127.4179),
        infoWindow: InfoWindow(title: '학군단'),
      ),
      Marker(
        markerId: MarkerId('대학본부'),
        position: LatLng(36.35537, 127.4209),
        infoWindow: InfoWindow(title: '대학본부'),
      ),
      Marker(
        markerId: MarkerId('학생회관(동아리실)'),
        position: LatLng(36.35451, 127.4193),
        infoWindow: InfoWindow(title: '학생회관(동아리실)'),
      ),
      Marker(
        markerId: MarkerId('사범대학'),
        position: LatLng(36.35473, 127.4202),
        infoWindow: InfoWindow(title: '사범대학'),
      ),
      Marker(
        markerId: MarkerId('종합운동장'),
        position: LatLng(36.35346, 127.4193),
        infoWindow: InfoWindow(title: '종합운동장'),
      ),
    ],
    '대덕 캠퍼스': [
      Marker(
        markerId: MarkerId('대덕정문'),
        position: LatLng(36.40024, 127.3920),
        infoWindow: InfoWindow(title: '대덕정문'),
      ),
      Marker(
        markerId: MarkerId('진리관'),
        position: LatLng(36.399516402422414, 127.39073904300818),
        infoWindow: InfoWindow(title: '진리관'),
      ),
      Marker(
        markerId: MarkerId('자유관'),
        position: LatLng(36.39922267978285, 127.39237065456217),
        infoWindow: InfoWindow(title: '자유관'),
      ),
      Marker(
        markerId: MarkerId('생명나노과학대학'),
        position: LatLng(36.398647044913815, 127.39134500217854),
        infoWindow: InfoWindow(title: '생명나노과학대학'),
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedLocationCategory = '전체';
    _initialCameraPosition = _mapPositions[_selectedActivityCategory]!;
    _initializeMarkers();
    _getCurrentLocation(); // 추가: 현재 위치 가져오기
    _startPositionStream(); // 추가: 위치 스트림 시작
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // 위치 스트림 구독 해제
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 위치 서비스가 활성화되지 않으면 사용자를 알림
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // 권한이 거부되면 사용자에게 알림
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 권한이 영구적으로 거부된 경우 사용자에게 알림
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _updateCurrentLocation(position);
  }

  void _startPositionStream() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      _updateCurrentLocation(position);
    });
  }

  void _updateCurrentLocation(Position position) {
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _updateMarkers(); // 마커 업데이트 호출
    });
  }

  void _initializeMarkers() {
    _markers.clear();
    var markers = _categoryMarkers[_selectedActivityCategory]!;
    for (var marker in markers) {
      _markers.add(
        Marker(
          markerId: marker.markerId,
          position: marker.position,
          infoWindow: marker.infoWindow,
          onTap: () => _navigateToPartyListScreen(marker.markerId.value),
        ),
      );
    }
  }

  void _updateMarkers() {
    setState(() {
      _initializeMarkers(); // 마커 초기화
    });
  }

  void _navigateToPartyListScreen(String markerId) {
    int listIndex = _convertMarkerIdToListIndex(markerId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartyPage(selectedBuildNum: listIndex),
      ),
    );
  }

  int _convertMarkerIdToListIndex(String markerId) {
    var indexMap = {
      '오정 캠퍼스': {'평생교육원': 0, '정문': 1, '56주년기념관': 2, '조형예술대학': 3, '학교도서관': 4, '쪽문': 5, '경상대학': 6, '한남XR센터': 7, '인돈학술원': 8, '문과대학': 9, '법과대학': 10, '11번건물': 11, '탈메이지기념관': 12, '북문': 13, '성지관': 14, '이과대학': 15, '공과대학': 16, '미술교육관': 17, '창업지원단': 18, '학군단': 19, '대학본부': 20, '학생회관(동아리실)': 21, '사범대학': 22, '종합운동장': 23,},
      '대덕 캠퍼스': {'대덕정문': 24, '진리관': 25, '자유관': 26, '생명나노과학대학': 27,},
    };
    if (indexMap.containsKey(_selectedActivityCategory)) {
      var categoryMap = indexMap[_selectedActivityCategory];
      if (categoryMap != null && categoryMap.containsKey(markerId)) {
        return categoryMap[markerId]!;
      }
    }
    return 0;
  }

  void _onActivityCategorySelected(String? category) {
    if (category != null) {
      setState(() {
        _selectedActivityCategory = category;
        _selectedLocationCategory = '전체';
        _initialCameraPosition = _mapPositions[category]!;
        _initializeMarkers();
      });
      Future.delayed(Duration(milliseconds: 300), () {
        _controllerCompleter.future.then((controller) {
          controller.animateCamera(CameraUpdate.newCameraPosition(_initialCameraPosition));
        });
      });
    }
  }

  void _onLocationCategorySelected(String? location) {
    if (location != null && location != '전체') {
      setState(() {
        _selectedLocationCategory = location;
        if (location == '내 위치') {
          _moveToCurrentLocation();
        } else {
          var selectedMarker = _categoryMarkers[_selectedActivityCategory]!.firstWhere(
                (marker) => marker.markerId.value == location,
            orElse: () => _categoryMarkers[_selectedActivityCategory]!.first,
          );
          _controllerCompleter.future.then((controller) {
            controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
              target: selectedMarker.position,
              zoom: 18.0,
            )));
            controller.showMarkerInfoWindow(selectedMarker.markerId);
          });
        }
      });
    } else {
      _onActivityCategorySelected(_selectedActivityCategory);
    }
  }

  void _moveToCurrentLocation() {
    if (_currentPosition != null) {
      _controllerCompleter.future.then((controller) {
        controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: _currentPosition!,
          zoom: 18.0,
        )));
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _controllerCompleter.complete(controller);
    _mapController.setMapStyle('[Your Custom Style Here]'); // Optional: Map Style
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

  @override
  Widget build(BuildContext context) {
    DateTime? _lastPressed;
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
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedActivityCategory,
                  onChanged: _onActivityCategorySelected,
                  items: ['오정 캠퍼스', '대덕 캠퍼스'].map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: TextStyle(fontSize: 20), // 글자 크기 설정
                      ),
                    );
                  }).toList(),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                ),
              ),
              SizedBox(width: 10),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLocationCategory,
                  onChanged: _onLocationCategorySelected,
                  items: ['전체', '내 위치', ..._categoryMarkers[_selectedActivityCategory]!.map((marker) => marker.markerId.value).toList()].map((String location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(
                        location,
                        style: TextStyle(fontSize: 20), // 글자 크기 설정
                      ),
                    );
                  }).toList(),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        body: GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          markers: _markers,
          onMapCreated: _onMapCreated,
          cameraTargetBounds: CameraTargetBounds(_mapBounds[_selectedActivityCategory]!), // 지도의 범위 제한
          minMaxZoomPreference: MinMaxZoomPreference(_minZoom, _maxZoom), // 줌 범위 설정
          myLocationEnabled: true, // 현재 위치 표시
          myLocationButtonEnabled: true, // 현재 위치로 이동하는 버튼 표시
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
}
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _studentID = '';
  String _nickName = '';

  String get studentId => _studentID;
  String get nickname => _nickName;

  void setUser(String studentId, String nickname) {
    _studentID = studentId;
    _nickName = nickname;
    notifyListeners();
  }
}
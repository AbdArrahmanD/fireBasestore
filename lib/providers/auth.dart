import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  Timer? authTimer;
  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null &&
        _userId != null) {
      return _token;
    } else {
      return null;
    }
  }

  Future<void>? authenticate(
      String email, String password, String urlSegment) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyBbW1H-b42aAd975igklArlmjHK0AjaqWY';
    try {
      var res = await http.post(Uri.parse(url),
          body: json.encode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }));
      final resData = json.decode(res.body);
      if (resData['error'] != null) {
        throw resData['error']['message'];
      }
      _token = resData['idToken'];
      _expiryDate = DateTime.now()
          .add(Duration(seconds: int.parse(resData['expiresIn'])));
      _userId = resData['localId'];
      autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'expiryDate': _expiryDate?.toIso8601String(),
      });
      prefs.setString("userData", userData);
      if (prefs.containsKey("userData"))
        print('Shared Prefernces Work Sucssessfully');
    } catch (e) {
      print('my error is : $e');
      throw e;
    }
  }

  Future<bool> tryAutoLogin() async {
    final pref = await SharedPreferences.getInstance();
    if (pref.containsKey("userData")) {
      var rawData = pref.getString("userData")!;
      final extractdUserData = json.decode(rawData);
      final expiryDate =
          DateTime.parse(extractdUserData["expiryDate"].toString());
      if (expiryDate.isBefore(DateTime.now())) return false;
      _token = extractdUserData["token"].toString();
      _userId = extractdUserData["userId"].toString();
      _expiryDate = expiryDate;
      print('token is : $_token');
      print('User ID is : $_userId');
      print('Expiry Date is : $_expiryDate');
      notifyListeners();
      autoLogout();
      return true;
    } else {
      return false;
    }
  }

  Future<void> signIn(String email, String password) async {
    return authenticate(email, password, 'signInWithPassword');
  }

  Future<void> signUp(String email, String password) async {
    return authenticate(email, password, 'signUp');
  }

  void logout() async {
    _token = null;
    _userId = null;
    authTimer = null;
    var pref = await SharedPreferences.getInstance();
    pref.clear();
    notifyListeners();
  }

  void autoLogout() {
    if (authTimer != null) {
      authTimer!.cancel();
    }
    int timeToExpire = _expiryDate!.difference(DateTime.now()).inSeconds;
    authTimer = Timer(Duration(seconds: timeToExpire), logout);
  }
}

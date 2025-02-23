import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore 추가
import 'package:navermapapp/login/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final Function(bool) onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false; // 로딩 상태를 나타내는 변수
  bool _obscurePassword = true; // 비밀번호 숨김 여부를 나타내는 변수
  String? _deviceId; // 디바이스 ID 저장 변수

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? deviceId;

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
      }
    } catch (e) {
      print('디바이스 ID 가져오기 오류: $e');
    }

    setState(() {
      _deviceId = deviceId;
    });
  }

  // Future<void> _loadDeviceId() async {
  //   try {
  //     final FirebaseInstallations installations =
  //         FirebaseInstallations.instance;
  //     final String installationId = await installations.getId();

  //     setState(() {
  //       _deviceId = installationId;
  //     });

  //     debugPrint("Firebase Installation ID: $_deviceId");
  //   } catch (e) {
  //     debugPrint("Firebase Installation ID 가져오기 실패: $e");
  //   }
  // }

  // Future<String> getPersistentUserId() async {
  //   final auth = FirebaseAuth.instance;
  //   //final firestore = FirebaseFirestore.instance;

  //   if (auth.currentUser == null) {
  //     // 익명 로그인
  //     await auth.signInAnonymously();
  //   }

  //   return auth.currentUser!.uid;
  // }

  // Future<void> _loadDeviceId() async {
  //   try {
  //     final String userId = await getPersistentUserId();

  //     setState(() {
  //       _deviceId = userId;
  //     });

  //     debugPrint("Persistent User ID: $_deviceId");
  //   } catch (e) {
  //     debugPrint("Persistent User ID 가져오기 실패: $e");
  //     setState(() {
  //       _errorMessage = 'Persistent User ID를 가져오는데 실패했습니다: ${e.toString()}';
  //     });
  //   }
  // }

  Future<void> _saveLoginState(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('email', email); // 전화번호 저장
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // 로딩 시작
        _errorMessage = ''; // 에러 메시지 초기화
      });

      try {
        final String email = _emailController.text.trim();
        final String password = _passwordController.text.trim();

        // Firebase Authentication을 사용하여 로그인
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Firestore에서 사용자 정보 가져오기 (이메일 필드 사용)
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data()
              as Map<String, dynamic>; // 첫 번째 문서 사용
          final storedDeviceId = userData['deviceId'] as String?;
          final documentId = querySnapshot.docs.first.id; // 문서 ID

          // 디바이스 ID 비교
          if (storedDeviceId != null && storedDeviceId != _deviceId) {
            // 디바이스 ID가 다를 경우 에러 메시지 설정
            setState(() {
              _errorMessage = '다른 기기에서 가입된 이메일입니다.';
            });
            // Firebase Authentication에서 로그아웃 (선택 사항)
            await FirebaseAuth.instance.signOut();
            return; // 로그인 중단
          } else {
            // 디바이스 ID가 같거나 없는 경우 deviceId 업데이트
            await FirebaseFirestore.instance
                .collection('users')
                .doc(documentId) // 문서 ID 사용
                .update({'deviceId': _deviceId});

            _saveLoginState(email);
            widget.onLoginSuccess(true);
          }
        } else {
          // 사용자 정보가 Firestore에 없는 경우 (예외 처리)
          setState(() {
            _errorMessage = '사용자 정보를 찾을 수 없습니다.';
          });
          // Firebase Authentication에서 로그아웃 (선택 사항)
          await FirebaseAuth.instance.signOut();
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = '존재하지 않는 이메일입니다.';
            break;
          case 'wrong-password':
            message = '잘못된 비밀번호입니다.';
            break;
          case 'invalid-email':
            message = '유효하지 않은 이메일 주소입니다.';
            break;
          case 'user-disabled':
            message = '사용자 계정이 비활성화되었습니다.';
            break;
          default:
            message = '로그인에 실패했습니다: ${e.message}';
        }
        setState(() {
          _errorMessage = message;
        });
      } finally {
        setState(() {
          _isLoading = false; // 로딩 종료
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.jpg',
                  height: 100,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    hintText: '이메일 주소를 입력하세요',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요.';
                    }
                    if (!value.contains('@')) {
                      return '유효한 이메일 형식이 아닙니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '비밀번호를 입력하세요',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle: TextStyle(fontSize: 18),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('로그인'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupPage()),
                    );
                  },
                  child: const Text(
                    '계정이 없으신가요? 회원가입',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

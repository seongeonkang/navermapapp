import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 사용
import 'package:navermapapp/otp_verification_page.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:navermapapp/user_info_page.dart';
import 'package:shared_preferences/shared_preferences.dart'; // UserInfoPage 임포트

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.isSignUp = false});

  final bool isSignUp;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  String? _verificationId;
  String? _errorMessage;

  final _phoneNumberMaskFormatter = MaskTextInputFormatter(
    mask: '###-####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Future<void> _verifyPhoneNumber(String phoneNumber) async {
    setState(() {
      _errorMessage = null;
    });
    try {
      if (widget.isSignUp) {
        // 회원가입 모드
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("알림"),
                content: const Text("이미 등록된 사용자입니다."),
                actions: [
                  TextButton(
                    child: const Text("확인"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          return;
        }
      } else {
        // 로그인 모드
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get();

        // users 컬렉션에 존재하면 MyPage로 이동
        if (querySnapshot.docs.isNotEmpty) {
          _saveLoginState(phoneNumber); // 로그인 상태 저장 및 전화번호 저장
          Navigator.of(context).pop(true);
          return;
        } else {
          // users 컬렉션에 존재하지 않으면 오류 메시지 표시
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("알림"),
                content: const Text("등록되지 않은 전화번호입니다."),
                actions: [
                  TextButton(
                    child: const Text("확인"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          return;
        }
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('자동 인증 완료');
          await FirebaseAuth.instance.signInWithCredential(credential);
          _saveLoginState(phoneNumber);
          _showSuccessMessage();
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Error Message: ${e.message}');
          setState(() {
            _errorMessage = '인증 실패: ${e.message}';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });

          // 회원가입 모드일 경우 UserInfoPage로, 로그인 모드일 경우 OTPVerificationPage로 이동
          if (widget.isSignUp) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPVerificationPage(
                  verificationId: verificationId,
                  phoneNumber: phoneNumber,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserInfoPage(
                  phoneNumber: phoneNumber,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      debugPrint('Error Message: $e');
      setState(() {
        _errorMessage = '오류 발생: $e';
      });
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('인증 성공!')),
    );
  }

  Future<void> _saveLoginState(String phoneNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('phoneNumber', phoneNumber); // 전화번호 저장
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSignUp ? '회원가입' : '로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  hintText: '010-1234-5678',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [_phoneNumberMaskFormatter],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '전화번호를 입력해주세요.';
                  }
                  if (!RegExp(r'^010-\d{4}-\d{4}$').hasMatch(value)) {
                    return '전화번호 형식이 올바르지 않습니다. (010-1234-5678)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    String phoneNumber =
                        '+82${_phoneNumberController.text.substring(1).replaceAll('-', '')}';
                    _verifyPhoneNumber(phoneNumber);
                  }
                },
                child: Text(widget.isSignUp ? '회원가입' : '로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

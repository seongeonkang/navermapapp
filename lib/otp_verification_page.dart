import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart'; // OTP 입력 UI
import 'package:navermapapp/user_info_page.dart'; // UserInfoPage 임포트

class OTPVerificationPage extends StatefulWidget {
  const OTPVerificationPage(
      {super.key, required this.verificationId, required this.phoneNumber});

  final String verificationId;
  final String phoneNumber;

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final _otpController = TextEditingController();
  String? _errorMessage;

  Future<void> _verifyOTP(String otp) async {
    setState(() {
      _errorMessage = null;
    });
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // 인증 성공 후, 기본 정보 입력 화면으로 이동
      Navigator.pushReplacement(
        // 이전 화면으로 돌아가지 못하도록
        context,
        MaterialPageRoute(
          builder: (context) => UserInfoPage(phoneNumber: widget.phoneNumber),
        ),
      );
    } catch (e) {
      print('OTP 인증 실패: $e');
      print('Error Message: $e'); // 에러 메시지 로그 출력
      setState(() {
        _errorMessage = 'OTP 인증 실패: $e';
      });
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('인증 성공!')),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP 인증'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('인증 코드를 입력해주세요.'),
            const SizedBox(height: 20),
            // OTP 입력 필드 (pinput 라이브러리 사용)
            Pinput(
              controller: _otpController,
              length: 6, // OTP 길이
              onCompleted: (pin) => _verifyOTP(pin),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) // 에러 메시지 표시
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                _verifyOTP(_otpController.text);
              },
              child: const Text('인증'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:navermapapp/mypage/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhoneVerification extends StatefulWidget {
  final Function(bool) onLoginSuccess;

  const PhoneVerification({super.key, required this.onLoginSuccess});

  @override
  State<PhoneVerification> createState() => _PhoneVerificationState();
}

class _PhoneVerificationState extends State<PhoneVerification> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 이미지
              Image.asset(
                'assets/logo.jpg', // 로고 이미지 경로를 수정하세요.
                height: 100,
              ),
              const SizedBox(height: 40),

              // 로그인 상태에 따라 다른 위젯 표시
              if (_isLoggedIn)
                const Text("이미 로그인 되었습니다!") // 로그인 되었을 때 메시지
              else
                Column(
                  children: [
                    // 회원가입 Card
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: InkWell(
                        onTap: () {
                          // LoginPage로 이동 (회원가입 모드)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(
                                  isSignUp: true), // LoginPage로 이동, 회원가입 모드
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 20.0),
                          child: const Center(
                            child: Text(
                              '전화번호로 회원가입',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 이미 가입하셨나요? 로그인
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("이미 가입하셨나요?"),
                        TextButton(
                          onPressed: () async {
                            // 로그인 화면으로 이동
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LoginPage(), // LoginPage로 이동 (로그인 모드)
                              ),
                            );

                            if (result == true) {
                              // 로그인 성공 시
                              widget.onLoginSuccess(true); // MainPage의 상태 업데이트
                            }
                          },
                          child: const Text(
                            '로그인',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

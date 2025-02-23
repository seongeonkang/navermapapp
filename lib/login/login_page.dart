import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _saveLoginState(_emailController.text.trim());
        widget.onLoginSuccess(true);
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
      // appBar: AppBar(
      //   title: const Text('로그인'),
      //   centerTitle: true,
      //   backgroundColor: Colors.blueAccent, // 앱바 색상 변경
      // ),
      appBar: null,
      body: Center(
        // 중앙 정렬을 위해 Center 위젯 사용
        child: SingleChildScrollView(
          // 화면 넘침 방지
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 로고 또는 이미지 추가
                Image.asset(
                  'assets/logo.jpg', // 로고 이미지 경로 (assets 폴더에 이미지 추가 필요)
                  height: 100,
                ),
                const SizedBox(height: 20),
                // 이메일 입력 필드
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    hintText: '이메일 주소를 입력하세요',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email), // 이메일 아이콘 추가
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
                // 비밀번호 입력 필드
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '비밀번호를 입력하세요',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock), // 비밀번호 아이콘 추가
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

                // 에러 메시지 표시
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                // 로그인 버튼
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _signInWithEmailAndPassword, // 로딩 중에는 버튼 비활성화
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle: TextStyle(fontSize: 18),
                    backgroundColor: Colors.blueAccent, // 버튼 색상 변경
                    foregroundColor: Colors.white, // 글자 색상 변경
                    shape: RoundedRectangleBorder(
                      // 버튼 모양 변경
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

                // 회원가입 버튼
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
                  ), // 색상 변경
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:device_info_plus/device_info_plus.dart'; // 디바이스 정보 패키지
// import 'dart:io'; // Platform 정보 사용
import 'package:firebase_app_installations/firebase_app_installations.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

enum EmailVerificationStatus {
  unverified,
  verifying,
  duplicate,
  available,
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  EmailVerificationStatus _emailVerificationStatus =
      EmailVerificationStatus.unverified;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _nicknameFocusNode = FocusNode();

  String? _deviceId; // 디바이스 ID 저장 변수

  @override
  void initState() {
    super.initState();
    // _getDeviceId();
    _loadDeviceId();

    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
    _confirmPasswordFocusNode.addListener(_onFocusChange);
    _nicknameFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();

    _emailFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _confirmPasswordFocusNode.removeListener(_onFocusChange);
    _nicknameFocusNode.removeListener(_onFocusChange);

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _nicknameFocusNode.dispose();

    super.dispose();
  }

  void _onFocusChange() {
    if (_emailFocusNode.hasFocus ||
        _passwordFocusNode.hasFocus ||
        _confirmPasswordFocusNode.hasFocus ||
        _nicknameFocusNode.hasFocus) {
      setState(() {
        if (_emailVerificationStatus == EmailVerificationStatus.available) {
          _errorMessage = ''; // 모든 필드에 포커스가 가면 성공 메시지 숨김
        }
      });
    }
  }

  // Future<void> _getDeviceId() async {
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   String? deviceId;

  //   try {
  //     if (Platform.isAndroid) {
  //       AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //       deviceId = androidInfo.id;
  //     } else if (Platform.isIOS) {
  //       IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
  //       deviceId = iosInfo.identifierForVendor;
  //     }
  //   } catch (e) {
  //     print('디바이스 ID 가져오기 오류: $e');
  //   }

  //   setState(() {
  //     _deviceId = deviceId;
  //   });
  // }

  Future<void> _loadDeviceId() async {
    try {
      final FirebaseInstallations installations =
          FirebaseInstallations.instance;
      final String installationId = await installations.getId();

      setState(() {
        _deviceId = installationId;
      });

      debugPrint("Firebase Installation ID: $_deviceId");
    } catch (e) {
      debugPrint("Firebase Installation ID 가져오기 실패: $e");
    }
  }

  Future<void> _checkEmailAvailability() async {
    setState(() {
      _emailVerificationStatus = EmailVerificationStatus.verifying;
      _errorMessage = ''; // Clear any previous error messages
    });

    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        setState(() {
          _emailVerificationStatus = EmailVerificationStatus.duplicate;
          _errorMessage = '이미 사용중인 이메일입니다.';
        });
      } else {
        setState(() {
          _emailVerificationStatus = EmailVerificationStatus.available;
          _errorMessage = '사용 가능한 이메일 주소입니다.'; // Add success message
        });
      }
    } catch (e) {
      setState(() {
        _emailVerificationStatus = EmailVerificationStatus.unverified;
        _errorMessage = '이메일 확인 중 오류가 발생했습니다: ${e.toString()}';
      });
    }
  }

  Future<void> _createUserWithEmailAndPassword() async {
    if (_formKey.currentState!.validate() &&
        _emailVerificationStatus == EmailVerificationStatus.available &&
        _deviceId != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // 디바이스 ID 중복 확인
        final QuerySnapshot deviceIdResult = await FirebaseFirestore.instance
            .collection('users')
            .where('deviceId', isEqualTo: _deviceId)
            .limit(1)
            .get();

        if (deviceIdResult.docs.isNotEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = '이 디바이스에서 이미 다른 계정으로 가입했습니다.';
          });
          return; // 회원 가입 중단
        }

        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = credential.user;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': _emailController.text.trim(),
            'nickname': _nicknameController.text.trim(),
            'profileImageUrl': null,
            'createdAt': FieldValue.serverTimestamp(),
            'deviceId': _deviceId, // 디바이스 ID 저장
          });
        }

        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        String errorMessage = '회원가입에 실패했습니다.';
        if (e.code == 'weak-password') {
          errorMessage = '비밀번호가 너무 약합니다. 6자 이상이어야 합니다.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = '이미 사용중인 이메일입니다.';
        } else if (e.code == 'invalid-email') {
          errorMessage = '유효하지 않은 이메일 주소입니다.';
        } else {
          errorMessage = '알 수 없는 오류가 발생했습니다: ${e.message}';
        }
        setState(() {
          _errorMessage = errorMessage;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Firestore 오류: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (_emailVerificationStatus != EmailVerificationStatus.available) {
        setState(() {
          _errorMessage = "이메일 중복 확인을 해주세요.";
        });
      } else if (_deviceId == null) {
        setState(() {
          _errorMessage = "디바이스 ID를 가져오는데 실패했습니다.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '회원 가입',
                      style:
                          Theme.of(context).textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: '이메일',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
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
                            focusNode: _emailFocusNode,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _checkEmailAvailability,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text('중복 확인'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요.';
                        }
                        if (value.length < 6) {
                          return '비밀번호는 6자 이상이어야 합니다.';
                        }
                        return null;
                      },
                      focusNode: _passwordFocusNode,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: '비밀번호 확인',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호 확인을 입력해주세요.';
                        }
                        if (value != _passwordController.text) {
                          return '비밀번호가 일치하지 않습니다.';
                        }
                        return null;
                      },
                      focusNode: _confirmPasswordFocusNode,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력해주세요.';
                        }
                        return null;
                      },
                      focusNode: _nicknameFocusNode,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _emailVerificationStatus ==
                                  EmailVerificationStatus.available &&
                              !_isLoading &&
                              _deviceId != null
                          ? _createUserWithEmailAndPassword
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('회원가입'),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

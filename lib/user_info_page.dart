import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController(); // 이메일 컨트롤러 추가
  String _gender = 'male'; // 기본값: 남성
  DateTime? _birthDate; // 선택된 생년월일
  bool _isIdAvailable = true;
  bool _isNicknameAvailable = true;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _checkIdAvailability(String id) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('id', isEqualTo: id)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  Future<bool> _checkNicknameAvailability(String nickname) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        DateTime tempSelectedDate = _birthDate ?? DateTime.now();

        return SizedBox(
          height: MediaQuery.of(context).size.height / 2.5,
          child: Column(
            children: [
              SizedBox(
                height: 230,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempSelectedDate,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      tempSelectedDate = newDate;
                    });
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _birthDate = tempSelectedDate;
                  });
                  Navigator.pop(context);
                },
                child: const Text('확인', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveUserInfo() async {
    if (_formKey.currentState!.validate()) {
      // 아이디 중복 검사
      if (!await _checkIdAvailability(_idController.text)) {
        setState(() {
          _isIdAvailable = false;
        });
        return;
      }

      // 닉네임 중복 검사
      if (!await _checkNicknameAvailability(_nicknameController.text)) {
        setState(() {
          _isNicknameAvailable = false;
        });
        return;
      }

      try {
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'phoneNumber': widget.phoneNumber,
            'id': _idController.text,
            'nickname': _nicknameController.text,
            'email': _emailController.text, // 이메일 정보 추가
            'gender': _gender,
            'birthDate':
                _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
            'profilePicture': null,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('정보가 저장되었습니다.')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인증 오류: 사용자 정보를 찾을 수 없습니다.')),
          );
        }
      } catch (e) {
        print('사용자 정보 저장 오류: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 오류: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nicknameController.dispose();
    _emailController.dispose(); // 이메일 컨트롤러 dispose 추가
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기본 정보 입력'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: '아이디',
                  border: const OutlineInputBorder(),
                  errorText: !_isIdAvailable ? '이미 사용중인 아이디입니다.' : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '아이디를 입력해주세요.';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _isIdAvailable = true;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  border: const OutlineInputBorder(),
                  errorText: !_isNicknameAvailable ? '이미 사용중인 닉네임입니다.' : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요.';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _isNicknameAvailable = true;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                // 이메일 입력 필드 추가
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요.';
                  }
                  if (!value.contains('@')) {
                    return '유효한 이메일 주소를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('성별:'),
                  Radio<String>(
                    value: 'male',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  const Text('남성'),
                  Radio<String>(
                    value: 'female',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  const Text('여성'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '생년월일: ${_birthDate != null ? DateFormat('yyyy년 M월 d일', 'ko').format(_birthDate!) : '선택 안됨'}',
                  ),
                  TextButton(
                    onPressed: () => _showDatePicker(),
                    child: const Text('생년월일 선택'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUserInfo,
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const EditProfilePage(
      {super.key, required this.userData, required this.onProfileUpdated});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  File? _profileImage;
  final picker = ImagePicker();
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _nicknameController =
        TextEditingController(text: widget.userData['nickname'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    _profileImageUrl = widget.userData['profileImageUrl'];
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_profileImage == null) return;

    final fileName = p.basename(_profileImage!.path);
    final destination = 'profile_images/$fileName';

    try {
      final ref = FirebaseStorage.instance
          .ref(destination)
          .child('file/'); // Firebase Storage 경로 설정
      await ref.putFile(_profileImage!);

      _profileImageUrl = await ref.getDownloadURL(); // 다운로드 URL 가져오기

      print('Image Uploaded');
    } catch (e) {
      print('error occurred');
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      await _uploadImage(); // 이미지 먼저 업로드

      // 수정된 정보로 userData 업데이트
      Map<String, dynamic> updatedData = {
        ...widget.userData,
        'nickname': _nicknameController.text,
        'email': _emailController.text,
        'profileImageUrl': _profileImageUrl, // 프로필 이미지 URL 업데이트
      };

      // Firestore에 업데이트
      try {
        // 전화번호를 사용하여 users 컬렉션에서 사용자 정보 찾기
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: widget.userData['phoneNumber'])
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          // 사용자 정보 업데이트
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userSnapshot.docs.first.id)
              .update({
            'nickname': _nicknameController.text,
            'email': _emailController.text,
            'profileImageUrl': _profileImageUrl, // Firestore에 이미지 URL 저장
          });

          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로필이 업데이트되었습니다.')),
          );

          // 이전 페이지로 돌아가면서 업데이트된 정보 전달
          widget.onProfileUpdated(updatedData); // 변경된 프로필 이미지 URL도 전달
          Navigator.pop(context);
        } else {
          // 사용자 정보를 찾을 수 없는 경우 오류 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다.')),
          );
        }
      } catch (e) {
        // 오류 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 업데이트 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (builder) {
                        return Container(
                          height: 150.0,
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Column(
                            children: <Widget>[
                              const Text(
                                '사진 선택',
                                style: TextStyle(
                                  fontSize: 20.0,
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  TextButton.icon(
                                    icon: const Icon(Icons.camera),
                                    onPressed: () {
                                      getImage(ImageSource.camera);
                                      Navigator.pop(context);
                                    },
                                    label: const Text('카메라'),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.image),
                                    onPressed: () {
                                      getImage(ImageSource.gallery);
                                      Navigator.pop(context);
                                    },
                                    label: const Text('갤러리'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('assets/default_profile.png')
                                as ImageProvider,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(labelText: '닉네임'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '닉네임을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: '이메일'),
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
                ElevatedButton(
                  onPressed: _updateProfile,
                  child: const Text('프로필 업데이트'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

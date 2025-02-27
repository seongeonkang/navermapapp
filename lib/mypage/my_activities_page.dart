import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:navermapapp/mypage/my_detail_page.dart';
import 'package:navermapapp/mypage/my_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 패키지 추가

class MyActivitiesPage extends StatefulWidget {
  const MyActivitiesPage({super.key});

  @override
  State<MyActivitiesPage> createState() => _MyActivitiesPageState();
}

class _MyActivitiesPageState extends State<MyActivitiesPage> {
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  // SharedPreferences에서 이메일 정보 가져오기
  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email');
    });
  }

  // 스낵바 표시 함수
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _getImage(ImageSource source, BuildContext context) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);

      if (pickedFile != null) {
        if (pickedFile.path.isNotEmpty) {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MyPreviewPage(image: File(pickedFile.path)),
              ),
            );
          } else {
            print("위젯이 더 이상 활성 상태가 아닙니다. Navigator.push를 호출하지 않습니다.");
          }
        } else {
          print("Error: Image path is empty.");
          if (context.mounted) {
            _showSnackBar(context, '이미지 경로가 비어 있습니다.');
          }
        }
      } else {
        print("이미지 선택 취소");
        if (context.mounted) {
          _showSnackBar(context, '이미지 선택이 취소되었습니다.');
        }
      }
    } catch (e) {
      print("Error picking image: $e");
      if (context.mounted) {
        _showSnackBar(context, '이미지 선택 중 오류가 발생했습니다: $e'); // 더 구체적인 에러 메시지 고려
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userEmail == null
          ? const Center(child: CircularProgressIndicator()) // 이메일 로딩 중 표시
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('photos')
                  .where('email', isEqualTo: userEmail) // 이메일로 필터링
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('데이터를 불러오는 데 실패했습니다: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('데이터가 없습니다.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc =
                        snapshot.data!.docs[index]; // DocumentSnapshot 객체 가져오기
                    final data = doc.data() as Map<String, dynamic>;
                    final documentId = doc.id; // 문서 ID 가져오기

                    // 데이터에 문서 ID 추가
                    data['documentId'] = documentId;

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyDetailPage(
                                photoData: data,
                                onDelete: () {
                                  // 삭제 후 필요한 작업 수행 (예: 목록에서 해당 아이템 제거)
                                  setState(() {}); // 목록 업데이트
                                  Navigator.pop(context); // 상세 페이지 닫기
                                },
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Image.network(
                                data['imageUrl'], // 썸네일 이미지 URL
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                        '좌표: ${data['latitude']}, ${data['longitude']}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              // 모달 모양 변경
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext bc) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '이미지 선택',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor, // 테마 색상 사용
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildOption(
                            context: context,
                            icon: Icons.camera_alt,
                            text: '카메라',
                            onTap: () {
                              Navigator.pop(bc);
                              _getImage(ImageSource.camera, context);
                            },
                          ),
                          _buildOption(
                            context: context,
                            icon: Icons.image,
                            text: '갤러리',
                            onTap: () {
                              Navigator.pop(bc);
                              _getImage(ImageSource.gallery, context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  // 선택 옵션 위젯을 생성하는 함수
  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 30,
              color: Theme.of(context).primaryColor, // 테마 색상 사용
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

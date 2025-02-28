import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:navermapapp/mypage/my_detail_page.dart';
import 'package:navermapapp/mypage/my_preview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyActivitiesPage extends StatefulWidget {
  final bool showOnlyShared;

  const MyActivitiesPage({super.key, this.showOnlyShared = false});

  @override
  State<MyActivitiesPage> createState() => _MyActivitiesPageState();
}

class _MyActivitiesPageState extends State<MyActivitiesPage> {
  String? userEmail;
  Future<QuerySnapshot<Map<String, dynamic>>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email');
      _dataFuture = _fetchData();
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchData() async {
    if (userEmail == null) {
      return Future.value(null);
    }

    Query<Map<String, dynamic>> query;

    if (widget.showOnlyShared) {
      query = FirebaseFirestore.instance
          .collection('photos')
          .where('shareYn', isEqualTo: 'Y');
    } else {
      query = FirebaseFirestore.instance
          .collection('photos')
          .where('email', isEqualTo: userEmail);
    }

    return query.get();
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

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
        _showSnackBar(context, '이미지 선택 중 오류가 발생했습니다: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('데이터를 불러오는 데 실패했습니다: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting ||
                _dataFuture == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('데이터가 없습니다.'),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data();
                final documentId = doc.id;

                data['documentId'] = documentId;

                return Card(
                  elevation: 4, // 그림자 효과 추가
                  shape: RoundedRectangleBorder(
                    // 모서리 둥글게
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias, // 모서리 짤림 방지
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyDetailPage(
                            photoData: data,
                            onDelete: () {
                              setState(() {
                                _refreshData();
                              });
                              Navigator.pop(context);
                            },
                            showBottomTabBar: !widget.showOnlyShared,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 가로 사이즈에 맞춘 이미지
                        AspectRatio(
                          aspectRatio: 16 / 9, // 가로 세로 비율 설정 (예: 16:9)
                          child: Image.network(
                            data['imageUrl'],
                            fit: BoxFit.cover, // 이미지가 영역을 꽉 채우도록 설정
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (BuildContext context, Object error,
                                StackTrace? stackTrace) {
                              return const Icon(Icons.error);
                            },
                          ),
                        ),
                        // 이미지 아래에 제목 표시
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            data['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: !widget.showOnlyShared
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
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
                                color: Theme.of(context).primaryColor,
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
            )
          : null,
    );
  }

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
              color: Theme.of(context).primaryColor,
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:navermapapp/mypage/my_edit_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _userReviews = [];
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _phoneNumber = prefs.getString('phoneNumber');

    if (_phoneNumber != null) {
      // users 컬렉션에서 전화번호로 사용자 정보 찾기
      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: _phoneNumber)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          _userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        });

        // 리뷰 데이터 로드
        QuerySnapshot reviewSnapshot = await _firestore
            .collection('reviews')
            .where('userId', isEqualTo: userSnapshot.docs.first.id)
            .get();

        setState(() {
          _userReviews = reviewSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // 프로필 수정 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyEditProfilePage(
                    userData: _userData!,
                    onProfileUpdated: (updatedData) {
                      setState(() {
                        _userData = updatedData;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 사진
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _userData!['profileImageUrl'] != null
                          ? NetworkImage(_userData!['profileImageUrl'])
                          : const AssetImage('assets/default_profile.png')
                              as ImageProvider, // 기본 이미지 처리
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 정보 표시
                  Center(
                    child: Text(
                      _userData!['nickname'] ?? '닉네임 없음',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Center(
                    child: Text(
                      _userData!['email'] ?? '이메일 없음',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Center(
                    child: Text(
                      _phoneNumber ?? '전화번호 없음',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 팔로잉, 팔로워, 리뷰 건수
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildProfileStat(
                          '팔로잉', _userData!['followingCount'] ?? 0),
                      _buildProfileStat(
                          '팔로워', _userData!['followerCount'] ?? 0),
                      _buildProfileStat('리뷰', _userReviews.length),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 리뷰 목록
                  const Text(
                    '작성한 리뷰',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _userReviews.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            title: Text(_userReviews[index]['title'] ??
                                '제목 없음'), // 리뷰 제목 표시
                            subtitle: Text(_userReviews[index]['content'] ??
                                '내용 없음'), // 리뷰 내용 표시
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}

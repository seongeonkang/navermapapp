// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:navermapapp/detail_page.dart';

// class MyPage extends StatelessWidget {
//   const MyPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('photos').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Center(child: Text('데이터를 불러오는 데 실패했습니다.'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('데이터가 없습니다.'));
//           }

//           return ListView.builder(
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final data =
//                   snapshot.data!.docs[index].data() as Map<String, dynamic>;
//               return Card(
//                 margin: const EdgeInsets.all(8.0),
//                 child: InkWell(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => DetailPage(photoData: data),
//                       ),
//                     );
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Row(
//                       children: [
//                         Image.network(
//                           data['imageUrl'], // 썸네일 이미지 URL
//                           width: 80,
//                           height: 80,
//                           fit: BoxFit.cover,
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 data['title'],
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               Text(
//                                   '좌표: ${data['latitude']}, ${data['longitude']}'),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:navermapapp/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPage extends StatefulWidget {
  final Function(bool) onLoginSuccess;

  const MyPage({super.key, required this.onLoginSuccess});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
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

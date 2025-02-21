// import 'package:flutter/material.dart';
// import 'package:navermapapp/camera_page.dart';
// import 'package:navermapapp/home_page.dart';
// import 'package:navermapapp/search_page.dart'; // 검색 페이지
// import 'package:navermapapp/mypage.dart'; // 마이페이지

// class MainPage extends StatefulWidget {
//   const MainPage({super.key});

//   @override
//   State<MainPage> createState() => _MainPageState();
// }

// class _MainPageState extends State<MainPage> {
//   int _selectedIndex = 0; // 선택된 탭 인덱스

//   // 탭에 해당하는 위젯 목록
//   final List<Widget> _widgetOptions = <Widget>[
//     const HomePage(), // 홈 페이지 (사진 목록)
//     const SearchPage(), // 검색 페이지 (임시)
//     const MyPage(), // 마이페이지 (임시)
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     Widget _getMypageWidget() {
//       if (_isLoggedIn) {
//         return const ProfilePage(); // 로그인 상태이면 ProfilePage
//       } else {
//         return const MyPage(); // 로그인되지 않았으면 MyPage
//       }
//     }

//     // 탭에 해당하는 위젯 목록
//     final List<Widget> _widgetOptions = <Widget>[
//       const HomePage(),
//       const SearchPage(),
//       _getMypageWidget(), // 로그인 상태에 따라 MyPage 또는 ProfilePage
//     ];

//     void _onItemTapped(int index) {
//       setState(() {
//         _selectedIndex = index;
//       });
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           '흔 적',
//           style: TextStyle(
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color.fromARGB(255, 33, 166, 243),
//       ),
//       body: _widgetOptions.elementAt(_selectedIndex), // 선택된 탭의 위젯 표시
//       // floatingActionButton: _selectedIndex ==
//       //         2 // 홈 탭에서만 FloatingActionButton 표시
//       //     ? FloatingActionButton(
//       //         onPressed: () {
//       //           Navigator.push(
//       //             context,
//       //             MaterialPageRoute(builder: (context) => const CameraPage()),
//       //           );
//       //         },
//       //         child: const Icon(Icons.camera_alt),
//       //       )
//       //     : null,
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: '홈',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.search),
//             label: '검색',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: '마이페이지',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Colors.amber[800],
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:navermapapp/home_page.dart';
import 'package:navermapapp/mypage.dart';
import 'package:navermapapp/mypage/phone_verification.dart';
import 'package:navermapapp/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase 인증 추가

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
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

  //탭 변경 함수
  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 로그아웃 함수
  Future<void> _logout() async {
    // 로그아웃 확인 다이얼로그 표시
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("로그아웃"),
          content: const Text("로그아웃 하시겠습니까?"),
          actions: [
            TextButton(
              child: const Text("아니오"),
              onPressed: () {
                Navigator.of(context).pop(false); // 아니오 선택
              },
            ),
            TextButton(
              child: const Text("예"),
              onPressed: () {
                Navigator.of(context).pop(true); // 예 선택
              },
            ),
          ],
        );
      },
    );

    // "예"를 선택한 경우 로그아웃 진행
    if (confirmLogout == true) {
      try {
        await FirebaseAuth.instance.signOut(); // Firebase 로그아웃
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false); // 로그인 상태 초기화
        setState(() {
          _isLoggedIn = false; // 상태 업데이트
          _selectedIndex = 0; // 홈 탭으로 이동
        });
      } catch (e) {
        print("로그아웃 오류: $e");
        // 오류 처리 (예: 스낵바 표시)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget getMypageWidget() {
      if (_isLoggedIn) {
        return const MyPage();
      } else {
        return PhoneVerification(
          onLoginSuccess: (success) {
            setState(() {
              _isLoggedIn = success;
            });
          },
        );
      }
    }

    final List<Widget> widgetOptions = <Widget>[
      const HomePage(),
      const SearchPage(),
      getMypageWidget(),
    ];

    void onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '흔 적',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 33, 166, 243),
        actions: [
          // 로그아웃 아이콘 버튼
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoggedIn ? _logout : null, // 로그인 상태일 때만 활성화
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '검색',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: onItemTapped,
      ),
    );
  }
}

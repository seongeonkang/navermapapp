import 'package:flutter/material.dart';
import 'package:navermapapp/camera_page.dart';
import 'package:navermapapp/home_page.dart';
import 'package:navermapapp/search_page.dart'; // 검색 페이지
import 'package:navermapapp/mypage.dart'; // 마이페이지

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // 선택된 탭 인덱스

  // 탭에 해당하는 위젯 목록
  final List<Widget> _widgetOptions = <Widget>[
    const HomePage(), // 홈 페이지 (사진 목록)
    const SearchPage(), // 검색 페이지 (임시)
    const MyPage(), // 마이페이지 (임시)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '흔 적',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 33, 166, 243),
      ),
      body: _widgetOptions.elementAt(_selectedIndex), // 선택된 탭의 위젯 표시
      floatingActionButton: _selectedIndex ==
              2 // 홈 탭에서만 FloatingActionButton 표시
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraPage()),
                );
              },
              child: const Icon(Icons.camera_alt),
            )
          : null,
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
        onTap: _onItemTapped,
      ),
    );
  }
}

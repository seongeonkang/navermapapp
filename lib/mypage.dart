import 'package:flutter/material.dart';
import 'package:navermapapp/mypage/my_activities_page.dart';
import 'package:navermapapp/mypage/my_profile_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // AppBar를 null로 설정하여 제거
      body: Column(
        // AppBar를 제거했으므로 TabBar를 배치할 Column 추가
        children: [
          TabBar(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: '나의흔적'),
              Tab(text: '프로필'),
            ],
          ),
          Expanded(
            // TabBarView가 화면을 채우도록 Expanded로 감싸줍니다.
            child: TabBarView(
              controller: _tabController,
              children: const <Widget>[
                MyActivitiesPage(),
                MyProfilePage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

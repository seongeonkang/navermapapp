// import 'package:flutter/material.dart';
// import 'package:navermapapp/location_info_page.dart';
// import 'package:navermapapp/share_trace_page.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       //appBar: null, // AppBar 삭제
//       body: Column(
//         children: [
//           Material(
//             // elevation 을 주기 위해 Material 로 감쌌습니다.
//             elevation: 4.0, // 그림자 효과를 줍니다.
//             child: TabBar(
//               controller: _tabController,
//               labelColor: Colors.blue, // 선택된 탭의 색상
//               unselectedLabelColor: Colors.grey, // 선택되지 않은 탭의 색상
//               tabs: [
//                 Tab(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
//                     children: [
//                       Icon(Icons.location_on), // 지역정보 아이콘
//                       SizedBox(width: 8), // 아이콘과 텍스트 간 간격
//                       Text('지역정보'),
//                     ],
//                   ),
//                 ),
//                 Tab(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
//                     children: [
//                       Icon(Icons.share), // 흔적공유 아이콘
//                       SizedBox(width: 8), // 아이콘과 텍스트 간 간격
//                       Text('흔적공유'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: const [
//                 LocationInfoPage(), // 지역정보 페이지
//                 ShareTracePage(), // 흔적공유 페이지
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// home_page.dart

import 'package:flutter/material.dart';
import 'package:navermapapp/location_info_page.dart';
import 'package:navermapapp/mypage/my_activities_page.dart'; // MyActivitiesPage 임포트

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
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
      body: Column(
        children: [
          Material(
            elevation: 4.0,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on),
                      SizedBox(width: 8),
                      Text('지역정보'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('흔적공유'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LocationInfoPage(),
                MyActivitiesPage(
                    showOnlyShared:
                        true), // shareYn이 Y인 것만 보여주는 MyActivitiesPage
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:navermapapp/main_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showPermissionDialog = true; // 권한 안내 다이얼로그 표시 여부

  @override
  void initState() {
    super.initState();
    // 초기화는 다이얼로그가 닫힌 후에 진행하도록 변경
  }

  Future<void> _initializeApp() async {
    // Firebase 초기화
    await Firebase.initializeApp();

    // 권한 요청
    await _requestPermissions();

    // 잠시 대기 후 메인 페이지로 이동
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  Future<void> _requestPermissions() async {
    // 필요한 권한 목록
    List<Permission> permissions = [
      Permission.camera,
      Permission.location,
    ];

    // 권한 요청
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // 권한 상태 확인 (선택 사항)
    statuses.forEach((permission, status) {
      debugPrint("$permission: $status");
    });

    // 필요한 권한이 거부되었을 경우, 사용자에게 알림을 보여주는 로직을 추가할 수 있습니다.
    if (statuses[Permission.camera]!.isDenied ||
        statuses[Permission.location]!.isDenied) {
      // 권한이 거부되었을 때 처리 (예: 사용자에게 설정으로 이동하도록 안내)
      debugPrint("권한이 거부되었습니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image(
                  image: AssetImage('assets/logo.jpg'),
                  // width: 200,
                  // height: 200,
                  fit: BoxFit.cover,
                ),
                const Text(
                  '나의 흔적',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(),
              ],
            ),
          ),

          // 권한 안내 다이얼로그
          if (_showPermissionDialog)
            Container(
              color: Colors.black54, // 반투명 배경
              child: Center(
                child: AlertDialog(
                  title: const Text('권한 요청 안내'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('앱을 사용하기 위해서는 다음\n권한이 필요합니다.'),
                      SizedBox(height: 10),
                      Text('- 카메라: 사진 촬영 및 이미지 업로드'),
                      Text('- 위치: 현재 위치 정보 사용'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showPermissionDialog = false; // 다이얼로그 닫기
                        });
                        _initializeApp(); // 권한 요청 및 앱 초기화 진행
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

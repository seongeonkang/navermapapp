import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:navermapapp/main_page.dart'; // MainPage import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Your App Name', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

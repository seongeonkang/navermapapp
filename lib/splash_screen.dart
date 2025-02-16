// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:navermapapp/main_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showPermissionDialog = false; // 권한 안내 다이얼로그 표시 여부

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((allGranted) {
      if (allGranted) {
        _initializeApp(); // 모든 권한이 허용되었으면 앱 초기화
      } else {
        setState(() {
          _showPermissionDialog = true; // 권한이 필요하면 다이얼로그 표시
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    if (!_showPermissionDialog) {
      _navigateToMainPage();
    }
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
      setState(() {
        _showPermissionDialog = true; // 권한 거부 시 다이얼로그 다시 표시
      });
    } else {
      setState(() {
        _showPermissionDialog = false; // 모든 권한 허용 시 다이얼로그 숨김
      });
    }
  }

  void _navigateToMainPage() async {
    // 잠시 대기 후 메인 페이지로 이동
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  Future<bool> _checkPermissions() async {
    // 필요한 권한 목록
    List<Permission> permissions = [
      Permission.camera,
      Permission.location,
    ];

    bool allGranted = true;

    for (var permission in permissions) {
      final status = await permission.status;
      if (status != PermissionStatus.granted) {
        allGranted = false;
        break;
      }
    }
    return allGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.jpg',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
                const Text(
                  '나의 흔적',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.black, // 텍스트 색상 변경
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
                  content: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 300,
                      maxHeight: 150,
                    ),
                    child: Align(
                      // Align 위젯으로 감싸기
                      alignment: Alignment.topLeft, // 왼쪽 상단 정렬
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Column 내부 텍스트 왼쪽 정렬
                        children: [
                          Text('앱을 사용하기 위해서는 다음\n권한이 필요합니다.'),
                          SizedBox(height: 20),
                          Text('- 카메라: 사진 촬영 및 이미지 업로드'),
                          SizedBox(height: 10),
                          Text('- 위치: 현재 위치 정보 사용'),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        setState(() {
                          _showPermissionDialog = false; // 다이얼로그 닫기
                        });
                        await _requestPermissions(); // 권한 요청
                        _navigateToMainPage(); // 권한 획득 후 메인 페이지로 이동
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

  @override
  void dispose() {
    super.dispose();
  }
}

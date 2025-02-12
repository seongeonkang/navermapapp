import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:navermapapp/preview_page.dart';
import 'dart:math' as math; // math 라이브러리 임포트

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _cameraController!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewPage(imagePath: image.path),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('사진 촬영')),
//       body: FutureBuilder<void>(
//         future: _initializeControllerFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             // return CameraPreview(_cameraController!);

//             // return Transform.rotate(
//             //   angle: math.pi / 2, // 90도 회전 (반시계 방향)
//             //   child: Center(
//             //     child: AspectRatio(
//             //       aspectRatio: _cameraController!.value.aspectRatio,
//             //       child: CameraPreview(_cameraController!),
//             //     ),
//             //   ),
//             // );

//             // return Column(
//             //   // Column 또는 Row 위젯을 사용
//             //   children: [
//             //     Expanded(
//             //       child: Transform.rotate(
//             //         angle: math.pi / 2, // 필요에 따라 회전 각도 조정
//             //         child: AspectRatio(
//             //           aspectRatio: _cameraController!.value.aspectRatio,
//             //           child: CameraPreview(_cameraController!),
//             //         ),
//             //       ),
//             //     ),
//             //   ],
//             // );
//             return FittedBox(
//               fit: BoxFit.fill, // 이미지를 늘려 꽉 채움 (왜곡될 수 있음)
//               child: SizedBox(
//                 width: MediaQuery.of(context).size.width,
//                 height: MediaQuery.of(context).size.height,
//                 child: Transform.rotate(
//                   angle: math.pi / 2, // 필요에 따라 회전 각도 조정
//                   child: CameraPreview(_cameraController!),
//                 ),
//               ),
//             );
//           } else {
//             return const Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _takePicture,
//         child: const Icon(Icons.camera_alt),
//       ),
//     );
//   }
// }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('사진 촬영')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: screenHeight *
                      _cameraController!.value.aspectRatio, // 수정됨
                  height: screenHeight,
                  child: Transform.rotate(
                    angle: math.pi / 2,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

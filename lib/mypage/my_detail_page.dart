import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img; // image 패키지 추가

class MyDetailPage extends StatefulWidget {
  final Map<String, dynamic> photoData;

  const MyDetailPage({super.key, required this.photoData});

  @override
  State<MyDetailPage> createState() => _MyDetailPageState();
}

class _MyDetailPageState extends State<MyDetailPage> {
  @override
  Widget build(BuildContext context) {
    final double latitude = widget.photoData['latitude'];
    final double longitude = widget.photoData['longitude'];
    final String imageUrl = widget.photoData['imageUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세 정보'),
      ),
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 300,
            child: NaverMap(
              // client: NMapClientId(clientId: 'YOUR_NAVER_MAP_CLIENT_ID'),
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(latitude, longitude),
                  zoom: 16,
                ),
              ),
              onMapReady: (controller) {
                // controller.addOverlay(NMarker(
                //   id: 'markerId',
                //   position: NLatLng(latitude, longitude),
                //   icon: NOverlayImage.fromAssetImage(
                //       const AssetImage('assets/marker.png')
                //           as String), // 마커 이미지 에셋 경로
                // ));
                _addMarkerWithImage(controller, latitude, longitude, imageUrl);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('제목: ${widget.photoData['title']}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text('내용: ${widget.photoData['content']}',
                    style: const TextStyle(fontSize: 16)),
                Text('좌표: $latitude, $longitude',
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 썸네일 이미지를 마커에 표시하는 함수
  Future<void> _addMarkerWithImage(NaverMapController controller,
      double latitude, double longitude, String imageUrl) async {
    NMarker marker;
    try {
      // 1. 네트워크 이미지 다운로드
      final http.Response response = await http.get(Uri.parse(imageUrl));
      final Directory tempDir = await getTemporaryDirectory();
      final File imageFile = File('${tempDir.path}/marker_image.png');
      await imageFile.writeAsBytes(response.bodyBytes);

      // 2. 이미지 리사이즈
      final img.Image? originalImage =
          img.decodeImage(imageFile.readAsBytesSync());
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }
      final img.Image resizedImage =
          img.copyResize(originalImage, width: 80, height: 80); // 원하는 크기로 리사이즈

      // 3. 리사이즈된 이미지를 파일로 저장
      final File resizedImageFile =
          File('${tempDir.path}/resized_marker_image.png');
      resizedImageFile.writeAsBytesSync(img.encodePng(resizedImage));

      // 4. 리사이즈된 이미지로부터 NOverlayImage 생성
      final overlayImage = NOverlayImage.fromFile(resizedImageFile);

      // 5. NMarker 생성
      marker = NMarker(
        id: 'markerId',
        position: NLatLng(latitude, longitude),
        icon: overlayImage,
      );
    } catch (e) {
      debugPrint("Error loading image: $e");
      // 이미지 로딩 실패 시 기본 마커 표시
      marker = NMarker(
        id: 'markerId',
        position: NLatLng(latitude, longitude),
        // icon 속성을 설정하지 않으면 기본 마커 아이콘이 표시됩니다.
      );
    }
    controller.addOverlay(marker);
  }
}

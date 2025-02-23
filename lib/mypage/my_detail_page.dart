// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_naver_map/flutter_naver_map.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'package:image/image.dart' as img; // image 패키지 추가

// class MyDetailPage extends StatefulWidget {
//   final Map<String, dynamic> photoData;

//   const MyDetailPage({super.key, required this.photoData});

//   @override
//   State<MyDetailPage> createState() => _MyDetailPageState();
// }

// class _MyDetailPageState extends State<MyDetailPage> {
//   @override
//   Widget build(BuildContext context) {
//     final double latitude = widget.photoData['latitude'];
//     final double longitude = widget.photoData['longitude'];
//     final String imageUrl = widget.photoData['imageUrl'];

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('상세 정보'),
//       ),
//       body: Column(
//         children: [
//           SizedBox(
//             width: double.infinity,
//             height: 300,
//             child: NaverMap(
//               // client: NMapClientId(clientId: 'YOUR_NAVER_MAP_CLIENT_ID'),
//               options: NaverMapViewOptions(
//                 initialCameraPosition: NCameraPosition(
//                   target: NLatLng(latitude, longitude),
//                   zoom: 16,
//                 ),
//               ),
//               onMapReady: (controller) {
//                 // controller.addOverlay(NMarker(
//                 //   id: 'markerId',
//                 //   position: NLatLng(latitude, longitude),
//                 //   icon: NOverlayImage.fromAssetImage(
//                 //       const AssetImage('assets/marker.png')
//                 //           as String), // 마커 이미지 에셋 경로
//                 // ));
//                 _addMarkerWithImage(controller, latitude, longitude, imageUrl);
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('제목: ${widget.photoData['title']}',
//                     style: const TextStyle(
//                         fontSize: 18, fontWeight: FontWeight.bold)),
//                 Text('내용: ${widget.photoData['content']}',
//                     style: const TextStyle(fontSize: 16)),
//                 Text('좌표: $latitude, $longitude',
//                     style: const TextStyle(fontSize: 14)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 썸네일 이미지를 마커에 표시하는 함수
//   Future<void> _addMarkerWithImage(NaverMapController controller,
//       double latitude, double longitude, String imageUrl) async {
//     NMarker marker;
//     try {
//       // 1. 네트워크 이미지 다운로드
//       final http.Response response = await http.get(Uri.parse(imageUrl));
//       final Directory tempDir = await getTemporaryDirectory();
//       final File imageFile = File('${tempDir.path}/marker_image.png');
//       await imageFile.writeAsBytes(response.bodyBytes);

//       // 2. 이미지 리사이즈
//       final img.Image? originalImage =
//           img.decodeImage(imageFile.readAsBytesSync());
//       if (originalImage == null) {
//         throw Exception('Failed to decode image');
//       }
//       final img.Image resizedImage =
//           img.copyResize(originalImage, width: 80, height: 80); // 원하는 크기로 리사이즈

//       // 3. 리사이즈된 이미지를 파일로 저장
//       final File resizedImageFile =
//           File('${tempDir.path}/resized_marker_image.png');
//       resizedImageFile.writeAsBytesSync(img.encodePng(resizedImage));

//       // 4. 리사이즈된 이미지로부터 NOverlayImage 생성
//       final overlayImage = NOverlayImage.fromFile(resizedImageFile);

//       // 5. NMarker 생성
//       marker = NMarker(
//         id: 'markerId',
//         position: NLatLng(latitude, longitude),
//         icon: overlayImage,
//       );
//     } catch (e) {
//       debugPrint("Error loading image: $e");
//       // 이미지 로딩 실패 시 기본 마커 표시
//       marker = NMarker(
//         id: 'markerId',
//         position: NLatLng(latitude, longitude),
//         // icon 속성을 설정하지 않으면 기본 마커 아이콘이 표시됩니다.
//       );
//     }
//     controller.addOverlay(marker);
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage 패키지 추가

class MyDetailPage extends StatefulWidget {
  final Map<String, dynamic> photoData;

  const MyDetailPage({super.key, required this.photoData});

  @override
  State<MyDetailPage> createState() => _MyDetailPageState();
}

class _MyDetailPageState extends State<MyDetailPage> {
  late String documentId;
  List<String> detailImageUrls = []; // 상세 이미지 URL 목록

  @override
  void initState() {
    super.initState();
    documentId = widget.photoData['documentId'];
    _loadDetailImages();
  }

  // 상세 이미지 로드
  Future<void> _loadDetailImages() async {
    final CollectionReference detailCollection = FirebaseFirestore.instance
        .collection('photosdetail')
        .doc(documentId)
        .collection('images');

    final QuerySnapshot snapshot = await detailCollection.get();

    setState(() {
      detailImageUrls =
          snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
    });
  }

  // 갤러리에서 여러 이미지 선택
  Future<void> _pickMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    _uploadImagesToFirestore(images);
  }

  // Firestore에 이미지 업로드
  Future<void> _uploadImagesToFirestore(List<XFile> images) async {
    final CollectionReference detailCollection = FirebaseFirestore.instance
        .collection('photosdetail')
        .doc(documentId)
        .collection('images');

    for (XFile image in images) {
      // 이미지를 Firebase Storage에 업로드하고 URL을 얻는 로직 (예시)
      String imageUrl = await _uploadImageToStorage(image);

      // Firestore에 이미지 정보 저장
      await detailCollection.add({'imageUrl': imageUrl});
    }

    // 이미지 로드
    _loadDetailImages();
  }

  // Firebase Storage에 이미지 업로드
  Future<String> _uploadImageToStorage(XFile image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      File file = File(image.path);
      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return 'https://via.placeholder.com/150'; // 에러 발생 시 임시 URL 반환
    }
  }

  @override
  Widget build(BuildContext context) {
    final double latitude = widget.photoData['latitude'];
    final double longitude = widget.photoData['longitude'];
    final String imageUrl = widget.photoData['imageUrl'];
    final String documentId = widget.photoData['documentId']; // 문서 ID 가져오기

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세 정보'),
        backgroundColor: Colors.indigo, // AppBar 색상 변경
      ),
      body: SingleChildScrollView(
        // 스크롤 가능하도록 추가
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              height: 300,
              child: NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: NLatLng(latitude, longitude),
                    zoom: 16,
                  ),
                ),
                onMapReady: (controller) {
                  _addMarkerWithImage(
                      controller, latitude, longitude, imageUrl);
                },
              ),
            ),
            // 상세 이미지 슬라이더
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: detailImageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        detailImageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.error));
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('제목: ${widget.photoData['title']}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo)), // 제목 스타일 변경
                      const SizedBox(height: 8),
                      Text('내용: ${widget.photoData['content']}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('좌표: $latitude, $longitude',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('문서 ID: $documentId',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: '사진 추가',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share),
            label: '공유하기',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            _pickMultipleImages();
          } else if (index == 1) {
            // TODO: 공유 기능 구현
          }
        },
      ),
    );
  }

  // 썸네일 이미지를 마커에 표시하는 함수
  // Future<void> _addMarkerWithImage(NaverMapController controller,
  //     double latitude, double longitude, String imageUrl) async {
  //   NMarker marker;
  //   File? resizedImageFile; // finally 블록에서 접근하기 위해 nullable로 선언

  //   try {
  //     // 1. 네트워크 이미지 다운로드
  //     final http.Response response = await http
  //         .get(Uri.parse(imageUrl))
  //         .timeout(const Duration(seconds: 10)); // 타임아웃 설정
  //     if (response.statusCode != 200) {
  //       throw Exception('Failed to load image: HTTP ${response.statusCode}');
  //     }
  //     final Directory tempDir = await getTemporaryDirectory();
  //     final File imageFile = File('${tempDir.path}/marker_image.png');
  //     await imageFile.writeAsBytes(response.bodyBytes);

  //     // 2. 이미지 리사이즈
  //     final img.Image? originalImage =
  //         img.decodeImage(imageFile.readAsBytesSync());
  //     if (originalImage == null) {
  //       throw Exception('Failed to decode image');
  //     }
  //     final img.Image resizedImage =
  //         img.copyResize(originalImage, width: 80, height: 80); // 원하는 크기로 리사이즈

  //     // 3. 리사이즈된 이미지를 파일로 저장
  //     resizedImageFile = File('${tempDir.path}/resized_marker_image.png');
  //     resizedImageFile.writeAsBytesSync(img.encodePng(resizedImage));

  //     // 4. 리사이즈된 이미지로부터 NOverlayImage 생성
  //     final overlayImage = NOverlayImage.fromFile(resizedImageFile);

  //     // 5. NMarker 생성
  //     marker = NMarker(
  //       id: 'markerId',
  //       position: NLatLng(latitude, longitude),
  //       icon: overlayImage,
  //     );
  //   } catch (e) {
  //     debugPrint("Error loading image: $e");
  //     // 이미지 로딩 실패 시 기본 마커 표시
  //     marker = NMarker(
  //       id: 'markerId',
  //       position: NLatLng(latitude, longitude),
  //       // icon 속성을 설정하지 않으면 기본 마커 아이콘이 표시됩니다.
  //     );
  //   } finally {
  //     // 임시 파일 삭제
  //     if (resizedImageFile != null && resizedImageFile.existsSync()) {
  //       resizedImageFile.deleteSync();
  //     }
  //   }
  //   controller.addOverlay(marker);
  // }

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

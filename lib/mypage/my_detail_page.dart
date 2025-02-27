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

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_naver_map/flutter_naver_map.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'package:image/image.dart' as img;
// import 'package:image_picker/image_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage 패키지 추가

// class MyDetailPage extends StatefulWidget {
//   final Map<String, dynamic> photoData;

//   const MyDetailPage({super.key, required this.photoData});

//   @override
//   State<MyDetailPage> createState() => _MyDetailPageState();
// }

// class _MyDetailPageState extends State<MyDetailPage> {
//   late String documentId;
//   List<String> detailImageUrls = []; // 상세 이미지 URL 목록

//   @override
//   void initState() {
//     super.initState();
//     documentId = widget.photoData['documentId'];
//     _loadDetailImages();
//   }

//   // 상세 이미지 로드
//   Future<void> _loadDetailImages() async {
//     final CollectionReference detailCollection = FirebaseFirestore.instance
//         .collection('photosdetail')
//         .doc(documentId)
//         .collection('images');

//     final QuerySnapshot snapshot = await detailCollection.get();

//     setState(() {
//       detailImageUrls =
//           snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
//     });
//   }

//   // 갤러리에서 여러 이미지 선택
//   Future<void> _pickMultipleImages() async {
//     final ImagePicker picker = ImagePicker();
//     final List<XFile> images = await picker.pickMultiImage();

//     _uploadImagesToFirestore(images);
//   }

//   // Firestore에 이미지 업로드
//   Future<void> _uploadImagesToFirestore(List<XFile> images) async {
//     final CollectionReference detailCollection = FirebaseFirestore.instance
//         .collection('photosdetail')
//         .doc(documentId)
//         .collection('images');

//     for (XFile image in images) {
//       // 이미지를 Firebase Storage에 업로드하고 URL을 얻는 로직 (예시)
//       String imageUrl = await _uploadImageToStorage(image);

//       // Firestore에 이미지 정보 저장
//       await detailCollection.add({'imageUrl': imageUrl});
//     }

//     // 이미지 로드
//     _loadDetailImages();
//   }

//   // Firebase Storage에 이미지 업로드
//   Future<String> _uploadImageToStorage(XFile image) async {
//     try {
//       final storageRef = FirebaseStorage.instance
//           .ref()
//           .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//       File file = File(image.path);
//       await storageRef.putFile(file);
//       return await storageRef.getDownloadURL();
//     } catch (e) {
//       print('Error uploading image: $e');
//       return 'https://via.placeholder.com/150'; // 에러 발생 시 임시 URL 반환
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double latitude = widget.photoData['latitude'];
//     final double longitude = widget.photoData['longitude'];
//     final String imageUrl = widget.photoData['imageUrl'];
//     final String documentId = widget.photoData['documentId']; // 문서 ID 가져오기

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('상세 정보'),
//         backgroundColor: Theme.of(context).primaryColor, // AppBar 색상 변경
//       ),
//       body: SingleChildScrollView(
//         // 스크롤 가능하도록 추가
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             SizedBox(
//               width: double.infinity,
//               height: 300,
//               child: NaverMap(
//                 options: NaverMapViewOptions(
//                   initialCameraPosition: NCameraPosition(
//                     target: NLatLng(latitude, longitude),
//                     zoom: 16,
//                   ),
//                 ),
//                 onMapReady: (controller) {
//                   _addMarkerWithImage(
//                       controller, latitude, longitude, imageUrl);
//                 },
//               ),
//             ),
//             // 상세 이미지 슬라이더
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 10),
//               height: 250,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: detailImageUrls.length,
//                 itemBuilder: (context, index) {
//                   return Container(
//                     width: 250,
//                     margin: const EdgeInsets.symmetric(horizontal: 5),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.3),
//                           spreadRadius: 1,
//                           blurRadius: 3,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: Image.network(
//                         detailImageUrls[index],
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return const Center(child: Icon(Icons.error));
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('제목: ${widget.photoData['title']}',
//                           style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.indigo)), // 제목 스타일 변경
//                       const SizedBox(height: 8),
//                       Text('내용: ${widget.photoData['content']}',
//                           style: const TextStyle(fontSize: 16)),
//                       const SizedBox(height: 8),
//                       Text('좌표: $latitude, $longitude',
//                           style: const TextStyle(
//                               fontSize: 14, color: Colors.grey)),
//                       const SizedBox(height: 8),
//                       Text('문서 ID: $documentId',
//                           style: const TextStyle(
//                               fontSize: 14, color: Colors.grey)),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: Colors.white,
//         selectedItemColor: Colors.indigo,
//         unselectedItemColor: Colors.grey,
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add_a_photo),
//             label: '사진 추가',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.share),
//             label: '공유하기',
//           ),
//         ],
//         onTap: (index) {
//           if (index == 0) {
//             _pickMultipleImages();
//           } else if (index == 1) {
//             // TODO: 공유 기능 구현
//           }
//         },
//       ),
//     );
//   }

//   // 썸네일 이미지를 마커에 표시하는 함수
//   // Future<void> _addMarkerWithImage(NaverMapController controller,
//   //     double latitude, double longitude, String imageUrl) async {
//   //   NMarker marker;
//   //   File? resizedImageFile; // finally 블록에서 접근하기 위해 nullable로 선언

//   //   try {
//   //     // 1. 네트워크 이미지 다운로드
//   //     final http.Response response = await http
//   //         .get(Uri.parse(imageUrl))
//   //         .timeout(const Duration(seconds: 10)); // 타임아웃 설정
//   //     if (response.statusCode != 200) {
//   //       throw Exception('Failed to load image: HTTP ${response.statusCode}');
//   //     }
//   //     final Directory tempDir = await getTemporaryDirectory();
//   //     final File imageFile = File('${tempDir.path}/marker_image.png');
//   //     await imageFile.writeAsBytes(response.bodyBytes);

//   //     // 2. 이미지 리사이즈
//   //     final img.Image? originalImage =
//   //         img.decodeImage(imageFile.readAsBytesSync());
//   //     if (originalImage == null) {
//   //       throw Exception('Failed to decode image');
//   //     }
//   //     final img.Image resizedImage =
//   //         img.copyResize(originalImage, width: 80, height: 80); // 원하는 크기로 리사이즈

//   //     // 3. 리사이즈된 이미지를 파일로 저장
//   //     resizedImageFile = File('${tempDir.path}/resized_marker_image.png');
//   //     resizedImageFile.writeAsBytesSync(img.encodePng(resizedImage));

//   //     // 4. 리사이즈된 이미지로부터 NOverlayImage 생성
//   //     final overlayImage = NOverlayImage.fromFile(resizedImageFile);

//   //     // 5. NMarker 생성
//   //     marker = NMarker(
//   //       id: 'markerId',
//   //       position: NLatLng(latitude, longitude),
//   //       icon: overlayImage,
//   //     );
//   //   } catch (e) {
//   //     debugPrint("Error loading image: $e");
//   //     // 이미지 로딩 실패 시 기본 마커 표시
//   //     marker = NMarker(
//   //       id: 'markerId',
//   //       position: NLatLng(latitude, longitude),
//   //       // icon 속성을 설정하지 않으면 기본 마커 아이콘이 표시됩니다.
//   //     );
//   //   } finally {
//   //     // 임시 파일 삭제
//   //     if (resizedImageFile != null && resizedImageFile.existsSync()) {
//   //       resizedImageFile.deleteSync();
//   //     }
//   //   }
//   //   controller.addOverlay(marker);
//   // }

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
import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class MyDetailPage extends StatefulWidget {
  final Map<String, dynamic> photoData;
  final VoidCallback? onDelete; // onDelete 콜백 추가

  const MyDetailPage({super.key, required this.photoData, this.onDelete});

  @override
  State<MyDetailPage> createState() => _MyDetailPageState();
}

class _MyDetailPageState extends State<MyDetailPage> {
  late String documentId;
  List<String> detailImageUrls = [];
  bool _isLoading = false;
  late PageController _pageController;
  bool _isDeleting = false; // 삭제 중 여부

  @override
  void initState() {
    super.initState();
    documentId = widget.photoData['documentId'];
    _loadDetailImages();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDetailImages() async {
    setState(() {
      _isLoading = true;
    });

    final CollectionReference detailCollection = FirebaseFirestore.instance
        .collection('photosdetail')
        .doc(documentId)
        .collection('images');

    try {
      final QuerySnapshot snapshot = await detailCollection.get();

      setState(() {
        detailImageUrls =
            snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading images: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 로딩 실패')),
      );
    }
  }

  Future<void> _pickMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    _uploadImagesToFirestore(images);
  }

  Future<void> _uploadImagesToFirestore(List<XFile> images) async {
    setState(() {
      _isLoading = true;
    });

    final CollectionReference detailCollection = FirebaseFirestore.instance
        .collection('photosdetail')
        .doc(documentId)
        .collection('images');

    try {
      for (XFile image in images) {
        String imageUrl = await _uploadImageToStorage(image);
        await detailCollection.add({'imageUrl': imageUrl});
      }
      await _loadDetailImages();
    } catch (e) {
      debugPrint('Error uploading images: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드 실패')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _uploadImageToStorage(XFile image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      File file = File(image.path);
      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return 'https://via.placeholder.com/150';
    }
  }

  Future<void> _deleteImage(
      String imageUrl, int index, StateSetter setPopupState) async {
    try {
      final CollectionReference detailCollection = FirebaseFirestore.instance
          .collection('photosdetail')
          .doc(documentId)
          .collection('images');

      QuerySnapshot querySnapshot =
          await detailCollection.where('imageUrl', isEqualTo: imageUrl).get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await detailCollection.doc(doc.id).delete();
      }

      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();

      setState(() {
        detailImageUrls.removeAt(index); // 메인 리스트에서 이미지 삭제
      });

      setPopupState(() {
        // 팝업 상태 업데이트
        if (detailImageUrls.isNotEmpty) {
          _pageController = PageController(initialPage: 0);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 삭제 완료')),
      );
    } catch (e) {
      debugPrint('Error deleting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 삭제 실패')),
      );
    }
  }

  void _showImagePopup(BuildContext context, int index) {
    _pageController = PageController(initialPage: index); // PageController 초기화

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setPopupState) {
            return Dialog(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    PhotoViewGallery.builder(
                      itemCount: detailImageUrls.length,
                      builder: (context, photoViewIndex) {
                        return PhotoViewGalleryPageOptions(
                          imageProvider:
                              NetworkImage(detailImageUrls[photoViewIndex]),
                          initialScale: PhotoViewComputedScale.contained * 0.8,
                          minScale: PhotoViewComputedScale.contained * 0.8,
                          maxScale: PhotoViewComputedScale.covered * 2,
                        );
                      },
                      scrollPhysics: const BouncingScrollPhysics(),
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.black,
                      ),
                      pageController: _pageController,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('이미지 삭제'),
                                content: const Text('정말로 이미지를 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final int currentPageIndex =
                                          _pageController.page!.round();
                                      final String imageUrlToDelete =
                                          detailImageUrls[currentPageIndex];
                                      _deleteImage(imageUrlToDelete,
                                          currentPageIndex, setPopupState);
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('삭제'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAllData() async {
    if (_isDeleting) return; // 이미 삭제 중이면 중복 실행 방지

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('전체 데이터 삭제'),
          content: const Text('정말로 모든 데이터를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // 다이얼로그 닫기

                setState(() {
                  _isDeleting = true; // 삭제 시작
                });

                try {
                  // 1. 상세 이미지 삭제
                  final CollectionReference detailCollection = FirebaseFirestore
                      .instance
                      .collection('photosdetail')
                      .doc(documentId)
                      .collection('images');

                  final QuerySnapshot detailSnapshot =
                      await detailCollection.get();

                  for (QueryDocumentSnapshot doc in detailSnapshot.docs) {
                    try {
                      // Storage에서 이미지 삭제
                      Reference storageRef = FirebaseStorage.instance
                          .refFromURL(doc['imageUrl'] as String);
                      await storageRef.delete();

                      // Firestore 문서 삭제
                      await detailCollection.doc(doc.id).delete();
                    } catch (e) {
                      debugPrint('Error deleting detail image: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('상세 이미지 삭제 실패')),
                      );
                    }
                  }

                  // 2. 메인 이미지 삭제
                  try {
                    // Storage에서 이미지 삭제
                    Reference mainStorageRef = FirebaseStorage.instance
                        .refFromURL(widget.photoData['imageUrl'] as String);
                    await mainStorageRef.delete();

                    // Firestore 문서 삭제
                    await FirebaseFirestore.instance
                        .collection('photos')
                        .doc(documentId)
                        .delete();

                    // 삭제 후 콜백 호출
                    if (widget.onDelete != null) {
                      widget.onDelete!();
                    }

                    //Navigator.pop(context); // MyDetailPage 닫기

                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text('전체 데이터 삭제 완료')),
                    // );
                  } catch (e) {
                    debugPrint('Error deleting main image: $e');
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text('메인 이미지 삭제 실패')),
                    // );
                  }
                } finally {
                  setState(() {
                    _isDeleting = false; // 삭제 종료
                  });
                  // if (mounted) {
                  //   Navigator.pop(context);
                  // }
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double latitude = widget.photoData['latitude'];
    final double longitude = widget.photoData['longitude'];
    final String imageUrl = widget.photoData['imageUrl'];
    final String documentId = widget.photoData['documentId'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세 정보'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
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
            if (detailImageUrls.isNotEmpty || _isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                height: 250,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : detailImageUrls.isEmpty
                        ? const Center(child: Text('데이터가 없습니다.'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: detailImageUrls.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _showImagePopup(context, index),
                                child: Container(
                                  width: 250,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 5),
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
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                            child: Icon(Icons.error));
                                      },
                                    ),
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
                              color: Colors.indigo)),
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
            icon: Icon(Icons.delete, color: Colors.red),
            label: '전체 삭제',
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
            _deleteAllData();
          } else if (index == 2) {
            // TODO: 공유 기능 구현
          }
        },
      ),
    );
  }

  Future<void> _addMarkerWithImage(NaverMapController controller,
      double latitude, double longitude, String imageUrl) async {
    NMarker marker;
    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));
      final Directory tempDir = await getTemporaryDirectory();
      final File imageFile = File('${tempDir.path}/marker_image.png');
      await imageFile.writeAsBytes(response.bodyBytes);

      final img.Image? originalImage =
          img.decodeImage(imageFile.readAsBytesSync());
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }
      final img.Image resizedImage =
          img.copyResize(originalImage, width: 80, height: 80);

      final File resizedImageFile =
          File('${tempDir.path}/resized_marker_image.png');
      resizedImageFile.writeAsBytesSync(img.encodePng(resizedImage));

      final overlayImage = NOverlayImage.fromFile(resizedImageFile);

      marker = NMarker(
        id: 'markerId',
        position: NLatLng(latitude, longitude),
        icon: overlayImage,
      );
    } catch (e) {
      debugPrint("Error loading image: $e");
      marker = NMarker(
        id: 'markerId',
        position: NLatLng(latitude, longitude),
      );
    }
    controller.addOverlay(marker);
  }
}

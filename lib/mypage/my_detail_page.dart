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
  final VoidCallback? onDelete;
  final bool showBottomTabBar;

  const MyDetailPage({
    super.key,
    required this.photoData,
    this.onDelete,
    this.showBottomTabBar = true,
  });

  @override
  State<MyDetailPage> createState() => _MyDetailPageState();
}

class _MyDetailPageState extends State<MyDetailPage> {
  late String documentId;
  List<String> detailImageUrls = [];
  bool _isLoading = false;
  late PageController _pageController;
  bool _isDeleting = false;
  bool _isFollowing = false;

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
        detailImageUrls.removeAt(index);
      });

      setPopupState(() {
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
    _pageController = PageController(initialPage: index);

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
    if (_isDeleting) return;

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
                Navigator.of(context).pop();

                setState(() {
                  _isDeleting = true;
                });

                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text("데이터 삭제 중..."),
                          ],
                        ),
                      );
                    },
                  );

                  final CollectionReference detailCollection = FirebaseFirestore
                      .instance
                      .collection('photosdetail')
                      .doc(documentId)
                      .collection('images');

                  final QuerySnapshot detailSnapshot =
                      await detailCollection.get();

                  for (QueryDocumentSnapshot doc in detailSnapshot.docs) {
                    try {
                      Reference storageRef = FirebaseStorage.instance
                          .refFromURL(doc['imageUrl'] as String);
                      await storageRef.delete();

                      await detailCollection.doc(doc.id).delete();
                    } catch (e) {
                      debugPrint('Error deleting detail image: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('상세 이미지 삭제 중 오류 발생')),
                      );
                    }
                  }

                  try {
                    Reference mainStorageRef = FirebaseStorage.instance
                        .refFromURL(widget.photoData['imageUrl'] as String);
                    await mainStorageRef.delete();

                    await FirebaseFirestore.instance
                        .collection('photos')
                        .doc(documentId)
                        .delete();

                    if (widget.onDelete != null) {
                      widget.onDelete!();
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('전체 데이터 삭제 완료')),
                    );
                  } catch (e) {
                    debugPrint('Error deleting main image: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('메인 이미지 삭제 중 오류 발생')),
                    );
                  }
                } catch (e) {
                  debugPrint('Error deleting data: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('데이터 삭제 중 오류 발생')),
                  );
                } finally {
                  setState(() {
                    _isDeleting = false;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  void _showShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '공유 및 해제',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Divider(
                height: 1,
                color: Colors.grey,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _updateShareYn('Y');
                          Navigator.pop(context);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.share, color: Colors.indigo, size: 30),
                            const SizedBox(height: 8),
                            const Text(
                              '공유',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _updateShareYn('N');
                          Navigator.pop(context);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.lock, color: Colors.grey, size: 30),
                            const SizedBox(height: 8),
                            const Text(
                              '해제',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateShareYn(String shareYn) async {
    try {
      String message = shareYn == 'Y' ? '흔적공유에 공유되었습니다.' : '흔적공유에 해제되었습니다.';

      await FirebaseFirestore.instance
          .collection('photos')
          .doc(documentId)
          .update({'shareYn': shareYn});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      debugPrint('Error updating shareYn: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유 상태 변경 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double latitude = widget.photoData['latitude'];
    final double longitude = widget.photoData['longitude'];
    final String imageUrl = widget.photoData['imageUrl'];
    final String documentId = widget.photoData['documentId'];
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세 정보'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          // showBottomTabBar가 true일 때는 팔로우 아이콘을 숨김
          if (!widget.showBottomTabBar)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isFollowing = !_isFollowing;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(_isFollowing ? '팔로우했습니다.' : '팔로우를 취소했습니다.')),
                  );
                },
                child: Icon(
                  _isFollowing ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: screenWidth,
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (BuildContext context, Object error,
                      StackTrace? stackTrace) {
                    return const Center(child: Icon(Icons.error));
                  },
                ),
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
            SizedBox(
              width: double.infinity,
              height: 200,
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
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomTabBar
          ? BottomNavigationBar(
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
                  _showShareBottomSheet(context);
                }
              },
            )
          : null,
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

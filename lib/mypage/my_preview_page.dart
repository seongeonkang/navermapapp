import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class MyPreviewPage extends StatefulWidget {
  final File image;
  const MyPreviewPage({super.key, required this.image});

  @override
  State<MyPreviewPage> createState() => _MyPreviewPageState();
}

class _MyPreviewPageState extends State<MyPreviewPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  Position? _currentPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // 권한 거부 처리
        debugPrint("위치 권한이 거부되었습니다.");
        setState(() {
          _isLoading = false;
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
        // LocationSettings 사용
        accuracy: LocationAccuracy.high, // 정확도 설정
        distanceFilter: 10, // 최소 이동 거리 (미터)
      ));
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImageAndSaveData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String fileName = path.basename(widget.image.path);
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child('uploads/$fileName');
      UploadTask uploadTask = firebaseStorageRef.putFile(widget.image);

      await uploadTask.whenComplete(() => null);

      String imageUrl = await firebaseStorageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('photos').add({
        'imageUrl': imageUrl,
        'title': _titleController.text,
        'content': _contentController.text,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // PreviewPage 닫기
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('미리보기 및 정보 입력')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Image.file(widget.image),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '제목',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '내용',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(_currentPosition == null
                        ? '위치 정보를 가져오는 중...'
                        : '위치: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}'),
                    ElevatedButton(
                      onPressed: _uploadImageAndSaveData,
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

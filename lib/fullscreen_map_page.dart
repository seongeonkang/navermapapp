import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:location/location.dart' as loc;
import 'package:url_launcher/url_launcher.dart';

class FullScreenMapPage extends StatefulWidget {
  final NLatLng initialLocation;
  final String address;
  final String title;

  const FullScreenMapPage({
    super.key,
    required this.initialLocation,
    required this.address,
    required this.title,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  NaverMapController? mapController;
  loc.LocationData? _currentLocation;
  NMarker? _currentLocationMarker;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    try {
      loc.Location location = loc.Location();
      loc.LocationData currentLocation = await location.getLocation();
      setState(() => _currentLocation = currentLocation);

      if (mapController != null) {
        _addCurrentLocationMarker();
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<NOverlayImage> createCustomMarkerIcon(Color color) async {
    return await NOverlayImage.fromWidget(
      widget: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child:
            const Icon(Icons.person_pin_circle, color: Colors.white, size: 26),
      ),
      size: const Size(32, 32),
      context: context,
    );
  }

  Future<void> _addCurrentLocationMarker() async {
    if (_currentLocation == null || mapController == null) return;

    final customIcon = await createCustomMarkerIcon(Colors.red);
    _currentLocationMarker = NMarker(
      id: "current_location",
      position:
          NLatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
      icon: customIcon,
    );
    mapController?.addOverlay(_currentLocationMarker!);
  }

  Future<void> moveMapToCurrentLocation() async {
    if (_currentLocation == null || mapController == null) return;

    await mapController!.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target:
            NLatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        zoom: 15,
      ),
    );
    _addCurrentLocationMarker();
  }

  Future<void> launchNaverMapNavigation() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 위치를 가져올 수 없습니다.')),
      );
      return;
    }

    final String appName = 'kr.co.skysofts.navermapapp'; // 실제 앱 패키지 이름으로 변경

    // 출발지: 현재 위치
    final double slat = _currentLocation!.latitude!;
    final double slng = _currentLocation!.longitude!;
    final String sname = '내 위치'; // 사용자에게 표시될 출발지 이름

    // 목적지: 위젯에서 전달받은 위치
    final double dlat = widget.initialLocation.latitude;
    final double dlng = widget.initialLocation.longitude;
    final String dname = widget.title;

    final String naverMapUrl = Platform.isAndroid
        ? 'nmap://route/public?slat=$slat&slng=$slng&sname=${Uri.encodeComponent(sname)}&dlat=$dlat&dlng=$dlng&dname=${Uri.encodeComponent(dname)}&appname=$appName'
        : 'nmap://route/public?slat=$slat&slng=$slng&sname=${Uri.encodeComponent(sname)}&dlat=$dlat&dlng=$dlng&dname=${Uri.encodeComponent(dname)}';

    final Uri url = Uri.parse(naverMapUrl);

    try {
      bool launched = await launchUrl(url);
      if (!launched) {
        // 네이버 지도가 열리지 않은 경우
        _launchNaverMapInAppStore();
      }
    } catch (e) {
      // URL 실행 중 오류 발생
      debugPrint('Error launching Naver Map: $e');
      _launchNaverMapInAppStore();
    }
  }

  void _launchNaverMapInAppStore() async {
    // 네이버 지도가 설치되어 있지 않은 경우, 앱스토어/플레이스토어로 연결
    final String appStoreUrl = Platform.isAndroid
        ? 'market://details?id=com.nhn.android.nmap' // Android 플레이스토어
        : 'https://apps.apple.com/kr/app/%EB%84%A4%EC%9D%B4%EB%B2%84-%EC%A7%80%EB%8F%84-%EB% 내 앱 스토어 id'; // iOS 앱스토어
    final Uri appStoreUri = Uri.parse(appStoreUrl);
    if (await canLaunchUrl(appStoreUri)) {
      await launchUrl(appStoreUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네이버 지도 앱을 열 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: widget.initialLocation,
                zoom: 16,
              ),
            ),
            onMapReady: (controller) async {
              mapController = controller;
              controller.addOverlay(NMarker(
                id: 'destinationMarker',
                position: widget.initialLocation,
              ));
              if (_currentLocation != null) {
                _addCurrentLocationMarker();
              }
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'movemap',
                  onPressed: moveMapToCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'navermapnavigation',
                  onPressed: launchNaverMapNavigation,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.directions),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

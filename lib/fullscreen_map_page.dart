// fullscreen_map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:location/location.dart' as loc;

class FullScreenMapPage extends StatefulWidget {
  final NLatLng initialLocation;
  final String address; // 주소 추가
  final String title; // 주소 추가

  const FullScreenMapPage(
      {super.key,
      required this.initialLocation,
      required this.address,
      required this.title});

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
    getCurrentLocation().then((location) {
      setState(() {
        _currentLocation = location;

        _currentLocationMarker = NMarker(
          id: "current_location",
          position: NLatLng(
              _currentLocation!.latitude!, _currentLocation!.longitude!),
          iconTintColor: Colors.blue,
        );
        mapController!.addOverlay(_currentLocationMarker!);
      });
    });
  }

  Future<loc.LocationData?> getCurrentLocation() async {
    try {
      loc.Location location = loc.Location();
      return await location.getLocation();
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  Future<void> moveMapToCurrentLocation() async {
    if (mapController == null || _currentLocation == null) return;

    await mapController!.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target:
            NLatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        zoom: 15,
      ),
    );

    setState(() {
      _currentLocationMarker = NMarker(
        id: "current_location",
        position:
            NLatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        iconTintColor: Colors.blue,
      );
      mapController!.addOverlay(_currentLocationMarker!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true, // AppBar 제목 중앙 정렬
      ),
      body: Stack(
        children: [
          // NaverMap(
          //   options: NaverMapViewOptions(
          //     initialCameraPosition: NCameraPosition(
          //       target: widget.initialLocation,
          //       zoom: 16,
          //     ),
          //   ),
          //   onMapReady: (controller) {
          //     mapController = controller;
          //     controller.addOverlay(NMarker(
          //       id: 'markerId',
          //       position: widget.initialLocation,
          //     ));
          //   },
          // ),
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: widget.initialLocation,
                zoom: 16,
              ),
            ),
            onMapReady: (controller) {
              mapController = controller;

              // 목적지 마커 추가
              controller.addOverlay(NMarker(
                id: 'destinationMarker',
                position: widget.initialLocation,
              ));

              // 내 위치 마커 추가 (위치가 있으면)
              if (_currentLocation != null) {
                controller.addOverlay(NMarker(
                  id: 'myLocationMarker',
                  position: NLatLng(_currentLocation!.latitude!,
                      _currentLocation!.longitude!),
                  iconTintColor: Colors.blue, // 내 위치 마커 색상
                ));
              }
            },
          ),
          Positioned(
            // 주소 표시 영역
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.8), // 반투명 배경
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.address, // 주소 표시
                style: TextStyle(
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
            child: FloatingActionButton(
              onPressed: () {
                if (_currentLocation != null) {
                  moveMapToCurrentLocation();
                }
              },
              child: Icon(Icons.my_location),
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

import 'package:flutter/material.dart';
import 'package:navermapapp/api_service.dart'; // API 서비스 관련 파일
import 'package:navermapapp/fullscreen_map_page.dart'; // 전체 화면 지도 페이지 관련 파일
import 'package:navermapapp/location_based_list_data.dart'; // 위치 기반 데이터 모델 관련 파일
import 'package:navermapapp/provider.dart'; // Provider 패턴 관련 파일
import 'package:provider/provider.dart'; // Provider 패키지
import 'package:flutter_naver_map/flutter_naver_map.dart'; // 네이버 지도 관련 파일
import 'package:share_plus/share_plus.dart'; // 공유 기능 제공 패키지
import 'package:proj4dart/proj4dart.dart'; // proj4dart 패키지 추가

class DetailPage extends StatefulWidget {
  // 상세 정보 페이지 StatefulWidget
  final Map<String, dynamic> itemData; // 상세 정보를 담은 데이터

  const DetailPage({super.key, required this.itemData}); // 생성자

  @override
  State<DetailPage> createState() => _DetailPageState(); // State 생성
}

class _DetailPageState extends State<DetailPage> {
  String title = '상세 정보'; // 페이지 제목 (초기값 설정)
  LocationBasedListData? detaillistData; // 상세 정보 데이터
  List<dynamic> imgListData = []; // 이미지 목록 데이터
  bool isLoading = false; // 로딩 상태
  String? selectedImageUrl; // 선택된 이미지 URL
  NLatLng? _location; // 지도 위치 정보
  NLatLng? _sharelocation; // 공유지도 위치 정보

  // 네이버 API 클라이언트 ID 및 시크릿 (반드시 안전하게 관리해야 함)

  @override
  void initState() {
    // 위젯 초기화
    super.initState();
    fetchListData(); // 데이터 가져오기
    fetchimgListData(); // 이미지 목록 데이터 가져오기

    // 초기 이미지 URL 설정
    selectedImageUrl = widget.itemData['firstimage'] ?? "";
    // 위젯이 처음 생성될 때 제목 초기화
    title = widget.itemData['title'] ?? '상세 정보';
  }

  Future<void> fetchListData() async {
    // 상세 정보 데이터 가져오는 함수
    setState(() {
      isLoading = true; // 로딩 시작
    });
    try {
      final params = {
        // API 요청 파라미터
        'contentTypeId': widget.itemData['contenttypeid'].toString(),
        'contentId': widget.itemData['contentid'].toString(),
        'MobileOS': 'AND',
        'MobileApp': 'navermapapp',
        'defaultYN': 'Y',
        'firstImageYN': 'Y',
        'areacodeYN': 'Y',
        'catcodeYN': 'Y',
        'addrinfoYN': 'Y',
        'mapinfoYN': 'Y',
        'overviewYN': 'Y'
      };

      final serviceKeyProvider =
          Provider.of<ServiceKeyProvider>(context, listen: false); // 서비스 키 가져오기
      final serviceKey = serviceKeyProvider.getServiceKey();

      final data = await ApiService.fetchData<LocationBasedListData>(
        // API 호출
        path: 'detailCommon1',
        serviceKey: serviceKey,
        params: params,
        responseModel: LocationBasedListData(),
        responseType: 'xml',
        itemsElement: 'item',
      );

      setState(() {
        // 상태 업데이트
        detaillistData = data;

        _location = NLatLng(
          // 지도 위치 정보 설정
          double.parse(detaillistData!.data[0]['mapy'] ?? '0'),
          double.parse(detaillistData!.data[0]['mapx'] ?? '0'),
        );

        // WGS84 (EPSG:4326) 좌표를 EPSG:3857로 변환
        if (detaillistData != null && detaillistData!.data.isNotEmpty) {
          try {
            final wgs84Y = double.parse(detaillistData!.data[0]['mapy'] ?? '0');
            final wgs84X = double.parse(detaillistData!.data[0]['mapx'] ?? '0');

            // 좌표계 정의
            final wgs84 = Projection.get('EPSG:4326')!;
            final mercator = Projection.get('EPSG:3857')!;

            // 좌표 변환
            final Point wgs84Point = Point(x: wgs84X, y: wgs84Y);
            final Point mercatorPoint = wgs84.transform(mercator, wgs84Point);

            // 변환된 좌표 저장
            _sharelocation = NLatLng(
              mercatorPoint.y, // 변환된 y 좌표 (위도)
              mercatorPoint.x, // 변환된 x 좌표 (경도)
            );

            debugPrint('WGS84: $wgs84X, $wgs84Y'); // WGS84 좌표 출력
            debugPrint(
                'EPSG:3857: ${mercatorPoint.x}, ${mercatorPoint.y}'); // EPSG:3857 좌표 출력
          } catch (e) {
            debugPrint('좌표 변환 오류: $e');
            _sharelocation = null; // 변환 실패 시 _location을 null로 설정
          }
        } else {
          _sharelocation = null;
        }
      });
    } catch (e) {
      debugPrint('Failed to fetch location based list data: $e'); // 오류 처리
    } finally {
      setState(() {
        isLoading = false; // 로딩 종료
      });
    }
  }

  Future<void> fetchimgListData() async {
    // 이미지 목록 데이터 가져오는 함수
    setState(() {
      isLoading = true; // 로딩 시작
    });
    try {
      final params = {
        // API 요청 파라미터
        'contentId': widget.itemData['contentid'].toString(),
        'MobileOS': 'AND',
        'MobileApp': 'navermapapp',
        'imageYN': 'Y',
        'subImageYN': 'Y',
        'numOfRows': '20',
      };

      final serviceKeyProvider =
          Provider.of<ServiceKeyProvider>(context, listen: false); // 서비스 키 가져오기
      final serviceKey = serviceKeyProvider.getServiceKey();

      final imgdata = await ApiService.fetchData<LocationBasedListData>(
        // API 호출
        path: 'detailImage1',
        serviceKey: serviceKey,
        params: params,
        responseModel: LocationBasedListData(),
        responseType: 'xml',
        itemsElement: 'item',
      );

      setState(() {
        // 상태 업데이트
        imgListData = imgdata.data ?? [];
      });
    } catch (e) {
      debugPrint('Failed to fetch location based list data: $e'); // 오류 처리
    } finally {
      setState(() {
        isLoading = false; // 로딩 종료
      });
    }
  }

  // void _showShareBottomSheet() {
  //   // 공유 옵션 BottomSheet 표시 함수
  //   showModalBottomSheet(
  //     // BottomSheet 표시
  //     context: context,
  //     builder: (BuildContext context) {
  //       return DraggableScrollableSheet(
  //         // 스크롤 가능한 BottomSheet
  //         initialChildSize: 0.3, // 초기 크기
  //         minChildSize: 0.2, // 최소 크기
  //         maxChildSize: 0.7, // 최대 크기
  //         expand: false, // 전체 화면으로 확장하지 않음
  //         builder: (BuildContext context, ScrollController scrollController) {
  //           return Container(
  //             // 컨테이너
  //             color: Colors.white,
  //             child: ListView(
  //               // 리스트 뷰
  //               controller: scrollController,
  //               children: <Widget>[
  //                 ListTile(
  //                   // 리스트 항목
  //                   leading: Icon(Icons.message), // 카카오톡 아이콘
  //                   title: Text('카카오톡으로 공유'), // 제목
  //                   onTap: () {
  //                     // 탭 이벤트
  //                     Navigator.pop(context); // BottomSheet 닫기
  //                     _shareToKakaoTalk(); // 카카오톡으로 공유 함수 호출
  //                   },
  //                 ),
  //                 // 다른 공유 옵션 추가 가능
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Future<void> _shareToKakaoTalk() async {
    // // 카카오톡으로 공유하는 함수
    // String shareText =
    //     '${widget.itemData['title']}\n${detaillistData?.data[0]['overview'] ?? ''}\n주소: ${detaillistData?.data[0]['addr1'] ?? ''}'; // 공유할 텍스트 생성 (제목, 설명, 주소)

    String shareText = '${widget.itemData['title']}'; // 공유할 텍스트 생성 (제목, 설명, 주소)

    // Google Maps URL 생성
    // if (_location != null) {
    //   String googleMapsUrl =
    //       'https://www.google.com/maps/search/?api=1&query=${_location!.latitude},${_location!.longitude}';
    //   shareText += '\n위치: $googleMapsUrl'; // 공유 텍스트에 위치 정보 추가
    // } else {
    //   shareText += '\n위치 정보 없음'; // 위치 정보가 없을 경우 메시지 추가
    // }

    if (_location != null) {
      //공공데이터 좌표가 WGS84 로 되어 있음
      //EPSG:4326 (WGS84) => EPSG:3857 (Web Mercator)으로 변환
      //네이버맵은 v5 기준, EPSG:3857 좌표계를 사용
      //위치만(마커표시가없음) : https://map.naver.com/v5/search?c={x좌표},{y좌표},{배율},0,0,0,dh
      //주소/타이틀(마커표시함) : https://map.naver.com/p/entry/address/{x좌표},{y좌표},{주소}?c=19.00,0,0,0,dh

      // String naverMapUrl =
      //     'https://map.naver.com/v5/?c=${_sharelocation!.longitude},${_sharelocation!.latitude},15,0,0,0,dh';

      // 네이버 지도 v5 웹 URL 생성
      String naverMapUrl =
          'https://map.naver.com/p/entry/address/${_sharelocation!.longitude},${_sharelocation!.latitude},${widget.itemData['title']}?c=19.00,0,0,0,dh';

      shareText += '\n위치: $naverMapUrl';
    } else {
      shareText += '\n위치 정보 없음';
    }

    Share.share(shareText,
        subject: widget.itemData['title']); // share_plus 사용 (제목을 subject로 전달)
  }

  @override
  Widget build(BuildContext context) {
    // 위젯 빌드
    return Scaffold(
      // Scaffold (기본 화면 구조)
      appBar: AppBar(
        // 앱 바
        title: Text(title), // 제목
        centerTitle: true, // 제목 가운데 정렬
      ),
      body: Padding(
        // Padding (여백)
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            // 로딩 중
            ? const Center(child: CircularProgressIndicator()) // 로딩 인디케이터 표시
            : (detaillistData != null && detaillistData!.data.isNotEmpty)
                // 데이터가 있는 경우
                ? SingleChildScrollView(
                    // 스크롤 가능한 영역
                    child: Column(
                      // Column (세로 정렬)
                      crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                      children: [
                        if (selectedImageUrl != null && selectedImageUrl != "")
                          // 선택된 이미지가 있는 경우
                          Image.network(
                            // 이미지 표시
                            selectedImageUrl!,
                            width: MediaQuery.of(context).size.width -
                                32, // 화면 너비에 맞춤
                            fit: BoxFit.cover, // 이미지 비율 유지하면서 채우기
                            errorBuilder: (BuildContext context,
                                Object exception, StackTrace? stackTrace) {
                              // 이미지 로딩 실패 시
                              return const Center(
                                  child: Text('Failed to load image'));
                            },
                          )
                        else
                          // 선택된 이미지가 없는 경우
                          Container(
                            // 빈 컨테이너 표시
                            width: MediaQuery.of(context).size.width - 32,
                            height: 150,
                            color: Colors.grey[200],
                            child:
                                const Center(child: Text('No image available')),
                          ),
                        const SizedBox(height: 8), // 간격 추가
                        SingleChildScrollView(
                          // 가로 스크롤 가능한 이미지 목록
                          scrollDirection: Axis.horizontal, // 가로 스크롤
                          child: Row(
                            // Row (가로 정렬)
                            children: imgListData.map((item) {
                              // 이미지 목록 순회
                              final imageUrl =
                                  item['originimgurl'] ?? ''; // 이미지 URL 가져오기
                              return Padding(
                                // Padding (간격)
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  // 탭 가능한 이미지
                                  onTap: () {
                                    // 탭 이벤트
                                    setState(() {
                                      // 선택된 이미지 URL 업데이트
                                      selectedImageUrl = imageUrl;
                                    });
                                  },
                                  child: Image.network(
                                    // 이미지 표시
                                    imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover, // 이미지 비율 유지하면서 채우기
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      // 이미지 로딩 실패 시
                                      return const Center(
                                          child: Text('Failed to load image'));
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8), // 간격 추가
                        Text(
                          // 상세 설명 표시
                          '${detaillistData?.data[0]['overview'] ?? '상세 설명 없음'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8), // 간격 추가
                        Text(
                          // 주소 표시
                          '주 소 : (${detaillistData?.data[0]['zipcode'] ?? '없음'}) ${detaillistData?.data[0]['addr1'] ?? '주소없음'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8), // 간격 추가
                        _location == null
                            // 위치 정보가 없는 경우
                            ? const Text("좌표 정보가 없습니다.") // 메시지 표시
                            : Stack(
                                // 위치 정보가 있는 경우
                                children: [
                                  // 네이버 맵
                                  SizedBox(
                                    // 지도 영역
                                    width:
                                        MediaQuery.of(context).size.width - 32,
                                    height: 200,
                                    child: NaverMap(
                                      // 네이버 맵 위젯
                                      options: NaverMapViewOptions(
                                        // 옵션 설정
                                        zoomGesturesEnable: false, // 줌 제스처 비활성화
                                        scrollGesturesEnable:
                                            false, // 스크롤 제스처 비활성화
                                        initialCameraPosition: NCameraPosition(
                                          // 초기 카메라 위치
                                          target: _location!,
                                          zoom: 15,
                                        ),
                                      ),
                                      onMapReady: (controller) {
                                        // 맵 준비 완료 시
                                        controller.addOverlay(NMarker(
                                          // 마커 추가
                                          id: UniqueKey()
                                              .toString(), //'markerId',
                                          position: _location!,
                                        ));
                                      },
                                    ),
                                  ),

                                  // 터치 이벤트를 감지하는 GestureDetector (맵 위에 배치)
                                  Positioned.fill(
                                    // 맵 전체 영역
                                    child: GestureDetector(
                                      // 탭 이벤트 감지
                                      behavior: HitTestBehavior
                                          .translucent, // 투명한 영역에서도 터치 감지
                                      onTap: () {
                                        // 탭 이벤트
                                        debugPrint("맵이 클릭되었습니다!"); // 디버깅용
                                        Navigator.push(
                                          // 전체 화면 지도 페이지로 이동
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenMapPage(
                                              // 전체 화면 지도 페이지
                                              initialLocation: _location!,
                                              address: detaillistData?.data[0]
                                                  ['addr1'],
                                              title: title,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 8), // 간격 추가
                      ],
                    ),
                  )
                : const Center(
                    // 데이터가 없는 경우
                    child: Text('상세 정보를 불러올 수 없습니다.'),
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // 하단 탐색 모음
        items: const <BottomNavigationBarItem>[
          // 아이템 목록
          BottomNavigationBarItem(
            icon: Icon(Icons.reviews), // 리뷰 쓰기 아이콘
            label: '리뷰 쓰기', // 리뷰 쓰기 텍스트
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share), // 공유하기 아이콘
            label: '공유하기', // 공유하기 텍스트
          ),
        ],
        currentIndex: 0, // 현재 선택된 아이템 인덱스
        onTap: (index) {
          // 탭 이벤트
          if (index == 1) {
            // Share button
            // _showShareBottomSheet(); // 공유 옵션 BottomSheet 표시
            _shareToKakaoTalk(); // 바로 카카오톡 공유 함수 호출
          }
          // Add logic for review button if needed
        },
      ),
    );
  }

  @override
  void dispose() {
    // 위젯 해제
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navermapapp/api_service.dart';
import 'package:navermapapp/area_code_data.dart';
import 'package:navermapapp/home_detail_page.dart';
import 'package:navermapapp/location_based_list_data.dart';
import 'package:navermapapp/provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AreaCodeData? areaCodeData;
  LocationBasedListData? locationBasedListData;
  bool isLoading = false;
  // String serviceKey =
  //     'hw6GHSr0QCkKe1CdUwRF71yOGIXqqwPIvgFoW%2F83sxctXH97yiFQ8DGB55SthPnZOIOffGphY9q8aslzXmMzhA%3D%3D';
  double? mapX;
  double? mapY;
  String selectedCategory = '음식점'; // 초기 선택된 카테고리
  double selectedRadius = 2000; // 초기 반경 값

  final Map<String, String> contentTypeMap = {
    '음식점': '39',
    '숙박': '32',
    '관광지': '12',
    '문화시설': '14',
    '행사': '15',
    '여행코스': '25',
    '레포츠': '28',
    '쇼핑': '38',
  };

  @override
  void initState() {
    super.initState();
    getCurrentLocation(); // 초기 위치 가져오기
  }

  Future<void> getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint("위치 권한이 거부되었습니다.");
        return;
      }

      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );

      Position position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings);
      setState(() {
        mapX = position.longitude;
        mapY = position.latitude;
      });
    } catch (e) {
      debugPrint("현재 위치를 가져오는 데 실패했습니다: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
      fetchLocationBasedListData(selectedCategory); // fetchData 호출 시 파라미터 전달
    }
  }

  Future<void> fetchLocationBasedListData(String contentType) async {
    try {
      setState(() {
        isLoading = true; // 로딩 시작
        // 기존 데이터 초기화
      });
      if (mapX == null || mapY == null) {
        debugPrint("위치 정보가 없어 API 호출을 중단합니다.");
        return;
      }

      // ContentTypeId 가져오기
      String? contentTypeId = contentTypeMap[contentType];
      if (contentTypeId == null) {
        debugPrint('해당 카테고리에 대한 ContentTypeId가 없습니다.');
        return;
      }

      final params = {
        'contentTypeId': contentTypeId,
        'mapX': mapX.toString(), // 현재 경도 사용
        'mapY': mapY.toString(), // 현재 위도 사용
        'radius': selectedRadius.toString(), // 선택된 반경 사용,
        'listYN': 'Y',
        'MobileOS': 'AND',
        'MobileApp': 'navermapapp',
        'numOfRows': '50',
        'pageNo': '1'
      };

      final serviceKeyProvider =
          Provider.of<ServiceKeyProvider>(context, listen: false);
      final serviceKey = serviceKeyProvider.getServiceKey();

      final data = await ApiService.fetchData<LocationBasedListData>(
        path: 'locationBasedList1',
        serviceKey: serviceKey, //serviceKey,
        params: params,
        responseModel: LocationBasedListData(),
        responseType: 'xml',
        itemsElement: 'item', // <item> 태그 명시
      );

      setState(() {
        locationBasedListData = data;

        selectedCategory = contentType;
      });
    } catch (e) {
      debugPrint('Failed to fetch location based list data: $e');
    } finally {
      setState(() {
        isLoading = false; // 로딩 종료
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            getCurrentLocation(); // 현 위치 아이콘 클릭 시 위치 다시 가져오기
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.my_location,
                size: 15, // 아이콘 크기 변경
                color: const Color.fromARGB(221, 239, 134, 21),
              ),
              SizedBox(width: 4),
              Text(
                '현위치',
                style: TextStyle(
                  fontSize: 14, // 폰트 크기 변경
                  fontWeight: FontWeight.normal, // 폰트 굵기 변경
                  fontFamily: 'Roboto', // 폰트 종류 변경 (선택 사항)
                  color: const Color.fromARGB(180, 16, 15, 15),
                ),
              ),
            ],
          ),
        ),
        // actions: [
        //   // actions 추가
        //   TextButton(
        //     onPressed: () {
        //       // 거리 설정 버튼 클릭 시 동작
        //       print('거리 설정 버튼 클릭!');
        //       // 여기에 거리 설정 관련 로직을 추가합니다.
        //     },
        //     style: TextButton.styleFrom(
        //       foregroundColor: Colors.white, // 버튼 텍스트 색상
        //     ),
        //     child: Text('거리 설정'),
        //   ),
        // ],

        // actions: [
        //   // actions 추가
        //   IconButton(
        //     icon: Icon(Icons.settings), // 설정 아이콘 사용
        //     onPressed: () {
        //       // 거리 설정 버튼 클릭 시 동작
        //       print('거리 설정 버튼 클릭!');
        //       // 여기에 거리 설정 관련 로직을 추가합니다.
        //     },
        //   ),
        // ],

        //actions 추가
        actions: [
          // InkWell 또는 GestureDetector 사용
          InkWell(
            onTap: () {
              // 거리 설정 버튼 클릭 시 동작
              print('거리 설정 버튼 클릭!');
              showModalBottomSheet(
                // Bottom Sheet 표시
                context: context,
                //backgroundColor: Colors.transparent, // 배경 투명하게 설정
                isScrollControlled: true, // 내용이 화면 전체를 차지하도록 설정
                builder: (BuildContext context) {
                  return StatefulBuilder(builder:
                      (BuildContext context, StateSetter setModalState) {
                    return Container(
                      width: MediaQuery.of(context).size.width, // 가로 크기를 화면에 맞춤
                      height: 200,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, // BottomSheet 배경색
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween, // 양 끝 정렬
                            children: [
                              SizedBox(width: 16),
                              Text(
                                '거리 설정',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                // 내리기 아이콘 버튼
                                icon: Icon(Icons.arrow_drop_down),
                                onPressed: () {
                                  Navigator.pop(context); // Bottom Sheet 닫기
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // 여기에 거리 설정 UI를 추가합니다.
                          Slider(
                            // Slider 추가
                            value: selectedRadius,
                            min: 100,
                            max: 5000,
                            divisions: 5, // Slider 눈금 개수

                            label:
                                '${selectedRadius.toStringAsFixed(0)}m', // 현재 값 표시
                            onChanged: (newValue) {
                              setModalState(() {
                                selectedRadius =
                                    newValue; // BottomSheet 내부 상태 변경
                              });
                            },
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Bottom Sheet 닫기
                              fetchLocationBasedListData(
                                  selectedCategory); // 새로운 거리로 데이터 가져오기
                            },
                            child: Text('적용'),
                          ),
                        ],
                      ),
                    );
                  });
                },
              );
            },
            child: Container(
              height: 34,
              padding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 1), // 적절한 패딩 설정
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 134, 160, 232), // 버튼 배경색
                borderRadius: BorderRadius.circular(8), // 둥근 모서리
              ),
              child: Center(
                child: Text(
                  '거리 설정',
                  style: TextStyle(
                    color: Colors.white, // 텍스트 색상
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          //   // ElevatedButton 사용
          // ElevatedButton(
          //   onPressed: () {
          //     // 거리 설정 버튼 클릭 시 동작
          //     print('거리 설정 버튼 클릭!');
          //     showModalBottomSheet(
          //       // Bottom Sheet 표시
          //       context: context,
          //       backgroundColor: Colors.transparent, // 배경 투명하게 설정
          //       isScrollControlled: true, // 내용이 화면 전체를 차지하도록 설정
          //       builder: (BuildContext context) {
          //         return Container(
          //           width: MediaQuery.of(context).size.width, // 가로 크기를 화면에 맞춤
          //           padding: EdgeInsets.all(16),
          //           decoration: BoxDecoration(
          //             color: Colors.white, // BottomSheet 배경색
          //             borderRadius: BorderRadius.only(
          //               topLeft: Radius.circular(20),
          //               topRight: Radius.circular(20),
          //             ),
          //           ),
          //           child: Column(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               Text(
          //                 '거리 설정',
          //                 style: TextStyle(
          //                   fontSize: 20,
          //                   fontWeight: FontWeight.bold,
          //                 ),
          //               ),
          //               SizedBox(height: 16),
          //               // 여기에 거리 설정 UI를 추가합니다.
          //               ElevatedButton(
          //                 onPressed: () {
          //                   Navigator.pop(context); // Bottom Sheet 닫기
          //                 },
          //                 child: Text('확인'),
          //               ),
          //             ],
          //           ),
          //         );
          //       },
          //     );
          //   },
          //   style: ElevatedButton.styleFrom(
          //     // ElevatedButton 스타일 설정
          //     backgroundColor: Colors.blue, // 배경색
          //     foregroundColor: Colors.white, // 텍스트 색상
          //     textStyle: TextStyle(fontWeight: FontWeight.bold), // 폰트 굵기
          //     shape: RoundedRectangleBorder(
          //       // 둥근 모서리
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //   ),
          //   child: Text('거리 설정'),
          // ),
          SizedBox(width: 8), // AppBar actions 간 간격
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              // Column 유지
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  // 카테고리 아이콘만 스크롤되도록
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryIcon(context, '음식점', Icons.restaurant),
                      _buildCategoryIcon(context, '숙박', Icons.hotel),
                      _buildCategoryIcon(context, '관광지', Icons.location_on),
                      _buildCategoryIcon(context, '쇼핑', Icons.shopping_cart),
                      _buildCategoryIcon(context, '문화시설', Icons.museum),
                      _buildCategoryIcon(context, '행사', Icons.event),
                      _buildCategoryIcon(context, '여행코스', Icons.map),
                      _buildCategoryIcon(context, '레포츠', Icons.directions_bike),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (locationBasedListData != null &&
                          locationBasedListData!.data.isNotEmpty)
                        ListView.builder(
                          itemCount: locationBasedListData!.data.length,
                          itemBuilder: (context, index) {
                            return CardItem(
                                locationBasedListData: locationBasedListData!,
                                index: index);
                          },
                        )
                      else if (!isLoading &&
                          locationBasedListData != null &&
                          locationBasedListData!.data.isEmpty)
                        const Center(
                          child: Text('데이터가 존재하지 않습니다.'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(
      BuildContext context, String label, IconData iconData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              debugPrint('$label 아이콘 탭!');
              fetchLocationBasedListData(label);
            },
            child: CircleAvatar(
              radius: 15,
              backgroundColor:
                  selectedCategory == label ? Colors.green : Colors.blue,
              child: Icon(
                iconData,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class CardItem extends StatelessWidget {
  const CardItem({
    super.key,
    required this.locationBasedListData,
    required this.index,
  });

  final LocationBasedListData locationBasedListData;
  final int index;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final contentId =
    //     locationBasedListData.data[index]['contentid'] ?? ''; // contentid 가져오기
    final itemData = locationBasedListData.data[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DetailPage(itemData: itemData), // contentid 전달
              ),
            );
          },
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                    child: locationBasedListData.data[index]['firstimage'] !=
                                null &&
                            locationBasedListData
                                .data[index]['firstimage'].isNotEmpty
                        ? Image.network(
                            locationBasedListData.data[index]['firstimage'],
                            width: screenWidth - 32,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext context,
                                Object exception, StackTrace? stackTrace) {
                              return const Center(
                                  child: Text('Failed to load image'));
                            },
                          )
                        : Container(
                            width: screenWidth - 32,
                            height: 150,
                            color: Colors.grey[200],
                            child: Center(child: Text('No image available')),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationBasedListData.data[index]['title'] ??
                              'No Title',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(locationBasedListData.data[index]['addr1'] ??
                            'No Address'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navermapapp/api_service.dart';
import 'package:navermapapp/area_code_data.dart';
import 'package:navermapapp/location_based_list_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AreaCodeData? areaCodeData;
  LocationBasedListData? locationBasedListData;
  bool isLoading = false;
  String serviceKey =
      'hw6GHSr0QCkKe1CdUwRF71yOGIXqqwPIvgFoW%2F83sxctXH97yiFQ8DGB55SthPnZOIOffGphY9q8aslzXmMzhA%3D%3D';
  double? mapX;
  double? mapY;
  String selectedCategory = '음식점'; // 초기 선택된 카테고리

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
        print("위치 권한이 거부되었습니다.");
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
      print("현재 위치를 가져오는 데 실패했습니다: $e");
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
        print("위치 정보가 없어 API 호출을 중단합니다.");
        return;
      }

      // ContentTypeId 가져오기
      String? contentTypeId = contentTypeMap[contentType];
      if (contentTypeId == null) {
        print('해당 카테고리에 대한 ContentTypeId가 없습니다.');
        return;
      }

      final params = {
        'contentTypeId': contentTypeId,
        'mapX': mapX.toString(), // 현재 경도 사용
        'mapY': mapY.toString(), // 현재 위도 사용
        'radius': '2000',
        'listYN': 'Y',
        'MobileOS': 'AND',
        'MobileApp': 'navermapapp',
        'numOfRows': '12',
        'pageNo': '1'
      };

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
          // if (isLoading)
          //   Container(
          //     color: Color.fromRGBO(0, 0, 0, 0.053),
          //     child: const Center(
          //       child: CircularProgressIndicator(),
          //     ),
          //   ),
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
              print('$label 아이콘 탭!');
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child:
                      locationBasedListData.data[index]['firstimage'] != null &&
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
    );
  }
}

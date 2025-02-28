import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navermapapp/api_service.dart';
import 'package:navermapapp/area_code_data.dart';
import 'package:navermapapp/home_detail_page.dart';
import 'package:navermapapp/location_based_list_data.dart';
import 'package:navermapapp/provider.dart';
import 'package:provider/provider.dart';

class LocationInfoPage extends StatefulWidget {
  const LocationInfoPage({super.key});

  @override
  State<LocationInfoPage> createState() => _LocationInfoPageState();
}

class _LocationInfoPageState extends State<LocationInfoPage> {
  AreaCodeData? areaCodeData;
  LocationBasedListData? locationBasedListData;
  bool isLoading = false;
  double? mapX;
  double? mapY;
  String selectedCategory = '음식점'; // 초기 선택된 카테고리
  double selectedRadius = 2000; // 초기 반경 값
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarContent = true;

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
    setState(() {
      isLoading = true;
    });
    getCurrentLocation();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset <= 0) {
      if (!_showAppBarContent) {
        setState(() {
          _showAppBarContent = true;
        });
      }
    } else {
      if (_showAppBarContent) {
        setState(() {
          _showAppBarContent = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    //await getCurrentLocation(); // Refresh data when pulled down
    await fetchLocationData();
  }

  Future<void> fetchLocationData() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint("위치 권한이 거부되었습니다.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 권한이 필요합니다.')),
        );
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
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('현재 위치를 가져오는데 실패했습니다.')),
      // );
    } finally {
      fetchLocationBasedListData(selectedCategory);
    }
  }

  Future<void> getCurrentLocation() async {
    fetchLocationData(); // fetchData 호출 시 파라미터 전달
  }

  Future<void> fetchLocationBasedListData(String contentType) async {
    try {
      setState(() {
        isLoading = true;
      });
      if (mapX == null || mapY == null) {
        debugPrint("위치 정보가 없어 API 호출을 중단합니다.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 정보가 없습니다.')),
        );
        return;
      }

      String? contentTypeId = contentTypeMap[contentType];
      if (contentTypeId == null) {
        debugPrint('해당 카테고리에 대한 ContentTypeId가 없습니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('해당 카테고리에 대한 정보가 없습니다.')),
        );
        return;
      }

      final params = {
        'contentTypeId': contentTypeId,
        'mapX': mapX.toString(),
        'mapY': mapY.toString(),
        'radius': selectedRadius.toString(),
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
        serviceKey: serviceKey,
        params: params,
        responseModel: LocationBasedListData(),
        responseType: 'xml',
        itemsElement: 'item',
      );

      setState(() {
        locationBasedListData = data;
        selectedCategory = contentType;
      });
    } catch (e) {
      debugPrint('Failed to fetch location based list data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터를 가져오는데 실패했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final validItems = locationBasedListData?.data
        .where((item) =>
            item['firstimage'] != null && item['firstimage'].isNotEmpty)
        .toList();

    return Scaffold(
      body: Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _showAppBarContent ? 120 : 0,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Visibility(
                visible: _showAppBarContent,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              getCurrentLocation();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.my_location,
                                  size: 15,
                                  color:
                                      const Color.fromARGB(221, 239, 134, 21),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '현위치',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Roboto',
                                    color:
                                        const Color.fromARGB(180, 16, 15, 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (BuildContext context) {
                                  return StatefulBuilder(builder:
                                      (BuildContext context,
                                          StateSetter setModalState) {
                                    return Container(
                                      width: MediaQuery.of(context).size.width,
                                      height: 200,
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
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
                                                MainAxisAlignment.spaceBetween,
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
                                                icon:
                                                    Icon(Icons.arrow_drop_down),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16),
                                          Slider(
                                            value: selectedRadius,
                                            min: 100,
                                            max: 5000,
                                            divisions: 5,
                                            label:
                                                '${selectedRadius.toStringAsFixed(0)}m',
                                            onChanged: (newValue) {
                                              setModalState(() {
                                                selectedRadius = newValue;
                                              });
                                            },
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              fetchLocationBasedListData(
                                                  selectedCategory);
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.settings,
                                  size: 15,
                                  color:
                                      const Color.fromARGB(221, 239, 134, 21),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '거리 설정',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Roboto',
                                    color:
                                        const Color.fromARGB(180, 16, 15, 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryIcon(
                                context, '음식점', Icons.restaurant),
                            _buildCategoryIcon(context, '숙박', Icons.hotel),
                            _buildCategoryIcon(
                                context, '관광지', Icons.location_on),
                            _buildCategoryIcon(
                                context, '쇼핑', Icons.shopping_cart),
                            _buildCategoryIcon(context, '문화시설', Icons.museum),
                            _buildCategoryIcon(context, '행사', Icons.event),
                            _buildCategoryIcon(context, '여행코스', Icons.map),
                            _buildCategoryIcon(
                                context, '레포츠', Icons.directions_bike),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else if (locationBasedListData != null &&
                      validItems != null &&
                      validItems.isNotEmpty)
                    ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      itemCount: validItems.length,
                      itemBuilder: (context, index) {
                        return CardItem(
                          locationBasedListData: locationBasedListData!,
                          index: index,
                          validItems: validItems,
                        );
                      },
                    )
                  else if (!isLoading &&
                      locationBasedListData != null &&
                      (validItems == null || validItems.isEmpty))
                    const Center(
                      child: Text('데이터가 존재하지 않습니다.'),
                    )
                  else if (!isLoading && locationBasedListData == null)
                    const Center(
                      child: Text('데이터가 존재하지 않습니다.'),
                    ),
                ],
              ),
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
    this.validItems,
  });

  final LocationBasedListData locationBasedListData;
  final int index;
  final List<dynamic>? validItems;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemData = validItems![index];

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
                builder: (context) => DetailPage(itemData: itemData),
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
                    child: itemData['firstimage'] != null &&
                            itemData['firstimage'].isNotEmpty
                        ? Image.network(
                            itemData['firstimage'],
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
                            child:
                                const Center(child: Text('No image available')),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemData['title'] ?? 'No Title',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(itemData['addr1'] ?? 'No Address'),
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

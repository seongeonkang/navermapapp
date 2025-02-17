import 'package:flutter/material.dart';
import 'package:navermapapp/api_service.dart';
import 'package:navermapapp/fullscreen_map_page.dart';
import 'package:navermapapp/location_based_list_data.dart';
import 'package:navermapapp/provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const DetailPage({super.key, required this.itemData});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String title = '상세 정보'; // 초기 제목 설정
  LocationBasedListData? detaillistData;
  List<dynamic> imgListData = [];
  bool isLoading = false;
  String? selectedImageUrl;
  NLatLng? _location;

  @override
  void initState() {
    super.initState();
    fetchListData();
    fetchimgListData();

    // 초기 이미지 URL 설정
    selectedImageUrl = widget.itemData['firstimage'] ?? "";
    // 위젯이 처음 생성될 때 제목 초기화
    title = widget.itemData['title'] ?? '상세 정보';
  }

  Future<void> fetchListData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final params = {
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
          Provider.of<ServiceKeyProvider>(context, listen: false);
      final serviceKey = serviceKeyProvider.getServiceKey();

      final data = await ApiService.fetchData<LocationBasedListData>(
        path: 'detailCommon1',
        serviceKey: serviceKey,
        params: params,
        responseModel: LocationBasedListData(),
        responseType: 'xml',
        itemsElement: 'item',
      );

      setState(() {
        detaillistData = data;

        _location = NLatLng(
          double.parse(detaillistData!.data[0]['mapy'] ?? '0'),
          double.parse(detaillistData!.data[0]['mapx'] ?? '0'),
        );
      });
    } catch (e) {
      debugPrint('Failed to fetch location based list data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchimgListData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final params = {
        'contentId': widget.itemData['contentid'].toString(),
        'MobileOS': 'AND',
        'MobileApp': 'navermapapp',
        'imageYN': 'Y',
        'subImageYN': 'Y',
        'numOfRows': '20',
      };

      final serviceKeyProvider =
          Provider.of<ServiceKeyProvider>(context, listen: false);
      final serviceKey = serviceKeyProvider.getServiceKey();

      final imgdata = await ApiService.fetchData<LocationBasedListData>(
        path: 'detailImage1',
        serviceKey: serviceKey,
        params: params,
        responseModel: LocationBasedListData(),
        responseType: 'xml',
        itemsElement: 'item',
      );

      setState(() {
        imgListData = imgdata.data ?? [];
        //if (imgListData.isNotEmpty) {
        // selectedImageUrl = imgListData[0]['originimgurl']; // 첫 번째 이미지 URL 설정
        //}
      });
    } catch (e) {
      debugPrint('Failed to fetch location based list data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title), // 동적으로 변경되는 제목
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : (detaillistData != null && detaillistData!.data.isNotEmpty)
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedImageUrl != null && selectedImageUrl != "")
                          Image.network(
                            selectedImageUrl!,
                            width: MediaQuery.of(context).size.width - 32,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext context,
                                Object exception, StackTrace? stackTrace) {
                              return const Center(
                                  child: Text('Failed to load image'));
                            },
                          )
                        else
                          Container(
                            width: MediaQuery.of(context).size.width - 32,
                            height: 150,
                            color: Colors.grey[200],
                            child: Center(child: Text('No image available')),
                          ),
                        SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: imgListData.map((item) {
                              final imageUrl = item['originimgurl'] ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImageUrl = imageUrl;
                                    });
                                  },
                                  child: Image.network(
                                    imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return const Center(
                                          child: Text('Failed to load image'));
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${detaillistData?.data[0]['overview'] ?? '상세 설명 없음'}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '주 소 : (${detaillistData?.data[0]['zipcode'] ?? '없음'}) ${detaillistData?.data[0]['addr1'] ?? '주소없음'}',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        _location == null
                            ? const Text("좌표 정보가 없습니다.")
                            : Stack(
                                children: [
                                  // 네이버 맵
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width - 32,
                                    height: 200,
                                    child: NaverMap(
                                      options: NaverMapViewOptions(
                                        zoomGesturesEnable: false,
                                        scrollGesturesEnable: false,
                                        initialCameraPosition: NCameraPosition(
                                          target: _location!,
                                          zoom: 15,
                                        ),
                                      ),
                                      onMapReady: (controller) {
                                        controller.addOverlay(NMarker(
                                          id: UniqueKey()
                                              .toString(), //'markerId',
                                          position: _location!,
                                        ));
                                      },
                                    ),
                                  ),

                                  // 터치 이벤트를 감지하는 GestureDetector (맵 위에 배치)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior
                                          .translucent, // 투명한 영역에서도 터치 감지
                                      onTap: () {
                                        debugPrint("맵이 클릭되었습니다!"); // 디버깅용
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenMapPage(
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
                        SizedBox(height: 8),
                      ],
                    ),
                  )
                : Center(
                    child: Text('상세 정보를 불러올 수 없습니다.'),
                  ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

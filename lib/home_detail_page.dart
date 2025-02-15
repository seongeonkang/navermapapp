// detail_page.dart
import 'package:flutter/material.dart';
import 'package:navermapapp/api_service.dart';
import 'package:navermapapp/location_based_list_data.dart';
import 'package:navermapapp/provider.dart';
import 'package:provider/provider.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const DetailPage({super.key, required this.itemData});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String title = '상세 정보'; // 초기 제목 설정
  LocationBasedListData? detaillistData;
  bool isLoading = false; // 로딩 상태를 나타내는 변수

  @override
  void initState() {
    super.initState();
    fetchListData();
    // 위젯이 처음 생성될 때 제목 초기화
    title = widget.itemData['title'] ?? '상세 정보';
  }

  Future<void> fetchListData() async {
    setState(() {
      isLoading = true; // 데이터 로딩 시작 시 로딩 상태를 true로 설정
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
        serviceKey: serviceKey, //serviceKey,
        params: params,
        responseModel: LocationBasedListData(),
        responseType: 'xml',
        itemsElement: 'item', // <item> 태그 명시
      );

      setState(() {
        detaillistData = data;
      });
    } catch (e) {
      debugPrint('Failed to fetch location based list data: $e');
    } finally {
      setState(() {
        isLoading = false; // 데이터 로딩 완료 시 로딩 상태를 false로 설정
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
        child: isLoading // 로딩 중일 때 로딩 Indicator 표시
            ? Center(child: CircularProgressIndicator())
            : (detaillistData != null && detaillistData!.data.isNotEmpty)
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (detaillistData?.data[0]['firstimage'] != null &&
                            detaillistData?.data[0]['firstimage'].isNotEmpty)
                          Image.network(
                            detaillistData?.data[0]['firstimage'],
                            width: MediaQuery.of(context).size.width - 32,
                            fit: BoxFit.cover,
                          ),
                        SizedBox(height: 8),
                        Text(
                          '우편번호: ${detaillistData?.data[0]['zipcode'] ?? '주소 없음'}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '주소: ${detaillistData?.data[0]['addr1'] ?? '전화번호 없음'}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${detaillistData?.data[0]['overview'] ?? '전화번호 없음'}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text('상세 정보를 불러올 수 없습니다.'), // 데이터가 없을 경우 메시지 표시
                  ),
      ),
    );
  }
}

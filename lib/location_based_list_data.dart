// location_based_list_data.dart
import 'package:navermapapp/api_response.dart';

class LocationBasedListData implements XmlApiResponse {
  List<Map<String, dynamic>> data = []; // List of Maps 형태로 저장

  @override
  void fromResponse(dynamic xmlData) {
    if (xmlData is List<Map<String, dynamic>>) {
      data = xmlData; // List of Maps 형태로 저장
    } else {
      print('Error: xmlData is not a List<Map<String, dynamic>>');
    }
  }

  // 특정 인덱스의 아이템에서 키에 해당하는 값을 가져오는 메서드
  dynamic getValue(int index, String key) {
    if (index >= 0 && index < data.length) {
      return data[index][key];
    }
    return null;
  }
}

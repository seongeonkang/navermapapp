// area_code_data.dart
import 'package:navermapapp/api_response.dart';

class AreaCodeData implements JsonApiResponse {
  String? code;
  String? name;

  @override
  void fromResponse(dynamic jsonData) {
    if (jsonData is Map<String, dynamic>) {
      code = jsonData['code'];
      name = jsonData['name'];
    } else {
      print('Error: jsonData is not a Map');
    }
  }
}

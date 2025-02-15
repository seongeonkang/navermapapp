// api_response.dart
abstract class ApiResponse {
  void fromResponse(dynamic data); // 응답 데이터 타입에 따라 처리
}

abstract class JsonApiResponse implements ApiResponse {
  @override
  void fromResponse(dynamic jsonData);
}

abstract class XmlApiResponse implements ApiResponse {
  @override
  void fromResponse(dynamic xmlData);
}

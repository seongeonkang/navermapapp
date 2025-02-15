// api_endpoints.dart
enum ApiEndpoint {
  areaCode1,
  locationBasedList1,
  searchBasedList1,
}

extension ApiEndpointExtension on ApiEndpoint {
  String get path {
    switch (this) {
      case ApiEndpoint.areaCode1:
        return 'areaCode1';
      case ApiEndpoint.locationBasedList1:
        return 'locationBasedList1';
      case ApiEndpoint.searchBasedList1:
        return 'searchBasedList1';
      default:
        return '';
    }
  }
}

// api_constants.dart
class ApiConstants {
  static const String baseUrl = 'http://apis.data.go.kr/B551011/KorService1';
}

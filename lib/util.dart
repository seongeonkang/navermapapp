// String buildUrl({
//   required String baseUrl,
//   required String path,
//   Map<String, dynamic>? queryParams,
// }) {
//   final uri = Uri.parse('$baseUrl/$path');
//   if (queryParams != null && queryParams.isNotEmpty) {
//     return uri.replace(queryParameters: queryParams).toString();
//   }
//   return uri.toString();
// }

// url_utils.dart
String buildUrl({
  required String baseUrl,
  required String path,
  required String serviceKey, // serviceKey 파라미터 추가
  Map<String, dynamic>? queryParams,
}) {
  final uri = Uri.parse('$baseUrl/$path');
  Map<String, dynamic> finalParams = {};

  // serviceKey는 별도로 처리하고, queryParams의 값들만 인코딩
  finalParams['serviceKey'] = serviceKey;

  if (queryParams != null && queryParams.isNotEmpty) {
    queryParams.forEach((key, value) {
      finalParams[key] = value.toString(); // 모든 값을 String으로 변환
    });
  }

  final query = finalParams.entries.map((e) => '${e.key}=${e.value}').join('&');

  return '${uri.toString()}?$query';
}

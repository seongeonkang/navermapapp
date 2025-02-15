// api_service.dart
import 'package:http/http.dart' as http;
import 'package:navermapapp/api_endpoints.dart';
import 'dart:convert';
import 'package:navermapapp/util.dart';
import 'package:navermapapp/api_response.dart';
import 'package:navermapapp/xml_parser.dart'; // Import XmlParser

class ApiService {
  // static Future<T> fetchData<T extends ApiResponse>({
  //   required String path,
  //   required String serviceKey,
  //   Map<String, dynamic>? params,
  //   required T responseModel,
  //   required String responseType, // "json" 또는 "xml"
  //   String itemsElement = 'item', // XML인 경우 Item Element 명시 (기본값: 'item')
  // }) async {
  //   final defaultParams = {'serviceKey': serviceKey};
  //   final combinedParams = {...defaultParams, if (params != null) ...params};

  //   final url = buildUrl(
  //     baseUrl: ApiConstants.baseUrl,
  //     path: path,
  //     queryParams: combinedParams,
  //   );
  static Future<T> fetchData<T extends ApiResponse>({
    required String path,
    required String serviceKey,
    Map<String, dynamic>? params,
    required T responseModel,
    required String responseType,
    String itemsElement = 'item',
  }) async {
    final url = buildUrl(
      baseUrl: ApiConstants.baseUrl,
      path: path,
      serviceKey: serviceKey, // serviceKey 전달
      queryParams: params,
    );

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      if (responseType == 'json') {
        final jsonData = jsonDecode(decodedBody);
        responseModel.fromResponse(jsonData);
      } else if (responseType == 'xml') {
        final xmlData =
            XmlParser.parseXml(decodedBody, itemsElement); // 모든 <item> 파싱
        responseModel.fromResponse(xmlData);
      } else {
        throw Exception('Unsupported response type: $responseType');
      }
      return responseModel;
    } else {
      throw Exception('Failed to load data');
    }
  }
}

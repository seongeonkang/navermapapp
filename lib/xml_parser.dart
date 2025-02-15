// xml_parser.dart
import 'package:xml/xml.dart' as xml;

class XmlParser {
  // XML 문자열을 파싱하여 List<Map<String, dynamic>> 형태로 반환
  static List<Map<String, dynamic>> parseXml(
      String xmlString, String itemsElement) {
    try {
      final document = xml.XmlDocument.parse(xmlString);
      final items = document.findAllElements(itemsElement); // <item> 태그들을 찾음
      List<Map<String, dynamic>> result = [];
      for (var item in items) {
        result.add(_parseElement(item)); // 각 <item> 태그를 파싱
      }
      return result;
    } catch (e) {
      print('XML 파싱 에러: $e');
      return [];
    }
  }

  static Map<String, dynamic> _parseElement(xml.XmlElement element) {
    Map<String, dynamic> data = {};
    for (var child in element.children) {
      if (child is xml.XmlElement) {
        if (child.children.isNotEmpty && child.children.first is xml.XmlText) {
          // 텍스트 값을 가진 요소
          data[child.name.local] = child.text;
        }
      }
    }
    return data;
  }
}

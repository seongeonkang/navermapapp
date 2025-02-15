// provider.dart (예시)
import 'package:flutter/material.dart';

class ServiceKeyProvider extends ChangeNotifier {
  String serviceKey =
      'hw6GHSr0QCkKe1CdUwRF71yOGIXqqwPIvgFoW%2F83sxctXH97yiFQ8DGB55SthPnZOIOffGphY9q8aslzXmMzhA%3D%3D';

  String getServiceKey() => serviceKey;

  void updateServiceKey(String newKey) {
    serviceKey = newKey;
    notifyListeners();
  }
}

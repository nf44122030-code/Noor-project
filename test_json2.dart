import 'dart:convert';
import 'package:flutter/foundation.dart';

void main() {
  try {
    final historyList = [];
    historyList.insert(0, {
      'fileId': '123',
      'name': 'test.csv',
      'ext': 'csv',
      'rowCount': 0,
    });
    
    final encoded = jsonEncode(historyList);
    debugPrint("Encoded: $encoded");
    
    final historyStr = encoded;
    final List<dynamic> jsonList = jsonDecode(historyStr);
    final items = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
    
    debugPrint("Success load: $items");
    
  } catch (e) {
    debugPrint("Error: $e");
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';

void main() {
  try {
    const historyStr = '[{"id":"1"}]';
    final historyList = List<Map<String,dynamic>>.from(jsonDecode(historyStr));
    debugPrint("Success: $historyList");
  } catch (e) {
    debugPrint("Error: $e");
  }
}

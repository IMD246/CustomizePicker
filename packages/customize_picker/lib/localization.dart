import 'package:flutter/foundation.dart';

class Localization {
  static String getContent({
    String? locale,
    required String key,
  }) {
    try {
      return _scriptLocalization[locale ?? "en"]?[key] ?? "";
    } catch (e) {
      if (kDebugMode) {
        print("unsupported locale: $locale");
      }
      rethrow;
    }
  }

  static final Map<String, Map<String, String>> _scriptLocalization = {
    "vi": _vi,
    "en": _en,
  };

  static final Map<String, String> _en = {
    "select": "Select",
  };
  static final Map<String, String> _vi = {
    "select": "Chọn",
  };
}

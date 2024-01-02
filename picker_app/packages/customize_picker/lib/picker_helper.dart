import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'media_picker.dart';

class PickerHelper {
  static Future pickAssets({
    required RequestType requestType,
    int? maxSelect,
    String? locale,
    required BuildContext context,
    List<AssetEntity>? selectedAssetlist,
  }) async {
    final result = await Navigator.push<List<AssetEntity>?>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return MediaPicker(
            requestType: requestType,
            selectedAssetlist: selectedAssetlist,
            maxSelect: maxSelect,
            locale: locale,
          );
        },
      ),
    );
    if (result != null && result.isNotEmpty) {
      return result;
    }
  }
}

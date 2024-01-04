import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';

import 'media_services.dart';

class MediaPickerModel extends ChangeNotifier {
  List<AssetEntity> selectedAssetlist = [];
  AssetPathEntity? selectedAlbum;
  List<AssetPathEntity> albumList = [];
  List<AssetEntity> assetList = [];
  ScrollController controller = ScrollController();
  int currentCount = 0;
  bool loadMoreValue = false;
  int totalAssets = 0;
  late RequestType requestType;
  late int? maxSelect;

  void init(
    final int? maxSelect,
    final RequestType requestType,
    final List<AssetEntity>? selectedAssetlist,
  ) {
    this.maxSelect = maxSelect;
    this.requestType = requestType;
    if (selectedAssetlist != null && selectedAssetlist.isNotEmpty) {
      this.selectedAssetlist.addAll(selectedAssetlist);
      notifyListeners();
    }
    controller.addListener(_scrollListener);
    _onLoadAlbums(requestType);
  }

  void selectAsset(AssetEntity assetEntity, int? maxSelect) {
    if (selectedAssetlist.any(
      (element) => element.id == assetEntity.id,
    )) {
      selectedAssetlist.remove(assetEntity);
      notifyListeners();
    } else {
      if (selectedAssetlist.length == maxSelect && maxSelect != null) return;
      selectedAssetlist.add(assetEntity);
      notifyListeners();
    }
  }

  void _scrollListener() {
    final isScrollUp =
        controller.position.userScrollDirection == ScrollDirection.forward;
    if (controller.position.extentAfter < 300 && !isScrollUp) {
      if (kDebugMode) {
        print("LoadMoreMore");
      }
      _onLoadMore();
    }
  }

  void _scrollToTop() {
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeIn,
    );
  }

  void _onLoadMore() {
    if (loadMoreValue) return;
    loadMoreValue = true;
    _onLoadAssets();
  }

  void _onLoadAssets({bool isClear = false}) {
    if (currentCount >= totalAssets) return;
    MediaServcies()
        .loadAssets(start: currentCount, selectedAlbum: selectedAlbum!)
        .then((value) {
      if (isClear) {
        assetList.clear();
      }
      assetList.addAll(value);

      notifyListeners();
      currentCount += 20;
      loadMoreValue = false;
    });
  }

  void _onLoadAlbums(RequestType requestType) {
    MediaServcies().loadAlbums(requestType).then((value) async {
      albumList = value;
      selectedAlbum = value[0];
      notifyListeners();
      totalAssets = await selectedAlbum!.assetCountAsync;
      _onLoadAssets(isClear: true);
    });
  }

  void onChangedAlbum(AssetPathEntity? value) async {
    if (selectedAlbum == value) return;
    selectedAlbum = value;
    notifyListeners();
    totalAssets = await selectedAlbum!.assetCountAsync;
    _reset();
  }

  void _reset() {
    _scrollToTop();
    currentCount = 0;
    _onLoadAssets(isClear: true);
  }

  @override
  void dispose() {
     controller.removeListener(_scrollListener);
    controller.dispose();
    super.dispose();
  }
}

import 'package:customize_picker/color_theme.dart';
import 'package:customize_picker/localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import 'media_services.dart';

class MediaPicker extends StatefulWidget {
  const MediaPicker({
    super.key,
    this.maxSelect,
    required this.requestType,
    this.locale,
    this.selectedAssetlist,
  });

  final int? maxSelect;
  final RequestType requestType;
  final String? locale;
  final List<AssetEntity>? selectedAssetlist;
  @override
  State<MediaPicker> createState() => _MediaPickerState();
}

class _MediaPickerState extends State<MediaPicker> {
  AssetPathEntity? selectedAlbum;
  List<AssetPathEntity> albumList = [];
  List<AssetEntity> selectedAssetlist = [];
  List<AssetEntity> assetList = [];
  ScrollController controller = ScrollController();
  int currentCount = 0;
  bool loadMoreValue = false;
  int totalAssets = 0;

  void _onLoadMore() {
    if (loadMoreValue) return;
    loadMoreValue = true;
    _onLoadAssets();
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

  void _onLoadAssets({bool isClear = false}) {
    if (currentCount >= totalAssets) return;
    MediaServcies()
        .loadAssets(start: currentCount, selectedAlbum: selectedAlbum!)
        .then((value) {
      if (isClear) {
        assetList.clear();
      }
      setState(() {
        assetList.addAll(value);
      });
      currentCount += 20;
      loadMoreValue = false;
    });
  }

  void _onLoadAlbums() {
    MediaServcies().loadAlbums(widget.requestType).then((value) async {
      setState(() {
        albumList = value;
        selectedAlbum = value[0];
      });
      totalAssets = await selectedAlbum!.assetCountAsync;
      _onLoadAssets(isClear: true);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectedAssetlist != null &&
        widget.selectedAssetlist!.isNotEmpty) {
      setState(() {
        selectedAssetlist.addAll(widget.selectedAssetlist!);
      });
    }
    controller.addListener(_scrollListener);
    _onLoadAlbums();
  }

  @override
  void dispose() {
    controller.removeListener(_scrollListener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: DropdownButton<AssetPathEntity>(
          value: selectedAlbum,
          isExpanded: false,
          underline: Container(
            height: 2,
            color: Theme.of(context).dividerColor,
          ),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
          dropdownColor: ColorTheme.colorWhite(context),
          iconEnabledColor: Theme.of(context).primaryColor,
          onChanged: (value) => _onChangedAlbum(value),
          items: albumList.map<DropdownMenuItem<AssetPathEntity>>(
            (album) {
              return DropdownMenuItem(
                value: album,
                child: Row(
                  children: [
                    Text(
                      album.name,
                      style: TextStyle(
                        fontSize: 18,
                        color: ColorTheme.colorBlack(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FutureBuilder(
                      initialData: 0,
                      future: album.assetCountAsync,
                      builder: (context, snapshot) {
                        return Text(
                          "(${snapshot.data})",
                          style: TextStyle(
                            fontSize: 18,
                            color: ColorTheme.colorBlack(context),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ).toList(),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop(selectedAssetlist);
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Text(
                  "${Localization.getContent(key: "select")} (${selectedAssetlist.length})",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: assetList.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GridView.builder(
              controller: controller,
              physics: const BouncingScrollPhysics(),
              itemCount: assetList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemBuilder: (context, index) {
                AssetEntity assetEntity = assetList[index];
                return GestureDetector(
                  onTap: () {
                    _selectAsset(assetEntity);
                  },
                  child: AbsorbPointer(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _assetWidget(assetEntity),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _assetWidget(AssetEntity assetEntity) {
    return Stack(
      children: [
        if (assetEntity.mimeType?.toLowerCase().contains("audio") == false)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(
                selectedAssetlist.contains(assetEntity) ? 15 : 0,
              ),
              child: AssetEntityImage(
                assetEntity,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(
                  250,
                ),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.error,
                    color: Colors.red,
                  );
                },
              ),
            ),
          ),
        if (assetEntity.mimeType?.toLowerCase().contains("video") == true)
          const Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.videocam_rounded,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: selectedAssetlist.contains(assetEntity)
                    ? Colors.blue
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              child: Text(
                "${selectedAssetlist.indexOf(assetEntity) + 1}",
                style: TextStyle(
                  fontSize: 12,
                  color: selectedAssetlist.contains(assetEntity)
                      ? Colors.white
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _selectAsset(AssetEntity assetEntity) {
    if (selectedAssetlist.any(
      (element) => element.id == assetEntity.id,
    )) {
      setState(() {
        selectedAssetlist.remove(assetEntity);
      });
    } else {
      if (selectedAssetlist.length == widget.maxSelect &&
          widget.maxSelect != null) return;
      setState(() {
        selectedAssetlist.add(assetEntity);
      });
    }
  }

  void _onChangedAlbum(AssetPathEntity? value) async {
    if (selectedAlbum == value) return;
    setState(() {
      selectedAlbum = value;
    });
    totalAssets = await selectedAlbum!.assetCountAsync;
    _reset();
  }

  void _reset() {
    _scrollToTop();
    currentCount = 0;
    _onLoadAssets(isClear: true);
  }
}

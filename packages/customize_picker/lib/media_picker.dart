import 'package:customize_picker/color_theme.dart';
import 'package:customize_picker/localization.dart';
import 'package:customize_picker/media_picker_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
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
  List<AssetEntity> assetList = [];
  ScrollController controller = ScrollController();
  int currentCount = 0;
  bool loadMoreValue = false;
  int totalAssets = 0;
  MediaPickerModel mediaPickerModel = MediaPickerModel();
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
        mediaPickerModel.selectedAssetlist.addAll(widget.selectedAssetlist!);
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: mediaPickerModel,
        ),
      ],
      child: Scaffold(
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
            focusColor: ColorTheme.colorBlack(context),
            dropdownColor: ColorTheme.colorBlack(context),
            iconEnabledColor: ColorTheme.colorBlack(context),
            onChanged: (value) => _onChangedAlbum(value),
            selectedItemBuilder: (BuildContext context) {
              return albumList.map<Widget>((AssetPathEntity item) {
                return Row(
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 18,
                        color: ColorTheme.colorBlack(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FutureBuilder(
                      initialData: 0,
                      future: item.assetCountAsync,
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
                );
              }).toList();
            },
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
                          color: ColorTheme.colorWhite(context),
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
                              color: ColorTheme.colorWhite(context),
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
                Navigator.of(context).pop(mediaPickerModel.selectedAssetlist);
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Selector<MediaPickerModel, int>(
                    shouldRebuild: (previous, next) => previous != next,
                    selector: (p0, p1) {
                      return p1.selectedAssetlist.length;
                    },
                    builder: (context, totalCount, child) {
                      return Text(
                        "${Localization.getContent(key: "select")} ($totalCount)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      );
                    },
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
                  return Selector<MediaPickerModel, bool>(
                    selector: (p0, p1) {
                      return p1.selectedAssetlist.contains(assetEntity);
                    },
                    shouldRebuild: (previous, next) => previous != next,
                    builder: (context, value, child) {
                      return GestureDetector(
                        key: ValueKey(assetEntity),
                        onTap: () {
                          mediaPickerModel.selectAsset(
                              assetEntity, widget.maxSelect);
                        },
                        child: AbsorbPointer(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _assetWidget(assetEntity),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
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
                mediaPickerModel.selectedAssetlist.contains(assetEntity)
                    ? 15
                    : 0,
              ),
              child: FutureBuilder<Uint8List?>(
                future: assetEntity.thumbnailDataWithSize(
                  const ThumbnailSize(200, 200),
                  quality: 60,
                ),
                key: ValueKey(assetEntity),
                initialData: null,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  return SizedBox(
                    key: ValueKey(assetEntity),
                    width: 200,
                    height: 200,
                    child: Image.memory(
                      key: ValueKey(assetEntity),
                      snapshot.data!,
                      cacheHeight: 200,
                      cacheWidth: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error);
                      },
                    ),
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
                color: mediaPickerModel.selectedAssetlist.contains(assetEntity)
                    ? Colors.blue
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              child: Text(
                "${mediaPickerModel.selectedAssetlist.indexOf(assetEntity) + 1}",
                style: TextStyle(
                  fontSize: 12,
                  color:
                      mediaPickerModel.selectedAssetlist.contains(assetEntity)
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

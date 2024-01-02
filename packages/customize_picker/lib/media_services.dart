import 'package:photo_manager/photo_manager.dart';

class MediaServcies {
  Future loadAlbums(RequestType requestType) async {
    var permission = await PhotoManager.requestPermissionExtend();
    List<AssetPathEntity> albumList = [];
    if (permission.isAuth) {
      albumList = await PhotoManager.getAssetPathList(
        type: requestType,
      );
    } else {
      PhotoManager.openSetting();
    }
    return albumList;
  }

  Future<List<AssetEntity>> loadAssets({
    int? start,
    required AssetPathEntity selectedAlbum,
  }) async {
    final totalCount = await selectedAlbum.assetCountAsync;
    if ((start ?? 0) >= totalCount) {
      return <AssetEntity>[];
    }
    List<AssetEntity> assetList = await selectedAlbum.getAssetListRange(
      start: start ?? 0,
      end: totalCount + 1,
    );
    return assetList;
  }
}

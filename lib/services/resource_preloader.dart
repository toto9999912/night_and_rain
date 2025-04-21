import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// 資源預載入服務，負責在遊戲開始前載入所有需要的資源
class ResourcePreloader {
  // 載入進度
  double _progress = 0;
  double get progress => _progress;

  // 載入狀態
  String _status = "準備載入資源...";
  String get status => _status;

  // 資源載入是否完成
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // 回調函數，用於通知外部更新載入進度
  final void Function(double progress, String status)? onProgressUpdate;

  // 需要預先載入的圖片資源
  final List<String> _imageAssets = [
    'assets/images/player.png',
    'assets/images/menu_title.png',
    'assets/images/village.png',
    'assets/images/item_pack.png',
    'assets/images/knight_idle.png',
  ];

  // 需要預先載入的其他資源 (字體等)
  final List<String> _otherAssets = ['fonts/Cubic_11.ttf'];

  ResourcePreloader({this.onProgressUpdate});

  /// 預載入所有遊戲資源
  Future<void> preloadResources() async {
    try {
      // 總資源數（用於計算進度）
      int totalAssets = _imageAssets.length + _otherAssets.length;
      int loadedAssets = 0;

      // 載入所有圖片資源
      for (final image in _imageAssets) {
        _updateStatus("載入圖片: ${_getFileName(image)}");
        await Flame.images.load(image.replaceAll('assets/images/', ''));
        loadedAssets++;
        _updateProgress(loadedAssets / totalAssets);
        await Future.delayed(const Duration(milliseconds: 100)); // 延遲，使載入動畫更流暢
      }

      // 載入所有精靈圖
      _updateStatus("載入物品精靈圖...");
      final itemSpriteSheet = await _loadSpriteSheet(
        'item_pack.png',
        Vector2(24, 24),
      );
      loadedAssets++;
      _updateProgress(loadedAssets / totalAssets);
      await Future.delayed(const Duration(milliseconds: 100));

      // 載入其他資源 (字體等)
      for (final asset in _otherAssets) {
        _updateStatus("載入資源: ${_getFileName(asset)}");
        // 對於字體，實際上 Flutter 已經包含在資源中，不需要額外載入
        // 但為了顯示載入進度，我們模擬一個載入過程
        await Future.delayed(const Duration(milliseconds: 200));
        loadedAssets++;
        _updateProgress(loadedAssets / totalAssets);
      }

      // 預載入系統完成
      _updateStatus("資源載入完成");
      _isLoaded = true;
      _updateProgress(1.0);

      // 額外延遲，確保用戶看到載入完成的狀態
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      _updateStatus("載入資源時發生錯誤: $e");
      print("預載入資源時發生錯誤: $e");
      rethrow;
    }
  }

  /// 載入精靈圖
  Future<SpriteSheet> _loadSpriteSheet(
    String imageName,
    Vector2 srcSize,
  ) async {
    final image = await Flame.images.load(imageName);
    return SpriteSheet(image: image, srcSize: srcSize);
  }

  /// 更新載入狀態
  void _updateStatus(String status) {
    _status = status;
    if (onProgressUpdate != null) {
      onProgressUpdate!(_progress, _status);
    }
  }

  /// 更新載入進度
  void _updateProgress(double progress) {
    _progress = progress;
    if (onProgressUpdate != null) {
      onProgressUpdate!(_progress, _status);
    }
  }

  /// 從資源路徑中取得檔案名稱
  String _getFileName(String path) {
    return path.split('/').last;
  }
}

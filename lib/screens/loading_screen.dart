import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../services/resource_preloader.dart';
import '../main.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  // 資源預載入服務
  late ResourcePreloader _resourcePreloader;

  // 載入進度和狀態
  double _progress = 0;
  String _status = "初始化...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 初始化資源預載入服務
    _resourcePreloader = ResourcePreloader(
      onProgressUpdate: (progress, status) {
        setState(() {
          _progress = progress;
          _status = status;
        });
      },
    );

    // 開始載入資源
    _startLoading();
  }

  // 開始載入資源
  Future<void> _startLoading() async {
    try {
      // 等待資源預載入完成
      await _resourcePreloader.preloadResources();

      // 預載入完成後，將載入狀態設為false
      setState(() {
        _isLoading = false;
      });

      // 等待一小段時間後進入遊戲
      Timer(const Duration(seconds: 1), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameWidget(game: NightAndRainGame()),
          ),
        );
      });
    } catch (e) {
      print("載入遊戲資源時發生錯誤: $e");
      // 顯示錯誤提示
      setState(() {
        _status = "載入失敗: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/village.png'),
              fit: BoxFit.cover,
              opacity: 0.5,
              colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 標題
              const Text(
                "夜與雨",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.blue,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // 載入中動畫
              if (_isLoading) ...[
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: Colors.lightBlue,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ] else ...[
                // 載入完成圖標
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 50,
                ),
              ],

              const SizedBox(height: 30),

              // 載入狀態
              Text(
                _status,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),

              const SizedBox(height: 20),

              // 進度條
              Container(
                width: 300,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.black45,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 進度百分比
              Text(
                "${(_progress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),

              const SizedBox(height: 50),

              // 提示文字
              const Text(
                "正在準備您的冒險之旅...",
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'scenario_selection_screen.dart';
import '../main.dart'; // 導入 GameScreen

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  // 添加動畫控制器
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化動畫控制器
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // 浮動動畫 - 用於標題上下輕微浮動
    _floatAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 發光動畫 - 用於調整標題的發光強度
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/village.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 替換文字標題為帶動畫的圖片標題
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: SizedBox(
                      width: 600,

                      child: const Image(
                        image: AssetImage('assets/images/menu_title.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),

              _buildMenuButton('劇本選擇', () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ScenarioSelectionScreen(),
                  ),
                );
              }),
              const SizedBox(height: 20),
              _buildMenuButton('特別企劃', () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GameWidget(game: NightAndRainGame()),
                  ),
                );
              }),

              const SizedBox(height: 20),
              _buildMenuButton('成就', () {
                _showAchievementsDialog(context);
              }),
              const SizedBox(height: 20),
              _buildMenuButton('離開', () {
                SystemNavigator.pop();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        backgroundColor: Colors.blue.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white70, width: 2),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAchievementsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.blue.shade900.withValues(alpha: 0.9),
            title: const Text(
              '成就列表',
              style: TextStyle(color: Colors.white, fontSize: 24),
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildAchievement('音癡?歌神?', '你成功偷錄下來夜唱的歌，他會恨你一輩子', false),
                  _buildAchievement(
                    '夜不在深，有燈則明',
                    '你居然在遊戲中實踐了發光體(他一定上輩子造孽，否則怎麼會認識妳這個大冤種)',
                    false,
                  ),
                  _buildAchievement('重來一次，還是選妳!', '他固然有他的旅程，但若無妳，', false),
                  _buildAchievement('交際能手', '與所有NPC對話', false),
                  _buildAchievement('大冒險家', '探索完整個地圖', false),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  '關閉',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildAchievement(String title, String description, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: unlocked ? Colors.amber : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.emoji_events : Icons.lock,
            color: unlocked ? Colors.amber : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: unlocked ? Colors.amber : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

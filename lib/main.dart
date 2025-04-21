import 'dart:math' as math;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/flame.dart';

import 'bullet.dart';
import 'npc.dart';
import 'player.dart';
import 'ui/health_mana_hud.dart';
import 'ui/hotkeys_hud.dart';
import 'ui/current_weapon_hud.dart';
import 'village_map.dart';
import 'screens/main_menu_screen.dart';
import 'models/enums.dart';

// 引入新創建的管理器和系統類
import 'managers/input_manager.dart';
import 'managers/ui_manager.dart';
import 'managers/npc_manager.dart';
import 'managers/bullet_manager.dart';
import 'systems/collision_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  runApp(const NightAndRainApp());
}

class NightAndRainApp extends StatelessWidget {
  const NightAndRainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Night and Rain',
      theme: ThemeData(
        fontFamily: 'Cubic11',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

/// 主遊戲類 - 現在只做頂層協調，實際功能由各個管理器和系統實現
class NightAndRainGame extends FlameGame with KeyboardEvents, MouseMovementDetector, TapDetector {
  // 主要遊戲元素
  late final Player player;
  late final CameraComponent cameraComponent;
  late final GameWorld gameWorld;
  late final HotkeysHud hotkeysHud; // 仍需要保留，因為很多地方引用

  // 設置
  final Vector2 mapSize = Vector2(3000, 3000);
  Vector2 mousePosition = Vector2.zero();

  // 各類管理器和系統
  late final InputManager inputManager;
  late final UIManager uiManager;

  // 標記UI是否已初始化
  bool _uiInitialized = false;

  @override
  Future<void> onLoad() async {
    await _setupGameWorld();
    await _setupPlayer();
    await _setupCamera();
    await _setupManagers();

    // 只創建 UI 組件但暫不添加到遊戲組件樹
    player.inventory.prepareUIComponents();

    await super.onLoad();

    // 在所有組件加載完成後，添加 UI 組件到遊戲組件樹
    await _initializeUIComponents();
  }

  /// 在所有組件加載完成後初始化 UI 組件
  Future<void> _initializeUIComponents() async {
    // 添加玩家的 UI 組件到遊戲組件樹
    await player.inventory.addUIComponentsToGame();
    _uiInitialized = true;
  }

  /// 設置遊戲世界和所有地圖相關組件
  Future<void> _setupGameWorld() async {
    gameWorld = GameWorld(mapSize);
    add(gameWorld);
  }

  /// 設置玩家角色
  Future<void> _setupPlayer() async {
    player = Player(mapSize);
    gameWorld.add(player);
  }

  /// 設置遊戲相機
  Future<void> _setupCamera() async {
    cameraComponent = CameraComponent(world: gameWorld)..viewfinder.anchor = Anchor.center;
    add(cameraComponent);
    cameraComponent.follow(player);
  }

  /// 設置各種管理器和系統
  Future<void> _setupManagers() async {
    inputManager = InputManager(this);
    uiManager = UIManager(this);

    // 初始化熱鍵系統
    hotkeysHud = HotkeysHud();
    await add(hotkeysHud);

    // 初始化當前武器顯示
    CurrentWeaponHud currentWeaponHud = CurrentWeaponHud();
    await add(currentWeaponHud);

    // 設置玩家武器變更事件通知
    player.onWeaponsChanged = () {
      // 當玩家武器清單發生變化時更新熱鍵系統
      hotkeysHud.updateWeaponReferences();

      // 不需要顯式更新 currentWeaponHud，因為它會自動檢測變化
    };
  }

  /// 顯示一條消息在螢幕上 - 代理到UI管理器
  void showMessage(String message, {double duration = 2.0}) {
    uiManager.showMessage(message, duration: duration);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    return inputManager.handleKeyEvent(event, keysPressed);
  }

  // 處理滑鼠移動 - 代理到輸入管理器
  @override
  void onMouseMove(PointerHoverInfo info) {
    inputManager.handleMouseMove(info);
  }

  // 處理點擊/觸摸 - 代理到輸入管理器
  @override
  void onTapDown(TapDownInfo info) {
    inputManager.handleTapDown(info);
  }

  @override
  void onTapUp(TapUpInfo info) {
    inputManager.handleTapUp(info);
  }

  @override
  void update(double dt) {
    super.update(dt);
    uiManager.update(dt);
  }
}

/// 遊戲世界 - 整合了新的管理器和系統
class GameWorld extends World {
  final Vector2 mapSize;
  late VillageMap villageMap;
  late CollisionSystem collisionSystem;
  late NPCManager npcManager;
  late BulletManager bulletManager;

  GameWorld(this.mapSize);

  @override
  Future<void> onLoad() async {
    await _setupMap();
    _setupSystems();
    await super.onLoad();
  }

  /// 設置地圖
  Future<void> _setupMap() async {
    villageMap = VillageMap(mapSize);
    add(villageMap);
    add(MapBorder(mapSize));
  }

  /// 設置各種系統和管理器
  void _setupSystems() {
    // 初始化碰撞系統
    collisionSystem = CollisionSystem(villageMap);

    // 初始化NPC管理器
    npcManager = NPCManager(mapSize, checkCollision);
    npcManager.spawnNPCs();

    // 將生成的NPC添加到遊戲世界
    for (final npc in npcManager.npcs) {
      add(npc);
    }

    // 初始化子彈管理器
    bulletManager = BulletManager();
  }

  /// 檢查是否與障礙物碰撞 - 代理到碰撞系統
  bool checkCollision(PositionComponent component) {
    return collisionSystem.checkCollision(component);
  }

  /// 添加子彈到遊戲世界 - 代理到子彈管理器
  void addBullet(Vector2 position, Vector2 direction, double speed, double damage, {Color? bulletColor, Vector2? bulletSize}) {
    final bullet = bulletManager.createBullet(position, direction, speed, damage, bulletColor: bulletColor, bulletSize: bulletSize);
    add(bullet);
  }

  /// 與最近的NPC互動 - 代理到NPC管理器
  NPC? interactWithNearestNPC(Vector2 playerPosition, {double maxDistance = 50.0}) {
    return npcManager.findNearestNPC(playerPosition, maxDistance: maxDistance);
  }

  @override
  void update(double dt) {
    super.update(dt);
    bulletManager.update(dt);
  }
}

/// 地圖邊界 - 視覺上顯示地圖邊界
class MapBorder extends PositionComponent {
  MapBorder(Vector2 mapSize) : super(size: mapSize);

  @override
  Future<void> onLoad() async {
    add(
      RectangleComponent(
        size: size,
        paint:
            Paint()
              ..color = Colors.red
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5.0,
      ),
    );
    await super.onLoad();
  }
}

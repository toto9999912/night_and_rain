import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/flame.dart';

import 'npc.dart';
import 'player.dart';
import 'ui/health_mana_hud.dart';
import 'ui/hotkeys_hud.dart';
import 'ui/current_weapon_hud.dart';
import 'village_map.dart';
import 'screens/main_menu_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

/// 主遊戲類 - 現在只做頂層協調，實際功能由各個管理器和系統實現
class NightAndRainGame extends FlameGame
    with KeyboardEvents, MouseMovementDetector, TapDetector {
  // 主要遊戲元素
  late final Player player;
  late final CameraComponent cameraComponent;
  late final GameWorld gameWorld;
  late final HotkeysHud hotkeysHud; // 仍需要保留，因為很多地方引用
  late final HealthManaHud healthManaHud; // 添加生命值與魔法值HUD引用

  // 設置
  final Vector2 mapSize = Vector2(3000, 3000);
  Vector2 mousePosition = Vector2.zero();

  // 各類管理器和系統
  late final InputManager inputManager;
  late final UIManager uiManager;

  // 標記UI是否已初始化
  bool _uiInitialized = false;

  // 標記遊戲是否準備好
  bool _isReady = false;
  bool get isReady => _isReady;

  // 初始化階段
  int _initStage = 0;

  @override
  Future<void> onLoad() async {
    debugPrint("遊戲初始化開始...");

    // 設置初始載入階段
    _initStage = 1;

    try {
      // 階段 1: 基礎遊戲元素設置
      await _setupGameWorld();
      _initStage = 2;

      // 階段 2: 設置玩家
      await _setupPlayer();
      player.combat.initWeapons();
      _initStage = 3;

      // 階段 3: 設置相機
      await _setupCamera();
      _initStage = 4;

      // 階段 4: 設置核心管理器
      await _setupManagersCore();
      _initStage = 5;

      // 階段 5: 調用 super.onLoad()
      await super.onLoad();
      _initStage = 6;

      // 階段 6: 初始化玩家UI組件
      await _initializePlayerUIComponents();
      _initStage = 7;

      // 階段 7: 初始化熱鍵和武器HUD
      await _initializeHotkeys();
      _initStage = 8;

      // 階段 8: 初始化生命值與魔法值HUD
      await _initializeHealthManaHud();
      _initStage = 9;

      // 設置標記
      _uiInitialized = true;
      _isReady = true;

      debugPrint("遊戲初始化完成，所有系統已就緒");
    } catch (e) {
      debugPrint("遊戲初始化失敗(階段 $_initStage): $e");
      rethrow;
    }
  }

  /// 核心管理器設置 - 不包含需要玩家引用的部分
  Future<void> _setupManagersCore() async {
    debugPrint("設置核心管理器...");
    inputManager = InputManager(this);
    uiManager = UIManager(this);
    debugPrint("核心管理器設置完成");
  }

  /// 設置遊戲世界和所有地圖相關組件
  Future<void> _setupGameWorld() async {
    debugPrint("設置遊戲世界...");
    gameWorld = GameWorld(mapSize);
    await add(gameWorld);
    debugPrint("遊戲世界設置完成");
  }

  /// 設置玩家角色
  Future<void> _setupPlayer() async {
    debugPrint("設置玩家角色...");
    player = Player(mapSize);
    gameWorld.add(player);
    debugPrint("玩家角色設置完成");
  }

  /// 設置遊戲相機
  Future<void> _setupCamera() async {
    debugPrint("設置遊戲相機...");
    cameraComponent = CameraComponent(world: gameWorld)
      ..viewfinder.anchor = Anchor.center;
    await add(cameraComponent);
    cameraComponent.follow(player);
    debugPrint("遊戲相機設置完成");
  }

  /// 完整初始化玩家UI組件
  Future<void> _initializePlayerUIComponents() async {
    debugPrint("開始初始化玩家UI組件...");
    try {
      // 準備UI組件
      player.inventory.initInventory();
      player.inventory.initEquipment();
      player.inventory.prepareUIComponents();

      // 添加UI組件到遊戲，並等待其完成
      await player.inventory.addUIComponentsToGame();
      debugPrint("玩家UI組件初始化完成");
    } catch (e) {
      debugPrint("初始化玩家UI組件時發生錯誤: $e");
      rethrow;
    }
  }

  Future<void> _initializeHotkeys() async {
    debugPrint("初始化熱鍵系統...");
    try {
      // 初始化熱鍵系統
      hotkeysHud = HotkeysHud();
      await cameraComponent.viewport.add(hotkeysHud);

      // 初始化當前武器顯示
      CurrentWeaponHud currentWeaponHud = CurrentWeaponHud();
      await cameraComponent.viewport.add(currentWeaponHud);

      // 设置玩家武器变更事件通知
      player.onWeaponsChanged = () {
        hotkeysHud.updateWeaponReferences();
      };

      hotkeysHud.updateWeaponReferences();
      debugPrint("熱鍵系統初始化完成");
    } catch (e) {
      debugPrint("初始化熱鍵系統時發生錯誤: $e");
      rethrow;
    }
  }

  Future<void> _initializeHealthManaHud() async {
    debugPrint("初始化生命值與魔法值HUD...");
    try {
      healthManaHud = HealthManaHud(player: player);
      await cameraComponent.viewport.add(healthManaHud); // 修改这里
      debugPrint("生命值與魔法值HUD初始化完成");
    } catch (e) {
      debugPrint("初始化生命值與魔法值HUD時發生錯誤: $e");
      rethrow;
    }
  }

  /// 顯示一條消息在螢幕上 - 代理到UI管理器
  void showMessage(String message, {double duration = 2.0}) {
    uiManager.showMessage(message, duration: duration);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
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
    if (_isReady) {
      uiManager.update(dt);
    }
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
  void addBullet(
    Vector2 position,
    Vector2 direction,
    double speed,
    double damage, {
    Color? bulletColor,
    Vector2? bulletSize,
  }) {
    final bullet = bulletManager.createBullet(
      position,
      direction,
      speed,
      damage,
      bulletColor: bulletColor,
      bulletSize: bulletSize,
    );
    add(bullet);
  }

  /// 與最近的NPC互動 - 代理到NPC管理器
  NPC? interactWithNearestNPC(
    Vector2 playerPosition, {
    double maxDistance = 50.0,
  }) {
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

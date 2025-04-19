class ScenarioData {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String duration;
  final String thumbnail;
  final bool locked;

  ScenarioData({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.duration,
    required this.thumbnail,
    this.locked = false,
  });
}

// 預設主線劇本數據
class MainScenarios {
  static List<ScenarioData> getMainScenarios() {
    return [
      ScenarioData(
        id: 'main1',
        title: '星界神話!啟程',
        description: '兩個ㄎㄧㄤㄎㄧㄤ的人莫名其妙的認識',
        difficulty: '簡單',
        duration: '約2小時',
        thumbnail: 'assets/images/player.png', // 使用現有圖片
        locked: false,
      ),
      ScenarioData(
        id: 'main2',
        title: '訊息大樓告急！懶蟲大軍襲來',
        description:
            '這鬼斧神工的訊息大樓據說是由兩個傳奇建築家在無數個夜晚搭建\n如今受到米蟲教邪惡的激進派蠱惑，曾經辛勤的訊息大樓小尖兵們如今成了行屍走肉般的懶蟲。',
        difficulty: '惡夢',
        duration: '約3小時',
        thumbnail: 'assets/images/player.png',
        locked: true,
      ),
      ScenarioData(
        id: 'main3',
        title: 'ＲＣ走音符',
        description: '曾經有一個傳奇智者掉進了',
        difficulty: '極難',
        duration: '約2.5小時',
        thumbnail: 'assets/images/player.png',
        locked: true,
      ),
    ];
  }
}

// 預設支線劇本數據
class SideScenarios {
  static List<ScenarioData> getSideScenarios() {
    return [
      ScenarioData(
        id: 'side1',
        title: '訊息大樓告急！懶蟲大軍襲來',
        description: '幫助村莊的商人找回被盜的貨物。',
        difficulty: '簡單',
        duration: '約30分鐘',
        thumbnail: 'assets/images/player.png',
        locked: false,
      ),
      ScenarioData(
        id: 'side2',
        title: '神秘的洞穴',
        description: '探索村莊附近的神秘洞穴，發現隱藏寶藏。',
        difficulty: '中等',
        duration: '約45分鐘',
        thumbnail: 'assets/images/player.png',
        locked: false,
      ),
      ScenarioData(
        id: 'side3',
        title: '失落的記憶',
        description: '協助一位失憶的旅人尋找自己的過去。',
        difficulty: '中等',
        duration: '約1小時',
        thumbnail: 'assets/images/player.png',
        locked: true,
      ),
    ];
  }
}

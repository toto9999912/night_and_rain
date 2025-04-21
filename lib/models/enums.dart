/// 遊戲中所有的枚舉類型定義

/// NPC類型枚舉 - 用於更容易地生成特定類型的NPC
enum NPCType { villager, merchant, guard }

/// 熱鍵物品類型枚舉
enum HotkeyItemType { empty, weapon, consumable }

/// 游戲事件類型枚舉
enum GameEventType { playerDamaged, npcInteraction, itemCollected, levelUp, questCompleted }

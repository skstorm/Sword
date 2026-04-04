/// 통계 데이터 — 랭킹 산출 및 업적 판정에 사용
class Statistics {
  final int highestEnhanceLevel;
  final int weeklyHighestLevel;
  final int totalDestroys;
  final int totalEnhanceAttempts;
  final int totalSells;
  final int totalGoldEarned;
  final int maxConsecutiveSuccess;
  final int maxConsecutiveFail;
  final int currentConsecutiveSuccess;
  final int currentConsecutiveFail;

  const Statistics({
    this.highestEnhanceLevel = 0,
    this.weeklyHighestLevel = 0,
    this.totalDestroys = 0,
    this.totalEnhanceAttempts = 0,
    this.totalSells = 0,
    this.totalGoldEarned = 0,
    this.maxConsecutiveSuccess = 0,
    this.maxConsecutiveFail = 0,
    this.currentConsecutiveSuccess = 0,
    this.currentConsecutiveFail = 0,
  });

  Statistics copyWith({
    int? highestEnhanceLevel,
    int? weeklyHighestLevel,
    int? totalDestroys,
    int? totalEnhanceAttempts,
    int? totalSells,
    int? totalGoldEarned,
    int? maxConsecutiveSuccess,
    int? maxConsecutiveFail,
    int? currentConsecutiveSuccess,
    int? currentConsecutiveFail,
  }) {
    return Statistics(
      highestEnhanceLevel: highestEnhanceLevel ?? this.highestEnhanceLevel,
      weeklyHighestLevel: weeklyHighestLevel ?? this.weeklyHighestLevel,
      totalDestroys: totalDestroys ?? this.totalDestroys,
      totalEnhanceAttempts: totalEnhanceAttempts ?? this.totalEnhanceAttempts,
      totalSells: totalSells ?? this.totalSells,
      totalGoldEarned: totalGoldEarned ?? this.totalGoldEarned,
      maxConsecutiveSuccess:
          maxConsecutiveSuccess ?? this.maxConsecutiveSuccess,
      maxConsecutiveFail: maxConsecutiveFail ?? this.maxConsecutiveFail,
      currentConsecutiveSuccess:
          currentConsecutiveSuccess ?? this.currentConsecutiveSuccess,
      currentConsecutiveFail:
          currentConsecutiveFail ?? this.currentConsecutiveFail,
    );
  }
}

/// 장인 숙련도 데이터 (P2에서 상세 구현)
class MasteryData {
  final int level;
  final int totalAttempts;

  const MasteryData({this.level = 1, this.totalAttempts = 0});

  MasteryData copyWith({int? level, int? totalAttempts}) {
    return MasteryData(
      level: level ?? this.level,
      totalAttempts: totalAttempts ?? this.totalAttempts,
    );
  }
}

/// 컬렉션 데이터 (P2에서 상세 구현)
class CollectionData {
  final Map<int, int> collected;

  const CollectionData({this.collected = const {}});

  int get uniqueCount => collected.length;
  int get totalCollectible => 11;
  double get completionRate =>
      totalCollectible == 0 ? 0 : uniqueCount / totalCollectible;

  CollectionData copyWith({Map<int, int>? collected}) {
    return CollectionData(collected: collected ?? this.collected);
  }
}

/// 보유 아이템 (P2에서 상세 구현)
class Inventory {
  final int protectionAmulets;
  final int blessingScrolls;

  const Inventory({this.protectionAmulets = 0, this.blessingScrolls = 0});

  Inventory copyWith({int? protectionAmulets, int? blessingScrolls}) {
    return Inventory(
      protectionAmulets: protectionAmulets ?? this.protectionAmulets,
      blessingScrolls: blessingScrolls ?? this.blessingScrolls,
    );
  }
}

/// 광고 일일 제한 (P2에서 상세 구현)
class AdLimits {
  final int adProtectionUsedToday;
  final DateTime lastResetDate;

  AdLimits({
    this.adProtectionUsedToday = 0,
    DateTime? lastResetDate,
  }) : lastResetDate = lastResetDate ?? DateTime(2000);

  AdLimits copyWith({int? adProtectionUsedToday, DateTime? lastResetDate}) {
    return AdLimits(
      adProtectionUsedToday:
          adProtectionUsedToday ?? this.adProtectionUsedToday,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }
}

/// 업적 데이터 (P3에서 상세 구현)
class AchievementData {
  final Set<String> achieved;

  const AchievementData({this.achieved = const {}});

  AchievementData copyWith({Set<String>? achieved}) {
    return AchievementData(achieved: achieved ?? this.achieved);
  }
}

/// 칭호 데이터 (P3에서 상세 구현)
class TitleData {
  final Set<String> earned;
  final String? equipped;

  const TitleData({this.earned = const {}, this.equipped});

  TitleData copyWith({Set<String>? earned, String? equipped}) {
    return TitleData(
      earned: earned ?? this.earned,
      equipped: equipped ?? this.equipped,
    );
  }
}

/// 유저 데이터 통합
class PlayerData {
  final int gold;
  final Statistics stats;
  final int fragments;
  final MasteryData mastery;
  final CollectionData collection;
  final Inventory inventory;
  final AdLimits adLimits;
  final AchievementData achievements;
  final TitleData titles;
  final String nickname;
  final bool isFirstRun;
  final DateTime lastSyncedAt;

  PlayerData({
    this.gold = 0,
    this.stats = const Statistics(),
    this.fragments = 0,
    this.mastery = const MasteryData(),
    this.collection = const CollectionData(),
    this.inventory = const Inventory(),
    AdLimits? adLimits,
    this.achievements = const AchievementData(),
    this.titles = const TitleData(),
    this.nickname = '',
    this.isFirstRun = true,
    DateTime? lastSyncedAt,
  })  : adLimits = adLimits ?? AdLimits(),
        lastSyncedAt = lastSyncedAt ?? DateTime(2000);

  PlayerData copyWith({
    int? gold,
    Statistics? stats,
    int? fragments,
    MasteryData? mastery,
    CollectionData? collection,
    Inventory? inventory,
    AdLimits? adLimits,
    AchievementData? achievements,
    TitleData? titles,
    String? nickname,
    bool? isFirstRun,
    DateTime? lastSyncedAt,
  }) {
    return PlayerData(
      gold: gold ?? this.gold,
      stats: stats ?? this.stats,
      fragments: fragments ?? this.fragments,
      mastery: mastery ?? this.mastery,
      collection: collection ?? this.collection,
      inventory: inventory ?? this.inventory,
      adLimits: adLimits ?? this.adLimits,
      achievements: achievements ?? this.achievements,
      titles: titles ?? this.titles,
      nickname: nickname ?? this.nickname,
      isFirstRun: isFirstRun ?? this.isFirstRun,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

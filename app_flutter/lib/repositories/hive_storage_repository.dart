import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:game_core/game_core.dart';

/// P2-33: 로컬 저장소 구현 (Hive)
class HiveStorageRepository implements StorageRepository {
  static const String _boxName = 'player_data';
  static const String _key = 'data';

  Box? _box;

  Future<Box> _getBox() async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<PlayerData> load() async {
    final box = await _getBox();
    final jsonStr = box.get(_key) as String?;
    if (jsonStr == null) return PlayerData();
    return _fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  @override
  Future<void> save(PlayerData data) async {
    final box = await _getBox();
    await box.put(_key, jsonEncode(_toJson(data)));
  }

  /// PlayerData → JSON Map
  static Map<String, dynamic> _toJson(PlayerData data) {
    return {
      'gold': data.gold,
      'fragments': data.fragments,
      'nickname': data.nickname,
      'isFirstRun': data.isFirstRun,
      'lastSyncedAt': data.lastSyncedAt.toIso8601String(),
      'stats': _statsToJson(data.stats),
      'mastery': _masteryToJson(data.mastery),
      'collection': _collectionToJson(data.collection),
      'inventory': _inventoryToJson(data.inventory),
      'adLimits': _adLimitsToJson(data.adLimits),
      'achievements': _achievementsToJson(data.achievements),
      'titles': _titlesToJson(data.titles),
    };
  }

  /// JSON Map → PlayerData
  static PlayerData _fromJson(Map<String, dynamic> json) {
    return PlayerData(
      gold: json['gold'] as int? ?? 0,
      fragments: json['fragments'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      isFirstRun: json['isFirstRun'] as bool? ?? true,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      stats: json['stats'] != null
          ? _statsFromJson(json['stats'] as Map<String, dynamic>)
          : const Statistics(),
      mastery: json['mastery'] != null
          ? _masteryFromJson(json['mastery'] as Map<String, dynamic>)
          : const MasteryData(),
      collection: json['collection'] != null
          ? _collectionFromJson(json['collection'] as Map<String, dynamic>)
          : const CollectionData(),
      inventory: json['inventory'] != null
          ? _inventoryFromJson(json['inventory'] as Map<String, dynamic>)
          : const Inventory(),
      adLimits: json['adLimits'] != null
          ? _adLimitsFromJson(json['adLimits'] as Map<String, dynamic>)
          : null,
      achievements: json['achievements'] != null
          ? _achievementsFromJson(json['achievements'] as Map<String, dynamic>)
          : const AchievementData(),
      titles: json['titles'] != null
          ? _titlesFromJson(json['titles'] as Map<String, dynamic>)
          : const TitleData(),
    );
  }

  // --- Statistics ---
  static Map<String, dynamic> _statsToJson(Statistics s) => {
        'highestEnhanceLevel': s.highestEnhanceLevel,
        'weeklyHighestLevel': s.weeklyHighestLevel,
        'totalDestroys': s.totalDestroys,
        'totalEnhanceAttempts': s.totalEnhanceAttempts,
        'totalSells': s.totalSells,
        'totalGoldEarned': s.totalGoldEarned,
        'maxConsecutiveSuccess': s.maxConsecutiveSuccess,
        'maxConsecutiveFail': s.maxConsecutiveFail,
        'currentConsecutiveSuccess': s.currentConsecutiveSuccess,
        'currentConsecutiveFail': s.currentConsecutiveFail,
      };

  static Statistics _statsFromJson(Map<String, dynamic> j) => Statistics(
        highestEnhanceLevel: j['highestEnhanceLevel'] as int? ?? 0,
        weeklyHighestLevel: j['weeklyHighestLevel'] as int? ?? 0,
        totalDestroys: j['totalDestroys'] as int? ?? 0,
        totalEnhanceAttempts: j['totalEnhanceAttempts'] as int? ?? 0,
        totalSells: j['totalSells'] as int? ?? 0,
        totalGoldEarned: j['totalGoldEarned'] as int? ?? 0,
        maxConsecutiveSuccess: j['maxConsecutiveSuccess'] as int? ?? 0,
        maxConsecutiveFail: j['maxConsecutiveFail'] as int? ?? 0,
        currentConsecutiveSuccess: j['currentConsecutiveSuccess'] as int? ?? 0,
        currentConsecutiveFail: j['currentConsecutiveFail'] as int? ?? 0,
      );

  // --- MasteryData ---
  static Map<String, dynamic> _masteryToJson(MasteryData m) => {
        'level': m.level,
        'totalAttempts': m.totalAttempts,
      };

  static MasteryData _masteryFromJson(Map<String, dynamic> j) => MasteryData(
        level: j['level'] as int? ?? 1,
        totalAttempts: j['totalAttempts'] as int? ?? 0,
      );

  // --- CollectionData ---
  static Map<String, dynamic> _collectionToJson(CollectionData c) => {
        'collected':
            c.collected.map((k, v) => MapEntry(k.toString(), v)),
      };

  static CollectionData _collectionFromJson(Map<String, dynamic> j) {
    final raw = j['collected'] as Map<String, dynamic>? ?? {};
    final collected = raw.map((k, v) => MapEntry(int.parse(k), v as int));
    return CollectionData(collected: collected);
  }

  // --- Inventory ---
  static Map<String, dynamic> _inventoryToJson(Inventory i) => {
        'protectionAmulets': i.protectionAmulets,
        'blessingScrolls': i.blessingScrolls,
      };

  static Inventory _inventoryFromJson(Map<String, dynamic> j) => Inventory(
        protectionAmulets: j['protectionAmulets'] as int? ?? 0,
        blessingScrolls: j['blessingScrolls'] as int? ?? 0,
      );

  // --- AdLimits ---
  static Map<String, dynamic> _adLimitsToJson(AdLimits a) => {
        'adProtectionUsedToday': a.adProtectionUsedToday,
        'lastResetDate': a.lastResetDate.toIso8601String(),
      };

  static AdLimits _adLimitsFromJson(Map<String, dynamic> j) => AdLimits(
        adProtectionUsedToday: j['adProtectionUsedToday'] as int? ?? 0,
        lastResetDate: j['lastResetDate'] != null
            ? DateTime.parse(j['lastResetDate'] as String)
            : null,
      );

  // --- AchievementData ---
  static Map<String, dynamic> _achievementsToJson(AchievementData a) => {
        'achieved': a.achieved.toList(),
      };

  static AchievementData _achievementsFromJson(Map<String, dynamic> j) {
    final list = (j['achieved'] as List<dynamic>?)?.cast<String>() ?? [];
    return AchievementData(achieved: list.toSet());
  }

  // --- TitleData ---
  static Map<String, dynamic> _titlesToJson(TitleData t) => {
        'earned': t.earned.toList(),
        'equipped': t.equipped,
      };

  static TitleData _titlesFromJson(Map<String, dynamic> j) {
    final list = (j['earned'] as List<dynamic>?)?.cast<String>() ?? [];
    return TitleData(
      earned: list.toSet(),
      equipped: j['equipped'] as String?,
    );
  }

  // Public serialization for SyncedRepository
  static Map<String, dynamic> toJsonPublic(PlayerData data) => _toJson(data);
  static PlayerData fromJsonPublic(Map<String, dynamic> json) =>
      _fromJson(json);
}

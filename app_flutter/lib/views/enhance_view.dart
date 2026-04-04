import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import '../bindings/game_binding.dart';
import 'widgets/sword_display_widget.dart';
import 'widgets/gold_indicator_widget.dart';

class EnhanceView extends ConsumerStatefulWidget {
  const EnhanceView({super.key});

  @override
  ConsumerState<EnhanceView> createState() => _EnhanceViewState();
}

class _EnhanceViewState extends ConsumerState<EnhanceView> {
  StreamSubscription<GameEvent>? _eventSubscription;
  String _resultMessage = '';
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    final engine = await ref.read(gameEngineProvider.future);
    ref.read(gameStateProvider.notifier).state = engine.state;
    _eventSubscription = engine.events.listen(_handleGameEvent);
  }

  void _handleGameEvent(GameEvent event) {
    if (event is EnhanceSuccessEvent) {
      setState(() => _resultMessage = '강화 성공! +${event.newLevel} ${event.newSwordName}');
      _playSuccessAnimation(event.prevLevel, event.newLevel);
    } else if (event is EnhanceFailEvent) {
      if (event.destroyed && event.adProtectionAvailable) {
        setState(() => _resultMessage = '강화 실패! 검이 파괴되었습니다...');
        _showAdProtectionDialog();
      } else if (event.destroyed) {
        setState(() => _resultMessage = '강화 실패! 검이 파괴되었습니다...');
        _playDestroyAnimation(event.destroyedLevel);
      } else {
        setState(() => _resultMessage = '강화 실패! (보호됨)');
      }
    } else if (event is SellEvent) {
      setState(() => _resultMessage = '판매 완료! +${event.goldGained}골드');
      _playSellAnimation(event.soldLevel, event.goldGained);
    } else if (event is CollectEvent) {
      setState(() => _resultMessage = '${event.collectedSwordName} 수집 완료!');
    } else if (event is FragmentGainEvent) {
      setState(() => _resultMessage = '파편 ${event.amount}개 획득!');
    } else if (event is MasteryLevelUpEvent) {
      setState(() => _resultMessage = '장인 숙련도 Lv.${event.newLevel} 달성!');
    } else if (event is AdRewardEvent) {
      switch (event.adType) {
        case AdType.protection:
          setState(() => _resultMessage = '검이 복구되었습니다!');
        case AdType.gold:
          setState(() => _resultMessage = '200골드 획득!');
        case AdType.booster:
          setState(() => _resultMessage = '확률 부스터 적용!');
      }
    } else if (event is UseItemEvent) {
      final name = event.itemType == ItemType.protectionAmulet ? '보호의 부적' : '축복의 주문서';
      setState(() => _resultMessage = '$name 사용!');
    } else if (event is CommandRejectedEvent) {
      setState(() => _resultMessage = _getRejectionMessage(event.reason));
    }
    _syncState();
  }

  void _syncState() async {
    final engine = await ref.read(gameEngineProvider.future);
    ref.read(gameStateProvider.notifier).state = engine.state;
  }

  String _getRejectionMessage(String reason) {
    switch (reason) {
      case 'insufficient_gold': return '골드가 부족합니다';
      case 'cannot_sell_wooden_sword': return '나무 검은 판매할 수 없습니다';
      case 'max_level_reached': return '최대 레벨에 도달했습니다';
      case 'pending_ad_protection': return '파괴 복구를 먼저 결정하세요';
      case 'no_item': return '아이템이 없습니다';
      default: return '불가능한 행동입니다';
    }
  }

  void _showAdProtectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('검이 파괴되었습니다!', style: TextStyle(color: Colors.red)),
        content: const Text('광고를 보고 검을 복구하시겠습니까?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final engine = await ref.read(gameEngineProvider.future);
              engine.dispatch(WatchAdCommand(adType: AdType.protection));
              _syncState();
            },
            child: const Text('광고 보기', style: TextStyle(color: Colors.amber)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final engine = await ref.read(gameEngineProvider.future);
              engine.dispatch(ConfirmDestroyCommand());
              _syncState();
            },
            child: const Text('파괴 확정', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _playSuccessAnimation(int prevLevel, int newLevel) async {
    setState(() => _isAnimating = true);
    final animController = ref.read(enhanceAnimationProvider);
    final configTable = ref.read(animationConfigProvider);
    final config = configTable.forLevel(newLevel);
    await animController.playSuccess(prevLevel, newLevel, config);
    setState(() => _isAnimating = false);
  }

  Future<void> _playDestroyAnimation(int destroyedLevel) async {
    setState(() => _isAnimating = true);
    final animController = ref.read(enhanceAnimationProvider);
    final configTable = ref.read(animationConfigProvider);
    final config = configTable.forLevel(destroyedLevel);
    await animController.playDestroy(destroyedLevel, config);
    setState(() => _isAnimating = false);
  }

  Future<void> _playSellAnimation(int level, int goldGained) async {
    setState(() => _isAnimating = true);
    final animController = ref.read(enhanceAnimationProvider);
    await animController.playSell(level, goldGained);
    setState(() => _isAnimating = false);
  }

  Future<void> _onEnhancePressed() async {
    if (_isAnimating) return;
    final engine = (await ref.read(gameEngineProvider.future));
    setState(() { _isAnimating = true; _resultMessage = '강화 중...'; });
    final state = engine.state;
    final animController = ref.read(enhanceAnimationProvider);
    final configTable = ref.read(animationConfigProvider);
    final config = configTable.forLevel(state.currentLevel + 1);
    await animController.playEnhanceAttempt(state.currentLevel + 1, config);
    engine.dispatch(EnhanceCommand());
    _syncState();
  }

  Future<void> _onSellPressed() async {
    if (_isAnimating) return;
    final engine = (await ref.read(gameEngineProvider.future));
    engine.dispatch(SellCommand());
    _syncState();
  }

  Future<void> _onCollectPressed() async {
    if (_isAnimating) return;
    final engine = (await ref.read(gameEngineProvider.future));
    engine.dispatch(CollectCommand());
    _syncState();
  }

  Future<void> _onUseItem(ItemType type) async {
    final engine = (await ref.read(gameEngineProvider.future));
    engine.dispatch(UseItemCommand(itemType: type));
    _syncState();
  }

  Future<void> _onWatchAd(AdType type) async {
    final engine = (await ref.read(gameEngineProvider.future));
    engine.dispatch(WatchAdCommand(adType: type));
    _syncState();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: const Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final sword = gameState.currentSword;
    final level = gameState.currentLevel;
    final gold = gameState.playerData.gold;
    final fragments = gameState.playerData.fragments;
    final inv = gameState.playerData.inventory;
    final isPending = gameState.pendingAdProtection;
    final canSell = level > 0 && !isPending;
    final canCollect = level >= 10 && !isPending;
    final canEnhance = !isPending;

    String successRateText = '???';
    final swordTable = ref.watch(swordTableProvider);
    if (level < 15 && swordTable.hasValue) {
      final targetSword = swordTable.value!.getSword(level + 1);
      if (targetSword != null && targetSword.successRate != null) {
        successRateText = '${(targetSword.successRate! * 100).toStringAsFixed(1)}%';
      }
    }

    // 활성 상태 체크
    final hasProtection = gameState.hasActiveProtection;
    final hasBlessing = gameState.activeModifiers.any((m) => m is BlessingScrollModifier);
    final hasBooster = gameState.activeModifiers.any((m) => m is AdBoosterModifier);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text('대장간', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SwordDisplayWidget(name: sword.name, level: level),
              const SizedBox(height: 24),
              GoldIndicatorWidget(gold: gold, fragments: fragments),
              const SizedBox(height: 8),
              // 골드 광고 버튼
              TextButton.icon(
                onPressed: () => _onWatchAd(AdType.gold),
                icon: const Icon(Icons.play_circle, size: 16),
                label: const Text('광고 보고 200골드'),
                style: TextButton.styleFrom(foregroundColor: Colors.amber[200]),
              ),
              const SizedBox(height: 16),
              Text('성공 확률: $successRateText', style: TextStyle(fontSize: 18, color: Colors.grey[400])),
              const SizedBox(height: 16),
              // 아이템 사용 영역
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (hasProtection)
                    const Chip(label: Text('보호중'), avatar: Icon(Icons.shield, size: 18), backgroundColor: Colors.blue)
                  else
                    ActionChip(
                      avatar: const Icon(Icons.shield, size: 18),
                      label: Text('부적 (${inv.protectionAmulets})'),
                      onPressed: inv.protectionAmulets > 0 ? () => _onUseItem(ItemType.protectionAmulet) : null,
                    ),
                  if (hasBlessing)
                    const Chip(label: Text('축복중'), avatar: Icon(Icons.auto_fix_high, size: 18), backgroundColor: Colors.purple)
                  else
                    ActionChip(
                      avatar: const Icon(Icons.auto_fix_high, size: 18),
                      label: Text('주문서 (${inv.blessingScrolls})'),
                      onPressed: inv.blessingScrolls > 0 ? () => _onUseItem(ItemType.blessingScroll) : null,
                    ),
                  if (hasBooster)
                    const Chip(label: Text('부스터중'), avatar: Icon(Icons.play_circle, size: 18), backgroundColor: Colors.orange)
                  else
                    ActionChip(
                      avatar: const Icon(Icons.play_circle, size: 18),
                      label: const Text('부스터 +5%'),
                      onPressed: () => _onWatchAd(AdType.booster),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              // 결과 메시지
              SizedBox(
                height: 30,
                child: Text(
                  _resultMessage,
                  style: const TextStyle(fontSize: 16, color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              // 액션 버튼
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: (_isAnimating || !canEnhance) ? null : _onEnhancePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('강화하기'),
                  ),
                  ElevatedButton(
                    onPressed: (_isAnimating || !canSell) ? null : _onSellPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('판매하기'),
                  ),
                  if (canCollect)
                    ElevatedButton(
                      onPressed: _isAnimating ? null : _onCollectPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('수집하기'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

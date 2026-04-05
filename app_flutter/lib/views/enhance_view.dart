import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import '../bindings/game_binding.dart';
import '../bindings/game_notifier.dart';
import '../helpers/event_message.dart';
import 'widgets/sword_display_widget.dart';
import 'widgets/gold_indicator_widget.dart';
import 'widgets/item_chips_widget.dart';
import 'widgets/action_buttons_widget.dart';

class EnhanceView extends ConsumerStatefulWidget {
  const EnhanceView({super.key});

  @override
  ConsumerState<EnhanceView> createState() => _EnhanceViewState();
}

class _EnhanceViewState extends ConsumerState<EnhanceView> {
  StreamSubscription<GameEvent>? _eventSub;
  String _resultMessage = '';
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    final engine = await ref.read(gameEngineProvider.future);
    final notifier = ref.read(gameNotifierProvider.notifier);
    notifier.initialize(engine);

    _eventSub = notifier.events.listen(_handleGameEvent);
  }

  void _handleGameEvent(GameEvent event) {
    setState(() => _resultMessage = eventToMessage(event));

    if (event is EnhanceSuccessEvent) {
      _playSuccessAnimation(event.prevLevel, event.newLevel);
    } else if (event is EnhanceFailEvent) {
      if (event.destroyed && event.adProtectionAvailable) {
        _showAdProtectionDialog();
      } else if (event.destroyed) {
        _playDestroyAnimation(event.destroyedLevel);
      }
    } else if (event is SellEvent) {
      _playSellAnimation(event.soldLevel, event.goldGained);
    }
  }

  void _showAdProtectionDialog() {
    final notifier = ref.read(gameNotifierProvider.notifier);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('검이 파괴되었습니다!', style: TextStyle(color: Colors.red)),
        content: const Text('광고를 보고 검을 복구하시겠습니까?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.dispatch(WatchAdCommand(adType: AdType.protection));
            },
            child: const Text('광고 보기', style: TextStyle(color: Colors.amber)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.dispatch(ConfirmDestroyCommand());
            },
            child: const Text('파괴 확정', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // --- Animation helpers ---

  Future<void> _playSuccessAnimation(int prevLevel, int newLevel) async {
    setState(() => _isAnimating = true);
    final animController = ref.read(enhanceAnimationProvider);
    final config = ref.read(animationConfigProvider).forLevel(newLevel);
    await animController.playSuccess(prevLevel, newLevel, config);
    setState(() => _isAnimating = false);
  }

  Future<void> _playDestroyAnimation(int destroyedLevel) async {
    setState(() => _isAnimating = true);
    final animController = ref.read(enhanceAnimationProvider);
    final config = ref.read(animationConfigProvider).forLevel(destroyedLevel);
    await animController.playDestroy(destroyedLevel, config);
    setState(() => _isAnimating = false);
  }

  Future<void> _playSellAnimation(int level, int goldGained) async {
    setState(() => _isAnimating = true);
    final animController = ref.read(enhanceAnimationProvider);
    await animController.playSell(level, goldGained);
    setState(() => _isAnimating = false);
  }

  // --- Actions ---

  Future<void> _onEnhancePressed() async {
    if (_isAnimating) return;
    final notifier = ref.read(gameNotifierProvider.notifier);
    final gameState = ref.read(gameNotifierProvider);
    if (gameState == null) return;

    setState(() { _isAnimating = true; _resultMessage = '강화 중...'; });
    final animController = ref.read(enhanceAnimationProvider);
    final config = ref.read(animationConfigProvider).forLevel(gameState.currentLevel + 1);
    await animController.playEnhanceAttempt(gameState.currentLevel + 1, config);
    notifier.dispatch(EnhanceCommand());
  }

  void _onSellPressed() {
    if (_isAnimating) return;
    ref.read(gameNotifierProvider.notifier).dispatch(SellCommand());
  }

  void _onCollectPressed() {
    if (_isAnimating) return;
    ref.read(gameNotifierProvider.notifier).dispatch(CollectCommand());
  }

  void _onUseItem(ItemType type) {
    ref.read(gameNotifierProvider.notifier).dispatch(UseItemCommand(itemType: type));
  }

  void _onWatchAd(AdType type) {
    ref.read(gameNotifierProvider.notifier).dispatch(WatchAdCommand(adType: type));
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameNotifierProvider);
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
    final isPending = gameState.pendingAdProtection;

    String successRateText = '???';
    final swordTable = ref.watch(swordTableProvider);
    if (level < 15 && swordTable.hasValue) {
      final targetSword = swordTable.value!.getSword(level + 1);
      if (targetSword != null && targetSword.successRate != null) {
        successRateText = '${(targetSword.successRate! * 100).toStringAsFixed(1)}%';
      }
    }

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
              TextButton.icon(
                onPressed: () => _onWatchAd(AdType.gold),
                icon: const Icon(Icons.play_circle, size: 16),
                label: const Text('광고 보고 200골드'),
                style: TextButton.styleFrom(foregroundColor: Colors.amber[200]),
              ),
              const SizedBox(height: 16),
              Text('성공 확률: $successRateText',
                  style: TextStyle(fontSize: 18, color: Colors.grey[400])),
              const SizedBox(height: 16),
              ItemChipsWidget(
                gameState: gameState,
                onUseItem: _onUseItem,
                onWatchAd: _onWatchAd,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 30,
                child: Text(
                  _resultMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ActionButtonsWidget(
                isAnimating: _isAnimating,
                canEnhance: !isPending,
                canSell: level > 0 && !isPending,
                canCollect: level >= 10 && !isPending,
                onEnhance: _onEnhancePressed,
                onSell: _onSellPressed,
                onCollect: _onCollectPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

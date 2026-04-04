import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import '../bindings/game_binding.dart';

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

    // Initialize state provider with engine's initial state
    ref.read(gameStateProvider.notifier).state = engine.state;

    // Listen to game events for animations
    _eventSubscription = engine.events.listen((event) {
      _handleGameEvent(event);
    });
  }

  void _handleGameEvent(GameEvent event) {
    if (event is EnhanceSuccessEvent) {
      setState(() {
        _resultMessage = '강화 성공! +${event.newLevel} ${event.newSwordName}';
      });
      _playSuccessAnimation(event.prevLevel, event.newLevel);
    } else if (event is EnhanceFailEvent) {
      if (event.destroyed) {
        setState(() {
          _resultMessage = '강화 실패! 검이 파괴되었습니다...';
        });
        _playDestroyAnimation(event.destroyedLevel);
      } else {
        setState(() {
          _resultMessage = '강화 실패! (보호됨)';
        });
      }
    } else if (event is SellEvent) {
      setState(() {
        _resultMessage = '판매 완료! +${event.goldGained}골드';
      });
      _playSellAnimation(event.soldLevel, event.goldGained);
    } else if (event is CommandRejectedEvent) {
      setState(() {
        _resultMessage = _getRejectionMessage(event.reason);
      });
    }
  }

  String _getRejectionMessage(String reason) {
    switch (reason) {
      case 'insufficient_gold':
        return '골드가 부족합니다';
      case 'cannot_sell_wooden_sword':
        return '나무 검은 판매할 수 없습니다';
      case 'max_level_reached':
        return '최대 레벨에 도달했습니다';
      default:
        return '불가능한 행동입니다';
    }
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

    final engineAsync = ref.read(gameEngineProvider);
    if (!engineAsync.hasValue) return;

    final engine = engineAsync.value!;

    setState(() {
      _isAnimating = true;
      _resultMessage = '강화 중...';
    });

    // Play suspense animation
    final state = engine.state;
    final animController = ref.read(enhanceAnimationProvider);
    final configTable = ref.read(animationConfigProvider);
    final config = configTable.forLevel(state.currentLevel + 1);
    await animController.playEnhanceAttempt(state.currentLevel + 1, config);

    // Execute command
    engine.dispatch(EnhanceCommand());

    // Update state provider
    ref.read(gameStateProvider.notifier).state = engine.state;
  }

  Future<void> _onSellPressed() async {
    if (_isAnimating) return;

    final engineAsync = ref.read(gameEngineProvider);
    if (!engineAsync.hasValue) return;

    final engine = engineAsync.value!;

    // Execute sell command
    engine.dispatch(SellCommand());

    // Update state provider
    ref.read(gameStateProvider.notifier).state = engine.state;
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
        body: Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    final sword = gameState.currentSword;
    final level = gameState.currentLevel;
    final gold = gameState.playerData.gold;

    // 확률 표시: +14이하 숫자, +15이상 "???"
    // swordTable에서 다음 레벨 검의 성공률 조회
    String successRateText = '???';
    final swordTable = ref.watch(swordTableProvider);
    if (level < 15 && swordTable.hasValue) {
      final targetSword = swordTable.value!.getSword(level + 1);
      if (targetSword != null && targetSword.successRate != null) {
        successRateText = '${(targetSword.successRate! * 100).toStringAsFixed(1)}%';
      }
    }

    final canSell = level > 0;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text('대장간', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sword display
              Text(
                sword.name,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '+$level',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(level),
                ),
              ),
              SizedBox(height: 32),

              // Gold display
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '$gold 골드',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Success rate
              Text(
                '성공 확률: $successRateText',
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              ),
              SizedBox(height: 48),

              // Result message
              SizedBox(
                height: 30,
                child: Text(
                  _resultMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isAnimating ? null : _onEnhancePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Text('강화하기'),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: (_isAnimating || !canSell) ? null : _onSellPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Text('판매하기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level >= 18) return Colors.white;
    if (level >= 15) return Color(0xFFFFD700); // gold
    if (level >= 10) return Color(0xFF9C27B0); // purple
    if (level >= 6) return Color(0xFF2196F3); // blue
    return Colors.grey[400]!;
  }
}

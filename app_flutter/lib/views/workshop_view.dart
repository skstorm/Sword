import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import '../bindings/game_binding.dart';
import '../bindings/game_notifier.dart';

class WorkshopView extends ConsumerWidget {
  const WorkshopView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    if (gameState == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: const Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.grey[850],
          title: const Text('공방', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.grey[400],
            tabs: const [
              Tab(text: '숙련도'),
              Tab(text: '교환소'),
              Tab(text: '도감'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MasteryTab(state: gameState),
            const _ExchangeTab(),
            const _CollectionTab(),
          ],
        ),
      ),
    );
  }
}

// ─── 숙련도 탭 ───

class _MasteryTab extends ConsumerWidget {
  final GameState state;
  const _MasteryTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masteryAsync = ref.watch(masteryTableProvider);
    if (!masteryAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final table = masteryAsync.value!;
    final mastery = state.playerData.mastery;
    final current = table.getLevel(mastery.level);
    final allLevels = table.allLevels;
    final nextIdx = allLevels.indexWhere((l) => l.level == mastery.level) + 1;
    final next = nextIdx < allLevels.length ? allLevels[nextIdx] : null;

    final progress = next != null
        ? (mastery.totalAttempts - current.requiredExp) /
            (next.requiredExp - current.requiredExp)
        : 1.0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.hardware, size: 64, color: Colors.amber[300]),
          const SizedBox(height: 16),
          Text(
            'Lv.${mastery.level}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            current.rewardDescription.isNotEmpty ? current.rewardDescription : '초보 장인',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          ),
          const SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('강화 횟수: ${mastery.totalAttempts}회',
                      style: TextStyle(color: Colors.grey[300])),
                  if (next != null)
                    Text('다음 레벨: ${next.requiredExp}회',
                        style: TextStyle(color: Colors.grey[500])),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation(Colors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (next != null) ...[
            Text('다음 보상', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Text(
                next.rewardDescription,
                style: const TextStyle(fontSize: 16, color: Colors.amber),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (next == null)
            const Text('최고 레벨 달성!',
                style: TextStyle(fontSize: 18, color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── 교환소 탭 ───

class _ExchangeTab extends ConsumerWidget {
  const _ExchangeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    if (gameState == null) return const SizedBox.shrink();

    final fragments = gameState.playerData.fragments;
    final inv = gameState.playerData.inventory;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond, color: Colors.cyan[300], size: 28),
                const SizedBox(width: 8),
                Text('$fragments 파편',
                    style: const TextStyle(
                        fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _ExchangeCard(
            icon: Icons.shield,
            iconColor: Colors.blue,
            name: '보호의 부적',
            cost: FragmentCost.protectionAmulet,
            owned: inv.protectionAmulets,
            fragments: fragments,
            onExchange: () => _exchange(ref, ItemType.protectionAmulet),
          ),
          const SizedBox(height: 16),
          _ExchangeCard(
            icon: Icons.auto_fix_high,
            iconColor: Colors.purple,
            name: '축복의 주문서',
            cost: FragmentCost.blessingScroll,
            owned: inv.blessingScrolls,
            fragments: fragments,
            onExchange: () => _exchange(ref, ItemType.blessingScroll),
          ),
          const SizedBox(height: 16),
          _ExchangeCard(
            icon: Icons.monetization_on,
            iconColor: Colors.amber,
            name: '골드 주머니 (500G)',
            cost: FragmentCost.goldPouch,
            owned: -1,
            fragments: fragments,
            onExchange: () => _exchange(ref, ItemType.goldPouch),
          ),
        ],
      ),
    );
  }

  void _exchange(WidgetRef ref, ItemType type) {
    ref.read(gameNotifierProvider.notifier).dispatch(ExchangeCommand(itemType: type));
  }
}

class _ExchangeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final int cost;
  final int owned;
  final int fragments;
  final VoidCallback onExchange;

  const _ExchangeCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.cost,
    required this.owned,
    required this.fragments,
    required this.onExchange,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = fragments >= cost;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.diamond, color: Colors.cyan[300], size: 14),
                    const SizedBox(width: 4),
                    Text('$cost', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                    if (owned >= 0) ...[
                      const SizedBox(width: 16),
                      Text('보유: $owned',
                          style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                    ],
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canAfford ? onExchange : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey[700],
            ),
            child: const Text('교환'),
          ),
        ],
      ),
    );
  }
}

// ─── 도감 탭 ───

class _CollectionTab extends ConsumerWidget {
  const _CollectionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    if (gameState == null) return const SizedBox.shrink();

    final swordAsync = ref.watch(swordTableProvider);
    if (!swordAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final swordTable = swordAsync.value!;
    final collectibles = swordTable.collectibleSwords;
    final collection = gameState.playerData.collection;
    final uniqueCount = collection.uniqueCount;
    final total = collectibles.length;
    final pct = total > 0 ? (uniqueCount / total * 100).toStringAsFixed(0) : '0';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '컬렉션 $uniqueCount/$total ($pct%)',
              style: const TextStyle(
                  fontSize: 18, color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: collectibles.length,
              itemBuilder: (context, index) {
                final sword = collectibles[index];
                final count = collection.collected[sword.level] ?? 0;
                final isCollected = count > 0;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCollected
                          ? Colors.amber.withValues(alpha: 0.5)
                          : Colors.grey[700]!,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isCollected) ...[
                        Text(
                          '+${sword.level}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sword.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\u2605' * count,
                          style: const TextStyle(fontSize: 14, color: Colors.amber),
                        ),
                      ] else ...[
                        Icon(Icons.lock, color: Colors.grey[600], size: 28),
                        const SizedBox(height: 4),
                        Text(
                          '???',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

library;

// ✅ 외부 공개 — 뷰가 사용하는 것들

// Models
export 'models/sword.dart';
export 'models/game_state.dart';
export 'models/modifier.dart';
export 'models/player.dart';
export 'models/mastery.dart';
export 'models/fragment.dart';
export 'models/collection.dart';
export 'models/achievement.dart';
export 'models/title.dart';
export 'models/ranking.dart';

// Commands
export 'commands/command.dart';
export 'commands/enhance_command.dart';
export 'commands/sell_command.dart';
export 'commands/collect_command.dart';
export 'commands/use_item_command.dart';
export 'commands/exchange_command.dart';
export 'commands/watch_ad_command.dart';
export 'commands/confirm_destroy_command.dart';

// Events
export 'events/game_event.dart';
export 'events/enhance_event.dart';
export 'events/economy_event.dart';
export 'events/fragment_event.dart';
export 'events/mastery_event.dart';
export 'events/collection_event.dart';
export 'events/ad_event.dart';

// Engine
export 'engine/game_engine.dart';
export 'engine/game_context.dart';
export 'engine/session_recorder.dart';

// Logic (shared types only)
export 'logic/logic_result.dart';

// Repositories
export 'repositories/storage_repository.dart';
export 'repositories/ranking_repository.dart';

// Data loaders
export 'data/sword_data_loader.dart';
export 'data/mastery_data_loader.dart';

// Util
export 'util/time_provider.dart';
export 'util/random_provider.dart';

// ❌ 비공개 — Logic 클래스는 export하지 않음
// logic/enhance_logic.dart      → Command 내부에서만 사용
// logic/economy_logic.dart      → Command 내부에서만 사용
// logic/fragment_logic.dart     → Command 내부에서만 사용
// logic/mastery_logic.dart      → Command 내부에서만 사용
// logic/collection_logic.dart   → Command 내부에서만 사용
// logic/achievement_logic.dart  → Command 내부에서만 사용
// logic/title_logic.dart        → Command 내부에서만 사용
// logic/ranking_logic.dart      → Command 내부에서만 사용
// logic/ad_reward_logic.dart    → Command 내부에서만 사용
// logic/game_session_logic.dart → Command 내부에서만 사용

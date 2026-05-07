# StudySync — Future Roadmap Review
*Reviewed against project state: Post-Audit Hardening (All 6 findings resolved, Phase 3 complete)*
*Date: 2026-05-06*

---

## 📍 Current Project State (Checkpoint)

| Area | Status |
|---|---|
| Auth routing | ✅ Reactive (`AppRouter` + `onAuthStateChange`) |
| Room join race | ✅ Fixed (upsert + DB UNIQUE INDEX) |
| Chat reliability | ✅ Async send with rollback on failure |
| Leaderboard error UX | ✅ Error widget + Retry button |
| Chat identity staleness | ✅ Fixed via auth event subscription |
| Chat persistence | ❌ Ephemeral broadcast only (no DB) |
| Social graph | ❌ Does not exist |
| Streak/Goal tracking | ❌ No DB contract |
| Google OAuth | ❌ Not implemented |

**Existing DB surface:** `profiles`, `rooms`, `room_members`, `study_sessions`, `get_my_stats` RPC, `leaderboard` query.

---

## ⚠️ Critical Gaps Before Starting Roadmap

> [!CAUTION]
> These must be resolved first. Skipping them will cause regressions as new features land.

1. **DB UNIQUE constraint audit note** — the `uniq_room_members` index was applied via the Supabase API but has no tracked migration file. Add it to a `supabase/migrations/` folder before the next dev cycle.
2. **Home screen placeholder data** — cards showing fake/static rooms and leaderboard positions exist in `home_screen.dart`. These must be replaced with live data *before* any visual redesign, or the redesign will be built on sand.
3. **Chat is ephemeral** — Quick Reactions and Friend-is-Online notifications both require durable message IDs and persistent presence state. Neither exists yet.

---

## 🗺️ Recommended Upgrade Phases

### Phase 4 — Auth & Onboarding Polish
*Smallest risk, highest daily-driver impact. Build on the already-hardened `AppRouter`.*

| Feature | Source Doc | Risk | DB Work |
|---|---|---|---|
| Minimalist login UI (logo + 2 buttons) | Tab 1 & Tab 2 | 🟢 Low | None |
| Google OAuth sign-in | Tab 1 & Tab 2 | 🟡 Medium | None (Supabase built-in) |
| New-user flow → `AppRouter` gate | `future plans.md` finding #4 | 🟡 Medium | None |
| Dark Mode / Theme Toggle | Tab 2 | 🟢 Low | None |

> [!IMPORTANT]
> Google OAuth must funnel through the existing `AppRouter` auth gate. Do **not** add a new post-auth destination — otherwise the profile-completion check will be bypassed for new Google users.

**Deliverable:** A clean, minimal login screen with both auth methods, both routing through `AppRouter` → `ProfileSetupScreen` for incomplete profiles.

---

### Phase 5 — Live Data & Dashboard Truth
*Replace placeholder home screen data with real, live queries. No new DB tables needed.*

| Feature | Source Doc | Risk | DB Work |
|---|---|---|---|
| Replace hardcoded home cards with live data | `future plans.md` finding #6 | 🟢 Low | None (use existing tables) |
| Quick Metrics card (daily/weekly hours, streak placeholder) | Tab 2 | 🟢 Low | Existing `get_my_stats` RPC |
| Recent Rooms (last 2 from `room_members` join) | Tab 2 | 🟢 Low | Query existing `room_members` |
| Comprehensive Progress Dashboard entry | Tab 2 | 🟢 Low | Existing stats RPC |

> [!TIP]
> `recent rooms` can be derived by joining `room_members` ordered by `joined_at DESC LIMIT 2`. No new table needed.

**Deliverable:** Home screen with all cards rendering live data, empty-state coverage on all cards.

---

### Phase 6 — Stats Expansion & Gamification Foundation
*Additive DB work. Must not break existing `get_my_stats` / `subjectBreakdown` contract.*

| Feature | Source Doc | Risk | DB Work |
|---|---|---|---|
| Study Streak tracking | Tab 1 & Tab 2 | 🟡 Medium | New `streaks` table or column on `profiles` |
| Daily Goal setting | Tab 2 | 🟡 Medium | `daily_goal_minutes` column on `profiles` |
| Goal progress visualization | Tab 2 | 🟡 Medium | Derived from `study_sessions` |
| Unlockable Themes (7-day streak reward) | Tab 1 | 🟡 Medium | `unlocked_themes[]` column on `profiles` |
| Daily To-Do List | Tab 2 | 🟡 Medium | New `todos` table |
| Upcoming Exam Alerts | Tab 2 | 🔴 High | New `exams` table + notification logic |
| Chapter progress/completion stats | Tab 2 | 🔴 High | New `chapter_progress` table |

> [!WARNING]
> All stats additions must be **additive** to `get_my_stats`. Do not alter or remove existing return keys (`daily`, `weekly`, `monthly`, `total`, `subjectBreakdown`) or the existing `stats_dashboard_screen.dart` will break.

**Recommended sub-order within Phase 6:**
1. Streak storage → 2. Daily goal → 3. To-Do list → 4. Unlockable themes → 5. Exam/chapter alerts (later phase)

---

### Phase 7 — Social Systems
*Highest infrastructure cost. Each feature depends on the one before it.*

| Feature | Source Doc | Risk | DB Work Prerequisite |
|---|---|---|---|
| Follow/Friend Graph | Tab 1 | 🔴 High | New `follows` table |
| Profile Search / Public Directory | Tab 1 | 🟡 Medium | Existing `profiles` + policy update |
| "Friend is Online" toast notifications | Tab 1 | 🔴 High | Presence system (Supabase Realtime presence) |
| Invite-to-Table (direct ping) | Tab 1 | 🔴 High | Push notification service + `invites` table |
| Quick Reactions (long-press emoji) | Tab 1 | 🟡 Medium | **Zero DB — Ephemeral Broadcast model** (see plan below) |

> [!TIP]
> **Quick Reactions do NOT require a DB refactor.** Approved design uses the existing Supabase Realtime broadcast channel. A reaction is simply a second typed broadcast event (`chat_reaction`) that targets a specific message by its client-generated prefixed ID. All state lives in memory — ephemeral, just like messages. See the **Ephemeral Broadcast Reactions Plan** section at the bottom of this document.

**Dependency Map for Social Phase:**
```
profiles (exists)
    └─→ follows table (NEW) ─→ Friend-is-Online ─→ Invite-to-Table
    └─→ profile search (existing table, policy work)

chat_reaction broadcast event (NO NEW TABLE)
    └─→ Quick Reactions  ← approved design
    └─→ Reactions vanish on leave/reconnect (by design, same as messages)
```

---

## 📊 Feature Priority Matrix

| Feature | Impact | Effort | Phase | Verdict |
|---|---|---|---|---|
| Minimalist Login UI | High | Low | 4 | ✅ Do first |
| Google OAuth | High | Medium | 4 | ✅ Do first |
| Dark Mode Toggle | Medium | Low | 4 | ✅ Quick win |
| Live Home Screen Data | High | Low | 5 | ✅ Do second |
| Recent Rooms card | Medium | Low | 5 | ✅ Quick win |
| Study Streak | High | Medium | 6 | ✅ Do third |
| Daily Goal | High | Medium | 6 | ✅ Do third |
| To-Do List | Medium | Medium | 6 | 🟡 Queue after streak |
| Unlockable Themes | High (engagement) | Medium | 6 | 🟡 Queue after streak |
| Exam Alerts | Medium | High | 6+ | 🔴 Later |
| Chapter Progress | Medium | High | 6+ | 🔴 Later |
| Follow Graph | High (social) | High | 7 | 🔴 Later |
| Friend Online Toasts | High (engagement) | High | 7 | 🔴 Needs presence infra |
| Invite-to-Table | High (engagement) | High | 7 | 🔴 Needs follow graph |
| Quick Reactions | Medium | Medium | 7 | 🟡 Approved — Ephemeral Broadcast model, no DB |

---

## 🗄️ New DB Surface Required (Summary)

| Table / Column | Phase | Purpose |
|---|---|---|
| `profiles.daily_goal_minutes` | 6 | Daily study goal |
| `profiles.current_streak_days` | 6 | Streak count |
| `profiles.last_study_date` | 6 | Streak calculation |
| `profiles.unlocked_themes[]` | 6 | Theme unlock list |
| `todos` table | 6 | Daily to-do list items |
| `exams` table | 6+ | Exam date + subject |
| `chapter_progress` table | 6+ | Per-chapter completion |
| `follows` table | 7 | Social graph (follower, following) |
| ~~`chat_messages` table~~ | ~~7~~ | ~~Persistent chat~~ — **not needed, reactions use broadcast** |
| ~~`message_reactions` table~~ | ~~7~~ | ~~DB reactions~~ — **not needed, reactions use broadcast** |

---

## ✅ What's Already Ready (No Work Needed)

- Sidebar navigation structure ✅ (exists, just needs real data)
- Stats entrypoint ✅ (exists, needs additive fields)
- Profile search ✅ (exists in `profile_service.dart`, needs a UI and follow model)
- Room join / room browsing ✅ (fully functional)
- Leaderboard ✅ (functional with error handling)

---

## 🚀 Recommended Next Action

**Start Phase 4:** Implement the minimalist login screen and Google OAuth — this has zero DB dependencies, the highest daily-driver visibility, and directly builds on the now-hardened `AppRouter` auth gate.

---

## 💬 Ephemeral Broadcast Reactions — Implementation Plan
*Zero DB. Zero schema changes. Works within the existing `ChatService` broadcast architecture.*

### Core Concept: Event-Sourced Ephemeral State
Reactions are **not stored**. They travel as a second broadcast event type on the same Supabase Realtime channel. All reaction state lives in each client's in-memory `List<ChatMessage>`. When a user leaves the room, reactions vanish — exactly like messages do today. This matches the app's existing philosophy of treating live rooms as **in-the-moment sessions**.

---

### Step 1 — Add `uuid` Package
```yaml
# pubspec.yaml
dependencies:
  uuid: ^4.5.1
```

---

### Step 2 — Updated `ChatMessage` Model
The model needs to become **mutable** (remove `const`/`final` on reactions), and gain a `messageId` and a `reactions` map.

```dart
// lib/models/chat_message.dart
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String messageId;   // e.g. "a1b2c3_f47ac10b-..."
  final String userId;
  final String username;
  final String text;
  final DateTime timestamp;

  // emoji → Set<userId> who reacted with that emoji
  // Mutable so _onIncomingReaction() can update in-place.
  final Map<String, Set<String>> reactions;

  ChatMessage({
    required this.messageId,
    required this.userId,
    required this.username,
    required this.text,
    required this.timestamp,
    Map<String, Set<String>>? reactions,
  }) : reactions = reactions ?? {};

  factory ChatMessage.fromBroadcast(Map<String, dynamic> payload) {
    return ChatMessage(
      messageId: (payload['message_id'] as String?) ?? '',
      userId:    (payload['user_id']    as String?) ?? '',
      username:  (payload['username']   as String?) ?? 'Anonymous',
      text:      (payload['text']       as String?) ?? '',
      timestamp: DateTime.tryParse((payload['ts'] as String?) ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toBroadcastPayload() => {
    'event_type': 'chat_message',
    'message_id': messageId,
    'user_id':    userId,
    'username':   username,
    'text':       text,
    'ts':         timestamp.toIso8601String(),
  };
}
```

---

### Step 3 — Prefixed Message ID Generator in `ChatService`
Combines the first 6 chars of the auth `user_id` (user-scoped prefix) with a UUIDv4 (random uniqueness). Zero collision risk.

```dart
// Inside ChatService — add this field and method:
final _uuid = const Uuid();

String _generateMessageId() {
  final prefix = _myUserId.length >= 6
      ? _myUserId.substring(0, 6)
      : _myUserId;
  return '${prefix}_${_uuid.v4()}';
}
```

Update `sendMessage()` to attach the generated ID:
```dart
final message = ChatMessage(
  messageId: _generateMessageId(),  // ← add this
  userId:    _myUserId,
  username:  _myUsername,
  text:      text,
  timestamp: DateTime.now(),
);
```

---

### Step 4 — `sendReaction()` in `ChatService`
A reaction is a fire-and-forget broadcast. No cooldown, no optimistic append — it just patches the target message in memory.

```dart
/// Sends a reaction emoji broadcast targeting [messageId].
/// Skips validation — reactions are not subject to spam rules.
Future<void> sendReaction({
  required String messageId,
  required String emoji,
  required bool isGlobal,
}) async {
  final channel = isGlobal ? _globalChannel : _roomChannel;
  if (channel == null) return;

  // Optimistically apply locally first
  _applyReaction(
    messageId: messageId,
    reactorUserId: _myUserId,
    emoji: emoji,
    isGlobal: isGlobal,
  );

  await channel.sendBroadcastMessage(
    event: 'reaction',
    payload: {
      'event_type':  'chat_reaction',
      'message_id':  messageId,
      'user_id':     _myUserId,
      'emoji':       emoji,
    },
  );
}

void _applyReaction({
  required String messageId,
  required String reactorUserId,
  required String emoji,
  required bool isGlobal,
}) {
  final list = isGlobal ? _globalMessages : _roomMessages;
  final idx = list.indexWhere((m) => m.messageId == messageId);
  if (idx == -1) return; // message not in local buffer (late joiner edge case)

  final msg = list[idx];
  final reactors = msg.reactions.putIfAbsent(emoji, () => {});

  if (reactors.contains(reactorUserId)) {
    // Toggle off — second tap removes the reaction
    reactors.remove(reactorUserId);
    if (reactors.isEmpty) msg.reactions.remove(emoji);
  } else {
    reactors.add(reactorUserId);
  }
  notifyListeners();
}
```

Add a handler for incoming `reaction` events in channel subscription setup:
```dart
// Inside joinGlobalChat() / joinRoomChat() channel.subscribe() callback:
channel.onBroadcast(
  event: 'reaction',
  callback: (payload) {
    final isGlobal = /* true or false depending on channel */;
    final reactorId = (payload['user_id'] as String?) ?? '';
    if (reactorId == _myUserId) return; // already applied optimistically
    _applyReaction(
      messageId:      (payload['message_id'] as String?) ?? '',
      reactorUserId:  reactorId,
      emoji:          (payload['emoji'] as String?) ?? '',
      isGlobal:       isGlobal,
    );
  },
);
```

---

### Step 5 — UI Changes in `sidebar_chat.dart`
Wrap each message bubble in a `GestureDetector` with `onLongPress` to open a small emoji picker row. On emoji tap, call `chatService.sendReaction()`.

Below the message text, render the reactions row:
```dart
// Inside the message bubble Column:
if (msg.reactions.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Wrap(
      spacing: 4,
      children: msg.reactions.entries.map((e) {
        final isMyReaction = e.value.contains(_currentUserId);
        return GestureDetector(
          onTap: () => widget.chatService.sendReaction(
            messageId: msg.messageId,
            emoji: e.key,
            isGlobal: widget.isGlobal,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isMyReaction
                  ? _primaryContainer.withValues(alpha: 0.7)
                  : _surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMyReaction ? _primary : _outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text('${e.key} ${e.value.length}',
                style: const TextStyle(fontSize: 12)),
          ),
        );
      }).toList(),
    ),
  ),
```

Emoji picker (shown on long-press):
```dart
// Quick emoji strip — 5 choices, no full picker needed:
const _reactionEmojis = ['👍', '❤️', '😂', '🎉', '🔥'];

void _showReactionPicker(BuildContext context, ChatMessage msg) {
  showModalBottomSheet(
    context: context,
    backgroundColor: _surfaceHigh,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _reactionEmojis.map((emoji) =>
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.chatService.sendReaction(
                messageId: msg.messageId,
                emoji: emoji,
                isGlobal: widget.isGlobal,
              );
            },
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ).toList(),
      ),
    ),
  );
}
```

---

### Broadcast Payload Contracts (Reference)

**`chat_message` event:**
```json
{
  "event_type": "chat_message",
  "message_id": "a1b2c3_f47ac10b-58b0-4b9e-9f06-d5b94a7e5a12",
  "user_id":    "<supabase-auth-uid>",
  "username":   "Alice",
  "text":       "Let's study calculus!",
  "ts":         "2026-05-06T12:30:00.000Z"
}
```

**`reaction` event:**
```json
{
  "event_type":  "chat_reaction",
  "message_id":  "a1b2c3_f47ac10b-58b0-4b9e-9f06-d5b94a7e5a12",
  "user_id":     "<reactor-auth-uid>",
  "emoji":       "🎉"
}
```

---

### Trade-offs (Accepted by Design)

| Trade-off | Accepted? | Reason |
|---|---|---|
| Reactions vanish when user leaves room | ✅ Yes | Same as messages — sessions are ephemeral by design |
| Late joiners don't see prior reactions | ✅ Yes | Same as messages — no history loaded on join |
| Network blip clears all state | ✅ Yes | Consistent with current chat behaviour |
| No cross-device reaction sync | ✅ Yes | Each session is independent |

### Files to Change (When Implementing)
1. `pubspec.yaml` — add `uuid: ^4.5.1`
2. `lib/models/chat_message.dart` — add `messageId`, `reactions` map, update factory/payload
3. `lib/services/chat_service.dart` — add `_generateMessageId()`, `sendReaction()`, `_applyReaction()`, `reaction` event handler in channel setup
4. `lib/widgets/sidebar_chat.dart` — add `onLongPress` picker, reactions row UI

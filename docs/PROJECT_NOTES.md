# StudySync — Project Memory & Notes

## 🗂️ Project Overview
A Flutter + Supabase group study platform.
**Workspace:** `c:\Users\SER\StudySync`
**Platform target:** Web (Chrome), Windows desktop

---

## 🔑 Supabase Config
- **Project URL:** `https://uenpxgcngqzggxmqifpw.supabase.co`
- **Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVlbnB4Z2NuZ3F6Z2d4bXFpZnB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3OTE2MDYsImV4cCI6MjA5MDM2NzYwNn0.bCat6zf7OoRLH_r598fPfDLxdUUS2i7CnNpG7uNLeNM`

---

## 🗃️ Supabase Database Tables

### `rooms`
```sql
create table public.rooms (
  id uuid not null default gen_random_uuid(),
  name text null,
  created_by uuid null,
  created_at timestamp with time zone not null default now(),
  constraint rooms_pkey primary key (id)
);
```


```sql
create table public.room_members (
  id uuid not null default gen_random_uuid(),
  room_id uuid not null,
  user_id uuid null,
  joined_at timestamp without time zone null default now(),
  constraint room_members_pkey primary key (id)
);
```

### `study_sessions`
```sql
CREATE TABLE study_sessions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  room_id     uuid NOT NULL REFERENCES rooms(id)      ON DELETE CASCADE,
  subject     text,
  start_time  timestamptz NOT NULL DEFAULT now(),
  end_time    timestamptz,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_sessions_room_active ON study_sessions (room_id, is_active);
CREATE INDEX idx_sessions_user_active ON study_sessions (user_id, is_active);
```

---

## 📁 File Structure
```
lib/
  main.dart                     ← Supabase init, session-aware routing
  screens/
    login_screen.dart           ← Email/password auth (signIn + signUp)
    home_screen.dart            ← Main homepage (matches prototype)
    room_detail_screen.dart     ← Live study table, timer, and member panel [UPDATED]
    room_sheet.dart             ← Bottom sheet for joining/creating rooms
  models/
    room_model.dart             ← Room data model
    study_session_model.dart    ← Session data model & duration formatting [NEW]
  services/
    room_service.dart           ← Supabase room CRUD logic
    session_service.dart        ← Session start/stop/fetch logic [NEW]
```

---

## 📈 Project Roadmap & Progress

### ✅ Phase 1: Core System (Completed)

#### Milestone 1: Foundation & Authentication
- [x] Flutter project initialization (Web & Desktop).
- [x] Supabase integration & backend configuration.
- [x] Email/Password Sign-in & Sign-up systems.
- [x] Database schema design for `rooms` and `room_members`.

#### Milestone 2: Room & Presence System
- [x] "Create Room" and "Join Room" logic.
- [x] Secure RLS (Row Level Security) policies for shared room data.
- [x] Real-time member listing and presence visibility.

#### Milestone 3: The Study Loop (The Heart of StudySync)
- [x] `study_sessions` tracking system.
- [x] Live HH:MM:SS study timer centerpiece in `RoomDetailScreen`.
- [x] Multi-user visibility (seeing friends' live subjects and progress).
- [x] Duplicate session prevention (backend/app-level guards).

#### Milestone 4: Accountability (Anti-Cheat)
- [x] **Anti-Fake Study Check-in System**.
- [x] 20-minute periodic check-in popups.
- [x] 60-second grace window with auto-stop on timeout.
- [x] Live session status indicators (🟢 Active / 🟡 Warning / 🔴 Inactive).

#### Milestone 5: Optimization & Polish
- [x] Mobile-responsive layout updates for all screens.
- [x] Premium "Dark Mode" aesthetic with Glassmorphism.
- [x] Transition animations and real-time state sync.

---

### 🔜 Phase 2: Social & Analytics (Next Up)

- [ ] **Leaderboards:** Daily, Weekly, and Monthly study time rankings.
- [ ] **Live Chat:** Minimalist, low-noise text chat within study rooms.
- [ ] **Personal Stats Dashboard:** Subject-wise breakdowns and calendar views.
- [ ] **Friend System:** Following friends and getting notified when they start studying.

---

## 🎨 Design System Colors
| Token | Hex |
|---|---|
| Background | `#0C0E11` |
| Surface | `#111417` |
| Primary | `#ADCBDB` |
| Primary Container | `#395664` |
| On Surface | `#E2E5EE` |
| On Surface Variant | `#A7ABB3` |
| Outline | `#44484F` |
| Green (Active) | `#4CAF50` |
| Red (Stop) | `#FF6B6B` |

**Fonts:** Inter (Body/Labels), Outfit or Roboto (Headlines)

---

## ⚠️ Known Gotchas
- `withOpacity()` is deprecated in newer Flutter — use `.withValues(alpha: x)`
- Timers are calculated from `DateTime.now()` vs `start_time` from DB for accuracy
- UI polls active sessions every **5 seconds** to maintain low latency vs DB load
- Center pulse animation follows the study state (green when studying)

---

## 🛠️ Environment & Tooling
- **MCP Client:** Configured with `supabase` and `StitchMCP`
- **Agent Skills:** 
  - `supabase-postgres-best-practices`
  - `find-skills`

---

## 📝 Changelog

##Old logs/notes are at: C:\Users\SER\StudySync\docs\old_project_notes.md 

[2026-04-19 13:03] - Account-Wide Focus Enforcement (Atomic Session Handoff)
? Completed
- Reverted the idx_one_active_session_per_user_device multi-device index.
- Applied idx_one_active_session_per_user strict unique index.
- Refactored start_session_atomic RPC to automatically terminate existing sessions for a user and safely perform atomic handoffs.

?? Changes
- [DB Schema] Dropped index idx_one_active_session_per_user_device
- [DB Schema] Created unique index idx_one_active_session_per_user where is_active = true
- [DB RPC] Modified start_session_atomic logic to update older sessions to is_active = false before proceeding to insert.

?? Status
Phase 3.x (Multi-device isolation): In Progress (~62%)
(Atomic session single source constraint deployed)

?? Next Steps
- Verify realtime listener properly triggers the "Session Paused" UI state on displaced devices.
- Begin final integration checks for Phase 3.x.

?? Notes / Issues
- Zero-Logout UX logic effectively handles active tracking, meaning leaderboard and focus time increments naturally correctly after switching.
  
[2026-04-19 13:05] -- Future Feature Roadmap  
?? Planned  
- Tracked implementation details in DEVICE_TRACKING_PLAN.md 

[2026-04-21 14:18] — NotebookLM MCP Integration Staging
✅ Completed
- Initialized standard Antigravity skill specification for NotebookLM in .agents/skills/notebooklm/SKILL.md.
- Added 
otebooklm with uvx notebooklm-mcp-cli provider to .gemini/antigravity/mcp_config.json.
- Verified local environment and identified missing uv package manager dependency.
- Staged the workspace and generated 'Ready for Auth' artifact for the user.

🔧 Changes
- Created SKILL.md inside .agents/skills/notebooklm/.
- Modified mcp_config.json to inject MCP entry.

📊 Status
- NotebookLM staging environment complete. Awaiting user action for uv installation and OAuth.

🚀 Next Steps
- User to install uv CLI.
- User to execute OAuth sequence and select context notebook for future operations.

⚠️ Notes / Issues
- uv command was missing on Windows OS.

[2026-04-22 13:56] — NotebookLM Authentication & Access Verification
✅ Completed
- Verified installation of uv package manager and NotebookLM CLI.
- Successfully completed OAuth authentication for NotebookLM.
- Confirmed access to the "StudySync" context notebook.

🔧 Changes
- Authenticated NotebookLM MCP server with the default Google profile.

📊 Status
- NotebookLM Integration Staging: Completed (100%).
- Ready for research-to-code workflow utilizing the StudySync notebook.

🚀 Next Steps
- Utilize NotebookLM context for upcoming complex codebase tasks.

⚠️ Notes / Issues
- Authentication successfully refreshed and tested via MCP tool.

[2026-04-22 14:20] — Device Tracking and Multi-Device Anti-Cheat Integration
✅ Completed
- Completed the UI integration for the Single Active Session device isolation logic.
- Implemented the "Session Paused" displaced device banner with inline CTA.
- Added device-specific hardware icons (Icons.smartphone, Icons.tablet_android, Icons.desktop_windows) in the Room Detail member list.

🔧 Changes
- Updated room_detail_screen.dart to check session.deviceType and display the corresponding icon.
- Added _getDeviceIcon helper function to room_detail_screen.dart.
- Styled the displaced device banner based on user feedback (amber background #2A1A00, #FFB86B text color).

📊 Status
- Device Tracking and Isolation feature UI and Backend are 100% complete.
- Ready for testing and validation.

🚀 Next Steps
- Verify the device handoff flow in the emulator/simulator.

⚠️ Notes / Issues
- No immediate issues observed. State management for displaced sessions effectively leverages LocalSessionState transitions.

[2026-04-22 14:30] - Device Isolation Automated Verification
✅ Completed
- Resolved compilation error regarding _isStarting in room_detail_screen.dart.
- Ran flutter test suite and confirmed all tests pass offline within performance constraints.

🔧 Changes
- [MODIFIED] lib/screens/room_detail_screen.dart - replaced remaining _isStarting reference with _sessionState == LocalSessionState.starting.

📊 Status
Phase 3.x (Multi-device isolation): Completed.

🚀 Next Steps
- User to verify the device handoff flow in the emulator/simulator or physical devices.

⚠️ Notes / Issues
- No issues. Ready for next phase.

[2026-04-28 19:21] � Fix Supabase MCP Authentication
? Completed
- Updated mcp_config.json to use Supabase Personal Access Token (PAT) for persistent authentication, bypassing the daily OAuth disconnection issue.

?? Changes
- [MODIFIED] c:\Users\SER\.gemini\antigravity\mcp_config.json: Replaced supabase serverUrl with npx command and SUPABASE_ACCESS_TOKEN env variable.

?? Status
- Infrastructure: 100% (Supabase MCP Auth Fix)

?? Next Steps
- User to refresh MCP servers in Antigravity to apply changes.

?? Notes / Issues
- The OAuth-based 'Authenticate' button is no longer needed for Supabase.


[2026-04-28 20:30] -- Dual-Layer Live Chat Feature Implementation
? Completed
- Queried StudySync NotebookLM notebook (ID: 760dbe36) for Phase 2.5/3 state, Aeon Slate design system, and Supabase Realtime architecture.
- Generated mobile-first chat UI concept via Stitch MCP (project 271650421636417831) � confirmed Bottom Sheet pattern, Aeon Slate tokens, PurnoBCC + Inter fonts, 'The Nocturnal Scholar' design system.
- Created lib/models/chat_message.dart � immutable ephemeral message model with fromBroadcast() / toBroadcastPayload().
- Created lib/services/chat_service.dart � dual-channel Supabase Realtime Broadcast service (global + room), ChangeNotifier, full spam guard.
- Created lib/widgets/chat_bottom_sheet.dart � DraggableScrollableSheet UI with cooldown ring, avatar initials, emoji support, Aeon Slate dark theme.
- Modified lib/screens/home_screen.dart � added _chatService, joinGlobalChat() in initState, leaveGlobalChat() in dispose, Global Chat icon button in AppBar.
- Modified lib/screens/room_detail_screen.dart � added _chatService, joinRoomChat() in initState, leaveRoomChat() in dispose, _buildChatFab() floating button.

?? Changes
- [NEW] lib/models/chat_message.dart
- [NEW] lib/services/chat_service.dart
- [NEW] lib/widgets/chat_bottom_sheet.dart
- [MODIFIED] lib/screens/home_screen.dart: +imports, +_chatService field, +lifecycle calls, +AppBar chat icon
- [MODIFIED] lib/screens/room_detail_screen.dart: +imports, +_chatService field, +lifecycle calls, +FAB with green dot badge

?? Status
- Phase 3 Chat Feature: 100% implemented.
- flutter analyze: 0 new errors (3 pre-existing room_sheet.dart errors unrelated to this feature).
- Architecture: Ephemeral Broadcast only � no DB tables created.

?? Next Steps
- Test on Android emulator: verify Bottom Sheet opens without obscuring timer.
- Test emoji support in chat bubbles (?? ?? ??).
- Test 3-second cooldown ring UX.
- Consider persisting last N messages per room in Supabase if users request chat history.

?? Notes / Issues
- room_sheet.dart has 3 pre-existing analysis errors (broken import of room_detail_screen.dart) � not introduced by this feature.
- Stitch MCP generated a full 'Nocturnal Scholar' design system spec � available at project 271650421636417831 for future UI reference.
- ChatService is a singleton � it persists across navigation. leaveRoomChat() is called in dispose() to clean up room channel correctly.


[2026-04-29 05:15] � Unified Sidebar Refinement & Syntax Fixes
? Completed
- Fixed all syntax errors in home_screen.dart caused by malformed escape characters (\' -> ').
- Refactored room_detail_screen.dart to remove references to the deprecated chat_bottom_sheet.dart.
- Removed unused imports (google_fonts, chat_message) across the codebase.
- Verified zero analysis errors with lutter analyze.

?? Changes
- Modified lib/screens/home_screen.dart: Removed literal backslashes from tooltip strings.
- Modified lib/screens/room_detail_screen.dart: Removed _buildChatFab() and imports related to bottom sheet chat.
- Modified lib/screens/room_sheet.dart: No changes needed directly, but the uri_does_not_exist error was resolved by fixing 
oom_detail_screen.dart.
- Modified lib/main.dart & lib/widgets/sidebar_chat.dart: Cleaned up unused imports.

?? Status
- Phase 3 Unified Sidebar Architecture: 100% completed and clean.

?? Next Steps
- Verify the desktop-to-mobile responsive transition in a live build.
- Continue monitoring UI consistency and performance metrics.

?? Notes / Issues
- Encoding issue encountered in 
oom_detail_screen.dart causing python/dart file reading issues, fixed by rewriting the file in utf-8 without the bad chars.
$content

[2026-05-01 14:55] � Hybrid Font System Refinement (Local Inter & PurnoBCC)
? Completed
- Implemented local bundling of Inter font to eliminate network latency (FOUT).
- Configured a robust hybrid font system: Inter for English/UI, PurnoBCC for Bangla fallback.
- Resolved dropdown rendering inconsistency in Chapter Selection box.
- Added explicit font fallbacks to Sidebar Chat messages and usernames.
- Fixed missing flutter_dotenv import in main.dart.

?? Changes
- Modified pubspec.yaml: Registered 'Inter' and 'PurnoBCC' (Regular/Semibold) from local assets.
- Modified lib/main.dart: Set primary fontFamily to 'Inter' and added global fontFamilyFallback.
- Modified lib/screens/room_detail_screen.dart: Explicitly added PurnoBCC fallback to DropdownButtonFormField and DropdownMenuItem children.
- Modified lib/widgets/sidebar_chat.dart: Added PurnoBCC fallback to chat message and username TextStyles.

?? Status
- Typography System: 100% refined and optimized for multi-language performance.
- flutter analyze: Clean (No issues found).

?? Next Steps
- Continue monitoring UI rendering on physical devices to ensure no other 'context pierces' are required for fallbacks.
- Finalize any remaining Phase 3 UI polish.

?? Notes / Issues
- The google_fonts package is now unused in main.dart as we've moved to local assets for Inter.


[2026-05-06 17:58] � Codex Audit Bug Fixes (Findings #2-#6)
? Completed
- Fix #2 (High): AppRouter converted to reactive auth routing. Now subscribes to onAuthStateChange via StreamSubscription in initState(). build() reads live _session field instead of one-shot currentSession snapshot. Subscription cancelled in dispose(). Navigator.pop() removed from profile_setup_screen.dart sign-out handler (AppRouter handles routing automatically).
- Fix #3 (High): joinRoom() race window eliminated. Replaced read-then-insert (maybeSingle + insert) with a single atomic upsert(onConflict: 'room_id,user_id', ignoreDuplicates: true). Join is now idempotent regardless of concurrency.
- Fix #4 (High): sendMessage() made async; now awaits channel.sendBroadcastMessage() Future. Added sendFailed ChatSendResult variant with rollback of optimistic append on transport failure. _handleSend() in sidebar_chat.dart rewritten to check returned ChatSendResult enum � input only cleared on ChatSendResult.success.
- Fix #5 (Medium): Leaderboard fetch errors no longer silently masquerade as empty data. Added _fetchError String? field. Outer catch sets it. build() renders _buildFetchError() widget (icon + message + Retry button) when non-null.
- Fix #6 (Medium): ChatService stale username fixed. Added _resetUserIdentity() method. Constructor now subscribes to onAuthStateChange; calls reset on signedOut, signedIn, userUpdated events. Auth StreamSubscription cancelled in dispose().
- Finding #1 (Critical/dotenv): Confirmed already fixed in codebase � import present, analyze passed before changes.

?? Changes
- [MODIFIED] lib/services/chat_service.dart: async sendMessage(), sendFailed enum, _resetUserIdentity(), auth StreamSubscription in constructor, cancel in dispose()
- [MODIFIED] lib/widgets/sidebar_chat.dart: _handleSend() now async, awaits sendMessage(), checks ChatSendResult enum
- [MODIFIED] lib/screens/app_router.dart: StreamSubscription<AuthState> on onAuthStateChange, live _session field, dispose() cancellation
- [MODIFIED] lib/screens/profile_setup_screen.dart: removed Navigator.pop() after signOut()
- [MODIFIED] lib/services/room_service.dart: joinRoom() uses upsert(onConflict, ignoreDuplicates) instead of maybeSingle+insert
- [MODIFIED] lib/screens/leaderboard_screen.dart: _fetchError field, _buildFetchError() widget with Retry button

?? Status
- Bug fixes: 5/5 complete (100%)
- dart analyze lib: 0 issues
- Phase: Post-Audit Hardening � Complete

?? Next Steps
- Apply UNIQUE INDEX on room_members(room_id, user_id) in Supabase dashboard for full DB-side race protection
- Manual test: sign-out from profile setup screen ? verify LoginScreen appears without Navigator.pop
- Manual test: send chat on cooldown ? verify input NOT cleared, error shown
- Manual test: simulate leaderboard fetch failure ? verify error widget + Retry renders

?? Notes / Issues
- DB-side UNIQUE constraint on room_members not applied (requires Supabase dashboard access). Client-side upsert is safe without it but a DB constraint is the belt-and-suspenders guard.
- ChatService is a singleton � the auth subscription in constructor persists for app lifetime (correct by design).

[2026-05-06 18:12] � DB Migration: UNIQUE INDEX on room_members
? Completed
- Applied CREATE UNIQUE INDEX IF NOT EXISTS uniq_room_members ON room_members(room_id, user_id) via Supabase Management API.
- Verified: pg_indexes query confirms index exists with btree on (room_id, user_id).

?? Changes
- [DB MIGRATION] Supabase project uenpxgcngqzggxmqifpw: uniq_room_members UNIQUE INDEX on public.room_members(room_id, user_id)

?? Status
- Fix #3 (Room Join Race): 100% complete � client-side upsert + DB-level UNIQUE constraint both in place.
- All 6 audit findings resolved.

?? Next Steps
- Manual QA: verify room join, auth routing, chat send, leaderboard error display.

?? Notes / Issues
- Index applied via Supabase Management API (POST /v1/projects/{ref}/database/query). No migration file created � consider adding to a tracked migrations folder for repo auditability.


[2026-05-06 18:19] - Future Roadmap Review
? Completed
- Reviewed 'Study Sync Future Upgrades.md' (Tab 1 & Tab 2) and 'docs/future plans.md' against current post-audit codebase state.
- Synthesized findings into a 4-phase roadmap (Phase 4 through Phase 7) with risk ratings, DB surface gaps, and a dependency map.

?? Changes
- [ARTIFACT] StudySync_Roadmap_Review.md created in brain/ artifacts directory.
- No code changes made (review/planning only).

?? Status
- Phase: Pre-Phase 4 Planning
- All audit findings resolved. Roadmap reviewed and prioritized.

?? Next Steps
- Phase 4: Minimalist Login UI + Google OAuth (zero DB dependencies, builds on hardened AppRouter)
- Phase 5: Replace home screen placeholder data with live queries
- Phase 6: Streak tracking, daily goals, gamification
- Phase 7: Social graph, persistent chat, reactions, notifications

?? Notes / Issues
- Quick Reactions require a full chat persistence refactor (ephemeral broadcast ? DB-backed messages)  
- All stats extensions must be additive to get_my_stats to avoid breaking stats_dashboard_screen.dart
- uniq_room_members DB migration has no tracked migration file yet.


[2026-05-06 18:35] - Ephemeral Broadcast Reactions - Design Plan Added
? Completed
- Reviewed proposed ephemeral broadcast reactions design (no DB required).
- Confirmed architecture: reactions sent as a second typed broadcast event ('chat_reaction'), targeting messages by client-generated prefixed message IDs.
- Updated StudySync_Roadmap_Review.md with full implementation plan covering: uuid package, updated ChatMessage model, _generateMessageId(), sendReaction(), _applyReaction(), reaction event handler, and UI long-press picker + reaction pills.
- Downgraded Quick Reactions from 'Very High effort / DB refactor required' to 'Medium effort / Zero DB'.

?? Changes
- [ARTIFACT] StudySync_Roadmap_Review.md updated: Phase 7 table, priority matrix, DB surface table, and new 'Ephemeral Broadcast Reactions Implementation Plan' section appended.
- No code changes (planning only).

?? Status
- Phase: Pre-Phase 4 Planning (roadmap fully documented)
- pubspec.yaml: unchanged (uuid not yet added)

?? Next Steps
- Decide which phase to tackle next (recommended: Phase 4 - Minimalist Login + Google OAuth)
- When ready to implement reactions: follow 5-step plan in roadmap artifact (4 files to change, no DB migrations)

?? Notes / Issues
- Quick Reactions toggle (double-tap to remove own reaction) is built into _applyReaction() design.
- Late-joiner trade-off accepted: reactions and messages are equally ephemeral by design.

[2026-05-07 16:21] - Ephemeral Broadcast Reactions Implemented
✅ Completed
- Added `uuid` package to pubspec.yaml.
- Made `ChatMessage` mutable and added `messageId` and `reactions` properties.
- Updated `ChatService` to handle reaction broadcasts, messageId generation, and optimistic updates.
- Integrated emoji picker (on long-press) and reaction pills into `SidebarChat` widget.

🔧 Changes
- `pubspec.yaml`: Added `uuid` dependency.
- `lib/models/chat_message.dart`: Added `messageId` and `reactions`.
- `lib/services/chat_service.dart`: Added `_generateMessageId()`, `sendReaction()`, `_onIncomingReaction()`, and `_applyReaction()`.
- `lib/widgets/sidebar_chat.dart`: Wrapped message bubble in `GestureDetector` with a `showModalBottomSheet` for the emoji picker and added `_buildReactions()`.

📊 Status
- Phase: Phase 3 (Chat) completed (ephemeral reactions added). Pre-Phase 4 Planning. % progress toward next milestone: Ready for Phase 4 (Minimalist Login + Google OAuth).

🚀 Next Steps
- Proceed with Phase 4 (Minimalist Login + Google OAuth).

⚠️ Notes / Issues
- Reactions are purely ephemeral and tied to the broadcast session. If a user leaves and rejoins, reactions will not be restored, which aligns with the ephemeral nature of the chat itself.

[2026-05-08 10:44] — Phase 4: Auth & Deep Link Hardening
✅ Completed
- Implemented deep link handling using `app_links` in `AppRouter` for Windows OAuth callback support.
- Updated `LoginScreen` Google OAuth flow with a visual feedback delay to prevent UI flashing and lock-up.
- Added explicit database migration file `20260508000000_uniq_room_members.sql`.
- Resolved Supabase Flutter SDK v2 API changes (positional `OAuthProvider` argument).

🔧 Changes
- [MODIFIED] `lib/screens/app_router.dart`: Added `AppLinks` stream listener to intercept `studysync://` URLs.
- [MODIFIED] `lib/screens/login_screen.dart`: Updated `_signInWithGoogle` to use `Future.delayed` and correct positional provider argument.
- [NEW] `supabase/migrations/20260508000000_uniq_room_members.sql`: Created migration file.

📊 Status
- Phase 4 (Auth & Onboarding Polish): Completed (100%).
- Ready for Phase 5 (Live Data Integration).

🚀 Next Steps
- Transition to Phase 5: Replace home screen placeholders with live Supabase data queries.
- Implement room fetching and active session synchronization on the dashboard.

⚠️ Notes / Issues
- Supabase SDK v2 API changes required updating `signInWithOAuth` syntax. `dart analyze` passes with zero issues.

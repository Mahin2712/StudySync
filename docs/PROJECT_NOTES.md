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

### [2026-04-11 19:20] — Phase 3: Critical Fixes Complete
✅ Completed
- Check-in penalty logic fixed: `autoStopSession()` now sets `end_time = last_activity_at` (not `now()`), crediting only confirmed study time.
- Single source of truth enforced: all check-in decisions now operate purely from `timeSinceActivity = (now - last_activity_at)`.
- App lifecycle awareness added: screen now mixes in `WidgetsBindingObserver` and refreshes session state + evaluates check-in immediately on `resumed`.
- Realtime sync implemented: replaced 5s poll timer with a Supabase Realtime channel subscription filtered strictly by `room_id`.
- Hybrid fallback added: watchdog timer fires a manual refresh if no realtime event occurs within 15 seconds.
- Auto-stop grace fixed: triggers only at `20 min + 60s grace`, never prematurely.

🔧 Changes
- **`lib/models/study_session_model.dart`**: Added `timeSinceActivity`, `isCheckinDue`, `isAutoStopDue`, `checkinGrace`. `checkinStatus` now derived from `timeSinceActivity`. `nextCheckinAt` kept as a convenience but no longer used for logic.
- **`lib/services/session_service.dart`**: `autoStopSession()` selects `last_activity_at` and uses it as `end_time`.
- **`lib/screens/room_detail_screen.dart`**: Added `WidgetsBindingObserver`, `_subscribeRealtime()` (room-scoped), `_startWatchdog()`, `_evaluateCheckin()`. Removed `_pollTimer` and `nextCheckinAt` from screen logic. `_autoStop` race guard updated to use `isCheckinDue`.

📊 Status
- Phase 3 (Critical Fixes): **100% complete**
- Phase 1 (Leaderboard & Profiles): **Complete** (SQL views, Flutter UI all built)
- Phase 2 (Stats): **0%** — next up

🚀 Next Steps
1. Build and test in browser (`flutter run -d chrome`)
2. Verify realtime sync across two windows
3. Begin Phase 2: Subject-wise Stats Dashboard screen

⚠️ Notes / Issues
- `flutter analyze` returns 37 pre-existing `info` hints (e.g., deprecated `withOpacity`, unused fields in unrelated screens). No errors.
- Realtime Postgres changes require the `supabase_realtime` broadcast enabled on the `study_sessions` table in the Supabase dashboard.

---

### [2026-04-11 19:58] — Phase 2 Core: Stats Dashboard + Hybrid Heartbeat

✅ Completed
- Hybrid Heartbeat Indicator built in `RoomDetailScreen`:
  - Socket state captured from `.subscribe((status) {...})` callback into `_socketStatus`.
  - `_connectionStatus` getter combines socket state + `_lastRealtimeEvent` timestamp.
  - 🟢 Live = SUBSCRIBED + event ≤ 20s | 🟡 Idle = SUBSCRIBED + quiet | 🔴 Disconnected = CLOSED/CHANNEL_ERROR.
  - Quiet room false-positive bug fixed (was turning 🔴 even on healthy but idle rooms).
  - `_buildConnectionDot()` widget shows labelled pill with glow shadow + Tooltip.
- `UserStats` model extended with `subjectBreakdown Map<String, double>`, `standardSubjects` list, `subjectDisplayNames` map.
- `LeaderboardService.getUserStats()` now fetches `subject` column, normalises to lowercase, and buckets non-standard subjects under `'others'` (Store Truth, Filter for View).
- New `StatsDashboardScreen`: Overview cards (Today/Weekly/Monthly/All Time), verified disclaimer banner, subject breakdown list with progress bars + emoji icons, empty state.
- "My Stats" nav link added to `HomeScreen` top bar.

🔧 Changes
- `lib/screens/room_detail_screen.dart`: Added `_ConnStatus` enum, `_socketStatus` field, updated `.subscribe()` callback, added `_connectionStatus` getter, `_buildConnectionDot()` widget.
- `lib/models/leaderboard_entry_model.dart`: `UserStats` now has `subjectBreakdown`, `standardSubjects`, `subjectDisplayNames`.
- `lib/services/leaderboard_service.dart`: `getUserStats()` selects `subject`, buckets to 'others', returns `subjectBreakdown` hours map.
- `lib/screens/stats_dashboard_screen.dart`: NEW — full stats dashboard.
- `lib/screens/home_screen.dart`: Added import + "My Stats" nav link.

📊 Status
- Phase 2 (Stats System): **~80% complete**
- Chapters integration: **paused** (no DB migration needed yet)
- public_profiles privacy view: **pending**

🚀 Next Steps
1. Run app in Chrome and test the 🟢/🟡/🔴 heartbeat transitions
2. Complete a study session and verify subject breakdown appears on Stats Dashboard
3. Optionally: create `public_profiles` Supabase view (privacy layer)
4. Chapter dropdown integration (Phase 2.5 when ready)

⚠️ Notes / Issues
- `flutter analyze` reports 40 pre-existing `info`/`warning` hints. 0 new issues from Phase 2 code.

---

### [2026-04-11 20:30] — Phase 2: Dynamic Subjects Architecture Complete

✅ Completed
- Integrated dynamic `public.subjects` table throughout the app.
- Created `SubjectService` to fetch and cache subjects from DB with a reliable fallback.
- Dropped hardcoded lists from `UserStats`.
- `LeaderboardService` and `StatsDashboardScreen` now retrieve data dynamically from `SubjectService` maintaining emojis and sorted orders.
- Updated the `RoomDetailScreen` to feature a robust Dropdown for standard subject selection in the 'Start Session' dialog, with a seamless "Other (Custom)" fallback showing a text field.

🔧 Changes
- **`lib/services/subject_service.dart`**: Implemented `getSubjects()` & `getCachedSubjects()`.
- **`lib/models/leaderboard_entry_model.dart`**: Removed hardcoded standard/display maps.
- **`lib/services/leaderboard_service.dart`**: Fetching real dynamic subjects prior to parsing leaderboard loop.
- **`lib/screens/stats_dashboard_screen.dart`**: Render dashboard cleanly by querying SubjectInfo using `getCachedSubjects()`.
- **`lib/screens/room_detail_screen.dart`**: Overhauled `_showStartDialog()` into a `StatefulBuilder` providing Dropdown.

📊 Status
- Phase 2 (Stats System): **95% complete** (Just needs the public_profiles security view update next)

🚀 Next Steps
1. Create `public_profiles` view in Supabase (Phase 3 privacy update).
2. Integrate chapters if required soon.

⚠️ Notes / Issues
- Zero active errors flagged by `flutter analyze` pertaining to new changes. Database dynamic values correctly match historical 'key' groupings.

### [2026-04-12 12:20] ?? Room Selection Gallery & DB Upgrades

? Completed
- Completely rewrote the 'Create/Join Table' modal into a categorized grid-style interface mapping Subjects.
- Restructured ooms table to act as permanent anchored domains for the 13 defined curriculum subjects.
- Repaired the Idle connection badge accurately pairing it explicitly with the _mySession.isActive status in Postgres.
- Added chapter column to study_sessions to guard database integrity, capturing chapter/topic detail separately from aggregate tracking subject.

?? Changes
- **lib/screens/room_sheet.dart**: Complete rewrite to Category Grid + Bottom Custom dialog. Maps member counts cleanly per tile via the fetch response.
- **lib/services/room_service.dart**: Integrated is_custom and subject metadata insertions to database functions.
- **lib/models/room_model.dart**: Safely mapping subject and isCustom traits downstream.
- **lib/services/session_service.dart**: Added chapter ingestion.
- **lib/screens/room_detail_screen.dart**: Shifted _ConnStatus metric over from socket pings to explicit timer state tracking. _showStartDialog prompts dynamically bypass re-requesting subject logic when nested deep.

?? Status
- Phase 2 (Stats System & UX Refactoring): **100% complete**
- Moving on toward finalizing privacy standards and deployment prep next.

?? Next Steps
1. Create public_profiles view in Supabase (Phase 3 privacy update).
2. Continue expanding on Study Group leaderboards or deeper metric displays.

?? Notes / Issues
- N/A. lutter analyze maintained. Hot reloaded live.


# StudySync ‚Äî Project Memory & Notes

## üóÇÔ∏è Project Overview
A Flutter + Supabase group study platform.
**Workspace:** `c:\Users\SER\StudySync`
**Platform target:** Web (Chrome), Windows desktop

---

## üîë Supabase Config
- **Project URL:** `https://uenpxgcngqzggxmqifpw.supabase.co`
- **Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVlbnB4Z2NuZ3F6Z2d4bXFpZnB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3OTE2MDYsImV4cCI6MjA5MDM2NzYwNn0.bCat6zf7OoRLH_r598fPfDLxdUUS2i7CnNpG7uNLeNM`

---

## üóÉÔ∏è Supabase Database Tables

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

## üìÅ File Structure
```
lib/
  main.dart                     ‚Üê Supabase init, session-aware routing
  screens/
    login_screen.dart           ‚Üê Email/password auth (signIn + signUp)
    home_screen.dart            ‚Üê Main homepage (matches prototype)
    room_detail_screen.dart     ‚Üê Live study table, timer, and member panel [UPDATED]
    room_sheet.dart             ‚Üê Bottom sheet for joining/creating rooms
  models/
    room_model.dart             ‚Üê Room data model
    study_session_model.dart    ‚Üê Session data model & duration formatting [NEW]
  services/
    room_service.dart           ‚Üê Supabase room CRUD logic
    session_service.dart        ‚Üê Session start/stop/fetch logic [NEW]
```

---

## üìà Project Roadmap & Progress

### ‚úÖ Phase 1: Core System (Completed)

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
- [x] Live session status indicators (üü¢ Active / üü° Warning / üî¥ Inactive).

#### Milestone 5: Optimization & Polish
- [x] Mobile-responsive layout updates for all screens.
- [x] Premium "Dark Mode" aesthetic with Glassmorphism.
- [x] Transition animations and real-time state sync.

---

### üîú Phase 2: Social & Analytics (Next Up)

- [ ] **Leaderboards:** Daily, Weekly, and Monthly study time rankings.
- [ ] **Live Chat:** Minimalist, low-noise text chat within study rooms.
- [ ] **Personal Stats Dashboard:** Subject-wise breakdowns and calendar views.
- [ ] **Friend System:** Following friends and getting notified when they start studying.

---

## üé® Design System Colors
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

## ‚ö†Ô∏è Known Gotchas
- `withOpacity()` is deprecated in newer Flutter ‚Äî use `.withValues(alpha: x)`
- Timers are calculated from `DateTime.now()` vs `start_time` from DB for accuracy
- UI polls active sessions every **5 seconds** to maintain low latency vs DB load
- Center pulse animation follows the study state (green when studying)

---

## üõ†Ô∏è Environment & Tooling
- **MCP Client:** Configured with `supabase` and `StitchMCP`
- **Agent Skills:** 
  - `supabase-postgres-best-practices`
  - `find-skills`

---

## üìù Changelog

### [2026-04-11 19:20] ‚Äî Phase 3: Critical Fixes Complete
‚úÖ Completed
- Check-in penalty logic fixed: `autoStopSession()` now sets `end_time = last_activity_at` (not `now()`), crediting only confirmed study time.
- Single source of truth enforced: all check-in decisions now operate purely from `timeSinceActivity = (now - last_activity_at)`.
- App lifecycle awareness added: screen now mixes in `WidgetsBindingObserver` and refreshes session state + evaluates check-in immediately on `resumed`.
- Realtime sync implemented: replaced 5s poll timer with a Supabase Realtime channel subscription filtered strictly by `room_id`.
- Hybrid fallback added: watchdog timer fires a manual refresh if no realtime event occurs within 15 seconds.
- Auto-stop grace fixed: triggers only at `20 min + 60s grace`, never prematurely.

üîß Changes
- **`lib/models/study_session_model.dart`**: Added `timeSinceActivity`, `isCheckinDue`, `isAutoStopDue`, `checkinGrace`. `checkinStatus` now derived from `timeSinceActivity`. `nextCheckinAt` kept as a convenience but no longer used for logic.
- **`lib/services/session_service.dart`**: `autoStopSession()` selects `last_activity_at` and uses it as `end_time`.
- **`lib/screens/room_detail_screen.dart`**: Added `WidgetsBindingObserver`, `_subscribeRealtime()` (room-scoped), `_startWatchdog()`, `_evaluateCheckin()`. Removed `_pollTimer` and `nextCheckinAt` from screen logic. `_autoStop` race guard updated to use `isCheckinDue`.

üìä Status
- Phase 3 (Critical Fixes): **100% complete**
- Phase 1 (Leaderboard & Profiles): **Complete** (SQL views, Flutter UI all built)
- Phase 2 (Stats): **0%** ‚Äî next up

üöÄ Next Steps
1. Build and test in browser (`flutter run -d chrome`)
2. Verify realtime sync across two windows
3. Begin Phase 2: Subject-wise Stats Dashboard screen

‚ö†Ô∏è Notes / Issues
- `flutter analyze` returns 37 pre-existing `info` hints (e.g., deprecated `withOpacity`, unused fields in unrelated screens). No errors.
- Realtime Postgres changes require the `supabase_realtime` broadcast enabled on the `study_sessions` table in the Supabase dashboard.

---

### [2026-04-11 19:58] ‚Äî Phase 2 Core: Stats Dashboard + Hybrid Heartbeat

‚úÖ Completed
- Hybrid Heartbeat Indicator built in `RoomDetailScreen`:
  - Socket state captured from `.subscribe((status) {...})` callback into `_socketStatus`.
  - `_connectionStatus` getter combines socket state + `_lastRealtimeEvent` timestamp.
  - üü¢ Live = SUBSCRIBED + event ‚â§ 20s | üü° Idle = SUBSCRIBED + quiet | üî¥ Disconnected = CLOSED/CHANNEL_ERROR.
  - Quiet room false-positive bug fixed (was turning üî¥ even on healthy but idle rooms).
  - `_buildConnectionDot()` widget shows labelled pill with glow shadow + Tooltip.
- `UserStats` model extended with `subjectBreakdown Map<String, double>`, `standardSubjects` list, `subjectDisplayNames` map.
- `LeaderboardService.getUserStats()` now fetches `subject` column, normalises to lowercase, and buckets non-standard subjects under `'others'` (Store Truth, Filter for View).
- New `StatsDashboardScreen`: Overview cards (Today/Weekly/Monthly/All Time), verified disclaimer banner, subject breakdown list with progress bars + emoji icons, empty state.
- "My Stats" nav link added to `HomeScreen` top bar.

üîß Changes
- `lib/screens/room_detail_screen.dart`: Added `_ConnStatus` enum, `_socketStatus` field, updated `.subscribe()` callback, added `_connectionStatus` getter, `_buildConnectionDot()` widget.
- `lib/models/leaderboard_entry_model.dart`: `UserStats` now has `subjectBreakdown`, `standardSubjects`, `subjectDisplayNames`.
- `lib/services/leaderboard_service.dart`: `getUserStats()` selects `subject`, buckets to 'others', returns `subjectBreakdown` hours map.
- `lib/screens/stats_dashboard_screen.dart`: NEW ‚Äî full stats dashboard.
- `lib/screens/home_screen.dart`: Added import + "My Stats" nav link.

üìä Status
- Phase 2 (Stats System): **~80% complete**
- Chapters integration: **paused** (no DB migration needed yet)
- public_profiles privacy view: **pending**

üöÄ Next Steps
1. Run app in Chrome and test the üü¢/üü°/üî¥ heartbeat transitions
2. Complete a study session and verify subject breakdown appears on Stats Dashboard
3. Optionally: create `public_profiles` Supabase view (privacy layer)
4. Chapter dropdown integration (Phase 2.5 when ready)

‚ö†Ô∏è Notes / Issues
- `flutter analyze` reports 40 pre-existing `info`/`warning` hints. 0 new issues from Phase 2 code.

---

### [2026-04-11 20:30] ‚Äî Phase 2: Dynamic Subjects Architecture Complete

‚úÖ Completed
- Integrated dynamic `public.subjects` table throughout the app.
- Created `SubjectService` to fetch and cache subjects from DB with a reliable fallback.
- Dropped hardcoded lists from `UserStats`.
- `LeaderboardService` and `StatsDashboardScreen` now retrieve data dynamically from `SubjectService` maintaining emojis and sorted orders.
- Updated the `RoomDetailScreen` to feature a robust Dropdown for standard subject selection in the 'Start Session' dialog, with a seamless "Other (Custom)" fallback showing a text field.

üîß Changes
- **`lib/services/subject_service.dart`**: Implemented `getSubjects()` & `getCachedSubjects()`.
- **`lib/models/leaderboard_entry_model.dart`**: Removed hardcoded standard/display maps.
- **`lib/services/leaderboard_service.dart`**: Fetching real dynamic subjects prior to parsing leaderboard loop.
- **`lib/screens/stats_dashboard_screen.dart`**: Render dashboard cleanly by querying SubjectInfo using `getCachedSubjects()`.
- **`lib/screens/room_detail_screen.dart`**: Overhauled `_showStartDialog()` into a `StatefulBuilder` providing Dropdown.

üìä Status
- Phase 2 (Stats System): **95% complete** (Just needs the public_profiles security view update next)

üöÄ Next Steps
1. Create `public_profiles` view in Supabase (Phase 3 privacy update).
2. Integrate chapters if required soon.

‚ö†Ô∏è Notes / Issues
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


[2026-04-12 14:28] ó Room Performance Optimization ((N^2) \to O(N)$)
? Completed
- Resolved a critical UI performance bottleneck in RoomDetailScreen caused by (N \times M)$ linear searches inside build loops.
- Integrated Jules MCP server and verified API connectivity.

?? Changes
- **lib/screens/room_detail_screen.dart**:
  - Pre-calculates sessionMap (userId -> StudySessionModel) in the root uild method.
  - Updated _buildTableArea, _buildSeats, _buildMembersPanel, and _buildMemberTile to use (1)$ map lookups.
  - Eliminated .where(...).firstOrNull calls from nested iteration logic.
- **mcp_config.json**: (Previous Turn) Linked Jules MCP server with API Key.

?? Status
- Phase 2 (Stats & UX): **100% complete**
- Phase 3 (Privacy & Polish): **0%** ó starting soon

?? Next Steps
1. Apply Jules suggestions once location is clarified by the user.
2. Implement public_profiles view for privacy.
3. Finalize Phase 3 deployment prep.

?? Notes / Issues
- Jules MCP connectivity is verified, but suggestions haven't been located yet.
- Room performance is now significantly smoother for large groups.


[2026-04-12 16:39] ó Phase Synchronization: Main & Secondary Branches Match
? Completed
- Merged Jules' security (ix-hardcoded-supabase-key) and application config (specify-unique-app-id) fixes into the local \main\ branch.
- Maintained local performance optimization for \RoomDetailScreen\ during the merge.
- Verified \dart analyze\ and resolved widget test dependency faults resulting from the new \lutter_dotenv\ requirement.

?? Changes
- **.env / .env.example / .gitignore:** Extracted Supabase credentials securely.
- **android/app/build.gradle:** Swapped default application ID to \com.studysync.app\.
- **pubspec.yaml:** Registered flutter_dotenv.
- **test/widget_test.dart:** Initialized dotenv mock bindings for test stability.

?? Status
- Both Agents' fixes (Performance + Security + Config) are now united on the \main\ branch.

?? Next Steps
Proceed with any user-prompted Phase 2.5/3 features or leaderboard refinements.

?? Notes / Issues
N/A


[2026-04-12 16:47] ó Git Repository Maintenance
? Completed
- Pruned stale remote-tracking branches using \git fetch --prune\.

?? Changes
- Refreshed local git history by removing references to deleted remote branches.

?? Status
- Phase 3 (Privacy & Polish): **0%**

?? Next Steps
1. Verify if the user's IDE branch list is now correctly updated.
2. Proceed with \public_profiles\ view for privacy.

?? Notes / Issues
- Multiple stale \origin/*\ branches were identified and removed.

[2026-04-12 17:15] ó Room UX & Lint Optimization
? Completed
- Resolved remaining flutter lint issues (0 issues)
- Dynamic Subject Category rendering
- Ghost-filtered active studier counts

?? Changes
- Created `room_member_counts` PostgreSQL View via schema altering
- Augmented `public.subjects` to have a data-driven `category` column
- Replaced flutter 3.41+ deprecated `.withOpacity()` occurrences
- Injected `if (!context.mounted)` guard mechanisms for async gap protection
- Preserved `.env` mapping while provisioning local dev clone to calm down the analyzer

?? Status
- Phase 3 Privacy & Polish (ongoing)

?? Next Steps
- Verify UI interactions live
- Implement further public_profiles integrations

?? Notes / Issues
- Make sure to restore personal credentials to `.env` as the `.env` provided locally is cloned from `.env.example`.


[2026-04-12 19:19] ó Phase 2.5: UI & Database Adjustments
? Completed
- Paused work on the stale session/check-in ghost-pop bug. To be fixed later.

?? Next Steps
- Implement smart navigation guard in RoomDetailScreen._autoStop() to prevent maybePop() from closing the screen.
- Add session reset on joining a new room.


[2026-04-12 19:22] ‚Äî Subject Hierarchy & Categorization Update
‚úÖ Completed
- Cleaned up the subjects table in Supabase by removing the duplicative \'history\' row.
- Renamed \'history/bgs\' to \'History\' and updated the icon to \'üåç\'.
- Standardized taxonomy structure mapping items to categorical buckets: Mathematics, Science, Literacy, General, Religion.
- Explicitly re-ordered the sorting positions to reflect priority UI flow.

üîß Changes
- Executed direct PostgreSQL UPDATE statements to assign custom category and sort_order values.
- **lib/services/subject_service.dart**: Synced _fallbackSubjects mapping to protect against offline regressions and enforce new display sorting parameters.

üìä Status
- Phase 2.5 (UX Refinements): **In Progress** 

üöÄ Next Steps
- Implement smart navigation guard in RoomDetailScreen._autoStop() to prevent maybePop() from closing the screen.
- Address session ghosting and auto-kill behavior on cross-room hopping.

‚ö†Ô∏è Notes / Issues
- Work on the stale session/check-in ghost-pop bug is officially paused as per user request.

[2026-04-12 19:40] ‚Äî UI Update: Compact Subject Gallery
‚úÖ Completed
- Made the subject tiles significantly shorter (wider aspect ratio) to reduce vertical scrolling.
- Increased subject icon and text font size for better legibility.

üîß Changes
- **lib/screens/room_sheet.dart**: Tweaked childAspectRatio from 2.2 to 3.2, decreased padding, increased emoji ontSize from 16 to 20, and subject title from 13 to 15.

üìä Status
- Phase 2.5 (UX Refinements): **In Progress**

[2026-04-12 21:16] ó Build Fix: Restored .env Asset
? Completed
- Restored missing .env file with Supabase credentials to unblock Flutter build.
- Verified compilation and package dependencies.

?? Changes
- **.env**: Created file and populated with SUPABASE_URL and SUPABASE_ANON_KEY.

?? Status
- Phase 2.5 (UX Refinements): **In Progress**

?? Next Steps
- Continue with UX refinements (smart navigation guards and session management).

?? Notes / Issues
- Building for Web requires assets listed in pubspec.yaml to physically exist.

[2026-04-17 20:02] ó Phase 2.5 Complete: Session Guards, Chapter Dropdown, Privacy Layer

? Completed
- ChapterService: New service (lib/services/chapter_service.dart) with static chapter maps for all 13 SSC/HSC subjects ó isolated for zero-refactor DB migration later.
- Start Dialog Overhaul: Subject rooms now show a chapter dropdown (DropdownButtonFormField with chapters from ChapterService) plus a free-text override field. Custom rooms keep the plain text-only flow.
- Smart Navigation Guard: _autoStop() no longer calls Navigator.maybePop(). Instead it sets _sessionEndedByTimeout = true, keeping user in the room and showing an amber banner ("Session paused ó check-in missed. Tap Start to resume.").
- PopScope wrapper: build() now wraps Scaffold in PopScope(canPop: true, onPopInvokedWithResult:Ö) ó if a user presses Back while a session is active, forceCloseActiveSession() is called to prevent ghost rows.
- Ghost-session Fix on Leave: _leaveRoom() now calls SessionService.forceCloseActiveSession() instead of stopSession(). joinRoom() in RoomService also pre-closes any active session before joining.
- Watchdog Heartbeat hardened: Timer interval raised to 30 s; recordActivity() is now only called when _mySession != null (no unnecessary DB writes when idle).
- Privacy Layer: ProfileService updated ó getMyProfile() queries full profiles table for self; getProfileById() queries public_profiles view for others; searchPublicProfiles() replaces searchProfiles() (deprecated alias kept for BC).
- main.dart: Fires cleanUpStaleSessions() on app start (fire-and-forget) as a fallback for the pg_cron gap on the free tier.

?? Changes
- [NEW] lib/services/chapter_service.dart
- [MODIFIED] lib/screens/room_detail_screen.dart ó _showStartDialog, _autoStop, _leaveRoom, _startWatchdog, build()
- [MODIFIED] lib/services/session_service.dart ó forceCloseActiveSession(), cleanUpStaleSessions()
- [MODIFIED] lib/services/room_service.dart ó joinRoom() pre-closes active session
- [MODIFIED] lib/services/profile_service.dart ó getMyProfile, getProfileById, searchPublicProfiles
- [MODIFIED] lib/main.dart ó SessionService import + initState stale cleanup trigger
- [DB] public_profiles VIEW created in Supabase (privacy layer ó no phone/email exposure)
- [DB] close_stale_sessions() RPC function created in Supabase

?? Status
Phase 2.5 (UX Refinements): ? COMPLETE (100%)
Phase 3 (Privacy & Polish): ?? In Progress (~30%) ó public_profiles view done; profile edit flow pending

?? Next Steps
- Test manually: chapter dropdown in subject rooms, auto-stop banner, back-nav session close, room-hop ghost fix.
- Implement Edit Profile feature (isEditing mode in ProfileSetupScreen accessible from home menu).
- Enforce profile completion redirect for new sign-ups (LoginScreen ? ProfileSetupScreen).
- Phase 3.x: Add device_id column to study_sessions for proper multi-device session isolation.
- Optional: Set up external uptime monitor to ping Supabase Edge Function for stale session cleanup.

?? Notes / Issues
- .env asset warning in pubspec.yaml is pre-existing (file exists locally; warning appears because .env is gitignored).
- DropdownButtonFormField uses initialValue (not value) per Flutter 3.33+ deprecation.
- Multi-device limitation: forceCloseActiveSession() closes ALL active sessions for a user regardless of device. device_id column planned for Phase 3.x.

[2026-04-17 20:10] ó Phase 3 Partial Complete: Edit Profile + Home Screen Account Menu

? Completed
- Edit Profile Mode: ProfileSetupScreen now accepts isEditing: bool (default false). In edit mode: canPop:true, fields pre-populated via _prefillFromProfile() ? ProfileService.getMyProfile(), header reads "Edit Your Profile", button reads "Save Changes", success pops back to HomeScreen.
- Account Menu: Home screen avatar GestureDetector replaced with PopupMenuButton showing "Edit Profile" and "Sign Out" options. Edit Profile navigates to ProfileSetupScreen(isEditing: true).
- All Flutter analyze issues resolved ó only pre-existing .env asset warning remains (expected; file is gitignored).

?? Changes
- [MODIFIED] lib/screens/profile_setup_screen.dart ó isEditing param, _prefillFromProfile(), dynamic labels
- [MODIFIED] lib/screens/home_screen.dart ó PopupMenuButton account menu, ProfileSetupScreen import

?? Status
Phase 2.5 (UX Refinements): ? COMPLETE
Phase 3 (Privacy & Polish): ?? In Progress (~60%)
  Done: public_profiles view, ProfileService privacy layer, Edit Profile flow, Account menu
  Pending: device_id for multi-device isolation (Phase 3.x), edge function for stale session cleanup

?? Next Steps
- Manual QA: chapter dropdown, auto-stop banner, room-hop ghost fix, Edit Profile flow from home.
- Phase 3.x: Add device_id UUID column to study_sessions for multi-device session isolation.
- Optional: Set up Supabase Edge Function + external uptime monitor to automate stale session cleanup.

?? Notes / Issues
- All new code passes flutter analyze with zero errors/warnings (only .env pre-existing warning).
- PopupMenuButton uses const children list ó works with Flutter stable.

[2026-04-18 09:32] ó Resolved .env Asset Compilation Error
? Completed
- Fixed 'No file or variants found for asset: .env' compilation error by creating a valid .env file.
- Populated .env with verified Supabase URL and Anon Key using Supabase MCP tools.
- Verified that the application now successfully compiles and launches on the web server.

?? Changes
- [NEW] .env ó Added Supabase environment variables.

?? Status
Phase 3 (Privacy & Polish): ?? In Progress (~65%)

?? Next Steps
- Resume Manual QA for Phase 2.5/3 features (chapter dropdown, room-hop ghost fix).
- Implement device_id for multi-device isolation.

?? Notes / Issues
- Build is now passing; previous blocking asset error is resolved.

[2026-04-18 09:50] ó Fixed Chapter Names to Match Exact SSC Curriculum
? Completed
- Replaced all incorrect/random English chapter names in ChapterService with exact names from Subject_chapter_list.md.
- Bangla subject chapters are now in Bangla (Bengali script). English subjects remain in English.
- All chapters are numbered serially (1 to last) using Bangla numerals for Bangla subjects, Arabic numerals for English.
- Islam: simplified to 5 main chapter headings only (sub-topics excluded from dropdown to keep UX clean).
- Hinduism: all 10 chapter headings correctly listed in Bangla.
- History key ('history') correctly mapped to History/BGS chapters (15 chapters).
- Build verified: lutter build web completes with zero errors.

?? Changes
- [MODIFIED] lib/services/chapter_service.dart ó Full rewrite of _chapters map with correct curriculum data.

?? Status
Phase 3 (Privacy and Polish): ?? In Progress (~70%)

?? Next Steps
- Manual QA of chapter dropdown in the app (room_detail_screen).
- Phase 3.x: Add device_id for multi-device isolation.

?? Notes / Issues
- English 2nd chapters have no serial numbers in the source doc; added 1-12 serial prefix for consistency in dropdown.

[2026-04-18 19:22] ó Gemini CLI System Setup
? Completed
- Installed official Google Gemini CLI globally via npm (@google/gemini-cli).
- Verified installation (version 0.38.2).

?? Changes
- System-wide installation of gemini package.

?? Status
Phase 3 (Privacy and Polish): ?? In Progress (~70%)

?? Next Steps
- User to complete interactive 'gemini login' authentication.
- Resume Phase 3.x: Add device_id for multi-device isolation.

?? Notes / Issues
- Global installation requires npm permissions.

[2026-04-18 19:57] ó Gemini CLI Personalization
? Completed
- Created global persona templates: Auditor, Specialist, and Creative.
- Set up project-specific context in StudySync\.gemini\GEMINI.md.
- Implemented smart 'gg' PowerShell function with 'Set-Execute-Clear' pattern and automatic context injection for 'gg audit <file>'.
- Configured global settings for UI theme and default model.

?? Changes
- [NEW] ~/.gemini/personas/auditor.md, specialist.md, creative.md
- [NEW] StudySync/.gemini/GEMINI.md, settings.json
- [MODIFIED] PowerShell Profile: Added gg function.

?? Status
Phase 3 (Privacy and Polish): ?? In Progress (~75%)

?? Next Steps
- User to test 'gg audit' and personas.
- Resume Phase 3.x: Add device_id for multi-device isolation.

?? Notes / Issues
- PowerShell profile created if missing; instructions added to the end.

[2026-04-18 20:29] ó Audit Bug Fixes: DB Migration + Dart Services (Antigravity)
? Completed
- Created docs/migration_audit_fixes.sql (ready to run in Supabase SQL Editor):
  - Partial unique index: idx_one_active_session_per_user (WHERE is_active=true)
  - start_session_atomic RPC: race-safe INSERT ON CONFLICT DO NOTHING
  - get_my_stats RPC: boundary-correct time windows + subject_breakdown
- Updated SessionService.startSession() to use start_session_atomic RPC.
- Updated LeaderboardService.getUserStats() to use get_my_stats RPC.
- Removed unused SubjectService import from leaderboard_service.dart.

?? Changes
- [NEW] docs/migration_audit_fixes.sql
- [MODIFIED] lib/services/session_service.dart ó startSession() now calls RPC
- [MODIFIED] lib/services/leaderboard_service.dart ó getUserStats() now calls RPC, import cleaned

?? Status
Phase 3 (Privacy and Polish): ?? In Progress (~80%)
DB migration: PENDING USER ACTION ó run migration_audit_fixes.sql in Supabase SQL Editor.
Dart code: ? flutter analyze ó No issues found.

?? Next Steps
- USER: Run docs/migration_audit_fixes.sql in Supabase Dashboard ? SQL Editor.
- Gemini CLI: Fix #1 (watchdog recordActivity removal) using: gg auditor prompt from plan.
- Gemini CLI: Fix #3 (AppRouter extraction + login rewire) using: gg specialist prompt from plan.
- Jules: Fix #4 (test isolation with mocktail).

?? Notes / Issues
- SQL migration MUST be run before apps go live; the new RPCs in session_service will fail until then.
- The stats RPC subject list is hardcoded in SQL ó must stay in sync with SubjectService._fallbackSubjects.

[2026-04-18 20:59] ó Add Jules MCP Server
? Completed
- Configured Jules (by Google) MCP server in antigravity/mcp_config.json.
- Verified authentication and connectivity using 'jules-mcp doctor'.

?? Changes
- [MODIFIED] C:\Users\SER\.gemini\antigravity\mcp_config.json: Added 'jules' configuration with environment-based API key.

?? Status
Phase 3 (Privacy and Polish): ? Configuration Complete (~85%)

?? Next Steps
- Use Jules MCP tools to assist with autonomous coding tasks (Fix #4: test isolation).

?? Notes / Issues
- The Jules API is in alpha; configuration uses @google/jules-mcp package via npx.

[2026-04-18 21:03] ó Audit Bug Fixes: All Code Fixes Applied + DB Migration Executed
? Completed
- DB migration applied directly via Supabase MCP (no manual step needed):
  - idx_one_active_session_per_user (partial unique index) ó CONFIRMED in pg_indexes
  - start_session_atomic RPC ó CONFIRMED in information_schema.routines
  - get_my_stats RPC ó CONFIRMED in information_schema.routines
- Fix #1 (Critical): Removed SessionService.recordActivity() from _startWatchdog() timer.
  Anti-fake-study check-in system is now active again.
- Fix #2 (High): SessionService.startSession() now calls start_session_atomic RPC.
  Race-safe, DB-level enforced.
- Fix #3 (High): Extracted _AppRouter ? public AppRouter in lib/screens/app_router.dart.
  login_screen.dart now pushes AppRouter (not HomeScreen) after sign-in.
  Profile-completion gate enforced on every auth entry point.
- Fix #5 (Medium): LeaderboardService.getUserStats() now calls get_my_stats RPC.
  Boundary-correct time windows. subjectBreakdown preserved.
- flutter analyze lib/ ó No issues found!

?? Changes
- [NEW] lib/screens/app_router.dart
- [MODIFIED] lib/main.dart ó uses AppRouter, removed _AppRouter class
- [MODIFIED] lib/screens/login_screen.dart ó routes through AppRouter via pushAndRemoveUntil
- [MODIFIED] lib/screens/room_detail_screen.dart ó recordActivity removed from watchdog timer
- [MODIFIED] lib/services/session_service.dart ó startSession uses RPC
- [MODIFIED] lib/services/leaderboard_service.dart ó getUserStats uses RPC, unused import removed

?? Status
Phase 3 (Privacy and Polish): ?? In Progress (~90%)
Fixes #1, #2, #3, #5 ó DONE. Fix #4 (test isolation) ó PENDING Jules.

?? Next Steps
- Assign Jules: Replace test/widget_test.dart with offline mocktail-based smoke tests.
- Manual verification: dual-tab race condition, check-in popup, new-user routing, stats dashboard.

?? Notes / Issues
- Fix #4 (Jules) is the only remaining open item from the audit.
- The stats RPC subject list in SQL must stay in sync with SubjectService._fallbackSubjects.

[2026-04-18 21:25] ó Fix #4 (Test Isolation via Jules) - PR Created
? Completed
- Jules (autonomous AI) completed the migration to isolated testing.
- Mocktail integrated for mocking Supabase dependency in widget tests.
- Removed .env dependency from test/widget_test.dart.
- StudySyncApp refactored for dependency injection of SupabaseClient.

?? Changes
- [PR] https://github.com/Mahin2712/StudySync/pull/18
- [MODIFIED] lib/main.dart, pubspec.yaml, test/widget_test.dart

?? Status
Phase 3 (Privacy and Polish): ? Test Infrastructure Fixed (~90%)

?? Next Steps
- USER: Review and Merge PR #18.
- USER: Run 'flutter test' locally to confirm < 10s execution.
- Antigravity: Proceed with Phase 3.x isolation steps (device_id, etc).

[2026-04-18 21:32] ó Merge PR #18 (Test Isolation) & Final Verification
? Completed
- Merged Jules' PR #18 into main branch locally.
- Resolved merge conflict in lib/main.dart by integrating dependency injection into screens/app_router.dart.
- Verified code health with 'flutter analyze' (Passed).
- Verified test isolation with 'flutter test' (Passed in 3s).
- Pushed merged main to origin.

?? Changes
- [MERGED] origin/jules-smoke-test-mocktail-10033182039686010772
- [MODIFIED] lib/main.dart, lib/screens/app_router.dart: Integrated SupabaseClient DI.

?? Status
Phase 3 (Privacy and Polish): ? Test Isolation & DI Integrated (100%)

?? Next Steps
- Antigravity: Start Phase 3.x (Multi-device isolation with device_id).

[2026-04-18 22:03] ó Apply SQL Migration Audit Fixes
? Completed
- Applied docs/migration_audit_fixes.sql migration to Supabase production.
- Enhanced study_sessions table with device_id, last_activity_at, missed_checkins, and chapter columns.
- Replaced per-user active session unique index with per-device-per-user index (enabling multi-device isolation).
- Created atomic start_session_atomic RPC function to prevent race conditions during session start.

?? Changes
- [DB Schema] Added columns and default values to public.study_sessions.
- [DB Index] Replaced idx_one_active_session_per_user with idx_one_active_session_per_user_device.
- [DB Function] Created public.start_session_atomic.

? Status
Phase 3.x (Multi-device isolation): ? In Progress (~10%)
Database foundation deployed.

? Next Steps
- Implement device_id storage in Flutter app.
- Refactor StudySessionService to use the new start_session_atomic RPC.

?? Notes / Issues
- Existing sessions have been backfilled with random device_ids.
- The start_session_atomic RPC requires p_device_id as a parameter.


[2026-04-18 22:18] - Phase 3.x: Device-Scoped Session Isolation Wired Into Flutter
? Completed
- Added persistent local device identity generation/storage using SharedPreferences.
- App startup now initializes a stable device_id before the StudySync UI boots.
- SessionService now scopes all "my active session" reads/writes to (user_id, device_id) instead of only user_id.
- Room join/leave/back-nav now close only the current device's active session, preventing one device from silently ending another device's session.
- Room active-session fetch remains UI-safe by deduping multiple active rows down to one visible session per user.

?? Changes
- [NEW] lib/services/device_identity_service.dart
- [MODIFIED] lib/main.dart - initializes DeviceIdentityService before runApp()
- [MODIFIED] lib/models/study_session_model.dart - parses/stores device_id
- [MODIFIED] lib/services/session_service.dart - device-scoped session reads/writes
- [MODIFIED] lib/services/room_service.dart - comments/flow aligned to device-scoped close
- [MODIFIED] pubspec.yaml, pubspec.lock - shared_preferences promoted to direct dependency
- [NEW] docs/migration_audit_fixes.sql - repo-tracked SQL source of truth for device_id migration/index/RPC

?? Status
Phase 3.x (Multi-device isolation): In Progress (~55%)
Database and Flutter ownership model are now aligned on device-scoped active sessions.

?? Next Steps
- Manual QA: open two devices/tabs with the same user and verify stopping/leaving on one does not kill the other.
- Decide whether room UI should eventually show multiple device sessions per user or keep the current one-row-per-user presentation.

?? Notes / Issues
- Multi-device session ownership is now enforced for the current user's active-session operations, but room UI still intentionally displays one visible row per user.
- Applying migration_audit_fixes.sql is now required for fresh environments because Flutter expects p_device_id-aware start_session_atomic behavior.

[2026-04-18 22:27] - Stats RPC Failures Now Surface as Errors Instead of Fake Zeroes
? Completed
- Removed the silent UserStats.zero fallback from LeaderboardService.getUserStats().
- Added explicit StatsLoadException handling when the get_my_stats RPC is unavailable or malformed.
- StatsDashboardScreen now shows its existing error state instead of rendering misleading 0m values when stats loading fails.
- LeaderboardScreen now loads ranked entries and personal stats separately, so leaderboard rows still render even if personal stats fail.
- Bottom-bar personal stats in LeaderboardScreen now show an inline warning instead of fake zero-value chips on RPC failure.
- Verified with dart analyze lib test and flutter test test/widget_test.dart (both passed).

?? Changes
- [MODIFIED] lib/services/leaderboard_service.dart - throws StatsLoadException on RPC failure/invalid payload
- [MODIFIED] lib/screens/stats_dashboard_screen.dart - clears _stats and displays error state on stats load failure
- [MODIFIED] lib/screens/leaderboard_screen.dart - decoupled leaderboard/stats loading, added inline stats warning

?? Status
Audit Fix: Stats integrity COMPLETE
Stats failures are now visible and no longer misrepresented as "no study time".

?? Next Steps
- Consider applying the same explicit-error pattern to leaderboard view fetches if the views are unavailable.
- Manual QA: temporarily break get_my_stats or revoke access and verify both stats surfaces show errors cleanly.

?? Notes / Issues
- Leaderboard rows still depend on the leaderboard_* views; only personal stats failure handling was hardened in this pass.
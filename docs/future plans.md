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
| Quick Reactions (double-tap emoji) | Tab 1 | 🔴 High | **Must persist chat messages first** (see below) |

> [!CAUTION]
> **Quick Reactions require a full chat architecture change.** Current `ChatService` uses Supabase Realtime broadcast — messages are ephemeral with no IDs, no persistence, and no way to address a specific message to react to. To implement reactions, you must first:
> 1. Create a `chat_messages` table (room_id, user_id, content, created_at)
> 2. Switch `ChatService` from `channel.sendBroadcastMessage()` to a DB insert + Realtime subscription
> 3. Add a `message_reactions` table (message_id, user_id, emoji)
>
> This is a significant refactor — treat it as its own epic.

**Dependency Map for Social Phase:**
```
profiles (exists)
    └─→ follows table (NEW) ─→ Friend-is-Online ─→ Invite-to-Table
    └─→ profile search (existing table, policy work)

chat_messages table (NEW)
    └─→ Quick Reactions
    └─→ Notification on reaction
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
| Quick Reactions | Medium | Very High | 7 | 🔴 Needs chat persistence refactor |

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
| `chat_messages` table | 7 | Persistent chat (replaces ephemeral) |
| `message_reactions` table | 7 | Emoji reactions on messages |

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

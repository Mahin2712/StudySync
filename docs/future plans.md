doc : https://docs.google.com/document/d/1E_9tk3UgLhKTT1SXGPbH1xjIK2WKFDZIhq-PlFcVDkY/edit?usp=sharing


**Findings**

- High: the plan underestimates how much new backend product surface it adds. Features like follow graph, invite-to-table, friend-online notifications, daily goals, streaks, to-do, exam alerts, recent rooms, and achievement-style unlocks do not map to existing tables or RPCs. The current app surface is mostly `profiles`, `rooms`, `room_members`, `study_sessions`, and a single stats RPC. Evidence: [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:17>), [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:18>), [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:19>), [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:40>), [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:55>), [room_service.dart](<C:\Users\SER\StudySync\lib\services\room_service.dart:9>), [leaderboard_service.dart](<C:\Users\SER\StudySync\lib\services\leaderboard_service.dart:40>).

- High: quick reactions are not a small UI add-on with the current chat design. Chat messages are explicitly broadcast-only and never persisted, so there is no durable message identity to react to, replay after reconnect, or notify against. Evidence: [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:16>), [chat_service.dart](<C:\Users\SER\StudySync\lib\services\chat_service.dart:13>), [chat_service.dart](<C:\Users\SER\StudySync\lib\services\chat_service.dart:97>), [chat_service.dart](<C:\Users\SER\StudySync\lib\services\chat_service.dart:132>), [chat_service.dart](<C:\Users\SER\StudySync\lib\services\chat_service.dart:207>).

- High: the stats/gamification part of the plan assumes data the system does not currently produce. The dashboard is built around `get_my_stats` returning `daily`, `weekly`, `monthly`, `total`, and `subjectBreakdown`; there is no streak, goal, achievement, or exam-progress contract today. If you extend this area, do it additively or you risk breaking the existing dashboard. Evidence: [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:23>), [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:35>), [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:40>), [leaderboard_service.dart](<C:\Users\SER\StudySync\lib\services\leaderboard_service.dart:45>), [stats_dashboard_screen.dart](<C:\Users\SER\StudySync\lib\screens\stats_dashboard_screen.dart:213>), [stats_dashboard_screen.dart](<C:\Users\SER\StudySync\lib\screens\stats_dashboard_screen.dart:373>).

- Medium: the minimalist sign-in idea is fine, but the plan should explicitly preserve the current auth/profile gate. `AppRouter` is the canonical post-auth funnel, and email auth already routes through it; any Google OAuth or new-user flow should land there too, otherwise profile completion will drift or be bypassed. Evidence: [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:7>), [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:34>), [app_router.dart](<C:\Users\SER\StudySync\lib\screens\app_router.dart:12>), [app_router.dart](<C:\Users\SER\StudySync\lib\screens\app_router.dart:47>), [login_screen.dart](<C:\Users\SER\StudySync\lib\screens\login_screen.dart:55>), [login_screen.dart](<C:\Users\SER\StudySync\lib\screens\login_screen.dart:66>).

- Medium: “friend is online” and “invite to table” are currently more infrastructure work than UI work. The home screen has placeholder notifications/friends icons with empty handlers, and profile search exists without any follow/friend relationship model. Evidence: [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:17>), [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:18>), [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:19>), [home_screen.dart](<C:\Users\SER\StudySync\lib\screens\home_screen.dart:262>), [home_screen.dart](<C:\Users\SER\StudySync\lib\screens\home_screen.dart:356>), [profile_service.dart](<C:\Users\SER\StudySync\lib\services\profile_service.dart:43>).

- Low: parts of the navigation/homepage proposal duplicate UI that already exists, but much of that UI is placeholder data. You already have a sidebar, join-table flow, global chat, and stats entrypoints; the bigger opportunity is replacing hard-coded room/leaderboard placeholders with real state before doing a full visual overhaul. Evidence: [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:33>), [Study Sync Future Upgrades.md](<C:\Users\SER\Downloads\Study Sync Future Upgrades.md:47>), [home_screen.dart](<C:\Users\SER\StudySync\lib\screens\home_screen.dart:173>), [home_screen.dart](<C:\Users\SER\StudySync\lib\screens\home_screen.dart:418>), [home_screen.dart](<C:\Users\SER\StudySync\lib\screens\home_screen.dart:794>).

The plan has good product instincts, but right now it mixes three different scopes: auth cleanup, UX polish, and entirely new social/productivity systems. Based on the current codebase, that is too broad for one upgrade cycle.

# Revised Upgrade Plan Review

## Summary
Prioritize features that fit the current architecture first, then add the backend primitives needed for social and productivity features. Keep the first release centered on auth polish, real home-screen data, and additive stats improvements.

## Recommended Order
1. Auth and onboarding pass.
   - Add Google OAuth beside email/password.
   - Keep `AppRouter` as the only post-auth destination for both sign-in methods and new-user flows.
   - Replace the current login form layout with the minimal entry UI only after routing rules are preserved.

2. Home/dashboard truth pass.
   - Replace hard-coded home placeholders with live room, leaderboard, and stats summaries.
   - Add recent rooms only after defining where recency is sourced from: room membership history or session history.
   - Treat the existing sidebar as a refinement target, not a rewrite target.

3. Stats expansion pass.
   - Extend stats additively from `get_my_stats`; do not break `subjectBreakdown`.
   - Introduce streaks first, then goals/themes only after streak storage and unlock rules exist.
   - Leave exam alerts and chapter completion for a later phase unless you also introduce subject/chapter progress storage.

4. Social systems pass.
   - Add a persistent social graph before online notifications or invite-to-table.
   - If you want reactions, first move chat from ephemeral broadcast-only messages to a persisted message model with message IDs.
   - Add notifications only after presence, device-targeting, and delivery rules are defined.

## Test Plan
- Auth: verify email login, Google login, first-time signup, returning-user login, and incomplete-profile routing all land in `AppRouter`.
- Dashboard: verify home cards and recent rooms render from live data with empty-state coverage.
- Stats: verify existing dashboard cards and `subjectBreakdown` still work when new fields are added.
- Social: verify reconnect/reload behavior for chat and notifications before shipping reactions or invites.

## Assumptions
- Review is grounded in the current repo state, not only the markdown plan.
- Stability-first ordering is intentional: architecture-fit and regression risk matter more than feature count.
- No runtime or backend-schema verification was run in this pass; this review is based on live code inspection.

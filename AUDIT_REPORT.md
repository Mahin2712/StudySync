# StudySync Codex Audit Report

## 1. The "Atomic Handoff" & Session Logic

### Finding 1: UI State Race Condition during Session Transitions
- **Severity Level:** Medium
- **Finding:** The `_loadSessionState` method in `RoomDetailScreen` can be triggered by Realtime Postgres events. If a user is in the middle of a `stopping` or `starting` transition, a Realtime event from a concurrent action (or even their own action arriving early) can overwrite the local `_sessionState` and `_mySession`, causing UI flickers or inconsistent button states.
- **Failure Path:**
  1. User taps "Stop Session" (`_sessionState` becomes `stopping`).
  2. A Realtime event for the session update arrives before the `stopSession()` RPC call completes.
  3. `_loadSessionState` is called, sees `my == null`, and sets `_sessionState = idle` (if it was previously `active`) or keeps it inconsistent.
- **Fix:** Add a transition guard to `_loadSessionState` to ignore updates while `starting` or `stopping`.

### Finding 2: Atomic Handoff Integrity
- **Severity Level:** Low
- **Finding:** The `start_session_atomic` RPC is robust against multiple active sessions for the same device. However, the `LocalSessionState` transition from `displaced` to `active` is currently handled implicitly by `_loadSessionState`.
- **Fix:** Explicitly handle the `displaced` state in the `startSession` flow to ensure a fresh "starting" phase is always entered.

---

## 2. Ephemeral Chat & Reaction Security

### Finding 3: Broadcast Payload Spoofing (Identity & Reactions)
- **Severity Level:** High
- **Finding:** The `ChatService` trusts the `user_id` and `username` fields in the broadcast payload for both messages and reactions. A malicious user can manually send a broadcast payload with a forged `user_id`.
- **Failure Path:**
  1. Malicious user uses a modified client or script.
  2. Sends a broadcast event `message` or `reaction` with `user_id` set to another user's ID.
  3. All other clients render the message/reaction as if it came from the victim.
- **Fix:** On the receiving side, verify that the broadcast payload `user_id` does not claim to be the local user if it didn't originate locally. For a complete fix, server-side validation or signed payloads are required.

### Finding 4: Reaction Hijacking
- **Severity Level:** High
- **Finding:** Since reactions are toggled based on the `user_id` in the payload, an attacker can send broadcasts that remove reactions from other users or add them.
- **Failure Path:** Same as Finding 3, but targeting the `reaction` event.
- **Fix:** Limit reaction toggling to the current user's local state or implement server-side verification.

---

## 3. Database & RLS (Row Level Security)

### Finding 5: Anti-Cheat Bypass via `last_activity_at` Manipulation
- **Severity Level:** High
- **Finding:** The anti-cheat mechanism (20-minute check-in) relies on `last_activity_at`. Clients are allowed to update this column directly via `SessionService.recordActivity()`. A malicious user can bypass the check-in requirement by periodically updating this column via a script.
- **Failure Path:**
  1. User starts a session.
  2. User runs a script: `while(true) { supabase.from('study_sessions').update({last_activity_at: now}).eq('id', session_id); sleep(60); }`
  3. The user never receives a check-in popup and can "study" indefinitely without being present.
- **Fix:** Move the `last_activity_at` update logic to a protected RPC that validates the activity (e.g., requires a recent chat message or a signed challenge). Alternatively, use a DB trigger to rate-limit updates.

---

## 4. Auth & Deep Link Hardening

### Finding 6: Deep Link Source Validation
- **Severity Level:** Medium
- **Finding:** `AppRouter` listens to all `app_links` and passes them to `getSessionFromUrl` if the scheme is `studysync`. While the Supabase SDK handles token validation, the application lacks a secondary check on the link's structure or intent.
- **Failure Path:** Potential for a malicious site to trigger the app with a crafted URL that might exploit vulnerabilities in the deep link parsing (though Supabase SDK is the primary parser).
- **Fix:** Implement stricter URI path validation in `AppRouter` before passing to `getSessionFromUrl`.

---

## 5. Performance (The "Scale" Test)

### Finding 7: Global Count Polling Scalability
- **Severity Level:** Medium
- **Finding:** The 5s polling for the global studier count (mentioned as existing) would create unnecessary DB load (1,200 req/min for 100 users).
- **Fix:** Replace polling with a `postgres_changes` Realtime listener on the `study_sessions` table (filtered for `is_active = true`) to update the global count reactively.

### Finding 8: UI Overdraw in `RoomDetailScreen`
- **Severity Level:** Low
- **Finding:** The `_uiTicker` in `RoomDetailScreen` triggers a `setState` every second. While necessary for the timer, it also re-paints complex `CustomPainter` dot grids and gradients.
- **Fix:** Repaint only the timer widget by moving it into a separate `StatefulWidget` or using a `ValueNotifier`.

# Device Icons & Anti-Cheat Implementation Plan

This document tracks the proposed implementation for showing device-specific hardware icons in the member list and maintaining anti-cheat integrity across multiple devices.

## Feature Overview
Show exactly which hardware (Mobile, Tablet, PC) friends are using while ensuring the anti-cheat system remains strictly locked to the device running the active session.

### 📱 Implementation: Device Icons in Member List

#### 1. Database Update: Track Device Type
Add a `device_type` column to `study_sessions` and update the `start_session_atomic` RPC.

```sql
-- Add device_type to track hardware platform
ALTER TABLE public.study_sessions 
ADD COLUMN device_type TEXT; -- 'mobile', 'tablet', or 'pc'

-- Update the RPC to accept and store the device type
CREATE OR REPLACE FUNCTION start_session_atomic(
  p_user_id UUID,
  p_room_id UUID,
  p_subject TEXT,
  p_chapter TEXT,
  p_device_id TEXT,
  p_device_type TEXT
)
RETURNS UUID AS $$
-- Logic: Insert into study_sessions (..., device_type) VALUES (..., p_device_type);
```

#### 2. Flutter: Detect & Pass Device Type
In `SessionService`, detect hardware before calling `start_session_atomic`.

* **Mobile:** Width < 600
* **Tablet:** Width between 600 and 1020
* **PC:** Width > 1020 or explicitly running on Windows desktop.

#### 3. UI: Add Icons to `RoomDetailScreen`
Add icons next to member names:
- **Mobile**: `Icons.smartphone`
- **Tablet**: `Icons.tablet_android`
- **PC**: `Icons.desktop_windows`

---

### 🛡️ Anti-Cheat Logic Context
The anti-cheat remains fully effective despite multi-device tracking:
* **Session-Specific Activity:** `recordActivity()` and check-in popups only fire on the device where the session is active.
* **The "Idle" Trap:** Watchdog timer on the original device will stop firing if the user moves to a secondary device without starting a session there.
* **Handoff Enforcement:** Starting a session on a new device triggers the **One Device Rule**, killing the previous session.

---

### 🚀 Next Steps
1. Run SQL Migration for `device_type`.
2. Update `SessionService` to detect and send platform type.
3. Refactor member list UI in `RoomDetailScreen`.

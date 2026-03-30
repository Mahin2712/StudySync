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

## ✅ Features Completed
- [x] Flutter + Supabase connected
- [x] Email/password login & signup
- [x] Session persistence (auto-navigate on re-open)
- [x] Homepage matching prototype (dark theme, round table, sidebar, right panel)
- [x] Room create / join / list system
- [x] **Study Session System (Timer + State)**
- [x] Live HH:MM:SS timer center-piece in RoomDetailScreen
- [x] Multi-user visibility (see others' live timers and subjects)
- [x] Duplicate session prevention (app-level guard)
- [x] Check-in System (Anti-Fake Study)

## 🔜 Upcoming Features

- [ ] Leaderboard (real-time study time tracking)
- [ ] Chat inside room
- [ ] User profiles

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

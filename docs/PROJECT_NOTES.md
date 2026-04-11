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

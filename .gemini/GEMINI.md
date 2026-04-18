# StudySync Project Context
This is a Flutter-based mobile and web application integrated with **Supabase**.

## Technical Architecture
- **Framework**: Flutter (Dart 3.x)
- **Backend-as-a-Service**: Supabase (Database, Auth, Storage, Realtime)
- **State Management**: Primary focus on services and direct integration.
- **Environment**: Managed via `.env` (flutter_dotenv).

## Key Components
- `lib/services/`: Core logic and Supabase integration (e.g., `ChapterService`).
- `lib/screens/`: UI implementation.
- `lib/models/`: Data structures.

## Database & Security
- **Supabase RLS**: Enabled for data isolation.
- **Realtime**: Used for live updates across devices.
- **Privacy**: Focus on `device_id` based multi-device isolation (Phase 3).

## Project Rules
- Prefer **reusable UI components**.
- Use **responsive design** patterns.
- Ensure all Supabase queries handle **errors and loading states** gracefully.

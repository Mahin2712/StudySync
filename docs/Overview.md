# StudySync Overview

## Project Summary
StudySync is a Flutter and Supabase group study platform built to make online study sessions feel shared, focused, and accountable. Instead of noisy calls or distraction-heavy social apps, the product centers on a calm virtual study room where users join the same table, start a session, track live study time, and stay honest through periodic check-ins.

This document is a cleaned project summary based on [`docs/PROJECT_NOTES.md`](/abs/path/c:/Users/SER/StudySync/docs/PROJECT_NOTES.md). The notes file remains the raw timeline and implementation memory. This file is the readable overview.

## Core Idea
The product is designed around a simple loop:

1. A user joins a study room.
2. They start a timed study session with a subject and optional chapter/topic.
3. Their session appears live to other room members.
4. Periodic check-ins confirm they are still actively studying.
5. When the session ends, time is saved for stats, rankings, and progress tracking.

The main goal is accountability through presence, simplicity, and live shared momentum.

## Current Product Scope
StudySync is currently a working Flutter application with Supabase-backed authentication, room management, session tracking, and analytics foundations. The active development focus has moved beyond MVP planning and into refinement, privacy, and polish.

### Implemented
- Email/password authentication with session-aware routing
- Profile setup and edit flow
- Room creation and joining
- Live room membership and presence visibility
- Real-time study session tracking
- Subject-aware and chapter-aware study session start flow
- Anti-fake-study check-in system with timeout handling
- Session auto-stop and stale-session cleanup safeguards
- Leaderboard screens and stats dashboard foundations
- Subject taxonomy support from database-backed subject definitions
- Privacy layer for public profile access

### In Progress or Planned
- Multi-device session isolation via `device_id`
- Live minimalist room chat
- Deeper stats and profile polish
- Friend and social notification systems
- Deployment and long-term operational cleanup

## Product Experience
The product experience is intentionally quiet and focused. The interface is built around a digital study table rather than a chat-first or video-first layout. Users can see active members, current study duration, and live room energy without overwhelming the screen.

Key UX principles:
- low distraction
- clear accountability
- live shared motivation
- subject-based organization
- mobile-friendly and responsive layouts

## Architecture Snapshot
### Frontend
- Flutter application
- Current development targets: Web and Windows desktop
- Android remains a natural expansion path from the Flutter codebase

### Backend
- Supabase for authentication, database, realtime updates, and profile/session data
- Environment-driven configuration through `.env`

### Core Domain Areas
- `auth`
- `profiles`
- `rooms`
- `study sessions`
- `check-ins`
- `leaderboards`
- `stats`
- `subjects and chapters`

## Main Data Model
The project is centered around a few key entities:

- `rooms`: shared study spaces
- `room_members`: membership and room presence
- `study_sessions`: active and historical study records
- `subjects`: structured subject catalog used by the app
- `public_profiles`: privacy-safe profile access layer

These tables and views support both live room behavior and long-term analytics.

## Current Status
Based on the project notes, StudySync has moved well past the early MVP definition. Core study-room behavior, accountability logic, stats foundations, subject/chapter organization, and privacy work are already in place. The remaining work is mostly focused on refinement, expansion, and stronger operational safeguards rather than proving the main concept.

## Source of Truth
For implementation history, timestamps, and raw milestone records, use [`docs/PROJECT_NOTES.md`](/abs/path/c:/Users/SER/StudySync/docs/PROJECT_NOTES.md).

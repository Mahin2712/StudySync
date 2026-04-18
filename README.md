# StudySync

StudySync is a focused group study platform built with Flutter and Supabase. It is designed for students who want the motivation of studying together online without turning the experience into a noisy call, a social feed, or a distraction loop.

At its core, StudySync creates a shared study room where members join the same table, start timed sessions, stay accountable through check-ins, and build real study history over time. The product is meant to feel calm, live, and disciplined: less like a chat app, more like sitting down with serious study partners.

## What The App Does
- Creates shared study rooms for live group sessions
- Tracks active study time in real time
- Records subject and chapter/topic context for each session
- Uses periodic check-ins to reduce fake or abandoned sessions
- Supports profile-based progress tracking and stats
- Builds toward leaderboards, analytics, and lightweight social features

## Current Highlights
- Flutter app with Supabase authentication and database integration
- Session-aware routing and profile completion flow
- Real-time room activity and study session visibility
- Anti-fake-study check-in system with grace window and auto-stop behavior
- Stats dashboard and leaderboard-related foundations
- Subject and chapter selection flow for structured study sessions
- Privacy-aware profile access layer

## Product Direction
StudySync is being shaped around a simple promise: make online study feel shared, honest, and sustainable.

The interface focuses on:
- a quiet study-table experience
- clear live presence
- low-friction accountability
- long-term progress visibility

## Stack
- Flutter
- Supabase
- Dart

## Status
The project is beyond the early idea stage and already has the core study loop implemented. Current work is focused on refinement, multi-device session safety, analytics growth, and social features like chat and richer profile systems.

## Repository Notes
- High-level project summary: [docs/Overview.md](/abs/path/c:/Users/SER/StudySync/docs/Overview.md)
- Raw timestamped project history: [docs/PROJECT_NOTES.md](/abs/path/c:/Users/SER/StudySync/docs/PROJECT_NOTES.md)

## Getting Started
```bash
flutter pub get
flutter run -d chrome
```

For local development, the app expects a `.env` file with Supabase credentials.

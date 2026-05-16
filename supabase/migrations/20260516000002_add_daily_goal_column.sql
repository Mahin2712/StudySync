-- Phase 6, Sub-phase 2: Add daily goal column to profiles
-- + Update public_profiles view to include goal and streak data

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS daily_goal_minutes integer NOT NULL DEFAULT 0;

-- Drop and recreate the public_profiles view with expanded columns
DROP VIEW IF EXISTS public.public_profiles;

CREATE VIEW public.public_profiles AS
SELECT
  id, username, student_name,
  avatar_url, profile_complete,
  current_streak_days, longest_streak_days,
  daily_goal_minutes
FROM public.profiles;

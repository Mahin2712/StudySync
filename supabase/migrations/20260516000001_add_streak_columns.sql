-- Phase 6, Sub-phase 1: Add streak tracking columns to profiles
-- + Create update_streak RPC

-- Add streak tracking columns to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS current_streak_days  integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS longest_streak_days  integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_study_date      date;

-- RPC: Recalculate streak on session completion
-- Called from the client after stopSession() succeeds
CREATE OR REPLACE FUNCTION public.update_streak()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid         uuid := auth.uid();
  v_today       date := (now() AT TIME ZONE 'Asia/Dhaka')::date;
  v_last_date   date;
  v_streak      integer;
  v_longest     integer;
BEGIN
  SELECT last_study_date, current_streak_days, longest_streak_days
  INTO v_last_date, v_streak, v_longest
  FROM public.profiles
  WHERE id = v_uid;

  IF v_last_date IS NULL OR v_last_date < v_today - 1 THEN
    -- Streak broken or first ever session
    v_streak := 1;
  ELSIF v_last_date = v_today - 1 THEN
    -- Consecutive day — extend streak
    v_streak := v_streak + 1;
  ELSIF v_last_date = v_today THEN
    -- Already studied today — no change
    NULL;
  END IF;

  IF v_streak > v_longest THEN
    v_longest := v_streak;
  END IF;

  UPDATE public.profiles
  SET current_streak_days = v_streak,
      longest_streak_days = v_longest,
      last_study_date     = v_today,
      updated_at          = now()
  WHERE id = v_uid;

  RETURN json_build_object(
    'current_streak', v_streak,
    'longest_streak', v_longest,
    'last_study_date', v_today
  );
END;
$$;

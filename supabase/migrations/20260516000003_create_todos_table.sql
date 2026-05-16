-- Phase 6, Sub-phase 3: Create todos table with RLS policies

CREATE TABLE IF NOT EXISTS public.todos (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title       text NOT NULL CHECK (char_length(title) <= 200),
  is_done     boolean NOT NULL DEFAULT false,
  is_recurring boolean NOT NULL DEFAULT false,  -- daily recurring (auto-reset)
  position    integer NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Index for fast per-user queries
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON public.todos (user_id);

-- RLS: users can only see and modify their own to-dos
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own todos"
  ON public.todos FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own todos"
  ON public.todos FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own todos"
  ON public.todos FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users delete own todos"
  ON public.todos FOR DELETE
  USING (auth.uid() = user_id);

-- RPC: Reset daily recurring todos at the start of a new day
-- Called lazily from the client when fetching todos
CREATE OR REPLACE FUNCTION public.reset_recurring_todos()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid   uuid := auth.uid();
  v_today date := (now() AT TIME ZONE 'Asia/Dhaka')::date;
BEGIN
  -- Only reset if the last update was before today
  UPDATE public.todos
  SET is_done = false,
      updated_at = now()
  WHERE user_id = v_uid
    AND is_recurring = true
    AND is_done = true
    AND (updated_at AT TIME ZONE 'Asia/Dhaka')::date < v_today;
END;
$$;

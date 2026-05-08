CREATE UNIQUE INDEX IF NOT EXISTS uniq_room_members ON public.room_members(room_id, user_id);

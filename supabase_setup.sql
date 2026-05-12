-- ============================================================
-- SwaplyApp — Fix "Could not find 'initiator_id' column"
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. ADD MISSING COLUMNS TO EXISTING swaps TABLE
--    (all use IF NOT EXISTS so it's safe to re-run)
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.swaps
  ADD COLUMN IF NOT EXISTS chat_id      uuid REFERENCES public.chats(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS initiator_id uuid REFERENCES auth.users(id)   ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS receiver_id  uuid REFERENCES auth.users(id)   ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS post_id      uuid REFERENCES public.posts(id)  ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS status       text DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS confirmed_at timestamp with time zone,
  ADD COLUMN IF NOT EXISTS completed_at timestamp with time zone,
  ADD COLUMN IF NOT EXISTS created_at   timestamp with time zone DEFAULT now();

-- ────────────────────────────────────────────────────────────
-- 2. ENABLE RLS + POLICIES FOR swaps
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.swaps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Swap participants can view swaps"   ON public.swaps;
DROP POLICY IF EXISTS "Initiator can create swaps"         ON public.swaps;
DROP POLICY IF EXISTS "Swap participants can update swaps" ON public.swaps;

CREATE POLICY "Swap participants can view swaps"
  ON public.swaps FOR SELECT
  USING (auth.uid() = initiator_id OR auth.uid() = receiver_id);

CREATE POLICY "Initiator can create swaps"
  ON public.swaps FOR INSERT
  WITH CHECK (auth.uid() = initiator_id);

CREATE POLICY "Swap participants can update swaps"
  ON public.swaps FOR UPDATE
  USING (auth.uid() = initiator_id OR auth.uid() = receiver_id);

-- ────────────────────────────────────────────────────────────
-- 3. NOTIFY POSTGREST TO RELOAD SCHEMA CACHE
--    (this is what fixes the PGRST204 error directly)
-- ────────────────────────────────────────────────────────────
NOTIFY pgrst, 'reload schema';

-- ────────────────────────────────────────────────────────────
-- 4. ADD MISSING COLUMNS TO chats (safe if already exist)
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.chats
  ADD COLUMN IF NOT EXISTS swap_confirmed boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS swap_status    text    DEFAULT 'none',
  ADD COLUMN IF NOT EXISTS post_id        uuid    REFERENCES public.posts(id) ON DELETE SET NULL;

NOTIFY pgrst, 'reload schema';
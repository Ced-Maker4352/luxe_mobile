-- ============================================================
-- Migration: 00002_create_generations
-- Purpose: Store every AI generation (image/video) a user creates.
--          This powers the Gallery screen and generation history.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.generations (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  storage_path  text,                       -- Supabase Storage path (e.g. 'user-content/<user_id>/<filename>')
  image_url     text,                       -- Full public/signed URL for display
  prompt        text,                       -- The text prompt used for generation
  style         text,                       -- Style preset selected (e.g. 'cinematic', 'editorial')
  type          text        NOT NULL DEFAULT 'image',  -- 'image' | 'video' | 'stitch' | 'campus' | 'logo'
  metadata      jsonb       DEFAULT '{}'::jsonb,       -- Flexible field for extras (aspect_ratio, model_used, etc.)
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Index for fast gallery queries by user
CREATE INDEX IF NOT EXISTS idx_generations_user_id ON public.generations(user_id);
CREATE INDEX IF NOT EXISTS idx_generations_type ON public.generations(type);
CREATE INDEX IF NOT EXISTS idx_generations_created_at ON public.generations(created_at DESC);

-- Enable RLS
ALTER TABLE public.generations ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own generations
CREATE POLICY IF NOT EXISTS "Users can view own generations"
  ON public.generations FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own generations
CREATE POLICY IF NOT EXISTS "Users can insert own generations"
  ON public.generations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own generations
CREATE POLICY IF NOT EXISTS "Users can delete own generations"
  ON public.generations FOR DELETE
  USING (auth.uid() = user_id);

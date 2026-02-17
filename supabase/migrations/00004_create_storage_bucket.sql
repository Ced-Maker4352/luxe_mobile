-- ============================================================
-- Migration: 00004_create_storage_bucket
-- Purpose: Create the Supabase Storage bucket for user content
--          (generated images, videos, uploads).
-- ============================================================

-- Create the bucket (run this in Supabase SQL Editor or via CLI)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-content',
  'user-content',
  false,                              -- Private bucket (requires auth)
  10485760,                           -- 10 MB max file size
  ARRAY['image/png', 'image/jpeg', 'image/webp', 'video/mp4']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies
-- Users can upload to their own folder: user-content/<user_id>/*
CREATE POLICY IF NOT EXISTS "Users can upload own content"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'user-content'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can view their own files
CREATE POLICY IF NOT EXISTS "Users can view own content"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'user-content'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own files
CREATE POLICY IF NOT EXISTS "Users can delete own content"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'user-content'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

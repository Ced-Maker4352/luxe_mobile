-- ============================================================
-- Migration: 00005_create_grant_credits_rpc
-- Purpose: Atomic credit granting via RPC, called by the
--          Stripe webhook Edge Function. Adds credits instead
--          of overwriting them.
-- ============================================================

CREATE OR REPLACE FUNCTION public.grant_credits(
  p_user_id uuid,
  p_photo_credits integer,
  p_video_credits integer,
  p_subscription_tier text,
  p_is_subscribed boolean
)
RETURNS void AS $$
BEGIN
  UPDATE public.profiles
  SET
    photo_generations = photo_generations + p_photo_credits,
    video_generations = video_generations + p_video_credits,
    subscription_tier = p_subscription_tier,
    is_subscribed = CASE
      WHEN p_is_subscribed THEN true
      ELSE is_subscribed  -- don't un-subscribe on one-time purchases
    END,
    updated_at = now()
  WHERE id = p_user_id;

  -- If no row was updated (shouldn't happen, but safety net)
  IF NOT FOUND THEN
    INSERT INTO public.profiles (id, photo_generations, video_generations, subscription_tier, is_subscribed, updated_at)
    VALUES (p_user_id, p_photo_credits, p_video_credits, p_subscription_tier, p_is_subscribed, now())
    ON CONFLICT (id) DO UPDATE SET
      photo_generations = public.profiles.photo_generations + p_photo_credits,
      video_generations = public.profiles.video_generations + p_video_credits,
      subscription_tier = p_subscription_tier,
      is_subscribed = CASE
        WHEN p_is_subscribed THEN true
        ELSE public.profiles.is_subscribed
      END,
      updated_at = now();
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

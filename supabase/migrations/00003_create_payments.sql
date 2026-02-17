-- ============================================================
-- Migration: 00003_create_payments
-- Purpose: Track Stripe payment transactions for audit,
--          refunds, and subscription management.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.payments (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  stripe_session_id   text        UNIQUE,           -- Stripe Checkout Session ID
  stripe_payment_intent text,                        -- Stripe PaymentIntent ID
  amount_cents        integer     NOT NULL DEFAULT 0, -- Amount in cents (e.g. 2900 = $29.00)
  currency            text        NOT NULL DEFAULT 'usd',
  status              text        NOT NULL DEFAULT 'pending',  -- 'pending' | 'completed' | 'failed' | 'refunded'
  package_id          text,                          -- e.g. 'creatorPack', 'professionalShoot', 'sub_monthly_49'
  credits_granted     integer     NOT NULL DEFAULT 0, -- Photo credits granted by this payment
  video_credits_granted integer   NOT NULL DEFAULT 0, -- Video credits granted
  promo_code          text,                          -- Promo code used, if any
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

-- Index for lookups
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_stripe_session ON public.payments(stripe_session_id);

-- Enable RLS
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own payment history
CREATE POLICY IF NOT EXISTS "Users can view own payments"
  ON public.payments FOR SELECT
  USING (auth.uid() = user_id);

-- Only server/service_role can insert payments (via Edge Functions)
-- No INSERT policy for anon/authenticated — webhook handles this

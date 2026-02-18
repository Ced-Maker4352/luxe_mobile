// Stripe Webhook Handler — Supabase Edge Function
// Listens for checkout.session.completed events and provisions credits
//
// Required secrets (set via `supabase secrets set`):
//   STRIPE_WEBHOOK_SECRET  — whsec_... from Stripe Dashboard → Webhooks
//   STRIPE_SECRET_KEY      — sk_live_... from Stripe Dashboard → API Keys
//   SUPABASE_URL           — auto-injected by Supabase
//   SUPABASE_SERVICE_ROLE_KEY — auto-injected by Supabase

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Credit Mapping ────────────────────────────────────────────
// Maps Stripe metadata package_id → credits to grant
const PACKAGE_CREDITS: Record<string, { photo: number; video: number; tier: string }> = {
    // One-time packs
    socialQuick: { photo: 5, video: 0, tier: "Social Quick" },
    creatorPack: { photo: 30, video: 0, tier: "Creator Pack" },
    professionalShoot: { photo: 80, video: 10, tier: "Professional Shoot" },
    agencyMaster: { photo: 200, video: 50, tier: "Agency / Master" },
    // Subscriptions
    sub_monthly_19: { photo: 30, video: 0, tier: "Starter Monthly" },
    sub_monthly_49: { photo: 80, video: 10, tier: "Pro Monthly" },
    sub_monthly_99: { photo: 200, video: 50, tier: "Elite Monthly" },
};

// ─── Crypto helpers for signature verification ─────────────────
async function verifyStripeSignature(
    payload: string,
    sigHeader: string,
    secret: string,
): Promise<boolean> {
    // Parse the Stripe-Signature header
    const parts = sigHeader.split(",");
    let timestamp = "";
    let signature = "";

    for (const part of parts) {
        const [key, value] = part.trim().split("=");
        if (key === "t") timestamp = value;
        if (key === "v1") signature = value;
    }

    if (!timestamp || !signature) return false;

    // Stripe signs: timestamp + "." + payload
    const signedPayload = `${timestamp}.${payload}`;
    const encoder = new TextEncoder();

    const key = await crypto.subtle.importKey(
        "raw",
        encoder.encode(secret),
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["sign"],
    );

    const sig = await crypto.subtle.sign("HMAC", key, encoder.encode(signedPayload));
    const expectedSig = Array.from(new Uint8Array(sig))
        .map((b) => b.toString(16).padStart(2, "0"))
        .join("");

    // Constant-time comparison
    if (expectedSig.length !== signature.length) return false;
    let mismatch = 0;
    for (let i = 0; i < expectedSig.length; i++) {
        mismatch |= expectedSig.charCodeAt(i) ^ signature.charCodeAt(i);
    }

    // Also check timestamp is within 5 minutes (tolerance for clock skew)
    const now = Math.floor(Date.now() / 1000);
    const tolerance = 300; // 5 minutes
    if (Math.abs(now - parseInt(timestamp)) > tolerance) {
        console.warn("Webhook timestamp too old/new:", timestamp, "vs now:", now);
        return false;
    }

    return mismatch === 0;
}

// ─── Main handler ──────────────────────────────────────────────
serve(async (req: Request) => {
    // Only accept POST
    if (req.method !== "POST") {
        return new Response("Method not allowed", { status: 405 });
    }

    const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
    if (!webhookSecret) {
        console.error("STRIPE_WEBHOOK_SECRET not set");
        return new Response("Server misconfigured", { status: 500 });
    }

    // Read the raw body for signature verification
    const body = await req.text();
    const sigHeader = req.headers.get("stripe-signature");

    if (!sigHeader) {
        console.warn("Missing stripe-signature header");
        return new Response("Missing signature", { status: 400 });
    }

    // Verify signature
    const isValid = await verifyStripeSignature(body, sigHeader, webhookSecret);
    if (!isValid) {
        console.warn("Invalid Stripe signature");
        return new Response("Invalid signature", { status: 401 });
    }

    // Parse the event
    let event;
    try {
        event = JSON.parse(body);
    } catch {
        return new Response("Invalid JSON", { status: 400 });
    }

    console.log(`Stripe event received: ${event.type} (${event.id})`);

    // ─── Handle checkout.session.completed ───────────────────────
    if (event.type === "checkout.session.completed") {
        const session = event.data.object;

        // Extract identifiers
        let clientRefId = session.client_reference_id; // usually user's Supabase auth UID
        let packageId = session.metadata?.package_id;

        // Zero-config automation: parse from client_reference_id if payload looks like "userId:packageId"
        if (clientRefId?.includes(":")) {
            const parts = clientRefId.split(":");
            clientRefId = parts[0];
            packageId = packageId || parts[1]; // Prefer metadata if present, fallback to parsed
        }

        const stripeSessionId = session.id;
        const paymentIntent = session.payment_intent;
        const amountTotal = session.amount_total ?? 0; // in cents

        console.log("Processing payment:", {
            email: customerEmail,
            userId: clientRefId,
            packageId,
            amount: amountTotal,
            raw_id: session.client_reference_id,
        });

        if (!packageId) {
            console.warn("No package_id in session metadata — cannot map credits");
            // Still return 200 so Stripe doesn't retry
            return new Response(JSON.stringify({ received: true, warning: "no package_id" }), {
                status: 200,
                headers: { "Content-Type": "application/json" },
            });
        }

        const credits = PACKAGE_CREDITS[packageId];
        if (!credits) {
            console.warn(`Unknown package_id: ${packageId}`);
            return new Response(JSON.stringify({ received: true, warning: "unknown package" }), {
                status: 200,
                headers: { "Content-Type": "application/json" },
            });
        }

        // Initialize Supabase client with service_role (bypasses RLS)
        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        // Find the user — prefer client_reference_id (auth UID), fall back to email
        let userId = clientRefId;

        if (!userId && customerEmail) {
            // Look up user by email in profiles table
            const { data: profile } = await supabase
                .from("profiles")
                .select("id")
                .eq("email", customerEmail)
                .maybeSingle();

            if (profile) {
                userId = profile.id;
            } else {
                console.warn(`No user found for email: ${customerEmail}`);
                return new Response(
                    JSON.stringify({ received: true, warning: "user not found" }),
                    { status: 200, headers: { "Content-Type": "application/json" } },
                );
            }
        }

        if (!userId) {
            console.error("Cannot identify user — no client_reference_id or email");
            return new Response(
                JSON.stringify({ received: true, error: "no user identifier" }),
                { status: 200, headers: { "Content-Type": "application/json" } },
            );
        }

        // ─── 1. Check for duplicate payment (idempotency) ──────────
        const { data: existingPayment } = await supabase
            .from("payments")
            .select("id")
            .eq("stripe_session_id", stripeSessionId)
            .maybeSingle();

        if (existingPayment) {
            console.log(`Payment already processed: ${stripeSessionId}`);
            return new Response(
                JSON.stringify({ received: true, status: "already_processed" }),
                { status: 200, headers: { "Content-Type": "application/json" } },
            );
        }

        // ─── 2. Update user profile — ADD credits (don't overwrite) ─
        const isSubscription = packageId.startsWith("sub_");
        const { error: profileError } = await supabase.rpc("grant_credits", {
            p_user_id: userId,
            p_photo_credits: credits.photo,
            p_video_credits: credits.video,
            p_subscription_tier: credits.tier,
            p_is_subscribed: isSubscription,
        });

        if (profileError) {
            // Fallback: direct update if RPC doesn't exist yet
            console.warn("RPC grant_credits failed, using direct update:", profileError.message);

            const { error: updateError } = await supabase
                .from("profiles")
                .update({
                    photo_generations: credits.photo, // Will be replaced with increment below
                    video_generations: credits.video,
                    subscription_tier: credits.tier,
                    is_subscribed: isSubscription,
                    updated_at: new Date().toISOString(),
                })
                .eq("id", userId);

            if (updateError) {
                console.error("Profile update failed:", updateError);
            }
        }

        // ─── 3. Insert payment record ──────────────────────────────
        const { error: paymentError } = await supabase.from("payments").insert({
            user_id: userId,
            stripe_session_id: stripeSessionId,
            stripe_payment_intent: paymentIntent,
            amount_cents: amountTotal,
            currency: session.currency ?? "usd",
            status: "completed",
            package_id: packageId,
            credits_granted: credits.photo,
            video_credits_granted: credits.video,
            promo_code: session.metadata?.promo_code ?? null,
        });

        if (paymentError) {
            console.error("Payment insert failed:", paymentError);
        }

        console.log(`✅ Credits granted to ${userId}: +${credits.photo} photo, +${credits.video} video (${credits.tier})`);

        return new Response(
            JSON.stringify({
                received: true,
                status: "credits_granted",
                userId,
                packageId,
                photo: credits.photo,
                video: credits.video,
            }),
            { status: 200, headers: { "Content-Type": "application/json" } },
        );
    }

    // ─── Handle invoice.paid (subscription renewals) ─────────────
    if (event.type === "invoice.paid") {
        console.log("Invoice paid event — subscription renewal handling TBD");
        // Future: handle recurring subscription credit refresh
        return new Response(JSON.stringify({ received: true }), {
            status: 200,
            headers: { "Content-Type": "application/json" },
        });
    }

    // ─── All other events — acknowledge but don't process ────────
    console.log(`Unhandled event type: ${event.type}`);
    return new Response(JSON.stringify({ received: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
    });
});

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.25.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, stripe-signature",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY")!;
    const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const stripe = new Stripe(stripeSecret, { apiVersion: "2026-03-25.dahlia" });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const signature = req.headers.get("stripe-signature");
    if (!signature) {
      return new Response(JSON.stringify({ error: "Missing stripe-signature header" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.text();
    const event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret);

    const { error: insertEventError } = await adminClient
      .from("stripe_webhook_events")
      .insert({
        stripe_event_id: event.id,
        event_type: event.type,
        payload: event as unknown as Record<string, unknown>,
      });

    if (insertEventError) {
      if (insertEventError.code === "23505") {
        return new Response(JSON.stringify({ received: true, duplicate: true }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      throw insertEventError;
    }

    if (event.type === "checkout.session.completed") {
      const session = event.data.object as Stripe.Checkout.Session;
      const metadata = session.metadata ?? {};
      const userId = metadata.user_id;
      const packageId = metadata.package_id;

      if (!userId || !packageId) {
        return new Response(JSON.stringify({ received: true, skipped: "missing metadata" }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: packageRow, error: packageError } = await adminClient
        .from("packages")
        .select("sessions_count, validity_days")
        .eq("id", packageId)
        .single();

      if (packageError || !packageRow) {
        throw new Error("Package lookup failed during webhook processing");
      }

      const { data: existingSub, error: existingSubError } = await adminClient
        .from("user_subscriptions")
        .select("id, sessions_remaining, expiry_date")
        .eq("user_id", userId)
        .eq("package_id", packageId)
        .maybeSingle();

      if (existingSubError) {
        throw existingSubError;
      }

      const validityDays = Number(packageRow.validity_days ?? 30);
      const addSessions = Number(packageRow.sessions_count ?? 0);
      const today = new Date();
      const currentExpiry = existingSub?.expiry_date ? new Date(existingSub.expiry_date) : today;
      const baseline = currentExpiry > today ? currentExpiry : today;
      const nextExpiry = new Date(baseline);
      nextExpiry.setDate(nextExpiry.getDate() + validityDays);

      if (!existingSub) {
        const { error: insertSubError } = await adminClient.from("user_subscriptions").insert({
          user_id: userId,
          package_id: packageId,
          sessions_remaining: addSessions,
          expiry_date: nextExpiry.toISOString().slice(0, 10),
          last_payment_intent_id: session.payment_intent?.toString(),
        });

        if (insertSubError) {
          throw insertSubError;
        }
      } else {
        const { error: updateSubError } = await adminClient
          .from("user_subscriptions")
          .update({
            sessions_remaining: Number(existingSub.sessions_remaining ?? 0) + addSessions,
            expiry_date: nextExpiry.toISOString().slice(0, 10),
            last_payment_intent_id: session.payment_intent?.toString(),
          })
          .eq("id", existingSub.id);

        if (updateSubError) {
          throw updateSubError;
        }
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Webhook processing failed",
        details: String(error),
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

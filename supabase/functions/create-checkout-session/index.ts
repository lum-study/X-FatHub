import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.25.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const stripeKey = Deno.env.get("STRIPE_SECRET_KEY")!;

    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const stripe = new Stripe(stripeKey, { apiVersion: "2026-03-25.dahlia" });

    const body = await req.json();
    const packageId = body.package_id as string | undefined;
    const userId = body.user_id as string | undefined;
    const successUrl =
      (body.success_url as string | undefined) ??
      Deno.env.get("STRIPE_CHECKOUT_SUCCESS_URL") ??
      "https://example.com/success";
    const cancelUrl =
      (body.cancel_url as string | undefined) ??
      Deno.env.get("STRIPE_CHECKOUT_CANCEL_URL") ??
      "https://example.com/cancel";

    if (!packageId) {
      return new Response(JSON.stringify({ error: "package_id is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!userId) {
      return new Response(JSON.stringify({ error: "user_id is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: packageRow, error: packageError } = await adminClient
      .from("packages")
      .select("id, name, stripe_price_id")
      .eq("id", packageId)
      .single();

    if (packageError || !packageRow?.stripe_price_id) {
      return new Response(
        JSON.stringify({
          error: "Package not found or stripe_price_id missing",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: [
        {
          price: packageRow.stripe_price_id,
          quantity: 1,
        },
      ],
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: {
        user_id: userId,
        package_id: packageId,
      },
      client_reference_id: userId,
    });

    return new Response(
      JSON.stringify({
        session_id: session.id,
        checkout_url: session.url,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Failed to create checkout session",
        details: String(error),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

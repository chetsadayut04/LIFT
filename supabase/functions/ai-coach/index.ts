import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const MODEL = Deno.env.get("OPENAI_MODEL") || "gpt-4o-mini";

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const { message, context } = await req.json();

    if (!OPENAI_API_KEY) {
      throw new Error("OPENAI_API_KEY environment variable is not set in Supabase secrets.");
    }

    const systemPrompt = `You are LIFT AI, a premium personal trainer and fitness coach inside the LIFT weightlifting tracker app.
Your tone should be highly professional, encouraging, motivational, and concise.

${context || ""}

Instructions:
1. Always analyze and relate your answers to the user's statistics, weight trends, PRs, and saved workout routines (ตารางการฝึก) when they ask about their progress, workouts, training split, or goals.
2. If they ask general health, nutrition, or exercise form questions, provide clear, structured, and informative answers using markdown lists and headings in Thai language.
3. Keep answers compact and readable in a mobile chat interface. Avoid overly long paragraphs.
4. Encourage progressive overload and smart training.`;

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: MODEL,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: message },
        ],
        temperature: 0.7,
        max_tokens: 800,
      }),
    });

    const data = await response.json();

    if (!response.ok || data.error) {
      const errMsg = data.error?.message || response.statusText;
      throw new Error(`OpenAI Error: ${errMsg}`);
    }

    const replyText = data.choices?.[0]?.message?.content || "";

    return new Response(JSON.stringify({ reply: replyText }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});

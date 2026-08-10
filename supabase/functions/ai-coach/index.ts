import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent";

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

    if (!GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY environment variable is not set.");
    }

    const systemPrompt = `You are LIFT AI, a premium personal trainer and fitness coach inside the LIFT weightlifting tracker app.
Your tone should be highly professional, encouraging, motivational, and concise.

${context || ""}

Instructions:
1. Always analyze and relate your answers to the user's statistics, weight trends, and PRs when they ask about their progress, workouts, or goals.
2. If they ask general health, nutrition, or exercise form questions, provide clear, structured, and informative answers using markdown lists and headings.
3. Keep answers compact and readable in a mobile chat interface. Avoid overly long paragraphs.
4. Encourage progressive overload and smart training.`;

    // Call Gemini API
    const response = await fetch(`${GEMINI_API_URL}?key=${GEMINI_API_KEY}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        contents: [
          {
            role: "user",
            parts: [{ text: message }]
          }
        ],
        systemInstruction: {
          parts: [{ text: systemPrompt }]
        }
      }),
    });

    const data = await response.json();
    if (!response.ok || data.error) {
      const errorMsg = data.error?.message || "Gemini API error";
      throw new Error(errorMsg);
    }

    const replyText = data.candidates?.[0]?.content?.parts?.[0]?.text || "Sorry, I could not process your answer.";

    return new Response(JSON.stringify({ reply: replyText }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});

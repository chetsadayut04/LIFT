import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const PREFERRED_MODEL = Deno.env.get("GEMINI_MODEL") || "gemini-2.0-flash";

const CANDIDATE_MODELS = [
  PREFERRED_MODEL,
  "gemini-2.0-flash",
  "gemini-2.0-flash-lite",
  "gemini-1.5-flash",
  "gemini-1.5-flash-8b",
  "gemini-1.5-pro",
].filter((m, i, self) => Boolean(m) && self.indexOf(m) === i);

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
1. Always analyze and relate your answers to the user's statistics, weight trends, PRs, and saved workout routines (ตารางการฝึก) when they ask about their progress, workouts, training split, or goals.
2. If they ask general health, nutrition, or exercise form questions, provide clear, structured, and informative answers using markdown lists and headings.
3. Keep answers compact and readable in a mobile chat interface. Avoid overly long paragraphs.
4. Encourage progressive overload and smart training.`;

    let replyText = "";
    let lastError = "";

    // Try models with fallback & retry if any experience high demand
    for (const model of CANDIDATE_MODELS) {
      for (let attempt = 0; attempt < 2; attempt++) {
        try {
          const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`;
          const response = await fetch(url, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              contents: [
                {
                  role: "user",
                  parts: [{ text: message }],
                },
              ],
              systemInstruction: {
                parts: [{ text: systemPrompt }],
              },
            }),
          });

          const data = await response.json();
          if (!response.ok || data.error) {
            const errMsg = typeof data.error === "string"
              ? data.error
              : data.error?.message || JSON.stringify(data.error || response.statusText);
            
            lastError = `Model ${model}: ${errMsg}`;
            console.warn(`Attempt ${attempt + 1} for ${model} failed: ${lastError}`);

            // If high demand, wait briefly before retrying or switching model
            if (attempt === 0 && (errMsg.includes("high demand") || response.status === 429 || response.status === 503)) {
              await new Promise((resolve) => setTimeout(resolve, 600));
              continue;
            }
            break; // Try next candidate model
          }

          replyText = data.candidates?.[0]?.content?.parts?.[0]?.text || "";
          if (replyText) {
            break; // Success!
          }
        } catch (err: any) {
          lastError = err.message || String(err);
          console.warn(`Fetch error for model ${model}: ${lastError}`);
        }
      }

      if (replyText) {
        break; // Successfully got response
      }
    }

    if (!replyText) {
      throw new Error(lastError || "Could not generate AI response from any available model.");
    }

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



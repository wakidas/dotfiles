import OpenAI from "openai";
import process from "node:process";

const chunks = [];
for await (const chunk of process.stdin) {
  chunks.push(chunk);
}

const diff = Buffer.concat(chunks).toString("utf8");
if (!diff.trim()) {
  console.error("staged diff is empty");
  process.exit(1);
}

const apiKey = process.env.OPENAI_API_KEY;
if (!apiKey) {
  console.error("OPENAI_API_KEY is not set");
  process.exit(1);
}

const model = process.env.OPENAI_MODEL || "gpt-4.1-mini";
const client = new OpenAI({ apiKey });

const response = await client.chat.completions.create({
  model,
  max_completion_tokens: 200,
  messages: [
    {
      role: "user",
      content:
        "以下のgit diff --stagedからコミットメッセージを生成してください。Conventional Commits形式で、本文は日本語で簡潔に。コミットメッセージのみを出力してください。コードブロックで囲わないでください。\n\n" +
        diff,
    },
  ],
});

const text = response.choices[0]?.message?.content?.trim();

if (!text) {
  console.error("message content is empty");
  process.exit(1);
}

process.stdout.write(text + "\n");

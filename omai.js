#!/usr/bin/env node
const fetch = require('node-fetch');
const dotenv = require('dotenv');
const fs = require('fs');
const readline = require('readline');

dotenv.config({ path: '/home/zebadiee/.npm-global/bin/.env' });

const endpoint = process.env.OR_ENDPOINT || 'https://openrouter.ai/api/v1/chat/completions';
const model = process.env.OR_MODEL || 'deepseek/deepseek-r1-0528-qwen3-8b';
const apiKey = process.env.OPENROUTER_API_KEY;
const roomFile = '/home/zebadiee/.npm-global/omarchy-wagon/room.json';

if (!apiKey) {
  console.error('Set OPENROUTER_API_KEY in your env or .env file.');
  process.exit(1);
}

const args = process.argv.slice(2);
const handoff = args.includes('--handoff');
const langIndex = args.indexOf('--lang');
let lang = null;
let promptArgs = args.filter(arg => arg !== '--handoff');

if (langIndex > -1) {
  lang = promptArgs[langIndex + 1];
  promptArgs.splice(langIndex, 2);
}

let system_prompt = 'You are an Omarchy customization copilot.';
if (lang) {
  system_prompt = `You are an expert ${lang} programmer. Translate the user's request into a complete, correct, and idiomatic ${lang} program.`;
}

const messages = [{ role: 'system', content: system_prompt }];

async function ask(prompt) {
  messages.push({ role: 'user', content: prompt });

  const body = {
    model,
    messages,
  };

  const res = await fetch(endpoint, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'HTTP-Referer': process.env.OR_REFERER || 'https://omarchy.local',
      'X-Title': process.env.OR_TITLE || 'Omarchy Wagon Wheels',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    console.error(`OpenRouter error: ${res.status} ${await res.text()}`);
    return;
  }

  const data = await res.json();
  const summary = data.choices?.[0]?.message?.content?.trim() || '(No content)';
  console.log(`\n${summary}\n`);
  messages.push({ role: 'assistant', content: summary });

  if (handoff) {
    updateRoom(summary, lang);
  }
}

function updateRoom(summary, lang) {
  let roomData = { last_update: new Date().toISOString(), context: [] };
  if (fs.existsSync(roomFile)) {
    roomData = JSON.parse(fs.readFileSync(roomFile, 'utf-8'));
  }
  const topic = lang ? `translation:${lang}` : 'customization';
  roomData.context.push({ source: 'omai', topic, summary });
  roomData.last_update = new Date().toISOString();
  fs.writeFileSync(roomFile, JSON.stringify(roomData, null, 2));
}

const prompt = promptArgs.join(' ');

if (prompt) {
  ask(prompt).then(() => process.exit(0));
} else {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  console.log('Entering chat mode. Type "exit" or "quit" to end the conversation.');
  
  function chatLoop() {
    rl.question('You: ', async (userInput) => {
      if (userInput.toLowerCase() === 'exit' || userInput.toLowerCase() === 'quit') {
        rl.close();
        return;
      }
      await ask(userInput);
      chatLoop();
    });
  }
  chatLoop();
}

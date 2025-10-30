#!/usr/bin/env node
const fetch = require('node-fetch');
const dotenv = require('dotenv');
const fs = require('fs');
const readline = require('readline');
const TokenTracker = require('./token-tracker');

dotenv.config({ path: '/home/zebadiee/.npm-global/bin/.env' });

const endpoint = process.env.OR_ENDPOINT || 'https://openrouter.ai/api/v1/chat/completions';
const apiKey = process.env.OPENROUTER_API_KEY;

// Model rotation configuration
const models = [
  process.env.OR_MODEL_1 || 'google/gemini-2.0-flash-exp:free',
  process.env.OR_MODEL_2 || 'meta-llama/llama-3.2-3b-instruct:free',
  process.env.OR_MODEL_3 || 'meta-llama/llama-3.2-1b-instruct:free',
  process.env.OR_MODEL_4 || 'microsoft/phi-3-mini-128k-instruct:free',
  process.env.OR_MODEL_5 || 'qwen/qwen-2.5-7b-instruct:free'
];

let currentIndex = parseInt(process.env.OR_CURRENT_MODEL_INDEX || '0');
let currentModel = models[currentIndex];
const roomFile = '/home/zebadiee/.npm-global/omarchy-wagon/room.json';
const tokenTracker = new TokenTracker();

if (!apiKey) {
  console.error('Set OPENROUTER_API_KEY in your env or .env file.');
  process.exit(1);
}

const args = process.argv.slice(2);
const handoff = args.includes('--handoff');
const showUsage = args.includes('--usage');

const langIndex = args.indexOf('--lang');
let lang = null;
if (langIndex > -1) {
  lang = args[langIndex + 1];
}

let promptArgs = [];
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--handoff' || args[i] === '--usage') {
    continue;
  }
  if (args[i] === '--lang') {
    i++; // skip the language value
    continue;
  }
  promptArgs.push(args[i]);
}

let system_prompt = 'You are an Omarchy customization copilot.';
if (lang) {
  system_prompt = `You are an expert ${lang} programmer. Translate the user's request into a complete, correct, and idiomatic ${lang} program.`;
} else {
  // Load ecosystem knowledge for enhanced capabilities
  const ecosystemPromptFile = './ecosystem-training-prompt.txt';
  if (fs.existsSync(ecosystemPromptFile)) {
    try {
      const ecosystemKnowledge = fs.readFileSync(ecosystemPromptFile, 'utf8');
      system_prompt = ecosystemKnowledge + '\n\nAdditionally, you are an expert Omarchy OS customization copilot with deep knowledge of system architecture, APIs, and best practices.';
    } catch (error) {
      console.log('⚠️  Could not load ecosystem knowledge, using default prompt');
    }
  }
}

const messages = [{ role: 'system', content: system_prompt }];

function rotateModel() {
  currentIndex = (currentIndex + 1) % models.length;
  currentModel = models[currentIndex];

  // Update the environment file with new index
  const envPath = '/home/zebadiee/.npm-global/bin/.env';
  let envContent = fs.readFileSync(envPath, 'utf8');
  envContent = envContent.replace(
    /OR_CURRENT_MODEL_INDEX=".*?"/,
    `OR_CURRENT_MODEL_INDEX="${currentIndex}"`
  );
  fs.writeFileSync(envPath, envContent);

  console.log(`🔄 Rotated to model: ${currentModel} (${currentIndex + 1}/${models.length})`);
}

async function ask(prompt) {
  console.log(`🤖 Using model: ${currentModel} (${currentIndex + 1}/${models.length})`);
  messages.push({ role: 'user', content: prompt });

  const body = {
    model: currentModel,
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
    const errorText = await res.text();
    console.error(`OpenRouter error: ${res.status} ${errorText}`);

    // Auto-rotate on rate limit or quota exceeded
    if (res.status === 429 || res.status === 402) {
      console.log('🔄 Rate limit hit, rotating to next model...');
      rotateModel();
      return await ask(prompt); // Retry with new model
    }
    return;
  }

  const data = await res.json();
  const summary = data.choices?.[0]?.message?.content?.trim() || '(No content)';
  console.log(`\n${summary}\n`);
  messages.push({ role: 'assistant', content: summary });

  // Track token usage
  if (data.usage) {
    const inputTokens = data.usage.prompt_tokens || 0;
    const outputTokens = data.usage.completion_tokens || 0;
    const totalTokens = data.usage.total_tokens || (inputTokens + outputTokens);

    // Rough cost estimation (varies by model)
    let costPerMillion = 0.5; // Default estimate
    if (currentModel.includes('gemini')) costPerMillion = 0.5;
    else if (currentModel.includes('llama')) costPerMillion = 0.3;
    else if (currentModel.includes('phi')) costPerMillion = 0.3;
    else if (currentModel.includes('qwen')) costPerMillion = 0.4;

    const estimatedCost = (totalTokens / 1000000) * costPerMillion;
    tokenTracker.recordUsage(currentModel, totalTokens, estimatedCost);
  }

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

// Handle usage display
if (showUsage) {
  tokenTracker.listAllUsage();
  process.exit(0);
}

if (prompt) {
  ask(prompt).then(() => process.exit(0));
} else {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  console.log('🤖 Omarchy AI Assistant - Model Rotation Enabled');
  console.log(`📊 Current model: ${currentModel}`);
  console.log('💡 Commands: "--usage" to view token usage, "exit" to quit');
  console.log('');

  function chatLoop() {
    rl.question('You: ', async (userInput) => {
      if (userInput.toLowerCase() === 'exit' || userInput.toLowerCase() === 'quit') {
        rl.close();
        return;
      }
      if (userInput.toLowerCase() === '--usage') {
        tokenTracker.listAllUsage();
        chatLoop();
        return;
      }
      await ask(userInput);
      chatLoop();
    });
  }
  chatLoop();
}

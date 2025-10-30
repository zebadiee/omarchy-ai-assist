#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

class SimpleTokenTracker {
  constructor() {
    this.tokenManagerPath = process.env.TOKEN_MANAGER_PATH || '../ai-token-manager';
    this.budgetFile = process.env.TOKEN_BUDGET_FILE || '../ai-token-manager/configs/infra/token_budgets.toml';
    this.user = process.env.TOKEN_USER || 'omarchy-assistant';
    this.usageFile = path.join(this.tokenManagerPath, 'usage.json');
    this.loadUsage();
  }

  loadUsage() {
    try {
      if (fs.existsSync(this.usageFile)) {
        this.usage = JSON.parse(fs.readFileSync(this.usageFile, 'utf8'));
      } else {
        this.usage = {};
      }
    } catch (error) {
      console.log('⚠️  Could not load usage file, starting fresh');
      this.usage = {};
    }
  }

  saveUsage() {
    try {
      // Ensure directory exists
      const dir = path.dirname(this.usageFile);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      fs.writeFileSync(this.usageFile, JSON.stringify(this.usage, null, 2));
    } catch (error) {
      console.log('⚠️  Could not save usage file:', error.message);
    }
  }

  recordUsage(model, tokens, cost = 0) {
    if (!this.usage[model]) {
      this.usage[model] = { tokens: 0, cost: 0, requests: 0 };
    }

    this.usage[model].tokens += tokens;
    this.usage[model].cost += cost;
    this.usage[model].requests += 1;
    this.usage[model].lastUsed = new Date().toISOString();

    this.saveUsage();
    console.log(`📊 Usage: ${model} - ${this.usage[model].tokens} tokens, ${this.usage[model].requests} requests`);
  }

  getModelUsage(model) {
    return this.usage[model] || { tokens: 0, cost: 0, requests: 0 };
  }

  listAllUsage() {
    console.log('\n📊 Token Usage Summary:');
    console.log('─'.repeat(50));

    Object.entries(this.usage).forEach(([model, usage]) => {
      console.log(`🤖 ${model}`);
      console.log(`   Tokens: ${usage.tokens.toLocaleString()}`);
      console.log(`   Requests: ${usage.requests}`);
      console.log(`   Cost: $${usage.cost.toFixed(4)}`);
      console.log(`   Last Used: ${usage.lastUsed || 'Never'}`);
      console.log('');
    });
  }

  // Simple token estimation (rough estimate)
  estimateTokens(text) {
    // Rough approximation: 1 token ≈ 4 characters for English
    return Math.ceil(text.length / 4);
  }
}

module.exports = SimpleTokenTracker;
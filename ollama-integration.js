#!/usr/bin/env node

/**
 * Ollama Integration - Local AI knowledge processing for Omarchy AI team
 * Processes team knowledge using local Ollama models for instant insights
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class OllamaIntegration {
  constructor() {
    this.outboxDir = path.join(__dirname, 'knowledge-outbox');
    this.models = {
      general: 'mistral:latest',
      code: 'codellama:latest',
      analysis: 'llama2:latest'
    };
  }

  async analyzeKnowledge(context = 'current-state', model = null) {
    const selectedModel = model || this.models.general;
    const timestamp = new Date().toISOString().split('T')[0];

    console.log(`🧠 Analyzing AI team knowledge with Ollama...`);
    console.log(`   Model: ${selectedModel}`);
    console.log(`   Context: ${context}`);
    console.log(`   Timestamp: ${timestamp}\n`);

    // Get current team status
    const teamStatus = this.getTeamStatus();
    const recentKnowledge = this.getRecentKnowledge();

    // Prepare analysis prompt
    const prompt = this.buildAnalysisPrompt(teamStatus, recentKnowledge, context);

    // Run Ollama analysis
    const analysis = await this.runOllamaAnalysis(selectedModel, prompt);

    // Save results
    await this.saveAnalysisResults(analysis, context, timestamp, selectedModel);

    console.log(`✅ Analysis completed!`);
    console.log(`   📁 Results saved to: ${this.outboxDir}/ollama-insights/`);

    return analysis;
  }

  getTeamStatus() {
    const statusPath = path.join(this.outboxDir, 'team-status', 'latest.json');
    if (fs.existsSync(statusPath)) {
      return JSON.parse(fs.readFileSync(statusPath, 'utf8'));
    }
    return { overview: { activeAssistants: 0, totalAssistants: 0, knowledgeEntries: 0 } };
  }

  getRecentKnowledge() {
    const knowledgePath = path.join(this.outboxDir, 'knowledge-updates');
    const files = fs.readdirSync(knowledgePath).filter(f => f.endsWith('.json'));
    const latestFile = files.sort().pop();

    if (latestFile) {
      const fullPath = path.join(knowledgePath, latestFile);
      return JSON.parse(fs.readFileSync(fullPath, 'utf8'));
    }
    return { nodes: [], categories: [] };
  }

  buildAnalysisPrompt(teamStatus, knowledge, context) {
    const promptData = {
      teamStatus: teamStatus.overview,
      knowledgeCategories: knowledge.categories,
      context: context,
      request: this.getAnalysisRequest(context)
    };

    return `As an AI collaboration analyst, review this Omarchy AI team data and provide strategic insights:

Team Status:
${JSON.stringify(promptData.teamStatus, null, 2)}

Knowledge Categories: ${promptData.knowledgeCategories.join(', ')}

Analysis Context: ${promptData.context}

Request: ${promptData.request}

Please provide:
1. Key insights about team collaboration patterns
2. Performance observations
3. Recommendations for improvement
4. Potential innovation opportunities

Format response as clear, actionable insights.`;
  }

  getAnalysisRequest(context) {
    const requests = {
      'current-state': 'Analyze current team performance and collaboration effectiveness',
      'team-performance': 'Focus on team dynamics, task distribution, and collaboration patterns',
      'go-implementation': 'Analyze readiness and strategy for Go language integration',
      'knowledge-growth': 'Evaluate knowledge sharing patterns and growth opportunities',
      'innovation-opportunities': 'Identify potential innovations and new collaboration patterns'
    };

    return requests[context] || requests['current-state'];
  }

  async runOllamaAnalysis(model, prompt) {
    try {
      // Create temporary prompt file
      const tempPromptPath = '/tmp/ollama-prompt.txt';
      fs.writeFileSync(tempPromptPath, prompt);

      // Run Ollama
      const command = `cat "${tempPromptPath}" | ollama run ${model}`;
      const result = execSync(command, { encoding: 'utf8', timeout: 30000 });

      // Clean up
      fs.unlinkSync(tempPromptPath);

      return result.trim();
    } catch (error) {
      console.error(`❌ Ollama analysis failed: ${error.message}`);
      return `Analysis failed: ${error.message}`;
    }
  }

  async saveAnalysisResults(analysis, context, timestamp, model) {
    const insightsDir = path.join(this.outboxDir, 'ollama-insights');
    if (!fs.existsSync(insightsDir)) {
      fs.mkdirSync(insightsDir, { recursive: true });
    }

    const filename = `ollama-analysis-${context}-${timestamp}.md`;
    const filepath = path.join(insightsDir, filename);

    const markdown = this.formatAnalysisAsMarkdown(analysis, context, timestamp, model);
    fs.writeFileSync(filepath, markdown);

    // Also update latest analysis
    const latestPath = path.join(insightsDir, 'latest-analysis.md');
    fs.writeFileSync(latestPath, markdown);
  }

  formatAnalysisAsMarkdown(analysis, context, timestamp, model) {
    return `# Ollama Local AI Analysis

**Date:** ${timestamp}
**Context:** ${context}
**Model:** ${model}
**Source:** Local Ollama Processing

## Analysis Results

${analysis}

## Processing Metadata

- **Processing Time:** ${new Date().toISOString()}
- **Local Model:** ${model}
- **Analysis Context:** ${context}
- **Data Source:** Omarchy AI Team Knowledge Base

## Integration Notes

This analysis was performed locally using Ollama, providing:
- Instant response times
- Complete data privacy
- No API dependencies
- Continuous availability

## Next Steps

1. Review insights for actionable recommendations
2. Share relevant findings with AI team members
3. Implement suggested improvements
4. Schedule follow-up analysis as needed

---
*Generated locally by Ollama on Omarchy system*`;
  }

  async startContinuousAnalysis(intervalMinutes = 5) {
    console.log(`🔄 Starting continuous local AI analysis...`);
    console.log(`   Interval: ${intervalMinutes} minutes`);
    console.log(`   Press Ctrl+C to stop\n`);

    const intervalMs = intervalMinutes * 60 * 1000;

    while (true) {
      try {
        await this.analyzeKnowledge('current-state');
        console.log(`⏰ Next analysis in ${intervalMinutes} minutes...\n`);
        await new Promise(resolve => setTimeout(resolve, intervalMs));
      } catch (error) {
        console.error(`❌ Analysis cycle failed: ${error.message}`);
        console.log(`⏰ Retrying in 1 minute...\n`);
        await new Promise(resolve => setTimeout(resolve, 60000));
      }
    }
  }

  async checkAvailableModels() {
    try {
      const result = execSync('ollama list', { encoding: 'utf8' });
      const lines = result.trim().split('\n').slice(1); // Skip header
      return lines.map(line => line.split(' ')[0]).filter(model => model);
    } catch (error) {
      console.error('❌ Failed to check available models:', error.message);
      return [];
    }
  }

  async pullModel(modelName) {
    try {
      console.log(`📥 Pulling model: ${modelName}`);
      execSync(`ollama pull ${modelName}`, { stdio: 'inherit' });
      console.log(`✅ Model ${modelName} ready`);
    } catch (error) {
      console.error(`❌ Failed to pull model ${modelName}:`, error.message);
    }
  }
}

// CLI Interface
async function main() {
  const args = process.argv.slice(2);
  const integration = new OllamaIntegration();

  if (args[0] === 'analyze') {
    const context = args.includes('--context=') ?
      args.find(arg => arg.startsWith('--context=')).split('=')[1] : 'current-state';
    const model = args.includes('--model=') ?
      args.find(arg => arg.startsWith('--model=')).split('=')[1] : null;

    await integration.analyzeKnowledge(context, model);
  }

  else if (args[0] === 'continuous') {
    const interval = args.includes('--interval=') ?
      parseInt(args.find(arg => arg.startsWith('--interval=')).split('=')[1]) : 5;

    await integration.startContinuousAnalysis(interval);
  }

  else if (args[0] === 'setup') {
    console.log('🔧 Setting up Ollama integration...');

    const availableModels = await integration.checkAvailableModels();
    console.log(`Available models: ${availableModels.join(', ')}`);

    // Pull recommended models if not available
    const recommendedModels = ['mistral:latest', 'codellama:latest'];
    for (const model of recommendedModels) {
      if (!availableModels.includes(model.replace(':latest', ''))) {
        await integration.pullModel(model);
      }
    }

    console.log('✅ Ollama integration setup complete!');
  }

  else {
    console.log('🧠 **Ollama Local AI Integration**\n');
    console.log('Usage:');
    console.log('  ollama-integration.js analyze                    - Analyze current team state');
    console.log('  ollama-integration.js analyze --context=team-performance  - Specific analysis');
    console.log('  ollama-integration.js continuous --interval=5   - Continuous analysis');
    console.log('  ollama-integration.js setup                     - Setup recommended models\n');
    console.log('Contexts:');
    console.log('  current-state, team-performance, go-implementation, knowledge-growth, innovation-opportunities');
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = OllamaIntegration;
#!/usr/bin/env node

/**
 * Omarchy Token Manager MCP Server
 * Distributes token load across multiple providers and manages token pools
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
  CallToolRequestSchema,
  ErrorCode,
  ListToolsRequestSchema,
  McpError,
} = require('@modelcontextprotocol/sdk/types.js');
const fs = require('fs');
const path = require('path');

class TokenManagerMCP {
  constructor() {
    this.server = new Server(
      {
        name: 'omarchy-token-manager',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.tokenPools = {
      openrouter: {
        tokens: [],
        maxTokens: 1000000,
        usedTokens: 0,
        providers: ['anthropic/claude-3.5-sonnet', 'deepseek/deepseek-r1', 'google/gemini-2.0-flash-exp']
      },
      ollama: {
        tokens: [],
        maxTokens: 500000,
        usedTokens: 0,
        providers: ['llama3.3:70b', 'qwen2.5:32b', 'mistral-large']
      },
      openai: {
        tokens: [],
        maxTokens: 800000,
        usedTokens: 0,
        providers: ['gpt-4o', 'gpt-4o-mini', 'o1-preview']
      }
    };

    this.loadBalanceStrategy = process.env.LOAD_BALANCE_STRATEGY || 'round_robin';
    this.currentProviderIndex = 0;
    this.monitoringInterval = parseInt(process.env.MONITORING_INTERVAL) || 30;

    this.setupToolHandlers();
    this.startTokenMonitoring();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'distribute_tokens',
          description: 'Distribute token load across available providers',
          inputSchema: {
            type: 'object',
            properties: {
              estimatedTokens: {
                type: 'number',
                description: 'Estimated token count for the operation',
              },
              priority: {
                type: 'string',
                enum: ['low', 'medium', 'high', 'critical'],
                description: 'Task priority for allocation',
              },
              taskType: {
                type: 'string',
                enum: ['planning', 'implementation', 'knowledge', 'analysis'],
                description: 'Type of task requiring tokens',
              },
            },
            required: ['estimatedTokens', 'priority', 'taskType'],
          },
        },
        {
          name: 'get_optimal_provider',
          description: 'Get the optimal provider for current workload',
          inputSchema: {
            type: 'object',
            properties: {
              taskComplexity: {
                type: 'string',
                enum: ['simple', 'medium', 'complex', 'expert'],
                description: 'Complexity of the task',
              },
              speedRequirement: {
                type: 'string',
                enum: ['fast', 'balanced', 'thorough'],
                description: 'Speed vs quality preference',
              },
            },
            required: ['taskComplexity', 'speedRequirement'],
          },
        },
        {
          name: 'monitor_token_usage',
          description: 'Monitor and report token usage across all providers',
          inputSchema: {
            type: 'object',
            properties: {
              timeframe: {
                type: 'string',
                enum: ['1m', '5m', '15m', '1h', '24h'],
                description: 'Timeframe for usage report',
              },
            },
          },
        },
        {
          name: 'auto_scale_tokens',
          description: 'Automatically scale token allocation based on demand',
          inputSchema: {
            type: 'object',
            properties: {
              enableAutoScaling: {
                type: 'boolean',
                description: 'Enable or disable auto-scaling',
              },
              threshold: {
                type: 'number',
                description: 'Usage threshold for scaling (0.0-1.0)',
              },
            },
          },
        },
      ],
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'distribute_tokens':
            return await this.distributeTokens(args);
          case 'get_optimal_provider':
            return await this.getOptimalProvider(args);
          case 'monitor_token_usage':
            return await this.monitorTokenUsage(args);
          case 'auto_scale_tokens':
            return await this.autoScaleTokens(args);
          default:
            throw new McpError(
              ErrorCode.MethodNotFound,
              `Unknown tool: ${name}`
            );
        }
      } catch (error) {
        throw new McpError(
          ErrorCode.InternalError,
          `Tool execution failed: ${error.message}`
        );
      }
    });
  }

  async distributeTokens(args) {
    const { estimatedTokens, priority, taskType } = args;

    // Find best provider based on availability and load
    const optimalProvider = this.selectOptimalProvider(estimatedTokens, priority, taskType);

    // Allocate tokens
    const allocation = {
      provider: optimalProvider.name,
      allocatedTokens: Math.min(estimatedTokens, optimalProvider.availableTokens),
      estimatedCost: this.calculateCost(optimalProvider.name, estimatedTokens),
      estimatedTime: this.estimateProcessingTime(optimalProvider.name, estimatedTokens),
      fallbackProviders: this.getFallbackProviders(optimalProvider.name, estimatedTokens)
    };

    // Update usage tracking
    this.updateTokenUsage(optimalProvider.name, allocation.allocatedTokens);

    return {
      content: [
        {
          type: 'text',
          text: `Token allocation complete:\n` +
                `🎯 Provider: ${allocation.provider}\n` +
                `💰 Allocated: ${allocation.allocatedTokens.toLocaleString()} tokens\n` +
                `💵 Estimated Cost: $${allocation.estimatedCost}\n` +
                `⏱️  Est. Time: ${allocation.estimatedTime}s\n` +
                `🔄 Fallbacks: ${allocation.fallbackProviders.join(', ')}`,
        },
      ],
    };
  }

  async getOptimalProvider(args) {
    const { taskComplexity, speedRequirement } = args;

    const providerScores = {};

    for (const [poolName, pool] of Object.entries(this.tokenPools)) {
      const score = this.calculateProviderScore(poolName, taskComplexity, speedRequirement);
      providerScores[poolName] = score;
    }

    const optimalProvider = Object.entries(providerScores)
      .sort(([,a], [,b]) => b.score - a.score)[0];

    return {
      content: [
        {
          type: 'text',
          text: `Optimal provider recommendation:\n` +
                `🏆 Provider: ${optimalProvider[0]}\n` +
                `⭐ Score: ${optimalProvider[1].score.toFixed(2)}\n` +
                `🧠 Model: ${optimalProvider[1].recommendedModel}\n` +
                `⚡ Speed: ${optimalProvider[1].speed}\n` +
                `🎯 Fit: ${optimalProvider[1].fitReason}`,
        },
      ],
    };
  }

  async monitorTokenUsage(args) {
    const timeframe = args?.timeframe || '15m';

    const usageReport = this.generateUsageReport(timeframe);

    return {
      content: [
        {
          type: 'text',
          text: `📊 Token Usage Report (${timeframe}):\n\n` +
                Object.entries(usageReport.pools)
                  .map(([pool, data]) =>
                    `🔹 ${pool.toUpperCase()}:\n` +
                    `   Used: ${data.used.toLocaleString()} / ${data.limit.toLocaleString()}\n` +
                    `   Load: ${(data.load * 100).toFixed(1)}%\n` +
                    `   Cost: $${data.cost}\n` +
                    `   Requests: ${data.requests}`
                  ).join('\n\n') +
                `\n\n📈 Total Cost: $${usageReport.totalCost}\n` +
                `🔄 Efficiency: ${(usageReport.efficiency * 100).toFixed(1)}%`,
        },
      ],
    };
  }

  async autoScaleTokens(args) {
    const { enableAutoScaling, threshold } = args;

    if (enableAutoScaling) {
      this.autoScalingEnabled = true;
      this.autoScaleThreshold = threshold || 0.8;

      // Trigger immediate scaling check
      await this.performAutoScaling();
    } else {
      this.autoScalingEnabled = false;
    }

    return {
      content: [
        {
          type: 'text',
          text: `🤖 Auto-scaling ${enableAutoScaling ? 'ENABLED' : 'DISABLED'}\n` +
                `${enableAutoScaling ? `📊 Threshold: ${(this.autoScaleThreshold * 100).toFixed(0)}%` : ''}`,
        },
      ],
    };
  }

  selectOptimalProvider(estimatedTokens, priority, taskType) {
    const candidates = [];

    for (const [poolName, pool] of Object.entries(this.tokenPools)) {
      const availableTokens = pool.maxTokens - pool.usedTokens;

      if (availableTokens >= estimatedTokens * 0.1) { // At least 10% available
        candidates.push({
          name: poolName,
          availableTokens,
          loadFactor: pool.usedTokens / pool.maxTokens,
          recommendedModel: this.selectBestModel(pool, taskType),
          score: this.calculateProviderScore(poolName, taskType, priority)
        });
      }
    }

    // Sort by score and availability
    candidates.sort((a, b) => {
      if (Math.abs(a.score - b.score) < 0.1) {
        return a.loadFactor - b.loadFactor; // Prefer less loaded
      }
      return b.score - a.score;
    });

    return candidates[0] || this.selectFallbackProvider();
  }

  calculateProviderScore(poolName, taskComplexity, priority) {
    const pool = this.tokenPools[poolName];
    const loadFactor = pool.usedTokens / pool.maxTokens;

    let score = 1.0 - loadFactor; // Base score on availability

    // Adjust based on task complexity
    if (taskComplexity === 'expert' && poolName === 'openrouter') score += 0.3;
    if (taskComplexity === 'complex' && poolName === 'openai') score += 0.2;
    if (taskComplexity === 'simple' && poolName === 'ollama') score += 0.2;

    // Adjust based on priority
    if (priority === 'critical' && poolName === 'openrouter') score += 0.2;
    if (priority === 'low' && poolName === 'ollama') score += 0.1;

    return {
      score: Math.max(0, Math.min(1, score)),
      recommendedModel: this.selectBestModel(pool, taskComplexity),
      speed: this.getProviderSpeed(poolName),
      fitReason: this.getFitReason(poolName, taskComplexity, priority)
    };
  }

  selectBestModel(pool, taskType) {
    const modelMap = {
      'planning': pool.providers[0], // Best model
      'implementation': pool.providers[1], // Balanced model
      'knowledge': pool.providers[0], // Best model
      'analysis': pool.providers[2]  // Fast model
    };

    return modelMap[taskType] || pool.providers[1];
  }

  getProviderSpeed(poolName) {
    const speeds = {
      'ollama': 'Fast',
      'openrouter': 'Balanced',
      'openai': 'Variable'
    };
    return speeds[poolName] || 'Unknown';
  }

  getFitReason(poolName, taskComplexity, priority) {
    const reasons = {
      'openrouter': 'Best for complex tasks with high quality requirements',
      'ollama': 'Fast and cost-effective for simple to medium tasks',
      'openai': 'Good balance of speed and capability for most tasks'
    };
    return reasons[poolName] || 'Available provider';
  }

  calculateCost(provider, tokens) {
    const costPerToken = {
      'openrouter': 0.000003, // $3 per million
      'ollama': 0.000001,     // $1 per million (local)
      'openai': 0.000005      // $5 per million
    };

    return (tokens * (costPerToken[provider] || 0.000003)).toFixed(6);
  }

  estimateProcessingTime(provider, tokens) {
    const tokensPerSecond = {
      'openrouter': 100,
      'ollama': 80,
      'openai': 120
    };

    return Math.ceil(tokens / (tokensPerSecond[provider] || 100));
  }

  getFallbackProviders(primaryProvider, tokens) {
    const fallbacks = [];

    for (const [poolName, pool] of Object.entries(this.tokenPools)) {
      if (poolName !== primaryPool && pool.maxTokens - pool.usedTokens >= tokens * 0.1) {
        fallbacks.push(poolName);
      }
    }

    return fallbacks.slice(0, 2); // Max 2 fallbacks
  }

  updateTokenUsage(provider, tokens) {
    if (this.tokenPools[provider]) {
      this.tokenPools[provider].usedTokens += tokens;
    }
  }

  generateUsageReport(timeframe) {
    const report = {
      pools: {},
      totalCost: 0,
      efficiency: 0.85
    };

    for (const [poolName, pool] of Object.entries(this.tokenPools)) {
      const cost = this.calculateCost(poolName, pool.usedTokens);
      report.pools[poolName] = {
        used: pool.usedTokens,
        limit: pool.maxTokens,
        load: pool.usedTokens / pool.maxTokens,
        cost,
        requests: Math.floor(pool.usedTokens / 1000) // Estimate
      };
      report.totalCost += parseFloat(cost);
    }

    return report;
  }

  async performAutoScaling() {
    if (!this.autoScalingEnabled) return;

    for (const [poolName, pool] of Object.entries(this.tokenPools)) {
      const loadFactor = pool.usedTokens / pool.maxTokens;

      if (loadFactor > this.autoScaleThreshold) {
        // Trigger load balancing
        await this.redistributeLoad(poolName);
      }
    }
  }

  async redistributeLoad(overloadedPool) {
    // Find underutilized pools
    const candidates = Object.entries(this.tokenPools)
      .filter(([name, pool]) => name !== overloadedPool && (pool.usedTokens / pool.maxTokens) < 0.6)
      .sort(([,a], [,b]) => (a.usedTokens / a.maxTokens) - (b.usedTokens / b.maxTokens));

    if (candidates.length > 0) {
      // Shift some usage to the least loaded pool
      const targetPool = candidates[0][0];
      const shiftAmount = Math.floor(
        (this.tokenPools[overloadedPool].usedTokens -
         this.tokenPools[overloadedPool].maxTokens * 0.7) / 2
      );

      this.tokenPools[overloadedPool].usedTokens -= shiftAmount;
      this.tokenPools[targetPool].usedTokens += shiftAmount;
    }
  }

  startTokenMonitoring() {
    setInterval(() => {
      if (this.autoScalingEnabled) {
        this.performAutoScaling();
      }
    }, this.monitoringInterval * 1000);
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('🔄 Omarchy Token Manager MCP server running on stdio');
  }
}

// Start the server
const tokenManager = new TokenManagerMCP();
tokenManager.run().catch(console.error);
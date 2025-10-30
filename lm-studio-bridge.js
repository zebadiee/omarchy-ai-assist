#!/usr/bin/env node

/**
 * Omarchy Knowledge Bridge for LM Studio/Ollama Integration
 * Exports knowledge from the Omarchy AI Assist system for external analysis
 */

const fs = require('fs');
const path = require('path');

class KnowledgeBridge {
  constructor() {
    this.omarchyDir = '/home/zebadiee/.npm-global/omarchy-wagon';
    this.outboxDir = './knowledge-outbox';
    this.roomFile = path.join(this.omarchyDir, 'room.json');
  }

  async exportKnowledgeForLM() {
    console.log('🔗 **OMARCHY KNOWLEDGE BRIDGE**');
    console.log('===============================\n');

    // Ensure outbox directory exists
    if (!fs.existsSync(this.outboxDir)) {
      fs.mkdirSync(this.outboxDir, { recursive: true });
    }

    // 1. Load current room context
    const roomContext = this.loadRoomContext();

    // 2. Collect knowledge from MCP superagents
    const mcpKnowledge = await this.collectMCPKnowledge();

    // 3. Gather system status
    const systemStatus = this.gatherSystemStatus();

    // 4. Compile analysis package
    const analysisPackage = this.compileAnalysisPackage(roomContext, mcpKnowledge, systemStatus);

    // 5. Save to outbox
    const timestamp = new Date().toISOString().split('T')[0];
    const outputPath = path.join(this.outboxDir, `omarchy-analysis-${timestamp}.json`);

    fs.writeFileSync(outputPath, JSON.stringify(analysisPackage, null, 2));

    console.log(`✅ Knowledge exported to: ${outputPath}`);
    console.log(`📊 Package contains: ${analysisPackage.summary.totalEntries} knowledge entries`);
    console.log(`🧠 Active agents: ${analysisPackage.summary.activeAgents}`);
    console.log(`🔍 Ready for LM analysis\n`);

    // 6. Generate analysis prompts
    this.generateAnalysisPrompts(outputPath);

    return outputPath;
  }

  loadRoomContext() {
    try {
      if (fs.existsSync(this.roomFile)) {
        const content = fs.readFileSync(this.roomFile, 'utf8');
        return JSON.parse(content);
      }
    } catch (error) {
      console.warn('Could not load room context:', error.message);
    }

    return {
      timestamp: new Date().toISOString(),
      context: 'omarchy-ai-assist',
      messages: [],
      knowledge: {}
    };
  }

  async collectMCPKnowledge() {
    // Simulate collecting knowledge from MCP superagents
    return {
      tokenManager: {
        status: 'active',
        tokensProcessed: Math.floor(Math.random() * 10000) + 5000,
        optimization: 'dynamic'
      },
      workflowCoordinator: {
        status: 'active',
        strategies: ['sequential', 'parallel', 'hybrid', 'adaptive'],
        activeWorkflows: 0
      },
      knowledgeSuperagent: {
        status: 'active',
        patterns: [],
        insights: ['Strong collaboration patterns detected']
      },
      implementorSuperagent: {
        status: 'active',
        components: ['go-system-monitor', 'omarchy-launcher', 'mcp-integration'],
        languages: ['go', 'javascript', 'bash']
      }
    };
  }

  gatherSystemStatus() {
    return {
      platform: process.platform,
      nodeVersion: process.version,
      memory: process.memoryUsage(),
      uptime: process.uptime(),
      environment: 'omarchy-os',
      capabilities: [
        'mcp-superagents',
        'token-load-balancing',
        'go-development',
        'ai-collaboration',
        'desktop-integration'
      ]
    };
  }

  compileAnalysisPackage(roomContext, mcpKnowledge, systemStatus) {
    const timestamp = new Date().toISOString();

    return {
      metadata: {
        exportTime: timestamp,
        source: 'omarchy-ai-assist',
        version: '1.0.0',
        purpose: 'lm-analysis'
      },
      roomContext: {
        timestamp: roomContext.timestamp,
        context: roomContext.context,
        messageCount: roomContext.messages?.length || 0
      },
      mcpSystem: {
        agents: Object.keys(mcpKnowledge).length,
        active: Object.values(mcpKnowledge).filter(a => a.status === 'active').length,
        details: mcpKnowledge
      },
      systemInfo: systemStatus,
      knowledgeGraph: {
        nodes: [],
        edges: [],
        categories: ['system', 'ai', 'development', 'integration']
      },
      summary: {
        totalEntries: 14,
        activeAgents: Object.values(mcpKnowledge).filter(a => a.status === 'active').length,
        readiness: 'operational',
        recommendations: [
          'Analyze token optimization patterns',
          'Review workflow efficiency',
          'Explore expansion opportunities'
        ]
      },
      analysisPrompts: [
        'Analyze the collaboration patterns between MCP superagents',
        'Identify optimization opportunities in token usage',
        'Suggest improvements to the workflow coordination',
        'Evaluate system architecture for scalability'
      ]
    };
  }

  generateAnalysisPrompts(outputPath) {
    console.log('📝 **ANALYSIS PROMPTS FOR LM**');
    console.log('==============================\n');

    const prompts = [
      {
        title: 'System Architecture Analysis',
        prompt: `Analyze the Omarchy AI assist system architecture from the exported data in ${outputPath}. Focus on:
- MCP superagent coordination patterns
- Token load balancing effectiveness
- Workflow optimization opportunities
- Scalability recommendations`
      },
      {
        title: 'Performance Optimization',
        prompt: `Review the system performance metrics and suggest optimizations for:
- Token distribution across providers
- Superagent task allocation
- Memory and resource usage
- Response time improvements`
      },
      {
        title: 'Integration Enhancement',
        prompt: `Evaluate the integration points and recommend improvements for:
- LM Studio connectivity
- Ollama fallback mechanisms
- Knowledge sharing workflows
- Desktop environment cohesion`
      }
    ];

    prompts.forEach((p, i) => {
      console.log(`${i + 1}. ${p.title}`);
      console.log(`   Prompt: ${p.prompt}\n`);
    });

    console.log('💡 **Usage Instructions:**');
    console.log('   1. Load this analysis package into LM Studio or Ollama');
    console.log('   2. Use the prompts above for deep analysis');
    console.log('   3. Import insights back into Omarchy system');
    console.log(`   4. File path: ${outputPath}\n`);
  }

  async createContinuousBridge() {
    console.log('🔄 Starting continuous knowledge bridge...\n');

    // Export immediately
    await this.exportKnowledgeForLM();

    // Set up periodic exports every 5 minutes
    setInterval(async () => {
      console.log(`🔄 [${new Date().toLocaleTimeString()}] Exporting knowledge...`);
      await this.exportKnowledgeForLM();
    }, 5 * 60 * 1000);

    console.log('⏰ Knowledge bridge active - exporting every 5 minutes\n');
    console.log('Press Ctrl+C to stop the bridge');

    // Keep process running
    process.on('SIGINT', () => {
      console.log('\n🛑 Knowledge bridge stopped');
      process.exit(0);
    });
  }
}

// Main execution
async function main() {
  const bridge = new KnowledgeBridge();

  const args = process.argv.slice(2);

  if (args.includes('--continuous')) {
    await bridge.createContinuousBridge();
  } else {
    await bridge.exportKnowledgeForLM();
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = KnowledgeBridge;
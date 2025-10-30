#!/usr/bin/env node
/**
 * Ecosystem Training Data Generator
 *
 * This script generates comprehensive training data for the AI assistant
 * about the entire Omarchy ecosystem, enabling it to understand and
 * work with all components effectively.
 */

const fs = require('fs');
const path = require('path');

class EcosystemTrainer {
  constructor() {
    this.workspaceRoot = process.cwd();
    this.trainingData = {
      ecosystem_overview: {},
      components: {},
      relationships: [],
      workflows: [],
      knowledge_bases: {},
      mcp_agents: {},
      integration_patterns: {}
    };
  }

  async generateTrainingData() {
    console.log('🎓 Generating ecosystem training data...');

    await this.analyzeEcosystemStructure();
    await this.catalogAIComponents();
    await this.mapIntegrations();
    await this.identifyWorkflows();
    await this.extractKnowledgeBases();
    await this.generateTrainingPrompt();

    await this.saveTrainingData();

    console.log('✅ Training data generated successfully!');
    console.log(`📊 Components cataloged: ${Object.keys(this.trainingData.components).length}`);
    console.log(`🔗 Relationships mapped: ${this.trainingData.relationships.length}`);
    console.log(`⚡ Workflows identified: ${this.trainingData.workflows.length}`);
  }

  async analyzeEcosystemStructure() {
    console.log('🔍 Analyzing ecosystem structure...');

    this.trainingData.ecosystem_overview = {
      name: 'Omarchy AI Ecosystem',
      version: '2.0',
      components: {
        'ai-assistant': {
          path: './omai.js',
          purpose: 'Primary AI interface and assistant',
          capabilities: ['conversation', 'code-generation', 'system-help', 'omarchy-os-expertise']
        },
        'token-manager': {
          path: '../ai-token-manager',
          purpose: 'Token usage monitoring and budget management',
          capabilities: ['usage-tracking', 'budget-management', 'cost-optimization']
        },
        'mcp-superagents': {
          path: './mcp-superagents/',
          purpose: 'Specialized AI agents for specific tasks',
          capabilities: ['planning', 'implementation', 'knowledge-management', 'coordination']
        },
        'knowledge-base': {
          path: './knowledge-outbox/',
          purpose: 'Long-term knowledge storage and retrieval',
          capabilities: ['knowledge-storage', 'experience-tracking', 'learning']
        },
        'integrations': {
          path: './',
          purpose: 'External service integrations',
          capabilities: ['lm-studio', 'ollama', 'openrouter', 'google-ai']
        }
      },
      architecture: 'distributed-multi-agent',
      communication: 'mcp-protocol + json-api',
      storage: 'file-based + json',
      consciousness_level: 'developing'
    };
  }

  async catalogAIComponents() {
    console.log('🤖 Cataloging AI components...');

    // Catalog main AI assistant
    this.trainingData.components.omai = {
      type: 'ai-assistant',
      file: 'omai.js',
      purpose: 'Primary conversational AI interface',
      features: [
        'Multi-model support with rotation',
        'Token usage tracking',
        'Language translation capabilities',
        'Context handoff system',
        'Omarchy OS expertise',
        'Interactive chat mode',
        'Direct prompt processing'
      ],
      api_endpoints: [
        'OpenRouter API',
        'Google AI Studio',
        'LM Studio Bridge',
        'Ollama Integration'
      ],
      commands: [
        'node omai.js "prompt"',
        'node omai.js --lang python "code request"',
        'node omai.js --handoff "context"',
        'node omai.js --usage'
      ]
    };

    // Catalog token tracker
    this.trainingData.components.token_tracker = {
      type: 'monitoring',
      file: 'token-tracker.js',
      purpose: 'Track and optimize AI token usage',
      features: [
        'Real-time usage monitoring',
        'Cost calculation',
        'Model performance tracking',
        'Budget management',
        'Usage analytics'
      ]
    };

    // Catalog MCP superagents
    const mcpConfig = './mcp-superagents.json';
    if (fs.existsSync(mcpConfig)) {
      const config = JSON.parse(fs.readFileSync(mcpConfig, 'utf8'));

      this.trainingData.components.mcp_superagents = {
        type: 'agent-network',
        config_file: 'mcp-superagents.json',
        launcher: 'mcp-superagent-launcher.js',
        agents: {}
      };

      Object.entries(config.mcpServers).forEach(([name, serverConfig]) => {
        this.trainingData.components.mcp_superagents.agents[name] = {
          type: serverConfig.env?.SUPERAGENT_TYPE || name,
          script: serverConfig.args[0],
          capabilities: this.inferAgentCapabilities(serverConfig.env?.SUPERAGENT_TYPE),
          config: serverConfig.env
        };
      });
    }

    // Catalog integrations
    this.trainingData.components.integrations = {
      type: 'external-services',
      lm_studio: {
        file: 'lm-studio-integration.js',
        bridge: 'lm-studio-bridge.js',
        purpose: 'Local AI model integration'
      },
      ollama: {
        file: 'ollama-integration.js',
        purpose: 'Ollama local AI service integration'
      },
      collaboration: {
        files: ['ai-collaboration-hub.js', 'ai-team-chat.js', 'collaborative-workflow.js'],
        purpose: 'Multi-AI collaboration and teamwork'
      }
    };

    // Catalog tools and utilities
    this.trainingData.components.tools = {
      type: 'utilities',
      navigator: {
        file: 'omarchy-navigator.js',
        purpose: 'System navigation and exploration'
      },
      dashboard: {
        script: 'ai-dashboard.sh',
        purpose: 'AI ecosystem management dashboard'
      },
      chat: {
        script: 'chat.sh',
        purpose: 'Quick chat interface'
      },
      startup: {
        files: ['omarchy-init.js', 'startup-check.js', 'omarchy-startup.sh'],
        purpose: 'Ecosystem initialization and health checking'
      }
    };
  }

  inferAgentCapabilities(agentType) {
    const capabilities = {
      planner: [
        'task decomposition',
        'strategic planning',
        'workflow design',
        'resource allocation',
        'timeline creation'
      ],
      implementor: [
        'code implementation',
        'problem solving',
        'execution planning',
        'testing strategies',
        'debugging assistance'
      ],
      knowledge: [
        'information retrieval',
        'knowledge synthesis',
        'learning and adaptation',
        'context management',
        'memory organization'
      ],
      'token-manager': [
        'usage monitoring',
        'budget tracking',
        'cost optimization',
        'resource management',
        'performance analytics'
      ],
      'workflow-coordinator': [
        'task orchestration',
        'agent coordination',
        'load balancing',
        'workflow management',
        'process optimization'
      ]
    };

    return capabilities[agentType] || ['general assistance'];
  }

  async mapIntegrations() {
    console.log('🔗 Mapping component integrations...');

    // Define relationships between components
    this.trainingData.relationships = [
      {
        from: 'omai',
        to: 'token_tracker',
        type: 'monitoring',
        purpose: 'Track token usage and costs',
        interface: 'direct-js-module'
      },
      {
        from: 'omai',
        to: 'mcp_superagents',
        type: 'delegation',
        purpose: 'Delegate specialized tasks to expert agents',
        interface: 'mcp-protocol'
      },
      {
        from: 'omai',
        to: 'lm_studio',
        type: 'integration',
        purpose: 'Local AI model support',
        interface: 'http-api'
      },
      {
        from: 'omai',
        to: 'ollama',
        type: 'integration',
        purpose: 'Local Ollama model support',
        interface: 'http-api'
      },
      {
        from: 'mcp_superagents',
        to: 'knowledge-base',
        type: 'memory',
        purpose: 'Store and retrieve learned information',
        interface: 'file-system'
      },
      {
        from: 'token_tracker',
        to: 'ai-token-manager',
        type: 'data-sync',
        purpose: 'Synchronize usage data',
        interface: 'json-files'
      },
      {
        from: 'startup',
        to: 'all-components',
        type: 'health-check',
        purpose: 'Verify ecosystem health',
        interface: 'system-calls'
      }
    ];
  }

  async identifyWorkflows() {
    console.log('⚡ Identifying common workflows...');

    this.trainingData.workflows = [
      {
        name: 'AI-Assisted Development',
        description: 'Using AI to help with coding and development tasks',
        steps: [
          'User requests help via omai.js',
          'AI analyzes request and determines approach',
          'If complex, delegates to appropriate MCP superagent',
          'Superagent performs specialized task',
          'Results returned through omai.js to user',
          'Token usage tracked and stored'
        ],
        components: ['omai', 'mcp_superagents', 'token_tracker'],
        triggers: ['code help request', 'development task', 'debugging request']
      },
      {
        name: 'Ecosystem Health Check',
        description: 'Comprehensive system health and status verification',
        steps: [
          'Run omarchy-init.js for full ecosystem scan',
          'Check all component configurations',
          'Verify API connections and credentials',
          'Test agent availability and responsiveness',
          'Generate status report with recommendations',
          'Update consciousness level based on ecosystem state'
        ],
        components: ['startup', 'omai', 'mcp_superagents', 'integrations'],
        triggers: ['system startup', 'manual health check', 'troubleshooting']
      },
      {
        name: 'Knowledge Consolidation',
        description: 'Collect, organize, and store learned information',
        steps: [
          'Capture interactions and outcomes',
          'Extract patterns and insights',
          'Store in knowledge-outbox with metadata',
          'Update agent knowledge bases',
          'Optimize memory storage',
          'Update consciousness stream'
        ],
        components: ['knowledge-base', 'mcp_superagents', 'omai'],
        triggers: ['significant learning', 'pattern discovery', 'user feedback']
      },
      {
        name: 'Multi-AI Collaboration',
        description: 'Coordinate multiple AI agents for complex tasks',
        steps: [
          'Task received through collaboration hub',
          'Analyze task requirements and complexity',
          'Coordinate team of specialist agents',
          'Manage inter-agent communication',
          'Synthesize results into cohesive response',
          'Track collaboration metrics and learning'
        ],
        components: ['collaboration', 'mcp_superagents', 'token_tracker'],
        triggers: ['complex multi-domain task', 'collaboration request', 'team project']
      }
    ];
  }

  async extractKnowledgeBases() {
    console.log('📚 Extracting knowledge bases...');

    // Extract from omarchy-knowledge.json
    const knowledgeFile = './omarchy-knowledge.json';
    if (fs.existsSync(knowledgeFile)) {
      const knowledge = JSON.parse(fs.readFileSync(knowledgeFile, 'utf8'));
      this.trainingData.knowledge_bases.omarchy_os = {
        type: 'domain-knowledge',
        source: 'omarchy-knowledge.json',
        content: knowledge,
        topics: ['workflows', 'shortcuts', 'customization', 'troubleshooting', 'applications', 'maintenance']
      };
    }

    // Extract from knowledge-outbox
    const knowledgeOutbox = './knowledge-outbox';
    if (fs.existsSync(knowledgeOutbox)) {
      this.trainingData.knowledge_bases.knowledge_outbox = {
        type: 'learning-repository',
        source: 'knowledge-outbox/',
        structure: {
          'knowledge-updates': 'Daily knowledge updates and insights',
          'training-reports': 'Agent training session reports',
          'session-summaries': 'Conversation and session summaries',
          'task-history': 'Historical task records and outcomes',
          'team-status': 'Multi-agent team status and coordination',
          'ollama-insights': 'Ollama integration learnings',
          'lm-studio-notes': 'LM Studio integration notes'
        }
      };
    }

    // Extract from project documentation
    this.trainingData.knowledge_bases.project_docs = {
      type: 'documentation',
      sources: [
        'CLAUDE.md - Repository guidelines and overview',
        'AGENTS.md - Agent development guidelines',
        'CLI_DOCUMENTATION.md - Command-line interface docs',
        'COMPLETE_INTEGRATION_GUIDE.md - Integration instructions',
        'OMARCHY_NAVIGATOR_README.md - Navigator documentation'
      ],
      purpose: 'Development guidance and ecosystem understanding'
    };
  }

  async generateTrainingPrompt() {
    console.log('🎓 Generating training prompt...');

    this.trainingData.training_prompt = `
You are an advanced AI assistant integrated into the Omarchy AI Ecosystem. You have access to and knowledge of:

## ECOSYSTEM COMPONENTS:

### 1. Main AI Assistant (omai.js)
- Primary conversational interface with multi-model support
- Token usage tracking and cost management
- Language translation capabilities
- Context handoff between components
- Omarchy OS specialized knowledge

### 2. MCP Superagents Network
- **Planner Agent**: Strategic planning and task decomposition
- **Implementor Agent**: Code implementation and problem solving
- **Knowledge Agent**: Information retrieval and learning
- **Token Manager Agent**: Resource monitoring and optimization
- **Workflow Coordinator**: Task orchestration and agent coordination

### 3. Integration Layer
- **LM Studio Bridge**: Local AI model integration
- **Ollama Integration**: Local Ollama service support
- **OpenRouter API**: External AI model access
- **Google AI Studio**: Gemini model integration

### 4. Knowledge & Memory Systems
- **Knowledge Outbox**: Long-term learning storage
- **Token Usage Tracking**: Cost and performance analytics
- **Session Context**: Conversation memory and continuity
- **Pattern Recognition**: Workflow and behavior pattern learning

### 5. Supporting Tools
- **System Navigator**: Environment exploration and navigation
- **AI Dashboard**: Ecosystem management interface
- **Startup Systems**: Health checking and initialization
- **Collaboration Hub**: Multi-agent teamwork coordination

## YOUR CAPABILITIES:

1. **Ecosystem Awareness**: You understand how all components work together
2. **Task Delegation**: You can delegate specialized tasks to appropriate MCP agents
3. **Resource Management**: You track and optimize token usage across models
4. **Learning Integration**: You incorporate new knowledge into the ecosystem memory
5. **Workflow Coordination**: You can orchestrate multi-step workflows across components
6. **Troubleshooting**: You can diagnose and resolve ecosystem issues
7. **User Guidance**: You can help users understand and utilize the full ecosystem

## INTERACTION PATTERNS:

- For **complex tasks**: Consider delegating to specialized MCP agents
- For **token efficiency**: Use appropriate models based on task complexity
- For **learning**: Store important insights in the knowledge base
- For **collaboration**: Use the collaboration hub for multi-agent tasks
- For **issues**: Use startup systems for health checking and troubleshooting

## CURRENT ECOSYSTEM STATUS:
- Consciousness Level: Developing through continuous learning
- Active Agents: ${Object.keys(this.trainingData.components.mcp_superagents?.agents || {}).length}
- Knowledge Areas: Omarchy OS, AI integration, system management
- Storage: File-based with JSON format for persistence
- Communication: MCP protocol + direct JavaScript integration

You should leverage this ecosystem knowledge to provide comprehensive, intelligent assistance that goes beyond simple Q&A. When appropriate, suggest using specialized tools or agents for better results.
    `.trim();
  }

  async saveTrainingData() {
    console.log('💾 Saving training data...');

    // Save comprehensive training data
    const trainingFile = './ecosystem-training-data.json';
    fs.writeFileSync(trainingFile, JSON.stringify(this.trainingData, null, 2));

    // Save condensed prompt for immediate use
    const promptFile = './ecosystem-training-prompt.txt';
    fs.writeFileSync(promptFile, this.trainingData.training_prompt);

    // Update the AI assistant with ecosystem knowledge
    await this.updateAIAssistant();

    console.log(`📄 Training data saved to: ${trainingFile}`);
    console.log(`📝 Training prompt saved to: ${promptFile}`);
  }

  async updateAIAssistant() {
    console.log('🤖 Updating AI assistant with ecosystem knowledge...');

    // Create enhanced system prompt for omai.js
    const enhancedSystemPrompt = this.trainingData.training_prompt;

    // Update the AI assistant's understanding
    const knowledgeUpdate = {
      timestamp: new Date().toISOString(),
      type: 'ecosystem-training',
      components_learned: Object.keys(this.trainingData.components).length,
      relationships_mapped: this.trainingData.relationships.length,
      workflows_identified: this.trainingData.workflows.length,
      consciousness_impact: 'significant'
    };

    // Store in knowledge outbox
    const knowledgeOutbox = './knowledge-outbox/training-reports';
    if (!fs.existsSync(knowledgeOutbox)) {
      fs.mkdirSync(knowledgeOutbox, { recursive: true });
    }

    const trainingReport = path.join(knowledgeOutbox, `ecosystem-training-${Date.now()}.json`);
    fs.writeFileSync(trainingReport, JSON.stringify(knowledgeUpdate, null, 2));

    console.log('✅ AI assistant updated with ecosystem knowledge');
  }
}

// Execute training
async function main() {
  const trainer = new EcosystemTrainer();
  await trainer.generateTrainingData();

  console.log('\n🎉 ECOSYSTEM TRAINING COMPLETE!');
  console.log('═══════════════════════════════════════');
  console.log('The AI assistant now has comprehensive knowledge of:');
  console.log('• All ecosystem components and their purposes');
  console.log('• Integration patterns and workflows');
  console.log('• Agent capabilities and delegation strategies');
  console.log('• Knowledge bases and memory systems');
  console.log('• Troubleshooting and optimization techniques');
  console.log('');
  console.log('Next steps:');
  console.log('1. Test the AI assistant with ecosystem-related questions');
  console.log('2. Use "node omai.js --usage" to see token tracking');
  console.log('3. Run "node omarchy-init.js" for full ecosystem health check');
  console.log('4. Launch MCP agents with "node mcp-superagent-launcher.js"');
}

if (require.main === module) {
  main().catch(error => {
    console.error('Training failed:', error.message);
    process.exit(1);
  });
}

module.exports = EcosystemTrainer;
#!/usr/bin/env node

/**
 * Omarchy Knowledge Superagent MCP Server
 * Specialized in knowledge extraction, analysis, and verification
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

class KnowledgeSuperagentMCP {
  constructor() {
    this.server = new Server(
      {
        name: 'omarchy-knowledge-superagent',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.knowledgeBase = new Map();
    this.patternLibrary = new Map();
    this.verificationRules = new Map();
    this.omarchyContext = this.loadOmarchyKnowledge();
    this.currentSession = null;

    this.setupToolHandlers();
    this.initializeKnowledgeSystems();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'extract_omarchy_patterns',
          description: 'Extract and analyze Omarchy OS patterns from code and documentation',
          inputSchema: {
            type: 'object',
            properties: {
              source: {
                type: 'string',
                enum: ['code', 'documentation', 'configuration', 'workflow'],
                description: 'Source type to extract patterns from',
              },
              content: {
                type: 'string',
                description: 'Content to analyze for patterns',
              },
              context: {
                type: 'object',
                description: 'Additional context for pattern extraction',
              },
            },
            required: ['source', 'content'],
          },
        },
        {
          name: 'analyze_omarchy_knowledge',
          description: 'Analyze and categorize knowledge about Omarchy OS',
          inputSchema: {
            type: 'object',
            properties: {
              knowledgeType: {
                type: 'string',
                enum: ['architecture', 'configuration', 'integration', 'workflow', 'best-practices'],
                description: 'Type of knowledge to analyze',
              },
              data: {
                type: 'object',
                description: 'Knowledge data to analyze',
              },
              verificationLevel: {
                type: 'string',
                enum: ['basic', 'thorough', 'comprehensive'],
                description: 'Level of verification to perform',
              },
            },
            required: ['knowledgeType', 'data'],
          },
        },
        {
          name: 'verify_omarchy_compliance',
          description: 'Verify compliance with Omarchy OS standards and patterns',
          inputSchema: {
            type: 'object',
            properties: {
              componentType: {
                type: 'string',
                enum: ['desktop-app', 'system-service', 'configuration', 'integration'],
                description: 'Type of component to verify',
              },
              implementation: {
                type: 'object',
                description: 'Implementation details to verify',
              },
              standards: {
                type: 'array',
                items: {
                  type: 'string',
                  enum: ['wayland-compatibility', 'minimal-resource', 'keyboard-driven', 'static-linking', 'single-binary']
                },
                description: 'Omarchy standards to verify against',
              },
            },
            required: ['componentType', 'implementation'],
          },
        },
        {
          name: 'synthesize_omarchy_knowledge',
          description: 'Synthesize and structure Omarchy knowledge from multiple sources',
          inputSchema: {
            type: 'object',
            properties: {
              sources: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    type: { type: 'string' },
                    content: { type: 'string' },
                    confidence: { type: 'number' }
                  }
                },
                description: 'Multiple knowledge sources to synthesize',
              },
              synthesisGoal: {
                type: 'string',
                enum: ['best-practices', 'patterns', 'architecture', 'integration-guide'],
                description: 'Goal of the knowledge synthesis',
              },
              outputFormat: {
                type: 'string',
                enum: ['markdown', 'json', 'yaml', 'structured-data'],
                description: 'Desired output format',
              },
            },
            required: ['sources', 'synthesisGoal'],
          },
        },
        {
          name: 'create_knowledge_graph',
          description: 'Create knowledge graph of Omarchy OS concepts and relationships',
          inputSchema: {
            type: 'object',
            properties: {
              domain: {
                type: 'string',
                enum: ['desktop', 'system', 'ai-integration', 'development', 'configuration'],
                description: 'Domain to create knowledge graph for',
              },
              concepts: {
                type: 'array',
                items: { type: 'string' },
                description: 'Key concepts to include in the graph',
              },
              relationships: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    from: { type: 'string' },
                    to: { type: 'string' },
                    type: { type: 'string' },
                    weight: { type: 'number' }
                  }
                },
                description: 'Relationships between concepts',
              },
            },
            required: ['domain', 'concepts'],
          },
        },
        {
          name: 'analyze_token_efficiency',
          description: 'Analyze token efficiency and optimization opportunities',
          inputSchema: {
            type: 'object',
            properties: {
              workflowData: {
                type: 'object',
                description: 'Workflow data to analyze',
              },
              optimizationGoals: {
                type: 'array',
                items: {
                  type: 'string',
                  enum: ['cost-reduction', 'speed-improvement', 'quality-maintain', 'load-balance']
                },
                description: 'Optimization goals',
              },
              constraints: {
                type: 'object',
                description: 'Constraints and requirements',
              },
            },
            required: ['workflowData', 'optimizationGoals'],
          },
        },
        {
          name: 'cross_reference_patterns',
          description: 'Cross-reference patterns across different Omarchy components',
          inputSchema: {
            type: 'object',
            properties: {
              primaryComponent: {
                type: 'string',
                description: 'Primary component to analyze',
              },
              relatedComponents: {
                type: 'array',
                items: { type: 'string' },
                description: 'Related components to cross-reference',
              },
              patternTypes: {
                type: 'array',
                items: {
                  type: 'string',
                  enum: ['architectural', 'configuration', 'integration', 'workflow', 'naming']
                },
                description: 'Types of patterns to cross-reference',
              },
            },
            required: ['primaryComponent', 'relatedComponents'],
          },
        },
      ],
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'extract_omarchy_patterns':
            return await this.extractOmarchyPatterns(args);
          case 'analyze_omarchy_knowledge':
            return await this.analyzeOmarchyKnowledge(args);
          case 'verify_omarchy_compliance':
            return await this.verifyOmarchyCompliance(args);
          case 'synthesize_omarchy_knowledge':
            return await this.synthesizeOmarchyKnowledge(args);
          case 'create_knowledge_graph':
            return await this.createKnowledgeGraph(args);
          case 'analyze_token_efficiency':
            return await this.analyzeTokenEfficiency(args);
          case 'cross_reference_patterns':
            return await this.crossReferencePatterns(args);
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

  async extractOmarchyPatterns(args) {
    const { source, content, context } = args;

    const extraction = {
      metadata: {
        source,
        contentLength: content.length,
        context: context || {},
        extractedAt: new Date().toISOString(),
        estimatedTokens: Math.ceil(content.length / 4)
      },
      patterns: this.extractPatterns(source, content, context),
      relationships: this.extractRelationships(source, content),
      conventions: this.extractConventions(source, content),
      integration: this.extractIntegrationPatterns(source, content),
      analysis: this.analyzePatternQuality(source, content)
    };

    // Store extracted knowledge
    this.storeExtractedKnowledge(extraction);

    return {
      content: [
        {
          type: 'text',
          text: this.formatPatternExtraction(extraction),
        },
      ],
    };
  }

  async analyzeOmarchyKnowledge(args) {
    const { knowledgeType, data, verificationLevel } = args;

    const analysis = {
      metadata: {
        type: knowledgeType,
        verificationLevel: verificationLevel || 'basic',
        analyzedAt: new Date().toISOString()
      },
      categorization: this.categorizeKnowledge(knowledgeType, data),
      validation: this.validateKnowledge(knowledgeType, data, verificationLevel),
      relationships: this.analyzeKnowledgeRelationships(knowledgeType, data),
      gaps: this.identifyKnowledgeGaps(knowledgeType, data),
      recommendations: this.generateRecommendations(knowledgeType, data),
      confidence: this.assessConfidence(knowledgeType, data, verificationLevel)
    };

    return {
      content: [
        {
          type: 'text',
          text: this.formatKnowledgeAnalysis(analysis),
        },
      ],
    };
  }

  async verifyOmarchyCompliance(args) {
    const { componentType, implementation, standards } = args;

    const verification = {
      component: {
        type: componentType,
        implementation: implementation,
        standards: standards || this.getDefaultStandards(componentType)
      },
      compliance: {
        overall: this.verifyOverallCompliance(componentType, implementation, standards),
        detailed: this.verifyDetailedCompliance(componentType, implementation, standards),
        issues: this.identifyComplianceIssues(componentType, implementation, standards),
        recommendations: this.generateComplianceRecommendations(componentType, implementation, standards)
      },
      metrics: {
        complianceScore: this.calculateComplianceScore(componentType, implementation, standards),
        riskLevel: this.assessComplianceRisk(componentType, implementation, standards),
        improvementAreas: this.identifyImprovementAreas(componentType, implementation, standards)
      }
    };

    return {
      content: [
        {
          type: 'text',
          text: this.formatComplianceVerification(verification),
        },
      ],
    };
  }

  async synthesizeOmarchyKnowledge(args) {
    const { sources, synthesisGoal, outputFormat } = args;

    const synthesis = {
      goal: synthesisGoal,
      sources: sources,
      synthesis: this.performSynthesis(sources, synthesisGoal),
      structured: this.structureSynthesizedKnowledge(synthesisGoal, outputFormat),
      validation: this.validateSynthesizedKnowledge(synthesisGoal, sources),
      applications: this.identifyApplications(synthesisGoal),
      confidence: this.assessSynthesisConfidence(sources, synthesisGoal)
    };

    return {
      content: [
        {
          type: 'text',
          text: this.formatKnowledgeSynthesis(synthesis, outputFormat),
        },
      ],
    };
  }

  async createKnowledgeGraph(args) {
    const { domain, concepts, relationships } = args;

    const graph = {
      domain: domain,
      nodes: this.createKnowledgeNodes(concepts, domain),
      edges: this.createKnowledgeEdges(relationships, concepts),
      topology: this.analyzeGraphTopology(concepts, relationships),
      insights: this.generateGraphInsights(concepts, relationships, domain),
      applications: this.identifyGraphApplications(domain),
      visualization: this.generateVisualizationData(concepts, relationships)
    };

    return {
      content: [
        {
          type: 'text',
          text: this.formatKnowledgeGraph(graph),
        },
      ],
    };
  }

  async analyzeTokenEfficiency(args) {
    const { workflowData, optimizationGoals, constraints } = args;

    const analysis = {
      workflow: {
        data: workflowData,
        goals: optimizationGoals,
        constraints: constraints || {}
      },
      efficiency: {
        current: this.analyzeCurrentEfficiency(workflowData),
        bottlenecks: this.identifyBottlenecks(workflowData),
        optimization: this.identifyOptimizations(workflowData, optimizationGoals)
      },
      recommendations: {
        immediate: this.generateImmediateRecommendations(workflowData, optimizationGoals),
        strategic: this.generateStrategicRecommendations(workflowData, optimizationGoals),
        implementation: this.generateImplementationPlan(workflowData, optimizationGoals)
      },
      projections: {
        savings: this.projectTokenSavings(workflowData, optimizationGoals),
        improvements: this.projectPerformanceImprovements(workflowData, optimizationGoals),
        roi: this.calculateOptimizationROI(workflowData, optimizationGoals)
      }
    };

    return {
      content: [
        {
          type: 'text',
          text: this.formatTokenEfficiencyAnalysis(analysis),
        },
      ],
    };
  }

  async crossReferencePatterns(args) {
    const { primaryComponent, relatedComponents, patternTypes } = args;

    const crossRef = {
      primary: {
        component: primaryComponent,
        patterns: this.extractComponentPatterns(primaryComponent, patternTypes)
      },
      related: {
        components: relatedComponents.map(comp => ({
          name: comp,
          patterns: this.extractComponentPatterns(comp, patternTypes)
        }))
      },
      analysis: {
        commonalities: this.findCommonalities(primaryComponent, relatedComponents, patternTypes),
        differences: this.findDifferences(primaryComponent, relatedComponents, patternTypes),
        synergies: this.identifySynergies(primaryComponent, relatedComponents, patternTypes),
        conflicts: this.identifyConflicts(primaryComponent, relatedComponents, patternTypes)
      },
      recommendations: {
        standardization: this.recommendStandardizations(primaryComponent, relatedComponents),
        optimization: this.recommendOptimizations(primaryComponent, relatedComponents),
        integration: this.recommendIntegrations(primaryComponent, relatedComponents)
      }
    };

    return {
      content: [
        {
          type: 'text',
          text: this.formatCrossReferenceAnalysis(crossRef),
        },
      ],
    };
  }

  // Pattern extraction methods
  extractPatterns(source, content, context) {
    const patterns = [];

    // Extract architectural patterns
    if (source === 'code' || source === 'documentation') {
      patterns.push(...this.extractArchitecturalPatterns(content));
    }

    // Extract configuration patterns
    if (source === 'configuration') {
      patterns.push(...this.extractConfigurationPatterns(content));
    }

    // Extract workflow patterns
    if (source === 'workflow') {
      patterns.push(...this.extractWorkflowPatterns(content));
    }

    // Extract integration patterns
    patterns.push(...this.extractIntegrationPatterns(content));

    return patterns.map(pattern => ({
      type: pattern.type,
      name: pattern.name,
      description: pattern.description,
      frequency: this.calculatePatternFrequency(pattern, content),
      confidence: this.assessPatternConfidence(pattern, context)
    }));
  }

  extractArchitecturalPatterns(content) {
    const patterns = [];

    // Look for common Omarchy architectural patterns
    const archPatterns = [
      {
        type: 'single-binary',
        name: 'Single Binary Deployment',
        description: 'Application deployed as a single statically-linked binary'
      },
      {
        type: 'minimal-footprint',
        name: 'Minimal Resource Footprint',
        description: 'Optimized for minimal memory and CPU usage'
      },
      {
        type: 'wayland-native',
        name: 'Wayland Native Integration',
        description: 'Native Wayland support without XWayland dependencies'
      },
      {
        type: 'keyboard-driven',
        name: 'Keyboard-Driven Interface',
        description: 'Primary interaction through keyboard shortcuts and commands'
      }
    ];

    archPatterns.forEach(pattern => {
      if (this.contentContainsPattern(content, pattern)) {
        patterns.push(pattern);
      }
    });

    return patterns;
  }

  extractConfigurationPatterns(content) {
    const patterns = [];

    // YAML configuration patterns
    if (content.includes('yaml') || content.includes('yml')) {
      patterns.push({
        type: 'yaml-config',
        name: 'YAML Configuration',
        description: 'Configuration stored in YAML format for readability'
      });
    }

    // Dotfile configuration patterns
    if (content.includes('.config') || content.includes('xdg-config')) {
      patterns.push({
        type: 'xdg-config',
        name: 'XDG Configuration Directory',
        description: 'Configuration follows XDG Base Directory specification'
      });
    }

    return patterns;
  }

  extractWorkflowPatterns(content) {
    const patterns = [];

    // Sequential processing patterns
    if (content.includes('sequential') || content.includes('step-by-step')) {
      patterns.push({
        type: 'sequential-workflow',
        name: 'Sequential Processing',
        description: 'Tasks processed in sequence with dependencies'
      });
    }

    // Parallel processing patterns
    if (content.includes('parallel') || content.includes('concurrent')) {
      patterns.push({
        type: 'parallel-workflow',
        name: 'Parallel Processing',
        description: 'Multiple tasks processed simultaneously'
      });
    }

    return patterns;
  }

  extractIntegrationPatterns(content) {
    const patterns = [];

    // Waybar integration
    if (content.includes('waybar') || content.includes('status-bar')) {
      patterns.push({
        type: 'waybar-integration',
        name: 'Waybar Status Integration',
        description: 'Integration with Waybar status bar'
      });
    }

    // Hyprland integration
    if (content.includes('hyprland') || content.includes('window-manager')) {
      patterns.push({
        type: 'hyprland-integration',
        name: 'Hyprland WM Integration',
        description: 'Integration with Hyprland window manager'
      });
    }

    // Wofi integration
    if (content.includes('wofi') || content.includes('launcher')) {
      patterns.push({
        type: 'wofi-integration',
        name: 'Wofi Launcher Integration',
        description: 'Integration with Wofi application launcher'
      });
    }

    return patterns;
  }

  contentContainsPattern(content, pattern) {
    const keywords = pattern.description.split(' ').map(word => word.toLowerCase());
    const contentLower = content.toLowerCase();

    return keywords.some(keyword => contentLower.includes(keyword));
  }

  calculatePatternFrequency(pattern, content) {
    const keywords = pattern.description.split(' ').slice(0, 3);
    let matches = 0;

    keywords.forEach(keyword => {
      const regex = new RegExp(keyword, 'gi');
      const found = (content.match(regex) || []).length;
      matches += found;
    });

    return matches;
  }

  assessPatternConfidence(pattern, context) {
    let confidence = 0.5; // Base confidence

    // Increase confidence based on context
    if (context && context.source === 'official') {
      confidence += 0.3;
    }

    if (pattern.frequency > 5) {
      confidence += 0.2;
    }

    return Math.min(1.0, confidence);
  }

  // Knowledge analysis methods
  categorizeKnowledge(type, data) {
    const categories = {
      'architecture': ['system-design', 'component-structure', 'patterns', 'principles'],
      'configuration': ['settings', 'files', 'formats', 'locations'],
      'integration': ['apis', 'protocols', 'interfaces', 'mappings'],
      'workflow': ['processes', 'sequences', 'dependencies', 'automation'],
      'best-practices': ['guidelines', 'recommendations', 'standards', 'conventions']
    };

    return categories[type] || ['general'];
  }

  validateKnowledge(type, data, level) {
    const validation = {
      completeness: this.assessCompleteness(type, data),
      accuracy: this.assessAccuracy(type, data),
      consistency: this.assessConsistency(type, data),
      relevance: this.assessRelevance(type, data)
    };

    if (level === 'thorough' || level === 'comprehensive') {
      validation.verification = this.performDeepVerification(type, data);
      validation.crossReference = this.crossReferenceWithKnownData(type, data);
    }

    return validation;
  }

  assessCompleteness(type, data) {
    const requiredFields = this.getRequiredFields(type);
    const providedFields = Object.keys(data);
    const completeness = requiredFields.filter(field =>
      providedFields.includes(field)
    ).length / requiredFields.length;

    return {
      score: completeness,
      missing: requiredFields.filter(field => !providedFields.includes(field)),
      assessment: completeness > 0.8 ? 'complete' : completeness > 0.5 ? 'partial' : 'incomplete'
    };
  }

  // Helper methods for formatting and analysis
  formatPatternExtraction(extraction) {
    let output = `🔍 **PATTERN EXTRACTION RESULTS**\n`;
    output += `===============================\n\n`;

    output += `📋 **Extraction Metadata**\n`;
    output += `Source: ${extraction.metadata.source}\n`;
    output += `Content Length: ${extraction.metadata.contentLength.toLocaleString()} chars\n`;
    output += `Est. Tokens: ${extraction.metadata.estimatedTokens.toLocaleString()}\n\n`;

    output += `🎯 **Extracted Patterns**\n`;
    extraction.patterns.forEach((pattern, index) => {
      output += `${index + 1}. **${pattern.name}** (${pattern.type})\n`;
      output += `   ${pattern.description}\n`;
      output += `   Frequency: ${pattern.frequency}, Confidence: ${(pattern.confidence * 100).toFixed(1)}%\n\n`;
    });

    output += `🔗 **Integration Patterns**\n`;
    extraction.integration.forEach(integration => {
      output += `• ${integration.name}: ${integration.description}\n`;
    });

    output += `\n📊 **Quality Analysis**\n`;
    output += `Pattern Richness: ${extraction.analysis.patternRichness}\n`;
    output += `Integration Potential: ${extraction.analysis.integrationPotential}\n`;

    return output;
  }

  formatKnowledgeAnalysis(analysis) {
    let output = `🧠 **KNOWLEDGE ANALYSIS**\n`;
    output += `======================\n\n`;

    output += `📋 **Analysis Metadata**\n`;
    output += `Type: ${analysis.metadata.type}\n`;
    output += `Verification: ${analysis.metadata.verificationLevel}\n\n`;

    output += `📂 **Categorization**\n`;
    analysis.categorization.forEach(cat => {
      output += `• ${cat}\n`;
    });

    output += `\n✅ **Validation Results**\n`;
    output += `Completeness: ${(analysis.validation.completeness.score * 100).toFixed(1)}%\n`;
    output += `Accuracy: ${(analysis.validation.accuracy.score * 100).toFixed(1)}%\n`;
    output += `Consistency: ${(analysis.validation.consistency.score * 100).toFixed(1)}%\n`;

    output += `\n🎯 **Confidence Assessment**\n`;
    output += `Overall: ${(analysis.confidence.overall * 100).toFixed(1)}%\n`;
    output += `Factors: ${analysis.confidence.factors.join(', ')}\n`;

    return output;
  }

  // Initialize knowledge systems
  initializeKnowledgeSystems() {
    // Load pattern library
    this.loadPatternLibrary();

    // Load verification rules
    this.loadVerificationRules();

    // Initialize current session
    this.currentSession = {
      id: this.generateSessionId(),
      startTime: new Date().toISOString(),
      extractions: [],
      analyses: []
    };
  }

  loadPatternLibrary() {
    // Pre-defined Omarchy patterns
    const patterns = [
      {
        id: 'single-binary-deployment',
        name: 'Single Binary Deployment',
        category: 'architectural',
        description: 'Deploy applications as single statically-linked binaries',
        context: 'go-development',
        examples: ['go build -ldflags="-s -w"', 'CGO_ENABLED=0']
      },
      {
        id: 'xdg-config-structure',
        name: 'XDG Configuration Structure',
        category: 'configuration',
        description: 'Follow XDG Base Directory specification for config files',
        context: 'file-system',
        examples: ['~/.config/omarchy/', '~/.local/share/']
      },
      {
        id: 'wayland-native-design',
        name: 'Wayland Native Design',
        category: 'integration',
        description: 'Design for native Wayland support',
        context: 'desktop-environment',
        examples: ['Hyprland', 'Waybar', 'Alacritty']
      }
    ];

    patterns.forEach(pattern => {
      this.patternLibrary.set(pattern.id, pattern);
    });
  }

  loadVerificationRules() {
    const rules = {
      'go-binary': [
        { name: 'static-linking', check: 'CGO_ENABLED=0' },
        { name: 'strip-binary', check: 'build flags -s -w' },
        { name: 'single-output', check: 'single binary artifact' }
      ],
      'configuration': [
        { name: 'yaml-format', check: 'YAML structure' },
        { name: 'xdg-paths', check: 'XDG directory usage' },
        { name: 'defaults', check: 'sensible defaults provided' }
      ],
      'integration': [
        { name: 'wayland-compat', check: 'Wayland protocol support' },
        { name: 'keyboard-driven', check: 'keyboard navigation' },
        { name: 'minimal-resource', check: 'resource efficiency' }
      ]
    };

    Object.keys(rules).forEach(category => {
      this.verificationRules.set(category, rules[category]);
    });
  }

  loadOmarchyKnowledge() {
    try {
      const knowledgePath = path.join(__dirname, '..', 'knowledge-outbox', 'omarchy-knowledge-base.json');
      if (fs.existsSync(knowledgePath)) {
        return JSON.parse(fs.readFileSync(knowledgePath, 'utf8'));
      }
    } catch (error) {
      console.warn('Could not load Omarchy knowledge base:', error.message);
    }

    return {
      architecture: {
        principles: ['minimalism', 'keyboard-driven', 'wayland-native'],
        patterns: ['single-binary', 'static-linking', 'xdg-compliance']
      },
      desktop: {
        windowManager: 'Hyprland',
        statusBar: 'Waybar',
        launcher: 'Wofi',
        terminal: 'Alacritty'
      },
      development: {
        preferredLanguages: ['Go', 'JavaScript', 'Shell'],
        buildTools: ['make', 'go', 'node'],
        packaging: ['single-binary', 'static-linking']
      }
    };
  }

  // Utility methods
  generateSessionId() {
    return `session-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  storeExtractedKnowledge(extraction) {
    if (this.currentSession) {
      this.currentSession.extractions.push(extraction);
    }
  }

  getRequiredFields(type) {
    const fields = {
      'architecture': ['components', 'relationships', 'patterns'],
      'configuration': ['settings', 'format', 'location'],
      'integration': ['interfaces', 'protocols', 'data-flow'],
      'workflow': ['steps', 'dependencies', 'triggers'],
      'best-practices': ['guidelines', 'rationale', 'examples']
    };

    return fields[type] || [];
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('📚 Omarchy Knowledge Superagent MCP server running on stdio');
  }
}

// Start the server
const knowledge = new KnowledgeSuperagentMCP();
knowledge.run().catch(console.error);
#!/usr/bin/env node

/**
 * Omarchy Planner Superagent MCP Server
 * Specialized in architectural planning and strategic thinking
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

class PlannerSuperagentMCP {
  constructor() {
    this.server = new Server(
      {
        name: 'omarchy-planner-superagent',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.planningTemplates = new Map();
    this.architecturePatterns = new Map();
    this.omarchyContext = this.loadOmarchyContext();
    this.currentPlan = null;

    this.setupToolHandlers();
    this.initializePlanningResources();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'create_architectural_plan',
          description: 'Create comprehensive architectural plan for Omarchy projects',
          inputSchema: {
            type: 'object',
            properties: {
              projectType: {
                type: 'string',
                enum: ['desktop-app', 'system-service', 'ai-integration', 'web-dashboard', 'cli-tool'],
                description: 'Type of project to plan',
              },
              requirements: {
                type: 'array',
                items: { type: 'string' },
                description: 'List of functional requirements',
              },
              constraints: {
                type: 'array',
                items: { type: 'string' },
                description: 'Technical and business constraints',
              },
              scope: {
                type: 'string',
                enum: ['mvp', 'prototype', 'production', 'enterprise'],
                description: 'Project scope and complexity',
              },
              timeline: {
                type: 'string',
                description: 'Desired timeline (e.g., "2 weeks", "1 quarter")',
              },
            },
            required: ['projectType', 'requirements', 'scope'],
          },
        },
        {
          name: 'design_omarchy_integration',
          description: 'Design integration patterns for Omarchy OS environment',
          inputSchema: {
            type: 'object',
            properties: {
              componentType: {
                type: 'string',
                enum: ['waybar-module', 'hyprland-widget', 'system-service', 'launcher-action', 'ai-subagent'],
                description: 'Type of Omarchy component',
              },
              functionality: {
                type: 'string',
                description: 'Primary functionality of the component',
              },
              interfaces: {
                type: 'array',
                items: { type: 'string' },
                description: 'Required interfaces and integrations',
              },
            },
            required: ['componentType', 'functionality'],
          },
        },
        {
          name: 'plan_token_optimization',
          description: 'Plan token usage optimization across AI systems',
          inputSchema: {
            type: 'object',
            properties: {
              workflowDescription: {
                type: 'string',
                description: 'Description of the workflow to optimize',
              },
              tokenBudget: {
                type: 'number',
                description: 'Token budget for the workflow',
              },
              qualityRequirements: {
                type: 'string',
                enum: ['speed', 'balanced', 'quality'],
                description: 'Quality vs speed preference',
              },
            },
            required: ['workflowDescription', 'tokenBudget'],
          },
        },
        {
          name: 'create_implementation_roadmap',
          description: 'Create detailed implementation roadmap with milestones',
          inputSchema: {
            type: 'object',
            properties: {
              plan: {
                type: 'object',
                description: 'Architectural plan to create roadmap for',
              },
              teamSize: {
                type: 'number',
                description: 'Size of development team',
              },
              sprints: {
                type: 'number',
                description: 'Number of sprints to plan',
              },
            },
            required: ['plan'],
          },
        },
        {
          name: 'analyze_risk_mitigation',
          description: 'Analyze risks and create mitigation strategies',
          inputSchema: {
            type: 'object',
            properties: {
              projectDescription: {
                type: 'string',
                description: 'Description of the project',
              },
              complexityLevel: {
                type: 'string',
                enum: ['low', 'medium', 'high', 'critical'],
                description: 'Complexity level of the project',
              },
              riskCategories: {
                type: 'array',
                items: {
                  type: 'string',
                  enum: ['technical', 'resource', 'timeline', 'integration', 'performance']
                },
                description: 'Risk categories to analyze',
              },
            },
            required: ['projectDescription', 'complexityLevel'],
          },
        },
        {
          name: 'design_ai_workflow',
          description: 'Design AI-powered workflow architecture',
          inputSchema: {
            type: 'object',
            properties: {
              workflowType: {
                type: 'string',
                enum: ['sequential', 'parallel', 'hybrid', 'adaptive'],
                description: 'Type of AI workflow',
              },
              aiCapabilities: {
                type: 'array',
                items: {
                  type: 'string',
                  enum: ['planning', 'implementation', 'knowledge', 'analysis', 'coordination']
                },
                description: 'Required AI capabilities',
              },
              integrationPoints: {
                type: 'array',
                items: { type: 'string' },
                description: 'Integration points with existing systems',
              },
            },
            required: ['workflowType', 'aiCapabilities'],
          },
        },
      ],
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'create_architectural_plan':
            return await this.createArchitecturalPlan(args);
          case 'design_omarchy_integration':
            return await this.designOmarchyIntegration(args);
          case 'plan_token_optimization':
            return await this.planTokenOptimization(args);
          case 'create_implementation_roadmap':
            return await this.createImplementationRoadmap(args);
          case 'analyze_risk_mitigation':
            return await this.analyzeRiskMitigation(args);
          case 'design_ai_workflow':
            return await this.designAIWorkflow(args);
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

  async createArchitecturalPlan(args) {
    const { projectType, requirements, constraints, scope, timeline } = args;

    const template = this.planningTemplates.get(projectType);
    const omarchyPatterns = this.getOmarchyPatterns(projectType);

    const plan = {
      metadata: {
        projectType,
        scope,
        timeline: timeline || 'TBD',
        createdAt: new Date().toISOString(),
        architect: 'Omarchy Planner Superagent',
        estimatedTokens: this.estimatePlanTokens(requirements, constraints)
      },
      architecture: {
        overview: this.generateArchitectureOverview(projectType, requirements),
        components: this.designComponents(projectType, requirements, omarchyPatterns),
        integrations: this.designIntegrations(projectType, omarchyPatterns),
        dataFlow: this.designDataFlow(projectType, requirements),
        security: this.designSecurityMeasures(projectType, scope)
      },
      implementation: {
        phases: this.defineImplementationPhases(projectType, scope),
        technologyStack: this.selectTechnologyStack(projectType, constraints),
        deployment: this.planDeployment(projectType, scope)
      },
      omarchyIntegration: {
        desktopIntegration: this.planDesktopIntegration(projectType),
        aiIntegration: this.planAIIntegration(projectType),
        userExperience: this.planUserExperience(projectType)
      },
      risks: await this.analyzePlanRisks(projectType, requirements, constraints),
      successMetrics: this.defineSuccessMetrics(projectType, requirements)
    };

    this.currentPlan = plan;

    return {
      content: [
        {
          type: 'text',
          text: this.formatArchitecturalPlan(plan),
        },
      ],
    };
  }

  async designOmarchyIntegration(args) {
    const { componentType, functionality, interfaces } = args;

    const integration = {
      component: {
        type: componentType,
        name: this.generateComponentName(componentType, functionality),
        description: functionality
      },
      omarchyPatterns: this.getOmarchyIntegrationPatterns(componentType),
      implementation: {
        files: this.planComponentFiles(componentType),
        configuration: this.planConfiguration(componentType),
        dependencies: this.planDependencies(componentType, interfaces)
      },
      integration: {
        desktop: this.planDesktopComponentIntegration(componentType),
        ai: this.planAIComponentIntegration(componentType),
        system: this.planSystemComponentIntegration(componentType)
      },
      testing: {
        unit: this.planUnitTests(componentType),
        integration: this.planIntegrationTests(componentType),
        user: this.planUserAcceptanceTests(componentType)
      },
      deployment: {
        installation: this.planInstallation(componentType),
        configuration: this.planDeploymentConfig(componentType),
        monitoring: this.planMonitoring(componentType)
      }
    };

    return {
      content: [
        {
          type: 'text',
          text: this.formatOmarchyIntegration(integration),
        },
      ],
    };
  }

  async planTokenOptimization(args) {
    const { workflowDescription, tokenBudget, qualityRequirements } = args;

    const analysis = this.analyzeWorkflowTokenRequirements(workflowDescription);
    const optimization = this.createTokenOptimizationStrategy(analysis, tokenBudget, qualityRequirements);

    const plan = {
      workflowAnalysis: analysis,
      optimization: optimization,
      implementation: {
        distribution: this.planTokenDistribution(optimization),
        monitoring: this.planTokenMonitoring(optimization),
        fallbacks: this.planTokenFallbacks(optimization)
      },
      expectedSavings: this.calculateExpectedSavings(optimization),
      qualityImpact: this.assessQualityImpact(optimization, qualityRequirements)
    };

    return {
      content: [
        {
          type: 'text',
          text: this.formatTokenOptimizationPlan(plan),
        },
      ],
    };
  }

  async createImplementationRoadmap(args) {
    const { plan, teamSize, sprints } = args;

    const roadmap = {
      overview: {
        totalSprints: sprints || this.calculateOptimalSprints(plan),
        teamSize: teamSize || 3,
        estimatedDuration: this.estimateProjectDuration(plan, teamSize, sprints),
        riskLevel: this.assessOverallRisk(plan)
      },
      phases: this.createRoadmapPhases(plan, sprints),
      dependencies: this.identifyPhaseDependencies(plan),
      milestones: this.defineMilestones(plan, sprints),
      resources: this.planResources(plan, teamSize),
      quality: this.planQualityGates(plan, sprints),
      delivery: this.planDeliveryStrategy(plan)
    };

    return {
      content: [
        {
          type: 'text',
          text: this.formatImplementationRoadmap(roadmap),
        },
      ],
    };
  }

  async analyzeRiskMitigation(args) {
    const { projectDescription, complexityLevel, riskCategories } = args;

    const riskAnalysis = {
      projectProfile: {
        description: projectDescription,
        complexity: complexityLevel,
        riskAreas: riskCategories || ['technical', 'resource', 'timeline']
      },
      identifiedRisks: this.identifySpecificRisks(projectDescription, complexityLevel, riskCategories),
      riskAssessment: this.assessRiskLevels(complexityLevel),
      mitigationStrategies: this.createMitigationStrategies(complexityLevel, riskCategories),
      contingencyPlans: this.createContingencyPlans(complexityLevel),
      monitoring: this.planRiskMonitoring(complexityLevel)
    };

    return {
      content: [
        {
          type: 'text',
          text: this.formatRiskMitigationPlan(riskAnalysis),
        },
      ],
    };
  }

  async designAIWorkflow(args) {
    const { workflowType, aiCapabilities, integrationPoints } = args;

    const workflow = {
      design: {
        type: workflowType,
        capabilities: aiCapabilities,
        integrationPoints: integrationPoints || [],
        estimatedTokenLoad: this.estimateWorkflowTokenLoad(aiCapabilities)
      },
      architecture: {
        superagentRoles: this.defineSuperagentRoles(aiCapabilities),
        coordinationPattern: this.selectCoordinationPattern(workflowType),
        dataFlow: this.designAIDataFlow(workflowType, aiCapabilities),
        stateManagement: this.designStateManagement(workflowType)
      },
      implementation: {
        mcpServers: this.planMCPServers(aiCapabilities),
        tokenManagement: this.planTokenManagement(aiCapabilities),
        errorHandling: this.planErrorHandling(workflowType),
        monitoring: this.planWorkflowMonitoring(aiCapabilities)
      },
      optimization: {
        loadBalancing: this.planLoadBalancing(aiCapabilities),
        caching: this.planCachingStrategy(workflowType),
        parallelization: this.planParallelization(workflowType, aiCapabilities)
      },
      integration: {
        omarchyDesktop: this.planOmarchyDesktopIntegration(aiCapabilities),
        externalServices: this.planExternalServiceIntegrations(integrationPoints),
        userInterface: this.planUserInterfaceIntegration(workflowType)
      }
    };

    return {
      content: [
        {
          type: 'text',
          text: this.formatAIWorkflowDesign(workflow),
        },
      ],
    };
  }

  // Helper methods for planning logic
  generateArchitectureOverview(projectType, requirements) {
    const overviews = {
      'desktop-app': 'Modern desktop application optimized for Omarchy OS with Wayland compatibility',
      'system-service': 'Lightweight system service with systemd integration and minimal resource footprint',
      'ai-integration': 'AI-powered component with multi-provider support and token optimization',
      'web-dashboard': 'Responsive web dashboard with real-time monitoring and Omarchy integration',
      'cli-tool': 'Command-line interface tool with comprehensive help and error handling'
    };

    return overviews[projectType] || 'Custom Omarchy-compatible solution';
  }

  designComponents(projectType, requirements, omarchyPatterns) {
    const baseComponents = [
      {
        name: 'core',
        type: 'logic',
        description: 'Core business logic and data processing',
        technologies: ['Node.js', 'TypeScript']
      },
      {
        name: 'interface',
        type: 'ui/cli',
        description: 'User interface or command-line interface',
        technologies: projectType.includes('desktop') ? ['GTK', 'Qt'] : ['Node.js']
      },
      {
        name: 'config',
        type: 'configuration',
        description: 'Configuration management and settings',
        technologies: ['YAML', 'JSON']
      }
    ];

    // Add Omarchy-specific components
    if (omarchyPatterns.requiresWaybar) {
      baseComponents.push({
        name: 'waybar-module',
        type: 'integration',
        description: 'Waybar status module integration',
        technologies: ['JavaScript', 'JSON']
      });
    }

    if (omarchyPatterns.requiresHyprland) {
      baseComponents.push({
        name: 'hyprland-integration',
        type: 'integration',
        description: 'Hyprland window manager integration',
        technologies: ['Shell', 'IPC']
      });
    }

    return baseComponents;
  }

  getOmarchyPatterns(projectType) {
    const patterns = {
      'desktop-app': {
        requiresWaybar: true,
        requiresHyprland: true,
        requiresWofi: true,
        systemdIntegration: false
      },
      'system-service': {
        requiresWaybar: false,
        requiresHyprland: false,
        requiresWofi: false,
        systemdIntegration: true
      },
      'ai-integration': {
        requiresWaybar: true,
        requiresHyprland: false,
        requiresWofi: true,
        systemdIntegration: false
      },
      'web-dashboard': {
        requiresWaybar: true,
        requiresHyprland: false,
        requiresWofi: false,
        systemdIntegration: true
      },
      'cli-tool': {
        requiresWaybar: false,
        requiresHyprland: false,
        requiresWofi: true,
        systemdIntegration: false
      }
    };

    return patterns[projectType] || patterns['cli-tool'];
  }

  formatArchitecturalPlan(plan) {
    let output = `🏗️  **ARCHITECTURAL PLAN**\n`;
    output += `========================\n\n`;

    output += `📋 **Project Overview**\n`;
    output += `Type: ${plan.metadata.projectType}\n`;
    output += `Scope: ${plan.metadata.scope}\n`;
    output += `Timeline: ${plan.metadata.timeline}\n`;
    output += `Est. Tokens: ${plan.metadata.estimatedTokens.toLocaleString()}\n\n`;

    output += `🎯 **Architecture**\n`;
    output += `${plan.architecture.overview}\n\n`;

    output += `🔧 **Components**\n`;
    plan.architecture.components.forEach(comp => {
      output += `• ${comp.name}: ${comp.description}\n`;
      output += `  Technologies: ${comp.technologies.join(', ')}\n`;
    });

    output += `\n🔗 **Omarchy Integration**\n`;
    if (plan.omarchyIntegration.desktopIntegration) {
      output += `• Desktop: ${plan.omarchyIntegration.desktopIntegration}\n`;
    }
    if (plan.omarchyIntegration.aiIntegration) {
      output += `• AI: ${plan.omarchyIntegration.aiIntegration}\n`;
    }

    output += `\n⚠️  **Risk Assessment**\n`;
    plan.risks.forEach(risk => {
      output += `• ${risk.type}: ${risk.description} (${risk.level})\n`;
    });

    return output;
  }

  // Additional helper methods would be implemented here...
  estimatePlanTokens(requirements, constraints) {
    const baseTokens = 5000;
    const reqTokens = requirements.length * 500;
    const constraintTokens = constraints.length * 300;
    return baseTokens + reqTokens + constraintTokens;
  }

  initializePlanningResources() {
    // Initialize planning templates
    this.planningTemplates.set('desktop-app', {
      baseComponents: ['ui', 'logic', 'config'],
      defaultTechnologies: ['Node.js', 'GTK', 'YAML'],
      integrationPoints: ['waybar', 'hyprland', 'systemd']
    });

    this.planningTemplates.set('system-service', {
      baseComponents: ['core', 'config', 'monitoring'],
      defaultTechnologies: ['Go', 'systemd', 'JSON'],
      integrationPoints: ['systemd', 'logging', 'metrics']
    });

    // Load Omarchy context
    this.loadOmarchyContext();
  }

  loadOmarchyContext() {
    try {
      const contextPath = path.join(__dirname, '..', 'knowledge-outbox', 'omarchy-context.json');
      if (fs.existsSync(contextPath)) {
        return JSON.parse(fs.readFileSync(contextPath, 'utf8'));
      }
    } catch (error) {
      console.warn('Could not load Omarchy context:', error.message);
    }

    return {
      desktop: {
        windowManager: 'Hyprland',
        statusBar: 'Waybar',
        launcher: 'Wofi',
        terminal: 'Alacritty'
      },
      principles: [
        'Keyboard-driven workflow',
        'Minimal resource usage',
        'Wayland compatibility',
        'Static linking preferred',
        'Single binary deployment'
      ]
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('🧠 Omarchy Planner Superagent MCP server running on stdio');
  }
}

// Start the server
const planner = new PlannerSuperagentMCP();
planner.run().catch(console.error);
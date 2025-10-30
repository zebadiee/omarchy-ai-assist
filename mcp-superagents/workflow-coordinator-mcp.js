#!/usr/bin/env node

/**
 * Omarchy Workflow Coordinator MCP Server
 * Coordinates distributed workflows across multiple superagents
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
  CallToolRequestSchema,
  ErrorCode,
  ListToolsRequestSchema,
  McpError,
} = require('@modelcontextprotocol/sdk/types.js');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class WorkflowCoordinatorMCP {
  constructor() {
    this.server = new Server(
      {
        name: 'omarchy-workflow-coordinator',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.activeWorkflows = new Map();
    this.superagentRegistry = new Map();
    this.taskQueue = [];
    this.completedTasks = [];
    this.parallelTasks = process.env.PARALLEL_TASKS === 'true';
    this.loadSharing = process.env.LOAD_SHARING === 'true';

    this.setupToolHandlers();
    this.initializeSuperagents();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'coordinate_distributed_workflow',
          description: 'Coordinate a distributed workflow across multiple superagents',
          inputSchema: {
            type: 'object',
            properties: {
              workflowId: {
                type: 'string',
                description: 'Unique identifier for the workflow',
              },
              tasks: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    type: {
                      type: 'string',
                      enum: ['planning', 'implementation', 'knowledge', 'analysis', 'coordination']
                    },
                    priority: {
                      type: 'string',
                      enum: ['low', 'medium', 'high', 'critical']
                    },
                    dependencies: {
                      type: 'array',
                      items: { type: 'string' }
                    },
                    input: { type: 'object' },
                    estimatedTokens: { type: 'number' }
                  }
                },
                description: 'Array of tasks to execute',
              },
              strategy: {
                type: 'string',
                enum: ['sequential', 'parallel', 'hybrid', 'adaptive'],
                description: 'Execution strategy',
              },
            },
            required: ['workflowId', 'tasks', 'strategy'],
          },
        },
        {
          name: 'monitor_workflow_status',
          description: 'Monitor status of active workflows',
          inputSchema: {
            type: 'object',
            properties: {
              workflowId: {
                type: 'string',
                description: 'Workflow ID to monitor (optional)',
              },
              includeCompleted: {
                type: 'boolean',
                description: 'Include completed tasks in response',
              },
            },
          },
        },
        {
          name: 'optimize_task_distribution',
          description: 'Optimize task distribution across available superagents',
          inputSchema: {
            type: 'object',
            properties: {
              rebalanceStrategy: {
                type: 'string',
                enum: ['load_balance', 'priority_based', 'capability_based', 'cost_optimized'],
                description: 'Rebalancing strategy',
              },
              workflowId: {
                type: 'string',
                description: 'Specific workflow to optimize (optional)',
              },
            },
          },
        },
        {
          name: 'scale_superagent_capacity',
          description: 'Dynamically scale superagent capacity based on workload',
          inputSchema: {
            type: 'object',
            properties: {
              superagentType: {
                type: 'string',
                enum: ['planner', 'implementor', 'knowledge', 'all'],
                description: 'Type of superagent to scale',
              },
              action: {
                type: 'string',
                enum: ['up', 'down', 'auto'],
                description: 'Scaling action',
              },
              targetCapacity: {
                type: 'number',
                description: 'Target capacity (for auto action)',
              },
            },
          },
        },
        {
          name: 'handle_failover',
          description: 'Handle failover scenarios for superagent failures',
          inputSchema: {
            type: 'object',
            properties: {
              failedSuperagent: {
                type: 'string',
                description: 'ID of failed superagent',
              },
              affectedTasks: {
                type: 'array',
                items: { type: 'string' },
                description: 'IDs of affected tasks',
              },
              failoverStrategy: {
                type: 'string',
                enum: ['redirect', 'retry', 'queue', 'escalate'],
                description: 'Failover strategy',
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
          case 'coordinate_distributed_workflow':
            return await this.coordinateDistributedWorkflow(args);
          case 'monitor_workflow_status':
            return await this.monitorWorkflowStatus(args);
          case 'optimize_task_distribution':
            return await this.optimizeTaskDistribution(args);
          case 'scale_superagent_capacity':
            return await this.scaleSuperagentCapacity(args);
          case 'handle_failover':
            return await this.handleFailover(args);
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

  async coordinateDistributedWorkflow(args) {
    const { workflowId, tasks, strategy } = args;

    const workflow = {
      id: workflowId,
      status: 'initializing',
      tasks: new Map(),
      strategy,
      startTime: new Date().toISOString(),
      dependencies: this.buildDependencyGraph(tasks)
    };

    // Initialize tasks
    for (const task of tasks) {
      workflow.tasks.set(task.id, {
        ...task,
        status: 'pending',
        assignedSuperagent: null,
        startTime: null,
        endTime: null,
        result: null,
        attempts: 0,
        maxAttempts: 3
      });
    }

    this.activeWorkflows.set(workflowId, workflow);

    // Start workflow execution
    const executionPromise = this.executeWorkflow(workflow);

    return {
      content: [
        {
          type: 'text',
          text: `🚀 Workflow "${workflowId}" initiated\n` +
                `📋 Tasks: ${tasks.length}\n` +
                `🎯 Strategy: ${strategy}\n` +
                `🔄 Status: ${workflow.status}\n` +
                `⏱️  Started: ${workflow.startTime}`,
        },
      ],
    };
  }

  async executeWorkflow(workflow) {
    workflow.status = 'running';

    switch (workflow.strategy) {
      case 'sequential':
        await this.executeSequential(workflow);
        break;
      case 'parallel':
        await this.executeParallel(workflow);
        break;
      case 'hybrid':
        await this.executeHybrid(workflow);
        break;
      case 'adaptive':
        await this.executeAdaptive(workflow);
        break;
    }

    workflow.status = 'completed';
    workflow.endTime = new Date().toISOString();
  }

  async executeSequential(workflow) {
    const sortedTasks = this.topologicalSort(workflow.dependencies);

    for (const taskId of sortedTasks) {
      const task = workflow.tasks.get(taskId);
      if (!task) continue;

      await this.executeTask(workflow, task);
    }
  }

  async executeParallel(workflow) {
    const readyTasks = Array.from(workflow.tasks.values())
      .filter(task => task.dependencies.length === 0);

    const promises = readyTasks.map(task => this.executeTask(workflow, task));
    await Promise.all(promises);

    // Continue with remaining tasks as dependencies resolve
    await this.processRemainingTasks(workflow);
  }

  async executeHybrid(workflow) {
    // Execute independent tasks in parallel, dependent sequentially
    const independentTasks = Array.from(workflow.tasks.values())
      .filter(task => task.dependencies.length === 0);

    // Parallel execution for independent tasks
    const independentPromises = independentTasks.map(task => this.executeTask(workflow, task));
    await Promise.all(independentPromises);

    // Sequential execution for dependent tasks
    const dependentTasks = Array.from(workflow.tasks.values())
      .filter(task => task.dependencies.length > 0);

    for (const task of dependentTasks) {
      await this.waitForDependencies(workflow, task);
      await this.executeTask(workflow, task);
    }
  }

  async executeAdaptive(workflow) {
    // Start with parallel, adapt based on performance
    const readyTasks = Array.from(workflow.tasks.values())
      .filter(task => task.dependencies.length === 0);

    if (readyTasks.length <= 2) {
      await this.executeSequential(workflow);
    } else {
      await this.executeParallel(workflow);
    }
  }

  async executeTask(workflow, task) {
    task.status = 'running';
    task.startTime = new Date().toISOString();
    task.attempts++;

    const superagent = await this.selectOptimalSuperagent(task);
    task.assignedSuperagent = superagent.id;

    try {
      const result = await this.callSuperagent(superagent, task);
      task.result = result;
      task.status = 'completed';
      task.endTime = new Date().toISOString();

      this.completedTasks.push({
        workflowId: workflow.id,
        taskId: task.id,
        superagent: superagent.id,
        duration: new Date(task.endTime) - new Date(task.startTime),
        tokens: result.tokenUsage || 0
      });

    } catch (error) {
      task.status = 'failed';
      task.error = error.message;
      task.endTime = new Date().toISOString();

      if (task.attempts < task.maxAttempts) {
        // Retry with exponential backoff
        await this.delay(Math.pow(2, task.attempts) * 1000);
        await this.executeTask(workflow, task);
      } else {
        // Handle failover
        await this.handleTaskFailover(workflow, task);
      }
    }
  }

  async selectOptimalSuperagent(task) {
    const availableSuperagents = Array.from(this.superagentRegistry.values())
      .filter(sa => sa.capabilities.includes(task.type) && sa.status === 'available');

    if (availableSuperagents.length === 0) {
      throw new Error(`No available superagents for task type: ${task.type}`);
    }

    // Select based on load and capability match
    return availableSuperagents
      .sort((a, b) => {
        const aScore = this.calculateSuperagentScore(a, task);
        const bScore = this.calculateSuperagentScore(b, task);
        return bScore - aScore;
      })[0];
  }

  calculateSuperagentScore(superagent, task) {
    let score = 1.0 - superagent.load;

    // Adjust for capability match
    if (superagent.specialization === task.type) score += 0.3;

    // Adjust for priority
    if (task.priority === 'critical' && superagent.performance > 0.9) score += 0.2;
    if (task.priority === 'low' && superagent.costEfficiency > 0.8) score += 0.1;

    return score;
  }

  async callSuperagent(superagent, task) {
    return new Promise((resolve, reject) => {
      const child = spawn('node', [superagent.path], {
        stdio: ['pipe', 'pipe', 'pipe'],
        env: {
          ...process.env,
          TASK_DATA: JSON.stringify(task),
          SUPERAGENT_ID: superagent.id
        }
      });

      let output = '';
      let errorOutput = '';

      child.stdout.on('data', (data) => {
        output += data.toString();
      });

      child.stderr.on('data', (data) => {
        errorOutput += data.toString();
      });

      child.on('close', (code) => {
        if (code === 0) {
          try {
            const result = JSON.parse(output);
            resolve(result);
          } catch (e) {
            resolve({ output, tokenUsage: this.estimateTokenUsage(output) });
          }
        } else {
          reject(new Error(`Superagent failed: ${errorOutput}`));
        }
      });

      // Send task data
      child.stdin.write(JSON.stringify(task));
      child.stdin.end();
    });
  }

  async monitorWorkflowStatus(args) {
    const { workflowId, includeCompleted } = args;

    let workflows;

    if (workflowId) {
      const workflow = this.activeWorkflows.get(workflowId);
      workflows = workflow ? [workflow] : [];
    } else {
      workflows = Array.from(this.activeWorkflows.values());
    }

    const statusReports = workflows.map(workflow => ({
      id: workflow.id,
      status: workflow.status,
      progress: this.calculateProgress(workflow),
      tasks: {
        total: workflow.tasks.size,
        completed: Array.from(workflow.tasks.values()).filter(t => t.status === 'completed').length,
        running: Array.from(workflow.tasks.values()).filter(t => t.status === 'running').length,
        failed: Array.from(workflow.tasks.values()).filter(t => t.status === 'failed').length
      },
      duration: workflow.endTime ?
        new Date(workflow.endTime) - new Date(workflow.startTime) :
        new Date() - new Date(workflow.startTime)
    }));

    let report = `📊 Workflow Status Report:\n\n`;

    statusReports.forEach(status => {
      report += `🔹 ${status.id}:\n` +
                `   Status: ${status.status}\n` +
                `   Progress: ${(status.progress * 100).toFixed(1)}%\n` +
                `   Tasks: ${status.tasks.completed}/${status.tasks.total} completed\n` +
                `   Duration: ${(status.duration / 1000).toFixed(1)}s\n\n`;
    });

    if (includeCompleted) {
      report += `✅ Recently Completed Tasks: ${this.completedTasks.slice(-5).length}\n`;
      this.completedTasks.slice(-5).forEach(task => {
        report += `   • ${task.taskId} (${task.workflowId}) - ${task.duration}ms\n`;
      });
    }

    return {
      content: [{ type: 'text', text: report }],
    };
  }

  async optimizeTaskDistribution(args) {
    const { rebalanceStrategy, workflowId } = args;

    let targetWorkflows = workflowId ?
      [this.activeWorkflows.get(workflowId)] :
      Array.from(this.activeWorkflows.values());

    targetWorkflows = targetWorkflows.filter(Boolean);

    let optimizations = 0;

    for (const workflow of targetWorkflows) {
      const pendingTasks = Array.from(workflow.tasks.values())
        .filter(task => task.status === 'pending');

      for (const task of pendingTasks) {
        const currentSuperagent = task.assignedSuperagent ?
          this.superagentRegistry.get(task.assignedSuperagent) : null;

        const optimalSuperagent = await this.selectOptimalSuperagent(task);

        if (!currentSuperagent || currentSuperagent.id !== optimalSuperagent.id) {
          task.assignedSuperagent = optimalSuperagent.id;
          optimizations++;
        }
      }
    }

    return {
      content: [
        {
          type: 'text',
          text: `⚖️  Task Distribution Optimized\n` +
                `🎯 Strategy: ${rebalanceStrategy}\n` +
                `🔄 Reassignments: ${optimizations}\n` +
                `📊 Workflows Affected: ${targetWorkflows.length}`,
        },
      ],
    };
  }

  async scaleSuperagentCapacity(args) {
    const { superagentType, action, targetCapacity } = args;

    let capacityChange = 0;

    if (action === 'auto' && targetCapacity) {
      const currentCapacity = this.getCurrentCapacity(superagentType);
      capacityChange = targetCapacity - currentCapacity;
    } else if (action === 'up') {
      capacityChange = 1;
    } else if (action === 'down') {
      capacityChange = -1;
    }

    if (capacityChange !== 0) {
      await this.adjustSuperagentCapacity(superagentType, capacityChange);
    }

    return {
      content: [
        {
          type: 'text',
          text: `📈 Superagent Scaling Complete\n` +
                `🤖 Type: ${superagentType}\n` +
                `⚡ Action: ${action}\n` +
                `📊 Capacity Change: ${capacityChange > 0 ? '+' : ''}${capacityChange}`,
        },
      ],
    };
  }

  async handleFailover(args) {
    const { failedSuperagent, affectedTasks, failoverStrategy } = args;

    let recoveredTasks = 0;

    for (const taskId of affectedTasks) {
      const task = this.findTaskById(taskId);
      if (!task) continue;

      switch (failoverStrategy) {
        case 'redirect':
          await this.redirectTask(task);
          recoveredTasks++;
          break;
        case 'retry':
          task.attempts = 0;
          task.status = 'pending';
          recoveredTasks++;
          break;
        case 'queue':
          this.taskQueue.push(task);
          recoveredTasks++;
          break;
        case 'escalate':
          await this.escalateTask(task);
          recoveredTasks++;
          break;
      }
    }

    return {
      content: [
        {
          type: 'text',
          text: `🔄 Failover Handling Complete\n` +
                `❌ Failed Superagent: ${failedSuperagent}\n` +
                `📋 Affected Tasks: ${affectedTasks.length}\n` +
                `✅ Recovered Tasks: ${recoveredTasks}\n` +
                `🎯 Strategy: ${failoverStrategy}`,
        },
      ],
    };
  }

  // Helper methods
  buildDependencyGraph(tasks) {
    const graph = new Map();

    for (const task of tasks) {
      graph.set(task.id, task.dependencies || []);
    }

    return graph;
  }

  topologicalSort(dependencies) {
    const visited = new Set();
    const result = [];

    const visit = (node) => {
      if (visited.has(node)) return;
      visited.add(node);

      const deps = dependencies.get(node) || [];
      deps.forEach(dep => visit(dep));

      result.push(node);
    };

    for (const node of dependencies.keys()) {
      visit(node);
    }

    return result;
  }

  calculateProgress(workflow) {
    const tasks = Array.from(workflow.tasks.values());
    if (tasks.length === 0) return 0;

    const completedTasks = tasks.filter(t => t.status === 'completed').length;
    return completedTasks / tasks.length;
  }

  async waitForDependencies(workflow, task) {
    for (const depId of task.dependencies) {
      const depTask = workflow.tasks.get(depId);
      while (depTask && depTask.status !== 'completed') {
        await this.delay(100);
      }
    }
  }

  async processRemainingTasks(workflow) {
    // Process tasks as their dependencies complete
    const checkTasks = async () => {
      const readyTasks = Array.from(workflow.tasks.values())
        .filter(task =>
          task.status === 'pending' &&
          task.dependencies.every(depId => {
            const depTask = workflow.tasks.get(depId);
            return depTask && depTask.status === 'completed';
          })
        );

      if (readyTasks.length > 0) {
        const promises = readyTasks.map(task => this.executeTask(workflow, task));
        await Promise.all(promises);

        // Recursively check for more ready tasks
        if (Array.from(workflow.tasks.values()).some(t => t.status === 'pending')) {
          await checkTasks();
        }
      }
    };

    await checkTasks();
  }

  estimateTokenUsage(text) {
    return Math.ceil(text.length / 4); // Rough estimate
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  findTaskById(taskId) {
    for (const workflow of this.activeWorkflows.values()) {
      const task = workflow.tasks.get(taskId);
      if (task) return task;
    }
    return null;
  }

  async redirectTask(task) {
    const newSuperagent = await this.selectOptimalSuperagent(task);
    task.assignedSuperagent = newSuperagent.id;
    task.status = 'pending';
  }

  async escalateTask(task) {
    task.priority = task.priority === 'critical' ? 'critical' :
                   task.priority === 'high' ? 'critical' : 'high';
    task.status = 'pending';
  }

  getCurrentCapacity(superagentType) {
    return Array.from(this.superagentRegistry.values())
      .filter(sa => superagentType === 'all' || sa.type === superagentType)
      .length;
  }

  async adjustSuperagentCapacity(superagentType, change) {
    // Implementation would spawn/terminate superagent instances
    console.log(`Adjusting ${superagentType} capacity by ${change}`);
  }

  initializeSuperagents() {
    // Register built-in superagents
    this.superagentRegistry.set('planner-1', {
      id: 'planner-1',
      type: 'planner',
      path: './mcp-superagents/planner-mcp.js',
      capabilities: ['planning', 'coordination'],
      specialization: 'planning',
      status: 'available',
      load: 0.3,
      performance: 0.95,
      costEfficiency: 0.8
    });

    this.superagentRegistry.set('implementor-1', {
      id: 'implementor-1',
      type: 'implementor',
      path: './mcp-superagents/implementor-mcp.js',
      capabilities: ['implementation', 'analysis'],
      specialization: 'implementation',
      status: 'available',
      load: 0.2,
      performance: 0.9,
      costEfficiency: 0.85
    });

    this.superagentRegistry.set('knowledge-1', {
      id: 'knowledge-1',
      type: 'knowledge',
      path: './mcp-superagents/knowledge-mcp.js',
      capabilities: ['knowledge', 'analysis'],
      specialization: 'knowledge',
      status: 'available',
      load: 0.1,
      performance: 0.92,
      costEfficiency: 0.75
    });
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('🎯 Omarchy Workflow Coordinator MCP server running on stdio');
  }
}

// Start the server
const coordinator = new WorkflowCoordinatorMCP();
coordinator.run().catch(console.error);
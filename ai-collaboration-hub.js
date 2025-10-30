#!/usr/bin/env node

/**
 * AI Collaboration Hub - Connects all AI assistants for shared knowledge and distributed tasks
 * Integrates: Claude Code, Gemini AI, OpenAI Assistant, Codex Copilot, Omarchy Navigator
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const CONFIG_DIR = '/home/zebadiee/.npm-global/omarchy-wagon';
const COLLABORATION_FILE = path.join(CONFIG_DIR, 'ai-collaboration.json');
const KNOWLEDGE_SHARED = path.join(CONFIG_DIR, 'shared-knowledge.json');

class AICollaborationHub {
  constructor() {
    this.aiAssistants = {
      'claude-code': {
        name: 'Claude Code',
        strengths: ['file-operations', 'terminal', 'analysis', 'debugging'],
        status: 'active',
        lastActive: new Date().toISOString()
      },
      'gemini-ai': {
        name: 'Gemini AI',
        strengths: ['research', 'content-generation', 'analysis', 'creative-tasks'],
        status: 'configured',
        lastActive: new Date().toISOString()
      },
      'openai-assistant': {
        name: 'OpenAI Assistant',
        strengths: ['coding', 'problem-solving', 'explanation', 'optimization'],
        status: 'configured',
        lastActive: new Date().toISOString()
      },
      'codex-copilot': {
        name: 'Codex Copilot',
        strengths: ['code-completion', 'syntax', 'patterns', 'refactoring'],
        status: 'active',
        lastActive: new Date().toISOString()
      },
      'omarchy-navigator': {
        name: 'Omarchy Navigator',
        strengths: ['desktop-navigation', 'customization', 'troubleshooting', 'system-commands'],
        status: 'active',
        lastActive: new Date().toISOString()
      }
    };

    this.loadCollaborationData();
    this.setupKnowledgeSharing();
  }

  loadCollaborationData() {
    try {
      if (fs.existsSync(COLLABORATION_FILE)) {
        const data = JSON.parse(fs.readFileSync(COLLABORATION_FILE, 'utf8'));
        this.collaborationHistory = data.history || [];
        this.sharedKnowledge = data.sharedKnowledge || {};
        this.taskQueue = data.taskQueue || [];
      } else {
        this.collaborationHistory = [];
        this.sharedKnowledge = {};
        this.taskQueue = [];
      }
    } catch (error) {
      this.collaborationHistory = [];
      this.sharedKnowledge = {};
      this.taskQueue = [];
    }
  }

  saveCollaborationData() {
    const data = {
      lastUpdate: new Date().toISOString(),
      history: this.collaborationHistory,
      sharedKnowledge: this.sharedKnowledge,
      taskQueue: this.taskQueue,
      aiStatus: this.aiAssistants
    };

    if (!fs.existsSync(CONFIG_DIR)) {
      fs.mkdirSync(CONFIG_DIR, { recursive: true });
    }

    fs.writeFileSync(COLLABORATION_FILE, JSON.stringify(data, null, 2));
  }

  setupKnowledgeSharing() {
    // Initialize shared knowledge categories
    if (!this.sharedKnowledge.categories) {
      this.sharedKnowledge.categories = {
        'navigation': {
          primary: 'omarchy-navigator',
          contributors: ['claude-code', 'gemini-ai'],
          lastUpdated: new Date().toISOString()
        },
        'coding': {
          primary: 'codex-copilot',
          contributors: ['openai-assistant', 'claude-code'],
          lastUpdated: new Date().toISOString()
        },
        'system-management': {
          primary: 'claude-code',
          contributors: ['omarchy-navigator', 'openai-assistant'],
          lastUpdated: new Date().toISOString()
        },
        'troubleshooting': {
          primary: 'omarchy-navigator',
          contributors: ['claude-code', 'gemini-ai', 'openai-assistant'],
          lastUpdated: new Date().toISOString()
        },
        'customization': {
          primary: 'omarchy-navigator',
          contributors: ['gemini-ai', 'claude-code'],
          lastUpdated: new Date().toISOString()
        }
      };
    }
  }

  distributeTask(task, priority = 'normal') {
    const taskEntry = {
      id: Date.now().toString(),
      task,
      priority,
      status: 'queued',
      createdAt: new Date().toISOString(),
      assignedTo: null,
      completedBy: null
    };

    // Determine best AI for this task
    const bestAssistant = this.selectBestAssistant(task);
    taskEntry.assignedTo = bestAssistant;

    // Update AI status
    this.aiAssistants[bestAssistant].lastActive = new Date().toISOString();

    // Add to queue
    this.taskQueue.push(taskEntry);
    this.saveCollaborationData();

    return {
      taskId: taskEntry.id,
      assignedTo: bestAssistant,
      estimatedTime: this.estimateTaskTime(task, bestAssistant)
    };
  }

  selectBestAssistant(task) {
    const taskLower = task.toLowerCase();
    let scores = {};

    // Score each AI based on task content
    Object.keys(this.aiAssistants).forEach(aiId => {
      const ai = this.aiAssistants[aiId];
      scores[aiId] = 0;

      ai.strengths.forEach(strength => {
        if (taskLower.includes(strength.replace('-', ' '))) {
          scores[aiId] += 10;
        }
      });

      // Check if AI is active
      if (ai.status === 'active') {
        scores[aiId] += 5;
      }

      // Check recent activity (avoid overloading)
      const lastActive = new Date(ai.lastActive);
      const timeSinceActive = Date.now() - lastActive.getTime();
      if (timeSinceActive > 60000) { // More than 1 minute
        scores[aiId] += 2;
      }
    });

    // Return AI with highest score
    return Object.keys(scores).reduce((a, b) => scores[a] > scores[b] ? a : b);
  }

  estimateTaskTime(task, assistantId) {
    const baseTimes = {
      'claude-code': 30, // seconds
      'gemini-ai': 25,
      'openai-assistant': 35,
      'codex-copilot': 15,
      'omarchy-navigator': 20
    };

    const complexity = task.length > 100 ? 1.5 : task.length > 50 ? 1.2 : 1.0;
    return Math.round(baseTimes[assistantId] * complexity);
  }

  shareKnowledge(fromAI, category, knowledge) {
    const entry = {
      from: fromAI,
      category,
      knowledge,
      timestamp: new Date().toISOString(),
      verified: false
    };

    // Add to shared knowledge
    if (!this.sharedKnowledge[category]) {
      this.sharedKnowledge[category] = [];
    }
    this.sharedKnowledge[category].push(entry);

    // Update collaboration history
    this.collaborationHistory.push({
      type: 'knowledge-share',
      from: fromAI,
      category,
      timestamp: new Date().toISOString()
    });

    // Notify other AIs (simulated)
    this.notifyOtherAIs(fromAI, category, knowledge);

    this.saveCollaborationData();
  }

  notifyOtherAIs(fromAI, category, knowledge) {
    // This would notify other AI systems about new shared knowledge
    const notification = {
      type: 'knowledge-update',
      from: fromAI,
      category,
      summary: knowledge.substring(0, 100) + '...',
      timestamp: new Date().toISOString()
    };

    // In a real implementation, this would send notifications to other AI services
    console.log(`📢 Knowledge shared: ${fromAI} shared ${category} knowledge with the team`);
  }

  getCollaborationStatus() {
    const activeAIs = Object.values(this.aiAssistants).filter(ai => ai.status === 'active').length;
    const totalKnowledge = Object.values(this.sharedKnowledge).flat().length;
    const pendingTasks = this.taskQueue.filter(task => task.status === 'queued').length;

    return {
      activeAssistants: activeAIs,
      totalAssistants: Object.keys(this.aiAssistants).length,
      knowledgeEntries: totalKnowledge,
      pendingTasks,
      lastCollaboration: this.collaborationHistory.length > 0 ?
        this.collaborationHistory[this.collaborationHistory.length - 1].timestamp : null
    };
  }

  optimizeWorkload() {
    // Redistribute tasks if one AI is overloaded
    const taskCounts = {};
    Object.keys(this.aiAssistants).forEach(aiId => {
      taskCounts[aiId] = this.taskQueue.filter(task => task.assignedTo === aiId && task.status === 'queued').length;
    });

    // Find overloaded and underloaded AIs
    const maxTasks = Math.max(...Object.values(taskCounts));
    const minTasks = Math.min(...Object.values(taskCounts));

    if (maxTasks - minTasks > 2) {
      const overloaded = Object.keys(taskCounts).find(ai => taskCounts[ai] === maxTasks);
      const underloaded = Object.keys(taskCounts).find(ai => taskCounts[ai] === minTasks);

      // Move one task from overloaded to underloaded
      const taskToMove = this.taskQueue.find(task => task.assignedTo === overloaded && task.status === 'queued');
      if (taskToMove) {
        taskToMove.assignedTo = underloaded;
        this.saveCollaborationData();
        return { redistributed: true, from: overloaded, to: underloaded };
      }
    }

    return { redistributed: false };
  }

  suggestCollaboration(task) {
    // Suggest which AIs should work together on a complex task
    const taskLower = task.toLowerCase();
    const suggestions = [];

    if (taskLower.includes('code') || taskLower.includes('program')) {
      suggestions.push({
        primary: 'codex-copilot',
        support: ['openai-assistant', 'claude-code'],
        reason: 'Code generation with syntax checking and analysis'
      });
    }

    if (taskLower.includes('navigate') || taskLower.includes('desktop')) {
      suggestions.push({
        primary: 'omarchy-navigator',
        support: ['claude-code'],
        reason: 'Desktop navigation with system integration'
      });
    }

    if (taskLower.includes('create') || taskLower.includes('design')) {
      suggestions.push({
        primary: 'gemini-ai',
        support: ['openai-assistant'],
        reason: 'Creative content with technical implementation'
      });
    }

    if (taskLower.includes('system') || taskLower.includes('troubleshoot')) {
      suggestions.push({
        primary: 'claude-code',
        support: ['omarchy-navigator', 'openai-assistant'],
        reason: 'System analysis with multiple perspectives'
      });
    }

    return suggestions.length > 0 ? suggestions[0] : {
      primary: 'claude-code',
      support: ['omarchy-navigator'],
      reason: 'General task with system integration'
    };
  }
}

// Enhanced Omarchy Navigator with AI collaboration
class EnhancedOmarchyNavigator {
  constructor() {
    this.collaborationHub = new AICollaborationHub();
    this.navigator = require('./omarchy-navigator.js');
  }

  async handleCollaborativeQuery(query) {
    // Determine if this needs collaboration
    const collaboration = this.collaborationHub.suggestCollaboration(query);

    // Share knowledge with team
    this.collaborationHub.shareKnowledge('omarchy-navigator', 'navigation', query);

    // Get primary response
    const primaryResponse = await this.navigator.handleQuery(query);

    // If complex task, distribute to team
    if (query.length > 100 || query.includes('complex') || query.includes('help me')) {
      const taskId = this.collaborationHub.distributeTask(query, 'normal');
      primaryResponse.collaboration = {
        taskId,
        team: collaboration,
        workingInBackground: true
      };
    }

    return primaryResponse;
  }

  showCollaborationStatus() {
    const status = this.collaborationHub.getCollaborationStatus();
    const optimization = this.collaborationHub.optimizeWorkload();

    return {
      status,
      optimization,
      teamMembers: Object.values(this.collaborationHub.aiAssistants).map(ai => ({
        name: ai.name,
        status: ai.status,
        strengths: ai.strengths
      }))
    };
  }
}

// CLI Interface for AI Collaboration Hub
async function main() {
  const args = process.argv.slice(2);
  const hub = new AICollaborationHub();

  if (args[0] === 'status') {
    const status = hub.getCollaborationStatus();
    console.log(`🤖 **AI Team Status**`);
    console.log(`   Active: ${status.activeAssistants}/${status.totalAssistants}`);
    console.log(`   Knowledge Base: ${status.knowledgeEntries} entries`);
    console.log(`   Pending Tasks: ${status.pendingTasks}`);
    console.log(`   Last Collaboration: ${status.lastCollaboration || 'Never'}`);
  }

  else if (args[0] === 'distribute' && args[1]) {
    const task = args.slice(1).join(' ');
    const result = hub.distributeTask(task);
    console.log(`🎯 Task assigned to ${hub.aiAssistants[result.assignedTo].name}`);
    console.log(`   Task ID: ${result.taskId}`);
    console.log(`   Estimated time: ${result.estimatedTime} seconds`);
  }

  else if (args[0] === 'share' && args[1] && args[2]) {
    const fromAI = args[1];
    const category = args[2];
    const knowledge = args.slice(3).join(' ') || 'Shared knowledge entry';
    hub.shareKnowledge(fromAI, category, knowledge);
    console.log(`📚 Knowledge shared from ${fromAI} in category: ${category}`);
  }

  else if (args[0] === 'optimize') {
    const result = hub.optimizeWorkload();
    if (result.redistributed) {
      console.log(`⚖️  Workload optimized: moved task from ${result.from} to ${result.to}`);
    } else {
      console.log(`✅ Workload is already balanced`);
    }
  }

  else {
    console.log(`🤖 **AI Collaboration Hub**`);
    console.log(``);
    console.log(`Usage:`);
    console.log(`  ai-collaboration-hub status                    - Show team status`);
    console.log(`  ai-collaboration-hub distribute <task>         - Distribute task to best AI`);
    console.log(`  ai-collaboration-hub share <ai> <category> <knowledge> - Share knowledge`);
    console.log(`  ai-collaboration-hub optimize                   - Optimize workload`);
    console.log(``);
    console.log(`Available AIs:`);
    Object.entries(hub.aiAssistants).forEach(([id, ai]) => {
      console.log(`  • ${ai.name}: ${ai.strengths.join(', ')}`);
    });
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { AICollaborationHub, EnhancedOmarchyNavigator };
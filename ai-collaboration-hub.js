#!/usr/bin/env node

/**
 * AI Collaboration Hub - Connects all AI assistants for shared knowledge and distributed tasks
 * Integrates: Claude Code, Gemini AI, OpenAI Assistant, Codex Copilot, Omarchy Navigator
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const crypto = require('crypto');

const CONFIG_DIR = '/home/zebadiee/.npm-global/omarchy-wagon';
const COLLABORATION_FILE = path.join(CONFIG_DIR, 'ai-collaboration.json');
const KNOWLEDGE_SHARED = path.join(CONFIG_DIR, 'shared-knowledge.json');
const VBH_FACTS_FILE = path.join(CONFIG_DIR, 'vbh-facts.json');

class AICollaborationHub {
  constructor() {
    this.aiAssistants = {
      'claude-code': {
        name: 'Claude Code',
        strengths: ['file-operations', 'terminal', 'analysis', 'debugging'],
        status: 'active',
        lastActive: new Date().toISOString(),
      },
      'gemini-ai': {
        name: 'Gemini AI',
        strengths: ['research', 'content-generation', 'analysis', 'creative-tasks'],
        status: 'configured',
        lastActive: new Date().toISOString(),
      },
      'openai-assistant': {
        name: 'OpenAI Assistant',
        strengths: ['coding', 'problem-solving', 'explanation', 'optimization'],
        status: 'configured',
        lastActive: new Date().toISOString(),
      },
      'codex-copilot': {
        name: 'Codex Copilot',
        strengths: ['code-completion', 'syntax', 'patterns', 'refactoring'],
        status: 'active',
        lastActive: new Date().toISOString(),
      },
      'omarchy-navigator': {
        name: 'Omarchy Navigator',
        strengths: ['desktop-navigation', 'customization', 'troubleshooting', 'system-commands'],
        status: 'active',
        lastActive: new Date().toISOString(),
      },
    };

    // VBH compliance state
    this.vbhCounter = parseInt(process.env.OM_VBH_COUNTER || '1');
    this.vbhFacts = this.loadVBHFacts();

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

  loadVBHFacts() {
    try {
      if (fs.existsSync(VBH_FACTS_FILE)) {
        return JSON.parse(fs.readFileSync(VBH_FACTS_FILE, 'utf8'));
      } else if (process.env.OM_VBH_FACTS) {
        return JSON.parse(process.env.OM_VBH_FACTS);
      } else {
        // Default VBH facts
        return {
          scope: "unified",
          site: "Omarchy",
          open_tasks: 0,
          provider: "gemini-2.0-flash-exp"
        };
      }
    } catch (error) {
      console.warn('⚠️  VBH facts loading failed, using defaults:', error.message);
      return {
        scope: "unified",
        site: "Omarchy",
        open_tasks: 0,
        provider: "unknown"
      };
    }
  }

  saveVBHFacts() {
    const data = {
      ...this.vbhFacts,
      lastUpdate: new Date().toISOString(),
      counter: this.vbhCounter
    };

    if (!fs.existsSync(CONFIG_DIR)) {
      fs.mkdirSync(CONFIG_DIR, { recursive: true });
    }

    fs.writeFileSync(VBH_FACTS_FILE, JSON.stringify(data, null, 2));
  }

  generateVBHHeader() {
    const content = JSON.stringify(this.vbhFacts);
    const sha = crypto.createHash('sha256').update(content).digest('hex').substring(0, 8);
    this.vbhCounter++;

    return `#VBH:${this.vbhCounter}:${sha}`;
  }

  validateVBHCompliance(text) {
    const lines = text.split('\n');
    let vbhHeader = null;
    let confirmLine = null;
    let confirmMatch = null;

    // Find VBH header and CONFIRM line
    for (const line of lines) {
      if (line.startsWith('#VBH:')) {
        vbhHeader = line;
      }
      if (line.startsWith('CONFIRM:')) {
        confirmLine = line;
        try {
          confirmMatch = JSON.parse(line.substring(8));
        } catch (e) {
          return { valid: false, error: 'Invalid JSON in CONFIRM line' };
        }
      }
    }

    // Check if both exist
    if (!vbhHeader) {
      return { valid: false, error: 'Missing VBH header' };
    }
    if (!confirmLine) {
      return { valid: false, error: 'Missing CONFIRM line' };
    }

    // Validate VBH header format
    const vbhMatch = vbhHeader.match(/^#VBH:(\d+):([a-f0-9]{8})$/);
    if (!vbhMatch) {
      return { valid: false, error: 'Invalid VBH header format' };
    }

    const vbhCounter = parseInt(vbhMatch[1]);
    const vbhHash = vbhMatch[2];

    // Verify hash matches CONFIRM content
    const confirmContent = JSON.stringify(confirmMatch);
    const expectedHash = crypto.createHash('sha256').update(confirmContent).digest('hex').substring(0, 8);

    if (vbhHash !== expectedHash) {
      return { valid: false, error: 'VBH hash does not match CONFIRM content' };
    }

    // Verify CONFIRM matches current facts
    const factErrors = [];
    if (confirmMatch.scope !== this.vbhFacts.scope) {
      factErrors.push(`scope mismatch: expected ${this.vbhFacts.scope}, got ${confirmMatch.scope}`);
    }
    if (confirmMatch.site !== this.vbhFacts.site) {
      factErrors.push(`site mismatch: expected ${this.vbhFacts.site}, got ${confirmMatch.site}`);
    }
    if (confirmMatch.provider !== this.vbhFacts.provider) {
      factErrors.push(`provider mismatch: expected ${this.vbhFacts.provider}, got ${confirmMatch.provider}`);
    }

    if (factErrors.length > 0) {
      return { valid: false, error: `Fact mismatches: ${factErrors.join(', ')}` };
    }

    return {
      valid: true,
      vbhCounter,
      confirmMatch,
      header: vbhHeader,
      confirmLine
    };
  }

  createVBHCompliantResponse(content, additionalFacts = {}) {
    const header = this.generateVBHHeader();
    const confirmFacts = {
      ...this.vbhFacts,
      ...additionalFacts
    };
    const confirmLine = `CONFIRM:${JSON.stringify(confirmFacts)}`;

    return `${header}\n${confirmLine}\n\n${content}`;
  }

  generateSemanticCacheKey(prompt, agent = null, purpose = null) {
    // Create a semantic fingerprint for caching
    const components = {
      prompt: prompt.toLowerCase().trim().substring(0, 200), // Normalize and limit length
      agent: agent || 'default',
      purpose: purpose || 'general',
      vbhScope: this.vbhFacts.scope,
      vbhSite: this.vbhFacts.site
    };

    const keyString = JSON.stringify(components, Object.keys(components).sort());
    const hash = crypto.createHash('sha256').update(keyString).digest('hex');

    return `sem_${hash.substring(0, 16)}`;
  }

  checkSemanticCache(cacheKey) {
    const cacheFile = path.join(CONFIG_DIR, 'semantic-cache.json');
    try {
      if (fs.existsSync(cacheFile)) {
        const cache = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
        const entry = cache[cacheKey];

        if (entry && !this.isCacheEntryExpired(entry)) {
          return entry;
        }
      }
    } catch (error) {
      console.warn('⚠️  Cache check failed:', error.message);
    }
    return null;
  }

  storeSemanticCache(cacheKey, response, metadata = {}) {
    const cacheFile = path.join(CONFIG_DIR, 'semantic-cache.json');
    let cache = {};

    try {
      if (fs.existsSync(cacheFile)) {
        cache = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
      }
    } catch (error) {
      console.warn('⚠️  Cache load failed, creating new cache:', error.message);
    }

    cache[cacheKey] = {
      response,
      metadata: {
        ...metadata,
        timestamp: new Date().toISOString(),
        vbhCounter: this.vbhCounter
      },
      expiresAt: new Date(Date.now() + (24 * 60 * 60 * 1000)).toISOString() // 24 hours
    };

    // Clean old entries
    this.cleanExpiredCacheEntries(cache);

    if (!fs.existsSync(CONFIG_DIR)) {
      fs.mkdirSync(CONFIG_DIR, { recursive: true });
    }

    fs.writeFileSync(cacheFile, JSON.stringify(cache, null, 2));
  }

  isCacheEntryExpired(entry) {
    return new Date() > new Date(entry.expiresAt);
  }

  cleanExpiredCacheEntries(cache) {
    const now = new Date();
    Object.keys(cache).forEach(key => {
      if (new Date(cache[key].expiresAt) < now) {
        delete cache[key];
      }
    });
  }

  // Simple MDL (Minimum Description Length) tracking
  calculateMDL(content) {
    if (!content || typeof content !== 'string') {
      return { bytes: 0, lines: 0, entropy: 0, complexity: 0 };
    }

    const lines = content.split('\n').length;
    const bytes = Buffer.byteLength(content, 'utf8');

    // Calculate simple entropy based on character frequency
    const charFreq = {};
    for (const char of content) {
      charFreq[char] = (charFreq[char] || 0) + 1;
    }

    let entropy = 0;
    const totalChars = content.length;
    for (const count of Object.values(charFreq)) {
      if (count > 0) {
        const probability = count / totalChars;
        entropy -= probability * Math.log2(probability);
      }
    }

    // Simple complexity estimation
    let complexity = 0;

    // Count unique tokens (words)
    const tokens = content.toLowerCase().match(/\b\w+\b/g) || [];
    const uniqueTokens = new Set(tokens);
    complexity += uniqueTokens.size * 0.1;

    // Add complexity for code-like patterns
    const codePatterns = [/\{.*\}/g, /\[.*\]/g, /\(.*\)/g, /function\s+\w+/g, /class\s+\w+/g];
    for (const pattern of codePatterns) {
      const matches = content.match(pattern) || [];
      complexity += matches.length * 0.5;
    }

    // Add complexity for nested structures
    const nestedLevel = (content.match(/^\s+/gm) || [])
      .reduce((max, spaces) => Math.max(max, spaces.length), 0) / 2;
    complexity += nestedLevel * 0.2;

    return {
      bytes,
      lines,
      entropy: Math.round(entropy * 100) / 100,
      complexity: Math.round(complexity * 100) / 100,
      mdlScore: Math.round((bytes * 0.001 + lines * 0.1 + entropy * 0.5 + complexity) * 100) / 100
    };
  }

  trackMDLHistory(identifier, content, metadata = {}) {
    const historyFile = path.join(CONFIG_DIR, 'mdl-history.json');
    let history = [];

    try {
      if (fs.existsSync(historyFile)) {
        history = JSON.parse(fs.readFileSync(historyFile, 'utf8'));
      }
    } catch (error) {
      console.warn('⚠️  Failed to load MDL history:', error.message);
    }

    const mdlMetrics = this.calculateMDL(content);
    const entry = {
      id: identifier,
      timestamp: new Date().toISOString(),
      vbhCounter: this.vbhCounter,
      metrics: mdlMetrics,
      metadata: {
        ...metadata,
        contentPreview: content.substring(0, 100) + (content.length > 100 ? '...' : '')
      }
    };

    history.push(entry);

    // Keep only last 100 entries to prevent file from growing too large
    if (history.length > 100) {
      history = history.slice(-100);
    }

    if (!fs.existsSync(CONFIG_DIR)) {
      fs.mkdirSync(CONFIG_DIR, { recursive: true });
    }

    fs.writeFileSync(historyFile, JSON.stringify(history, null, 2));

    return entry;
  }

  getMDLStats(limit = 10) {
    const historyFile = path.join(CONFIG_DIR, 'mdl-history.json');

    try {
      if (!fs.existsSync(historyFile)) {
        return { message: 'No MDL history found' };
      }

      const history = JSON.parse(fs.readFileSync(historyFile, 'utf8'));
      const recent = history.slice(-limit);

      if (recent.length === 0) {
        return { message: 'No MDL entries found' };
      }

      const avgMDL = recent.reduce((sum, entry) => sum + entry.metrics.mdlScore, 0) / recent.length;
      const avgComplexity = recent.reduce((sum, entry) => sum + entry.metrics.complexity, 0) / recent.length;
      const avgEntropy = recent.reduce((sum, entry) => sum + entry.metrics.entropy, 0) / recent.length;

      return {
        totalEntries: history.length,
        recentEntries: recent.length,
        averages: {
          mdlScore: Math.round(avgMDL * 100) / 100,
          complexity: Math.round(avgComplexity * 100) / 100,
          entropy: Math.round(avgEntropy * 100) / 100
        },
        trend: this.calculateMDLTrend(recent),
        recent: recent.map(entry => ({
          id: entry.id,
          timestamp: entry.timestamp,
          mdlScore: entry.metrics.mdlScore,
          complexity: entry.metrics.complexity,
          entropy: entry.metrics.entropy,
          preview: entry.metadata.contentPreview
        }))
      };
    } catch (error) {
      return { error: `Failed to load MDL stats: ${error.message}` };
    }
  }

  calculateMDLTrend(entries) {
    if (entries.length < 2) {
      return { direction: 'stable', change: 0 };
    }

    const recent = entries.slice(-5); // Last 5 entries
    const older = entries.slice(-10, -5); // Previous 5 entries

    if (older.length === 0) {
      return { direction: 'stable', change: 0 };
    }

    const recentAvg = recent.reduce((sum, entry) => sum + entry.metrics.mdlScore, 0) / recent.length;
    const olderAvg = older.reduce((sum, entry) => sum + entry.metrics.mdlScore, 0) / older.length;

    const change = ((recentAvg - olderAvg) / olderAvg) * 100;

    let direction;
    if (Math.abs(change) < 5) {
      direction = 'stable';
    } else if (change > 0) {
      direction = 'increasing';
    } else {
      direction = 'decreasing';
    }

    return {
      direction,
      change: Math.round(change * 100) / 100,
      recentAverage: Math.round(recentAvg * 100) / 100,
      olderAverage: Math.round(olderAvg * 100) / 100
    };
  }

  saveCollaborationData() {
    const data = {
      lastUpdate: new Date().toISOString(),
      history: this.collaborationHistory,
      sharedKnowledge: this.sharedKnowledge,
      taskQueue: this.taskQueue,
      aiStatus: this.aiAssistants,
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
        navigation: {
          primary: 'omarchy-navigator',
          contributors: ['claude-code', 'gemini-ai'],
          lastUpdated: new Date().toISOString(),
        },
        coding: {
          primary: 'codex-copilot',
          contributors: ['openai-assistant', 'claude-code'],
          lastUpdated: new Date().toISOString(),
        },
        'system-management': {
          primary: 'claude-code',
          contributors: ['omarchy-navigator', 'openai-assistant'],
          lastUpdated: new Date().toISOString(),
        },
        troubleshooting: {
          primary: 'omarchy-navigator',
          contributors: ['claude-code', 'gemini-ai', 'openai-assistant'],
          lastUpdated: new Date().toISOString(),
        },
        customization: {
          primary: 'omarchy-navigator',
          contributors: ['gemini-ai', 'claude-code'],
          lastUpdated: new Date().toISOString(),
        },
      };
    }
  }

  distributeTask(task, priority = 'normal', options = {}) {
    // Check semantic cache first
    const cacheKey = this.generateSemanticCacheKey(task, options.agent, options.purpose);
    const cachedResult = this.checkSemanticCache(cacheKey);

    if (cachedResult && !options.bypassCache) {
      console.log(`🎯 Cache hit for task: ${task.substring(0, 50)}...`);
      return {
        taskId: `cached_${Date.now()}`,
        assignedTo: cachedResult.metadata.assignedTo,
        estimatedTime: 0,
        cached: true,
        response: cachedResult.response,
        cacheTimestamp: cachedResult.metadata.timestamp
      };
    }

    const taskEntry = {
      id: Date.now().toString(),
      task,
      priority,
      status: 'queued',
      createdAt: new Date().toISOString(),
      assignedTo: null,
      completedBy: null,
      cacheKey,
      metadata: {
        purpose: options.purpose || 'general',
        requester: options.requester || 'user',
        vbhCounter: this.vbhCounter
      }
    };

    // Determine best AI for this task
    const bestAssistant = options.agent || this.selectBestAssistant(task);
    taskEntry.assignedTo = bestAssistant;

    // Update AI status
    this.aiAssistants[bestAssistant].lastActive = new Date().toISOString();

    // Add to queue
    this.taskQueue.push(taskEntry);
    this.saveCollaborationData();

    const result = {
      taskId: taskEntry.id,
      assignedTo: bestAssistant,
      estimatedTime: this.estimateTaskTime(task, bestAssistant),
      cached: false
    };

    // Store task metadata in cache for potential future use
    this.storeSemanticCache(cacheKey, result, {
      taskType: 'task_distribution',
      assignedTo: bestAssistant,
      priority
    });

    return result;
  }

  selectBestAssistant(task) {
    const taskLower = task.toLowerCase();
    let scores = {};

    // Score each AI based on task content
    Object.keys(this.aiAssistants).forEach((aiId) => {
      const ai = this.aiAssistants[aiId];
      scores[aiId] = 0;

      ai.strengths.forEach((strength) => {
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
      if (timeSinceActive > 60000) {
        // More than 1 minute
        scores[aiId] += 2;
      }
    });

    // Return AI with highest score
    return Object.keys(scores).reduce((a, b) => (scores[a] > scores[b] ? a : b));
  }

  estimateTaskTime(task, assistantId) {
    const baseTimes = {
      'claude-code': 30, // seconds
      'gemini-ai': 25,
      'openai-assistant': 35,
      'codex-copilot': 15,
      'omarchy-navigator': 20,
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
      verified: false,
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
      timestamp: new Date().toISOString(),
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
      timestamp: new Date().toISOString(),
    };

    // In a real implementation, this would send notifications to other AI services
    console.log(`📢 Knowledge shared: ${fromAI} shared ${category} knowledge with the team`);
  }

  getCollaborationStatus() {
    const activeAIs = Object.values(this.aiAssistants).filter(
      (ai) => ai.status === 'active',
    ).length;
    const totalKnowledge = Object.values(this.sharedKnowledge).flat().length;
    const pendingTasks = this.taskQueue.filter((task) => task.status === 'queued').length;

    return {
      activeAssistants: activeAIs,
      totalAssistants: Object.keys(this.aiAssistants).length,
      knowledgeEntries: totalKnowledge,
      pendingTasks,
      lastCollaboration:
        this.collaborationHistory.length > 0
          ? this.collaborationHistory[this.collaborationHistory.length - 1].timestamp
          : null,
    };
  }

  optimizeWorkload() {
    // Redistribute tasks if one AI is overloaded
    const taskCounts = {};
    Object.keys(this.aiAssistants).forEach((aiId) => {
      taskCounts[aiId] = this.taskQueue.filter(
        (task) => task.assignedTo === aiId && task.status === 'queued',
      ).length;
    });

    // Find overloaded and underloaded AIs
    const maxTasks = Math.max(...Object.values(taskCounts));
    const minTasks = Math.min(...Object.values(taskCounts));

    if (maxTasks - minTasks > 2) {
      const overloaded = Object.keys(taskCounts).find((ai) => taskCounts[ai] === maxTasks);
      const underloaded = Object.keys(taskCounts).find((ai) => taskCounts[ai] === minTasks);

      // Move one task from overloaded to underloaded
      const taskToMove = this.taskQueue.find(
        (task) => task.assignedTo === overloaded && task.status === 'queued',
      );
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
        reason: 'Code generation with syntax checking and analysis',
      });
    }

    if (taskLower.includes('navigate') || taskLower.includes('desktop')) {
      suggestions.push({
        primary: 'omarchy-navigator',
        support: ['claude-code'],
        reason: 'Desktop navigation with system integration',
      });
    }

    if (taskLower.includes('create') || taskLower.includes('design')) {
      suggestions.push({
        primary: 'gemini-ai',
        support: ['openai-assistant'],
        reason: 'Creative content with technical implementation',
      });
    }

    if (taskLower.includes('system') || taskLower.includes('troubleshoot')) {
      suggestions.push({
        primary: 'claude-code',
        support: ['omarchy-navigator', 'openai-assistant'],
        reason: 'System analysis with multiple perspectives',
      });
    }

    return suggestions.length > 0
      ? suggestions[0]
      : {
          primary: 'claude-code',
          support: ['omarchy-navigator'],
          reason: 'General task with system integration',
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
        workingInBackground: true,
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
      teamMembers: Object.values(this.collaborationHub.aiAssistants).map((ai) => ({
        name: ai.name,
        status: ai.status,
        strengths: ai.strengths,
      })),
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
    console.log(`   VBH Counter: ${hub.vbhCounter}`);
    console.log(`   Last Collaboration: ${status.lastCollaboration || 'Never'}`);
  } else if (args[0] === 'distribute' && args[1]) {
    const task = args.slice(1).join(' ');
    const options = {
      purpose: args.includes('--purpose') && args[args.indexOf('--purpose') + 1] ? args[args.indexOf('--purpose') + 1] : 'general',
      bypassCache: args.includes('--no-cache')
    };
    const result = hub.distributeTask(task, 'normal', options);
    if (result.cached) {
      console.log(`🎯 Cached result from ${hub.aiAssistants[result.assignedTo].name}`);
      console.log(`   Cache timestamp: ${result.cacheTimestamp}`);
    } else {
      console.log(`🎯 Task assigned to ${hub.aiAssistants[result.assignedTo].name}`);
      console.log(`   Task ID: ${result.taskId}`);
      console.log(`   Estimated time: ${result.estimatedTime} seconds`);
    }
  } else if (args[0] === 'share' && args[1] && args[2]) {
    const fromAI = args[1];
    const category = args[2];
    const knowledge = args.slice(3).join(' ') || 'Shared knowledge entry';
    hub.shareKnowledge(fromAI, category, knowledge);
    console.log(`📚 Knowledge shared from ${fromAI} in category: ${category}`);
  } else if (args[0] === 'optimize') {
    const result = hub.optimizeWorkload();
    if (result.redistributed) {
      console.log(`⚖️  Workload optimized: moved task from ${result.from} to ${result.to}`);
    } else {
      console.log(`✅ Workload is already balanced`);
    }
  } else if (args[0] === 'vbh-validate' && args[1]) {
    // VBH validation command
    const filePath = args[1];
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const validation = hub.validateVBHCompliance(content);

      if (validation.valid) {
        console.log(`✅ VBH validation passed for ${filePath}`);
        console.log(`   VBH Counter: ${validation.vbhCounter}`);
        console.log(`   CONFIRM: ${JSON.stringify(validation.confirmMatch)}`);
      } else {
        console.log(`❌ VBH validation failed for ${filePath}`);
        console.log(`   Error: ${validation.error}`);
        process.exit(1);
      }
    } catch (error) {
      console.error(`❌ Error reading file: ${error.message}`);
      process.exit(1);
    }
  } else if (args[0] === 'vbh-create') {
    // Create VBH-compliant response
    const content = args.slice(1).join(' ') || 'Sample VBH-compliant content';
    const vbhResponse = hub.createVBHCompliantResponse(content, {
      open_tasks: hub.taskQueue.filter(t => t.status === 'queued').length
    });
    console.log(vbhResponse);
  } else if (args[0] === 'cache-stats') {
    // Show semantic cache statistics
    const cacheFile = path.join(CONFIG_DIR, 'semantic-cache.json');
    try {
      if (fs.existsSync(cacheFile)) {
        const cache = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
        const entries = Object.keys(cache).length;
        const expired = Object.values(cache).filter(entry => hub.isCacheEntryExpired(entry)).length;
        console.log(`📊 Semantic Cache Statistics`);
        console.log(`   Total entries: ${entries}`);
        console.log(`   Expired entries: ${expired}`);
        console.log(`   Valid entries: ${entries - expired}`);
        console.log(`   Cache file: ${cacheFile}`);
      } else {
        console.log(`📊 No semantic cache found`);
      }
    } catch (error) {
      console.error(`❌ Error reading cache: ${error.message}`);
    }
  } else if (args[0] === 'cache-clear') {
    // Clear semantic cache
    const cacheFile = path.join(CONFIG_DIR, 'semantic-cache.json');
    try {
      if (fs.existsSync(cacheFile)) {
        fs.unlinkSync(cacheFile);
        console.log(`🗑️  Semantic cache cleared`);
      } else {
        console.log(`📊 No semantic cache to clear`);
      }
    } catch (error) {
      console.error(`❌ Error clearing cache: ${error.message}`);
    }
  } else if (args[0] === 'mdl-calculate' && args[1]) {
    // Calculate MDL for content
    const filePath = args[1];
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const mdlMetrics = hub.calculateMDL(content);

      console.log(`📊 MDL Analysis for ${filePath}:`);
      console.log(`   Bytes: ${mdlMetrics.bytes}`);
      console.log(`   Lines: ${mdlMetrics.lines}`);
      console.log(`   Entropy: ${mdlMetrics.entropy}`);
      console.log(`   Complexity: ${mdlMetrics.complexity}`);
      console.log(`   MDL Score: ${mdlMetrics.mdlScore}`);

      // Track in history
      hub.trackMDLHistory(filePath, content, { source: 'cli', path: filePath });
      console.log(`   📝 Tracked in MDL history`);
    } catch (error) {
      console.error(`❌ Error analyzing file: ${error.message}`);
    }
  } else if (args[0] === 'mdl-stats') {
    // Show MDL statistics
    const limit = args.includes('--limit') && args[args.indexOf('--limit') + 1] ?
      parseInt(args[args.indexOf('--limit') + 1]) : 10;

    const stats = hub.getMDLStats(limit);

    if (stats.error) {
      console.error(`❌ ${stats.error}`);
    } else if (stats.message) {
      console.log(`📊 ${stats.message}`);
    } else {
      console.log(`📊 MDL Statistics:`);
      console.log(`   Total entries: ${stats.totalEntries}`);
      console.log(`   Recent entries: ${stats.recentEntries}`);
      console.log(`   Average MDL Score: ${stats.averages.mdlScore}`);
      console.log(`   Average Complexity: ${stats.averages.complexity}`);
      console.log(`   Average Entropy: ${stats.averages.entropy}`);
      console.log(`   Trend: ${stats.trend.direction} (${stats.trend.change > 0 ? '+' : ''}${stats.trend.change}%)`);
      console.log();

      if (stats.recent.length > 0) {
        console.log(`📋 Recent entries:`);
        stats.recent.forEach(entry => {
          const date = new Date(entry.timestamp).toLocaleString();
          console.log(`   ${entry.id}: ${entry.mdlScore} (${date})`);
          console.log(`     ${entry.preview}`);
        });
      }
    }
  } else {
    console.log(`🤖 **AI Collaboration Hub**`);
    console.log(``);
    console.log(`Usage:`);
    console.log(`  ai-collaboration-hub status                    - Show team status`);
    console.log(`  ai-collaboration-hub distribute <task>         - Distribute task to best AI`);
    console.log(`    Options: --purpose <type> --no-cache`);
    console.log(`  ai-collaboration-hub share <ai> <category> <knowledge> - Share knowledge`);
    console.log(`  ai-collaboration-hub optimize                   - Optimize workload`);
    console.log(`  ai-collaboration-hub vbh-validate <file>       - Validate VBH compliance`);
    console.log(`  ai-collaboration-hub vbh-create <content>      - Create VBH-compliant response`);
    console.log(`  ai-collaboration-hub cache-stats                - Show semantic cache stats`);
    console.log(`  ai-collaboration-hub cache-clear                - Clear semantic cache`);
    console.log(`  ai-collaboration-hub mdl-calculate <file>       - Calculate MDL for file`);
    console.log(`  ai-collaboration-hub mdl-stats                  - Show MDL statistics`);
    console.log(`    Options: --limit <number>`);
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

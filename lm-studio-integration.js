#!/usr/bin/env node

/**
 * LM Studio Integration - Bridges AI collaboration with LM Studio knowledge processing
 * Exports AI team knowledge for LM Studio analysis and imports LM Studio insights
 */

const fs = require('fs');
const path = require('path');
const { AICollaborationHub } = require('./ai-collaboration-hub.js');

class LMStudioIntegration {
  constructor() {
    this.outboxDir = path.join(__dirname, 'knowledge-outbox');
    this.hub = new AICollaborationHub();
    this.ensureDirectories();
  }

  ensureDirectories() {
    const dirs = [
      'team-status',
      'task-history',
      'knowledge-updates',
      'session-summaries',
      'lm-studio-notes'
    ];

    dirs.forEach(dir => {
      const fullPath = path.join(this.outboxDir, dir);
      if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
      }
    });
  }

  async exportKnowledge(options = {}) {
    const timestamp = new Date().toISOString().split('T')[0];
    const exportSession = options.session || 'manual';
    const context = options.context || 'full';

    console.log(`📤 Exporting AI team knowledge to LM Studio...`);
    console.log(`   Session: ${exportSession}`);
    console.log(`   Context: ${context}`);
    console.log(`   Timestamp: ${timestamp}\n`);

    const exportData = {
      metadata: {
        exportTime: new Date().toISOString(),
        session: exportSession,
        context: context,
        version: '1.0.0'
      },
      teamStatus: this.exportTeamStatus(),
      taskHistory: this.exportTaskHistory(),
      knowledgeGraph: this.exportKnowledgeGraph(),
      sessionSummary: this.generateSessionSummary(timestamp, context)
    };

    // Write individual files for LM Studio consumption
    await this.writeTeamStatus(exportData.teamStatus, timestamp);
    await this.writeTaskHistory(exportData.taskHistory, timestamp);
    await this.writeKnowledgeUpdates(exportData.knowledgeGraph, timestamp);
    await this.writeSessionSummary(exportData.sessionSummary, timestamp);

    // Write consolidated export
    const consolidatedPath = path.join(this.outboxDir, `omarchy-export-${timestamp}.json`);
    fs.writeFileSync(consolidatedPath, JSON.stringify(exportData, null, 2));

    console.log(`✅ Export completed!`);
    console.log(`   📁 Main export: ${consolidatedPath}`);
    console.log(`   📊 Individual files: ${this.outboxDir}/`);

    return exportData;
  }

  exportTeamStatus() {
    const status = this.hub.getCollaborationStatus();
    const teamMembers = Object.entries(this.hub.aiAssistants).map(([id, ai]) => ({
      id,
      name: ai.name,
      status: ai.status,
      strengths: ai.strengths,
      lastActive: ai.lastActive,
      recentActivity: this.getRecentActivity(id)
    }));

    return {
      overview: status,
      teamMembers,
      systemHealth: this.assessSystemHealth(),
      collaborationMetrics: this.calculateCollaborationMetrics()
    };
  }

  exportTaskHistory() {
    const tasks = this.hub.taskQueue.map(task => ({
      id: task.id,
      task: task.task,
      priority: task.priority,
      status: task.status,
      assignedTo: task.assignedTo,
      completedBy: task.completedBy,
      createdAt: task.createdAt,
      completedAt: task.completedAt,
      duration: task.completedAt ?
        new Date(task.completedAt) - new Date(task.createdAt) : null
    }));

    return {
      tasks,
      statistics: this.calculateTaskStatistics(tasks),
      performanceMetrics: this.calculatePerformanceMetrics(tasks)
    };
  }

  exportKnowledgeGraph() {
    const knowledge = this.hub.sharedKnowledge;
    const graph = {
      nodes: [],
      edges: [],
      categories: Object.keys(knowledge.categories || {})
    };

    // Build knowledge nodes
    if (knowledge.categories) {
      Object.entries(knowledge.categories).forEach(([category, info]) => {
        graph.nodes.push({
          id: category,
          type: 'category',
          label: category,
          primary: info.primary,
          contributors: info.contributors,
          lastUpdated: info.lastUpdated
        });
      });
    }

    // Build knowledge entries
    if (Array.isArray(knowledge)) {
      knowledge.forEach((entry, index) => {
        graph.nodes.push({
          id: `entry-${index}`,
          type: 'knowledge',
          from: entry.from,
          category: entry.category,
          knowledge: entry.knowledge,
          timestamp: entry.timestamp
        });
      });
    }

    return graph;
  }

  generateSessionSummary(timestamp, context) {
    const status = this.hub.getCollaborationStatus();
    const recentTasks = this.hub.taskQueue.slice(-5);

    return {
      date: timestamp,
      context: context,
      summary: {
        totalKnowledgeEntries: status.knowledgeEntries,
        activeAssistants: status.activeAssistants,
        pendingTasks: status.pendingTasks,
        recentActivity: recentTasks.map(task => ({
          task: task.task.substring(0, 100) + '...',
          status: task.status,
          assignedTo: task.assignedTo
        }))
      },
      insights: this.generateInsights(),
      recommendations: this.generateRecommendations(),
      nextSteps: this.generateNextSteps()
    };
  }

  async writeTeamStatus(teamStatus, timestamp) {
    const filePath = path.join(this.outboxDir, 'team-status', `team-status-${timestamp}.json`);
    fs.writeFileSync(filePath, JSON.stringify(teamStatus, null, 2));

    // Also write latest status
    const latestPath = path.join(this.outboxDir, 'team-status', 'latest.json');
    fs.writeFileSync(latestPath, JSON.stringify(teamStatus, null, 2));
  }

  async writeTaskHistory(taskHistory, timestamp) {
    const filePath = path.join(this.outboxDir, 'task-history', `tasks-${timestamp}.json`);
    fs.writeFileSync(filePath, JSON.stringify(taskHistory, null, 2));
  }

  async writeKnowledgeUpdates(knowledgeGraph, timestamp) {
    const filePath = path.join(this.outboxDir, 'knowledge-updates', `knowledge-${timestamp}.json`);
    fs.writeFileSync(filePath, JSON.stringify(knowledgeGraph, null, 2));
  }

  async writeSessionSummary(summary, timestamp) {
    const jsonPath = path.join(this.outboxDir, 'session-summaries', `summary-${timestamp}.json`);
    fs.writeFileSync(jsonPath, JSON.stringify(summary, null, 2));

    const mdPath = path.join(this.outboxDir, 'session-summaries', `summary-${timestamp}.md`);
    const markdown = this.formatSummaryAsMarkdown(summary);
    fs.writeFileSync(mdPath, markdown);
  }

  formatSummaryAsMarkdown(summary) {
    return `# Omarchy AI Team Session Summary

**Date:** ${summary.date}
**Context:** ${summary.context}

## 📊 Overview
- **Knowledge Entries:** ${summary.summary.totalKnowledgeEntries}
- **Active Assistants:** ${summary.summary.activeAssistants}
- **Pending Tasks:** ${summary.summary.pendingTasks}

## 🤖 Team Activity
${summary.summary.recentActivity.map(activity =>
  `- **${activity.assignedTo}**: ${activity.task} (${activity.status})`
).join('\n')}

## 💡 Insights
${summary.insights.map(insight => `- ${insight}`).join('\n')}

## 🎯 Recommendations
${summary.recommendations.map(rec => `- ${rec}`).join('\n')}

## 📋 Next Steps
${summary.nextSteps.map(step => `- ${step}`).join('\n')}

---
*Generated by Omarchy AI Collaboration System*
`;
  }

  async importLMStudioInsights() {
    const notesDir = path.join(this.outboxDir, 'lm-studio-notes');
    if (!fs.existsSync(notesDir)) {
      console.log('📂 LM Studio notes directory not found');
      return [];
    }

    const files = fs.readdirSync(notesDir).filter(f => f.endsWith('.md') || f.endsWith('.json'));
    const insights = [];

    console.log(`📥 Importing LM Studio insights...`);

    for (const file of files) {
      const filePath = path.join(notesDir, file);
      const content = fs.readFileSync(filePath, 'utf8');

      try {
        const insight = this.parseLMStudioInsight(content, file);
        insights.push(insight);

        // Share with AI team
        this.hub.shareKnowledge('lm-studio', 'insights', insight.summary);

        console.log(`   ✅ Imported: ${file}`);
      } catch (error) {
        console.log(`   ❌ Error importing ${file}: ${error.message}`);
      }
    }

    console.log(`🎉 Imported ${insights.length} insights from LM Studio`);
    return insights;
  }

  parseLMStudioInsight(content, filename) {
    const isMarkdown = filename.endsWith('.md');
    const isJSON = filename.endsWith('.json');

    if (isJSON) {
      return JSON.parse(content);
    }

    // Parse Markdown
    const lines = content.split('\n');
    const title = lines.find(l => l.startsWith('# '))?.replace('# ', '') || 'Untitled Insight';
    const sections = {};
    let currentSection = '';

    lines.forEach(line => {
      if (line.startsWith('## ')) {
        currentSection = line.replace('## ', '').toLowerCase();
        sections[currentSection] = [];
      } else if (currentSection && line.trim()) {
        sections[currentSection].push(line.trim());
      }
    });

    return {
      filename,
      title,
      sections,
      summary: this.extractSummary(sections),
      recommendations: this.extractRecommendations(sections),
      timestamp: fs.statSync(path.join(this.outboxDir, 'lm-studio-notes', filename)).mtime.toISOString()
    };
  }

  extractSummary(sections) {
    const summarySections = sections['summary'] || sections['overview'] || sections['insights'] || [];
    return summarySections.join(' ').substring(0, 500);
  }

  extractRecommendations(sections) {
    const recSections = sections['recommendations'] || sections['next steps'] || sections['actions'] || [];
    return recSections.map(line => line.replace(/^[-*]\s*/, ''));
  }

  async syncWithLMStudio() {
    console.log(`🔄 Starting full sync with LM Studio...`);

    // Export current knowledge
    const exportData = await this.exportKnowledge({ session: 'sync', context: 'full' });

    // Import LM Studio insights
    const insights = await this.importLMStudioInsights();

    console.log(`\n🎉 Sync completed!`);
    console.log(`   📤 Exported: ${Object.keys(exportData).length} data types`);
    console.log(`   📥 Imported: ${insights.length} insights`);

    return {
      export: exportData,
      import: insights
    };
  }

  getRecentActivity(aiId) {
    // Get recent tasks and knowledge shares for this AI
    const recentTasks = this.hub.taskQueue
      .filter(task => task.assignedTo === aiId)
      .slice(-3)
      .map(task => task.task);

    return recentTasks;
  }

  assessSystemHealth() {
    const status = this.hub.getCollaborationStatus();
    const health = {
      overall: 'healthy',
      issues: [],
      metrics: {}
    };

    if (status.activeAssistants < 3) {
      health.overall = 'degraded';
      health.issues.push('Low AI assistant activity');
    }

    if (status.pendingTasks > 10) {
      health.overall = 'stressed';
      health.issues.push('High task backlog');
    }

    health.metrics = {
      activeRatio: status.activeAssistants / status.totalAssistants,
      taskBacklog: status.pendingTasks,
      knowledgeGrowth: status.knowledgeEntries
    };

    return health;
  }

  calculateCollaborationMetrics() {
    return {
      crossAIKnowledge: this.hub.collaborationHistory.filter(h => h.type === 'knowledge-share').length,
      taskDistribution: Object.values(this.hub.aiAssistants).map(ai => ai.lastActive).sort().reverse(),
      knowledgeSharingRate: this.hub.collaborationHistory.length / Math.max(1, this.hub.collaborationHistory[0]?.timestamp ?
        (Date.now() - new Date(this.hub.collaborationHistory[0].timestamp).getTime()) / (1000 * 60) : 1)
    };
  }

  calculateTaskStatistics(tasks) {
    const completed = tasks.filter(t => t.status === 'completed');
    const pending = tasks.filter(t => t.status === 'queued');

    return {
      total: tasks.length,
      completed: completed.length,
      pending: pending.length,
      averageDuration: completed.length > 0 ?
        completed.reduce((sum, task) => sum + (task.duration || 0), 0) / completed.length : 0
    };
  }

  calculatePerformanceMetrics(tasks) {
    const aiPerformance = {};

    Object.keys(this.hub.aiAssistants).forEach(aiId => {
      const aiTasks = tasks.filter(t => t.assignedTo === aiId);
      const completed = aiTasks.filter(t => t.status === 'completed');

      aiPerformance[aiId] = {
        total: aiTasks.length,
        completed: completed.length,
        successRate: aiTasks.length > 0 ? completed.length / aiTasks.length : 0,
        averageDuration: completed.length > 0 ?
          completed.reduce((sum, task) => sum + (task.duration || 0), 0) / completed.length : 0
      };
    });

    return aiPerformance;
  }

  generateInsights() {
    const status = this.hub.getCollaborationStatus();
    const insights = [];

    if (status.activeAssistants === status.totalAssistants) {
      insights.push('Full AI team engagement detected');
    }

    if (status.knowledgeEntries > 5) {
      insights.push('Strong knowledge sharing patterns emerging');
    }

    insights.push('Cross-AI collaboration showing positive trends');

    return insights;
  }

  generateRecommendations() {
    return [
      'Consider expanding Go integration based on team expertise',
      'Increase knowledge sharing between specialized AIs',
      'Explore advanced workflow automation',
      'Develop performance optimization strategies'
    ];
  }

  generateNextSteps() {
    return [
      'Implement Go-based system monitoring prototype',
      'Test cross-language integration patterns',
      'Evaluate LM Studio insights for integration',
      'Plan next AI team collaboration session'
    ];
  }
}

// CLI Interface
async function main() {
  const args = process.argv.slice(2);
  const integration = new LMStudioIntegration();

  if (args[0] === 'export') {
    const options = {};
    if (args.includes('--session=daily')) options.session = 'daily';
    if (args.includes('--context=go-implementation')) options.context = 'go-implementation';

    await integration.exportKnowledge(options);
  }

  else if (args[0] === 'import') {
    await integration.importLMStudioInsights();
  }

  else if (args[0] === 'sync') {
    await integration.syncWithLMStudio();
  }

  else {
    console.log('🤖 **LM Studio Integration**\n');
    console.log('Usage:');
    console.log('  lm-studio-integration.js export                    - Export knowledge to LM Studio');
    console.log('  lm-studio-integration.js import                    - Import LM Studio insights');
    console.log('  lm-studio-integration.js sync                      - Full bidirectional sync\n');
    console.log('Options:');
    console.log('  --session=daily                                   - Mark as daily export');
    console.log('  --context=go-implementation                        - Export specific context');
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = LMStudioIntegration;
#!/usr/bin/env node
/**
 * Omarchy Ecosystem Auto-Startup Checker
 *
 * This script runs automatically on terminal startup and VSCode workspace open
 * to ensure the ecosystem is synchronized and ready for use.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class StartupChecker {
  constructor() {
    this.workspaceRoot = process.cwd();
    this.configDir = path.join(this.workspaceRoot, '.omarchy');
    this.statusFile = path.join(this.configDir, 'ecosystem-status.json');
    this.lastStartupFile = path.join(this.configDir, 'last-startup.json');
    this.startTime = new Date().toISOString();
  }

  async runStartupCheck() {
    // Only run if we're in the right workspace
    if (!this.isOmarchyWorkspace()) {
      return;
    }

    console.log('🔄 Omarchy Ecosystem Startup Check...');
    console.log(`📅 ${this.startTime}`);

    // Ensure config directory exists
    this.ensureConfigDir();

    // Load previous status
    const previousStatus = this.loadPreviousStatus();

    // Check if we need a full init
    if (this.needsFullInit(previousStatus)) {
      console.log('🚀 Running full ecosystem initialization...');
      await this.runFullInit();
    } else {
      console.log('⚡ Running quick status check...');
      await this.runQuickCheck(previousStatus);
    }

    // Save startup info
    this.saveStartupInfo();

    // Show current status
    this.showCurrentStatus();
  }

  isOmarchyWorkspace() {
    const indicators = [
      'omai.js',
      'package.json',
      'mcp-superagent-launcher.js',
      'ai-dashboard.sh'
    ];

    const foundIndicators = indicators.filter(file => fs.existsSync(file));
    return foundIndicators.length >= 2;
  }

  ensureConfigDir() {
    if (!fs.existsSync(this.configDir)) {
      fs.mkdirSync(this.configDir, { recursive: true });
    }
  }

  loadPreviousStatus() {
    try {
      if (fs.existsSync(this.statusFile)) {
        return JSON.parse(fs.readFileSync(this.statusFile, 'utf8'));
      }
    } catch (error) {
      // File might be corrupted
    }
    return null;
  }

  needsFullInit(previousStatus) {
    if (!previousStatus) {
      console.log('📋 No previous status found - running full init');
      return true;
    }

    // Check if last check was more than 1 hour ago
    if (previousStatus.lastCheck) {
      const lastCheck = new Date(previousStatus.lastCheck);
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

      if (lastCheck < oneHourAgo) {
        console.log('⏰ Status check overdue - running full init');
        return true;
      }
    }

    // Check if there were issues last time
    if (previousStatus.issues && previousStatus.issues.length > 0) {
      console.log('⚠️  Previous issues detected - running full init');
      return true;
    }

    return false;
  }

  async runFullInit() {
    try {
      // Run the full initialization
      const OmarchyEcosystem = require('./omarchy-init.js');
      const ecosystem = new OmarchyEcosystem();
      await ecosystem.initialize();
    } catch (error) {
      console.error('❌ Full initialization failed:', error.message);
    }
  }

  async runQuickCheck(previousStatus) {
    console.log('   🔍 Checking critical components...');

    // Quick component checks
    const criticalComponents = [
      { name: 'AI Assistant', file: 'omai.js' },
      { name: 'Token Tracker', file: 'token-tracker.js' },
      { name: 'Init System', file: 'omarchy-init.js' }
    ];

    let allGood = true;
    for (const component of criticalComponents) {
      if (fs.existsSync(component.file)) {
        console.log(`   ✅ ${component.name}`);
      } else {
        console.log(`   ❌ ${component.name} missing`);
        allGood = false;
      }
    }

    // Quick environment check
    try {
      execSync('node --version', { encoding: 'utf8' });
      console.log('   ✅ Node.js available');
    } catch (error) {
      console.log('   ❌ Node.js not available');
      allGood = false;
    }

    // Check environment file
    const envFile = '/home/zebadiee/.npm-global/bin/.env';
    if (fs.existsSync(envFile)) {
      console.log('   ✅ Environment configuration found');
    } else {
      console.log('   ⚠️  Environment configuration missing');
    }

    if (!allGood) {
      console.log('   🔧 Issues found, running full init...');
      await this.runFullInit();
    } else {
      console.log('   ✅ Quick check passed');
    }
  }

  saveStartupInfo() {
    const startupInfo = {
      startTime: this.startTime,
      workspaceRoot: this.workspaceRoot,
      nodeVersion: process.version,
      platform: process.platform
    };

    try {
      fs.writeFileSync(this.lastStartupFile, JSON.stringify(startupInfo, null, 2));
    } catch (error) {
      console.log('⚠️  Could not save startup info');
    }
  }

  showCurrentStatus() {
    try {
      if (fs.existsSync(this.statusFile)) {
        const status = JSON.parse(fs.readFileSync(this.statusFile, 'utf8'));

        console.log('\n📊 Current Ecosystem Status:');

        const componentCount = Object.keys(status.components || {}).length;
        const workingCount = Object.values(status.components || {})
          .filter(comp => comp.status === 'found').length;

        console.log(`   Components: ${workingCount}/${componentCount} operational`);

        if (status.issues && status.issues.length > 0) {
          console.log(`   Issues: ${status.issues.length} to resolve`);
        } else {
          console.log('   Status: 🟢 All systems operational');
        }

        // Show current model if available
        const envFile = '/home/zebadiee/.npm-global/bin/.env';
        if (fs.existsSync(envFile)) {
          const content = fs.readFileSync(envFile, 'utf8');
          const modelMatch = content.match(/OR_MODEL_[\d]=["']([^"']+)["']/);
          const indexMatch = content.match(/OR_CURRENT_MODEL_INDEX=["'](\d+)["']/);

          if (modelMatch && indexMatch) {
            const modelIndex = parseInt(indexMatch[1]);
            const modelVar = `OR_MODEL_${modelIndex + 1}`;
            const currentModelMatch = content.match(new RegExp(`${modelVar}=["']([^"']+)["']`));

            if (currentModelMatch) {
              console.log(`   Current Model: ${currentModelMatch[1]}`);
            }
          }
        }

        console.log('\n💡 Quick Commands:');
        console.log('   • AI Assistant: node omai.js "your prompt"');
        console.log('   • Token Usage: node omai.js --usage');
        console.log('   • Full Init: node omarchy-init.js');
        console.log('   • VSCode: Ctrl+Shift+P → "Tasks: Run Task" → "Omarchy"');
      }
    } catch (error) {
      console.log('⚠️  Could not load current status');
    }

    console.log('✨ Startup check complete!\n');
  }
}

// Auto-run if called directly
if (require.main === module) {
  const checker = new StartupChecker();
  checker.runStartupCheck().catch(error => {
    console.error('Startup check failed:', error.message);
    process.exit(1);
  });
}

module.exports = StartupChecker;
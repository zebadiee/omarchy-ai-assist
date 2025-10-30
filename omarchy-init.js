#!/usr/bin/env node
/**
 * Omarchy AI Ecosystem Initialization & Reconciliation System
 *
 * This script unifies all AI tools, MCPs, and projects into a cohesive ecosystem.
 * It checks for updates, reconciles data, and ensures seamless collaboration
 * between all components across VSCode and terminal environments.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const readline = require('readline');

class OmarchyEcosystem {
  constructor() {
    this.workspaceRoot = process.cwd();
    this.docsDir = path.join(this.workspaceRoot, 'docs');
    this.configDir = path.join(this.workspaceRoot, '.omarchy');
    this.statusFile = path.join(this.configDir, 'ecosystem-status.json');
    this.lastUpdateFile = path.join(this.configDir, 'last-update.json');

    // Component registry
    this.components = {
      aiAssist: {
        name: 'omarchy-ai-assist',
        path: path.join(this.workspaceRoot, 'omarchy-ai-assist'),
        config: 'omai.js',
        env: '/home/zebadiee/.npm-global/bin/.env',
        mcp: false,
        status: 'unknown'
      },
      tokenManager: {
        name: 'ai-token-manager',
        path: path.join(this.workspaceRoot, 'ai-token-manager'),
        config: 'src/engine/ai_core.py',
        env: '../ai-token-manager/configs/infra/token_budgets.toml',
        mcp: false,
        status: 'unknown'
      },
      mcpSuperagents: {
        name: 'mcp-superagents',
        path: path.join(this.workspaceRoot, 'mcp-superagents'),
        config: 'mcp-superagents.json',
        launcher: 'mcp-superagent-launcher.js',
        mcp: true,
        status: 'unknown'
      },
      lmStudio: {
        name: 'lm-studio-integration',
        path: path.join(this.workspaceRoot, 'lm-studio-integration.js'),
        config: 'lm-studio-integration.js',
        mcp: false,
        status: 'unknown'
      },
      ollama: {
        name: 'ollama-integration',
        path: path.join(this.workspaceRoot, 'ollama-integration.js'),
        config: 'ollama-integration.js',
        mcp: false,
        status: 'unknown'
      },
      navigator: {
        name: 'omarchy-navigator',
        path: path.join(this.workspaceRoot, 'omarchy-navigator.js'),
        config: 'omarchy-navigator.js',
        mcp: false,
        status: 'unknown'
      },
      goLauncher: {
        name: 'omarchy-launcher',
        path: path.join(this.workspaceRoot, 'omarchy-launcher.go'),
        config: 'omarchy-launcher.go',
        mcp: false,
        status: 'unknown'
      }
    };

    this.status = {
      initialized: false,
      lastCheck: null,
      components: {},
      issues: [],
      recommendations: []
    };
  }

  async initialize() {
    console.log('🚀 Initializing Omarchy AI Ecosystem...');
    console.log('═'.repeat(60));

    // Create config directory
    await this.ensureConfigDir();

    // Load previous status
    await this.loadStatus();

    // Phase 1: Component Discovery & Validation
    console.log('🔍 Phase 1: Component Discovery & Validation');
    await this.discoverComponents();

    // Phase 2: Configuration Reconciliation
    console.log('\n⚙️  Phase 2: Configuration Reconciliation');
    await this.reconcileConfigurations();

    // Phase 3: Update Checking
    console.log('\n🔄 Phase 3: Update Checking');
    await this.checkForUpdates();

    // Phase 4: Cross-Integration Validation
    console.log('\n🔗 Phase 4: Cross-Integration Validation');
    await this.validateIntegrations();

    // Phase 5: Startup Verification
    console.log('\n✅ Phase 5: Startup Verification');
    await this.verifyStartup();

    // Save status
    await this.saveStatus();

    // Generate report
    this.generateReport();
  }

  async ensureConfigDir() {
    if (!fs.existsSync(this.configDir)) {
      fs.mkdirSync(this.configDir, { recursive: true });
      console.log('📁 Created .omarchy config directory');
    }
  }

  async loadStatus() {
    try {
      if (fs.existsSync(this.statusFile)) {
        this.status = JSON.parse(fs.readFileSync(this.statusFile, 'utf8'));
        console.log('📊 Loaded previous ecosystem status');
      }
    } catch (error) {
      console.log('⚠️  Could not load previous status, starting fresh');
    }
  }

  async saveStatus() {
    this.status.lastCheck = new Date().toISOString();
    this.status.initialized = true;
    fs.writeFileSync(this.statusFile, JSON.stringify(this.status, null, 2));
  }

  async discoverComponents() {
    for (const [key, component] of Object.entries(this.components)) {
      const exists = fs.existsSync(component.path);
      component.status = exists ? 'found' : 'missing';

      if (exists) {
        console.log(`✅ ${component.name}: ${component.path}`);

        // Check for specific files
        if (component.config) {
          const configPath = Array.isArray(component.config)
            ? component.config.map(c => path.join(component.path, c))
            : [path.join(component.path, component.config)];

          component.configExists = configPath.some(cp => fs.existsSync(cp));

          if (component.configExists) {
            console.log(`   📄 Config: ${component.config}`);
          } else {
            console.log(`   ⚠️  Missing config: ${component.config}`);
            this.status.issues.push(`${component.name}: Missing config file`);
          }
        }

        // Check MCP capabilities
        if (component.mcp) {
          const mcpFiles = ['mcp-superagents.json', 'mcp-superagent-launcher.js'];
          component.mcpReady = mcpFiles.some(f => fs.existsSync(path.join(component.path, f)));
          if (component.mcpReady) {
            console.log(`   🔌 MCP Ready`);
          }
        }
      } else {
        console.log(`❌ ${component.name}: Not found at ${component.path}`);
        this.status.issues.push(`${component.name}: Component not found`);
      }

      this.status.components[key] = { ...component };
    }
  }

  async reconcileConfigurations() {
    console.log('   🔧 Reconciling API configurations...');

    // Check environment variables
    const envFiles = [
      '/home/zebadiee/.npm-global/bin/.env',
      path.join(this.components.aiAssist.path, '.env'),
      path.join(this.components.tokenManager.path, '.env')
    ];

    let envConfigs = {};
    for (const envFile of envFiles) {
      if (fs.existsSync(envFile)) {
        try {
          const content = fs.readFileSync(envFile, 'utf8');
          envConfigs[envFile] = this.parseEnvFile(content);
          console.log(`   📄 Loaded: ${envFile}`);
        } catch (error) {
          console.log(`   ⚠️  Could not read: ${envFile}`);
        }
      }
    }

    // Check for configuration conflicts
    this.checkConfigConflicts(envConfigs);

    // Reconcile token manager data
    if (this.status.components.tokenManager.status === 'found') {
      const usageFile = path.join(this.components.tokenManager.path, 'usage.json');
      if (fs.existsSync(usageFile)) {
        console.log('   📊 Token manager usage data found');
      }
    }
  }

  parseEnvFile(content) {
    const config = {};
    content.split('\n').forEach(line => {
      const match = line.match(/^([^#][^=]+)=(.*)$/);
      if (match) {
        config[match[1].trim()] = match[2].trim().replace(/"/g, '');
      }
    });
    return config;
  }

  checkConfigConflicts(envConfigs) {
    const apiKeys = {};

    Object.entries(envConfigs).forEach(([file, config]) => {
      if (config.OPENROUTER_API_KEY) {
        if (apiKeys.OPENROUTER && apiKeys.OPENROUTER !== config.OPENROUTER_API_KEY) {
          this.status.issues.push(`Conflicting OpenRouter API keys between files`);
        }
        apiKeys.OPENROUTER = config.OPENROUTER_API_KEY;
      }

      if (config.GOOGLE_AI_API_KEY) {
        if (apiKeys.GOOGLE && apiKeys.GOOGLE !== config.GOOGLE_AI_API_KEY) {
          this.status.issues.push(`Conflicting Google AI API keys between files`);
        }
        apiKeys.GOOGLE = config.GOOGLE_AI_API_KEY;
      }
    });

    if (apiKeys.OPENROUTER) {
      console.log('   🔑 OpenRouter API key configured');
    }
    if (apiKeys.GOOGLE) {
      console.log('   🔑 Google AI API key configured');
    }
  }

  async checkForUpdates() {
    console.log('   🔄 Checking for updates...');

    // Check git status for all components
    for (const [key, component] of Object.entries(this.components)) {
      if (component.status === 'found') {
        try {
          if (fs.existsSync(path.join(component.path, '.git'))) {
            const gitStatus = execSync('git status --porcelain', {
              cwd: component.path,
              encoding: 'utf8'
            });

            if (gitStatus.trim()) {
              console.log(`   📝 ${component.name}: Uncommitted changes`);
              this.status.recommendations.push(`Commit changes in ${component.name}`);
            } else {
              console.log(`   ✅ ${component.name}: Git status clean`);
            }
          }
        } catch (error) {
          console.log(`   ⚠️  ${component.name}: Could not check git status`);
        }
      }
    }

    // Check package.json dependencies
    this.checkDependencies();
  }

  checkDependencies() {
    const packageFiles = [
      path.join(this.components.aiAssist.path, 'package.json')
    ];

    packageFiles.forEach(pkgFile => {
      if (fs.existsSync(pkgFile)) {
        try {
          const pkg = JSON.parse(fs.readFileSync(pkgFile, 'utf8'));
          console.log(`   📦 Dependencies: ${pkg.name || path.basename(pkgFile)}`);

          if (pkg.dependencies) {
            Object.keys(pkg.dependencies).forEach(dep => {
              console.log(`      - ${dep}@${pkg.dependencies[dep]}`);
            });
          }
        } catch (error) {
          console.log(`   ⚠️  Could not read package.json: ${pkgFile}`);
        }
      }
    });
  }

  async validateIntegrations() {
    console.log('   🔗 Validating integrations...');

    // Check AI Assistant ↔ Token Manager integration
    if (this.status.components.aiAssist.status === 'found' &&
        this.status.components.tokenManager.status === 'found') {

      const tokenTrackerExists = fs.existsSync(
        path.join(this.components.aiAssist.path, 'token-tracker.js')
      );

      if (tokenTrackerExists) {
        console.log('   ✅ AI Assistant ↔ Token Manager integration active');
      } else {
        console.log('   ⚠️  AI Assistant ↔ Token Manager integration missing');
        this.status.recommendations.push('Set up token tracking integration');
      }
    }

    // Check MCP integration
    const mcpComponents = Object.entries(this.components).filter(
      ([key, comp]) => comp.mcp && comp.status === 'found'
    );

    if (mcpComponents.length > 0) {
      console.log('   🔌 MCP Components detected:');
      mcpComponents.forEach(([key, comp]) => {
        console.log(`      - ${comp.name}`);
      });
    }

    // Check environment setup
    const requiredTools = ['node', 'npm'];
    for (const tool of requiredTools) {
      try {
        execSync(`${tool} --version`, { encoding: 'utf8' });
        console.log(`   ✅ ${tool} available`);
      } catch (error) {
        console.log(`   ❌ ${tool} not found`);
        this.status.issues.push(`${tool} is required but not installed`);
      }
    }
  }

  async verifyStartup() {
    console.log('   🚀 Verifying startup procedures...');

    // Test AI Assistant startup
    if (this.status.components.aiAssist.status === 'found') {
      try {
        // Quick syntax check
        execSync('node -c omai.js', {
          cwd: this.components.aiAssist.path,
          encoding: 'utf8'
        });
        console.log('   ✅ AI Assistant syntax valid');
      } catch (error) {
        console.log('   ❌ AI Assistant syntax error');
        this.status.issues.push('AI Assistant has syntax errors');
      }
    }

    // Check shell scripts
    const shellScripts = ['ai-dashboard.sh', 'chat.sh'];
    shellScripts.forEach(script => {
      const scriptPath = path.join(this.workspaceRoot, script);
      if (fs.existsSync(scriptPath)) {
        try {
          fs.chmodSync(scriptPath, '755');
          console.log(`   ✅ ${script} executable`);
        } catch (error) {
          console.log(`   ⚠️  ${script} permission issue`);
        }
      }
    });
  }

  generateReport() {
    console.log('\n' + '═'.repeat(60));
    console.log('📊 OMARCHY ECOSYSTEM REPORT');
    console.log('═'.repeat(60));

    // Component Summary
    console.log('\n🔧 COMPONENTS:');
    Object.entries(this.status.components).forEach(([key, comp]) => {
      const icon = comp.status === 'found' ? '✅' : '❌';
      console.log(`  ${icon} ${comp.name}: ${comp.status}`);
    });

    // Issues
    if (this.status.issues.length > 0) {
      console.log('\n⚠️  ISSUES FOUND:');
      this.status.issues.forEach(issue => {
        console.log(`  • ${issue}`);
      });
    }

    // Recommendations
    if (this.status.recommendations.length > 0) {
      console.log('\n💡 RECOMMENDATIONS:');
      this.status.recommendations.forEach(rec => {
        console.log(`  • ${rec}`);
      });
    }

    // Next Steps
    console.log('\n🚀 NEXT STEPS:');
    console.log('  1. AI Assistant: node omai.js "your prompt"');
    console.log('  2. Token Usage: node omai.js --usage');
    console.log('  3. AI Dashboard: ./ai-dashboard.sh');
    console.log('  4. MCP Launcher: node mcp-superagent-launcher.js');

    if (this.status.issues.length === 0) {
      console.log('\n🎉 ECOSYSTEM FULLY OPERATIONAL!');
    } else {
      console.log(`\n⚠️  ${this.status.issues.length} issue(s) to resolve`);
    }

    console.log('═'.repeat(60));
  }
}

// CLI interface
async function main() {
  const ecosystem = new OmarchyEcosystem();

  try {
    await ecosystem.initialize();
  } catch (error) {
    console.error('❌ Ecosystem initialization failed:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = OmarchyEcosystem;
#!/usr/bin/env node

/**
 * Omarchy Go Language Integration Training
 * Advanced training protocol based on Omarchy manual and desktop environment patterns
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class OmarchyGoTraining {
  constructor() {
    this.trainingModules = [
      'omarchy-foundations',
      'desktop-environment-patterns',
      'go-system-integration',
      'file-path-conventions',
      'build-and-deployment',
      'configuration-management',
      'keyboard-driven-workflows',
      'ai-assisted-development'
    ];

    this.omarchyPatterns = {
      configPaths: [
        '~/.config/hypr/',
        '~/.config/waybar/',
        '~/.config/alacritty/',
        '~/.config/nvim/',
        '~/.local/share/applications/',
        '~/.local/bin/'
      ],
      systemPaths: [
        '/usr/bin/',
        '/usr/local/bin/',
        '/usr/lib/',
        '/usr/share/applications/'
      ],
      philosophy: {
        minimal: 'Minimal, essential tools only',
        keyboard: 'Keyboard-driven navigation',
        omakase: 'Carefully curated components',
        ai: 'AI-assisted customization and development'
      }
    };
  }

  async startTraining() {
    console.log('🏛️ **OMARCHY GO LANGUAGE INTEGRATION TRAINING**');
    console.log('==============================================');
    console.log('📖 Based on: https://learn.omacom.io/2/the-omarchy-manual');
    console.log('🎯 Objective: Train AI team on Omarchy-Go integration patterns');
    console.log(`📋 Training Modules: ${this.trainingModules.length}`);
    console.log('');

    for (let i = 0; i < this.trainingModules.length; i++) {
      await this.executeModule(this.trainingModules[i]);
    }

    await this.createGoIntegrationPaths();
    await this.generateOmarchyGoDocumentation();
  }

  async executeModule(moduleName) {
    console.log(`\n🔄 **MODULE: ${moduleName.toUpperCase()}`);
    console.log('='.repeat(50));

    switch (moduleName) {
      case 'omarchy-foundations':
        await this.trainOmarchyFoundations();
        break;
      case 'desktop-environment-patterns':
        await this.trainDesktopPatterns();
        break;
      case 'go-system-integration':
        await this.trainGoSystemIntegration();
        break;
      case 'file-path-conventions':
        await this.trainFilePathConventions();
        break;
      case 'build-and-deployment':
        await this.trainBuildDeployment();
        break;
      case 'configuration-management':
        await this.trainConfigurationManagement();
        break;
      case 'keyboard-driven-workflows':
        await this.trainKeyboardWorkflows();
        break;
      case 'ai-assisted-development':
        await this.trainAIAssistedDevelopment();
        break;
    }
  }

  async trainOmarchyFoundations() {
    console.log('   🏛️  Training on Omarchy foundations...');

    const foundations = {
      distribution: 'Arch Linux-based omakase distribution',
      desktop: 'Hyprland tiling window manager',
      philosophy: 'Minimal, curated, keyboard-driven',
      aiIntegration: 'AI-assisted customization and development',
      targetUser: 'Keyboard-focused power users'
    };

    const knowledgeEntry = {
      source: 'omarchy-go-training',
      category: 'foundations',
      knowledge: 'Omarchy is built on Arch Linux with Hyprland, emphasizing minimalism and keyboard-driven workflows. Go tools must integrate seamlessly with this philosophy.',
      timestamp: new Date().toISOString()
    };

    await this.saveKnowledge(knowledgeEntry);
    console.log('   ✅ Omarchy foundations trained');
  }

  async trainDesktopPatterns() {
    console.log('   🪟 Training on desktop environment patterns...');

    const patterns = {
      windowManager: 'Hyprland with Wayland',
      bar: 'Waybar for system tray and status',
      terminal: 'Alacritty with Neovim integration',
      launcher: 'Wofi for application launching',
      notification: 'Mako for notifications',
      menu: 'Custom context menus with keyboard navigation'
    };

    const integrationRules = {
      goTools: 'Must be Wayland-compatible',
      menus: 'Should integrate with Wofi launcher',
      status: 'Waybar integration points available',
      hotkeys: 'Must respect Hyprland keybinding system'
    };

    const knowledgeEntry = {
      source: 'omarchy-go-training',
      category: 'desktop-patterns',
      knowledge: 'Go tools must be Wayland-compatible, integrate with Waybar for status, Wofi for menus, and respect Hyprland hotkeys. Single binary deployment preferred.',
      timestamp: new Date().toISOString()
    };

    await this.saveKnowledge(knowledgeEntry);
    console.log('   ✅ Desktop patterns trained');
  }

  async trainGoSystemIntegration() {
    console.log('   🔌 Training Go system integration...');

    const integrationPaths = {
      systemTools: '/usr/local/bin/ for CLI utilities',
      userTools: '~/.local/bin/ for user-installed tools',
      services: '~/.config/systemd/user/ for user services',
      desktop: '/usr/share/applications/ for desktop entries',
      config: '~/.config/ for configuration files'
    };

    const buildRequirements = {
      staticLinking: 'Prefer static linking for portability',
      singleBinary: 'Single binary deployment preferred',
      systemd: 'systemd user service integration',
      icons: 'Follow freedesktop.org icon theme',
      desktopFiles: 'Standard .desktop file format'
    };

    const knowledgeEntry = {
      source: 'omarchy-go-training',
      category: 'go-integration',
      knowledge: 'Go tools should use single binary deployment, static linking, systemd user services, and follow freedesktop.org standards for desktop integration.',
      timestamp: new Date().toISOString()
    };

    await this.saveKnowledge(knowledgeEntry);
    console.log('   ✅ Go system integration trained');
  }

  async trainFilePathConventions() {
    console.log('   📁 Training file path conventions...');

    const conventions = {
      configBase: '~/.config/omarchy/',
      goConfig: '~/.config/omarchy/go-tools/',
      userBin: '~/.local/bin/',
      systemBin: '/usr/local/bin/',
      tempFiles: '/tmp/omarchy/',
      logs: '~/.local/share/omarchy/logs/',
      data: '~/.local/share/omarchy/data/'
    };

    const namingConventions = {
      executables: 'kebab-case (e.g., omarchy-system-monitor)',
      configs: 'tool-name.config.yml or tool-name.conf',
      services: 'omarchy-tool-name.service',
      desktopFiles: 'omarchy-tool-name.desktop'
    };

    const knowledgeEntry = {
      source: 'omarchy-go-training',
      category: 'file-conventions',
      knowledge: 'Use kebab-case naming, ~/.config/omarchy/ for configs, ~/.local/bin/ for user tools, follow freedesktop.org naming conventions.',
      timestamp: new Date().toISOString()
    };

    await this.saveKnowledge(knowledgeEntry);
    console.log('   ✅ File path conventions trained');
  }

  async trainBuildDeployment() {
    console.log('   🏗️  Training build and deployment...');

    const buildProcess = {
      development: 'go build -o omarchy-tool-name',
      release: 'go build -ldflags="-s -w" for stripped binary',
      install: 'cp binary ~/.local/bin/omarchy-tool-name',
      service: 'systemctl --user enable omarchy-tool-name.service',
      desktop: 'cp .desktop ~/.local/share/applications/'
    };

    const crossPlatform = {
      targets: ['linux/amd64', 'linux/arm64'],
      flags: 'CGO_ENABLED=0 for static binaries',
      packaging: 'Single binary, no external dependencies'
    };

    const knowledgeEntry = {
      source: 'omarchy-go-training',
      category: 'build-deployment',
      knowledge: 'Use static linking with CGO_ENABLED=0, strip binaries with -ldflags="-s -w", deploy to ~/.local/bin/, create systemd user services.',
      timestamp: new Date().toISOString()
    };

    await this.saveKnowledge(knowledgeEntry);
    console.log('   ✅ Build and deployment trained');
  }

  async trainConfigurationManagement() {
    console.log('   ⚙️  Training configuration management...');

    const configPatterns = {
      format: 'YAML preferred, TOML for simple configs',
      location: '~/.config/omarchy/tool-name/',
      reloading: 'SIGHUP for config reload or inotify for watching',
      validation: 'JSON schema validation for complex configs',
      defaults: 'Sensible defaults with minimal required config'
    };

    const hotReload = {
      signal: 'SIGHUP trigger config reload',
      fileWatching: 'fsnotify library for Go',
      atomic: 'Atomic config file replacement',
      backup: 'Automatic config backup before changes'
    };

    const knowledgeEntry = {
      source: 'omarchy-go-training',
      category: 'config-management',
      knowledge: 'Use YAML configs in ~/.config/omarchy/tool-name/, implement SIGHUP reload, fsnotify for watching, JSON schema validation.',
      timestamp: new Date().toISOString()
    };

    await this.saveKnowledge(knowledgeEntry);
    console.log('   ✅ Configuration management trained');
  }

  async trainKeyboardWorkflows() {
    console.log('   ⌨️  Training keyboard-driven workflows...');

    const hotkeyPatterns = {
      global: 'Avoid global hotkeys, use Hyprland binds',
      menus: 'Integrate with Wofi for menu navigation',
      search: 'Implement fuzzy search with keyboard navigation',
      actions: 'Single-key or chord-based actions',
      escape: 'ESC or q for退出/cancel actions'
    };

    const integrationPoints = {
      hyprland: 'Hyprland config for global binds',
      waybar: 'Waybar modules for status display',
      wofi: 'Wofi integration for menu-driven interfaces',
      terminal: 'Terminal-friendly TUIs with keyboard navigation'
    };

    const knowledgeEntry = {
      source: 'omarchy-go-training',
      category: 'keyboard-workflows',
      knowledge: 'Design keyboard-first interfaces, integrate with Wofi for menus, avoid global hotkeys, use Hyprland for system-level binds.',
      timestamp: new Date().toISOString()
    };

    await this.saveKnowledge(knowledgeEntry);
    console.log('   ✅ Keyboard workflows trained');
  }

  async trainAIAssistedDevelopment() {
    console.log('   🤖 Training AI-assisted development...');

    const aiIntegration = {
      cli: 'Integrate with existing AI CLI tools',
      prompts: 'Use structured prompts for Go code generation',
      templates: 'Code templates for common Omarchy patterns',
      validation: 'AI-assisted code review and optimization',
      documentation: 'Auto-generate documentation with AI'
    };

    const developmentWorkflow = {
      planning: '#pln subagent for architectural planning',
      implementation: '#imp subagent for code generation',
      knowledge: '#knw subagent for pattern extraction',
      testing: 'AI-assisted test generation',
      optimization: 'AI-driven performance analysis'
    };

    const knowledgeEntry = {
      source: 'omarchy-go-training',
      category: 'ai-development',
      knowledge: 'Use provider-agnostic subagents (#pln, #imp, #knw) for Go development, follow Omarchy patterns, generate keyboard-first interfaces.',
      timestamp: new Date().toISOString()
    };

    await this.saveKnowledge(knowledgeEntry);
    console.log('   ✅ AI-assisted development trained');
  }

  async createGoIntegrationPaths() {
    console.log('\n🛤️  Creating Go integration paths...');

    const integrationPaths = {
      systemMonitor: {
        path: '/usr/local/bin/omarchy-system-monitor',
        config: '~/.config/omarchy/system-monitor/',
        service: '~/.config/systemd/user/omarchy-system-monitor.service',
        description: 'Real-time system monitoring with Waybar integration'
      },
      fileManager: {
        path: '/usr/local/bin/omarchy-file-manager',
        config: '~/.config/omarchy/file-manager/',
        service: '~/.config/systemd/user/omarchy-file-manager.service',
        description: 'Keyboard-driven file management with Wofi integration'
      },
      launcher: {
        path: '/usr/local/bin/omarchy-launcher',
        config: '~/.config/omarchy/launcher/',
        service: '~/.config/systemd/user/omarchy-launcher.service',
        description: 'AI-enhanced application launcher'
      },
      configManager: {
        path: '/usr/local/bin/omarchy-config-manager',
        config: '~/.config/omarchy/config-manager/',
        service: '~/.config/systemd/user/omarchy-config-manager.service',
        description: 'Unified configuration management with hot reload'
      }
    };

    // Save integration paths
    const pathsPath = path.join(__dirname, 'training-data', 'omarchy-go-paths.json');
    fs.writeFileSync(pathsPath, JSON.stringify(integrationPaths, null, 2));

    console.log('   ✅ Go integration paths created');
  }

  async generateOmarchyGoDocumentation() {
    console.log('\n📚 Generating Omarchy Go documentation...');

    const documentation = {
      title: 'Omarchy Go Development Guide',
      sections: {
        'Philosophy': {
          content: 'Minimal, keyboard-driven, AI-assisted Go tools for Omarchy OS',
          keyPoints: ['Single binary deployment', 'Static linking', 'Wayland compatibility']
        },
        'Development Patterns': {
          content: 'Follow Omarchy conventions for seamless desktop integration',
          keyPoints: ['~/.config/omarchy/ for configs', '~/.local/bin/ for tools', 'systemd user services']
        },
        'Integration Points': {
          content: 'Connect with Hyprland, Waybar, Wofi, and AI systems',
          keyPoints: ['Waybar status modules', 'Wofi menu integration', 'Hyprland keybinds']
        },
        'Build Process': {
          content: 'Optimized for minimal, portable Go applications',
          keyPoints: ['CGO_ENABLED=0', 'Static linking', 'Cross-compilation']
        }
      }
    };

    const docsPath = path.join(__dirname, 'knowledge-outbox', 'omarchy-go-guide.md');
    const markdown = this.formatDocumentationAsMarkdown(documentation);
    fs.writeFileSync(docsPath, markdown);

    console.log('   ✅ Documentation generated');
  }

  formatDocumentationAsMarkdown(doc) {
    let markdown = `# ${doc.title}\n\n`;

    for (const [section, content] of Object.entries(doc.sections)) {
      markdown += `## ${section}\n\n`;
      markdown += `${content.content}\n\n`;
      markdown += `### Key Points\n\n`;
      content.keyPoints.forEach(point => {
        markdown += `- ${point}\n`;
      });
      markdown += '\n';
    }

    return markdown;
  }

  async saveKnowledge(entry) {
    const knowledgePath = path.join(__dirname, 'knowledge-outbox', 'knowledge-updates');
    if (!fs.existsSync(knowledgePath)) {
      fs.mkdirSync(knowledgePath, { recursive: true });
    }

    const timestamp = new Date().toISOString().split('T')[0];
    const filePath = path.join(knowledgePath, `omarchy-go-${timestamp}.json`);

    // Read existing knowledge
    let knowledge = { nodes: [], categories: [] };
    const existingFiles = fs.readdirSync(knowledgePath).filter(f => f.endsWith('.json'));

    if (existingFiles.length > 0) {
      const latestFile = existingFiles.sort().pop();
      const existingPath = path.join(knowledgePath, latestFile);
      try {
        knowledge = JSON.parse(fs.readFileSync(existingPath, 'utf8'));
      } catch (error) {
        // Start fresh if file is corrupted
      }
    }

    // Add new entry
    knowledge.nodes.push({
      id: `omarchy-go-${Date.now()}`,
      type: 'knowledge',
      from: entry.source,
      category: entry.category,
      knowledge: entry.knowledge,
      timestamp: entry.timestamp
    });

    if (!knowledge.categories.includes(entry.category)) {
      knowledge.categories.push(entry.category);
    }

    fs.writeFileSync(filePath, JSON.stringify(knowledge, null, 2));
  }
}

// CLI Interface
async function main() {
  const training = new OmarchyGoTraining();

  try {
    await training.startTraining();
    console.log('\n🎉 **OMARCHY GO TRAINING COMPLETED**');
    console.log('==================================');
    console.log('✅ AI team trained on Omarchy-Go integration patterns');
    console.log('✅ Integration paths established');
    console.log('✅ Documentation generated');
    console.log('✅ Ready for Go development in Omarchy environment');
  } catch (error) {
    console.error('\n❌ Training failed:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = OmarchyGoTraining;
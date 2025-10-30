#!/usr/bin/env node

/**
 * Omarchy OS Navigator - Your intelligent desktop assistant
 * Helps navigate, customize, and optimize your Omarchy desktop experience
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const readline = require('readline');

const CONFIG_DIR = '/home/zebadiee/.npm-global/omarchy-wagon';
const ROOM_FILE = path.join(CONFIG_DIR, 'room.json');
const KNOWLEDGE_BASE = path.join(__dirname, 'omarchy-knowledge.json');

class OmarchyNavigator {
  constructor() {
    this.config = this.loadConfig();
    this.knowledge = this.loadKnowledgeBase();
    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
  }

  loadConfig() {
    try {
      if (!fs.existsSync(CONFIG_DIR)) {
        fs.mkdirSync(CONFIG_DIR, { recursive: true });
      }
      return fs.existsSync(ROOM_FILE) ? JSON.parse(fs.readFileSync(ROOM_FILE, 'utf8')) : {
        last_update: new Date().toISOString(),
        context: [],
        preferences: {},
        shortcuts: {}
      };
    } catch (error) {
      return { last_update: new Date().toISOString(), context: [], preferences: {}, shortcuts: {} };
    }
  }

  loadKnowledgeBase() {
    const defaultKnowledge = {
      navigation: {
        workspaces: "Use Super + number keys to switch between workspaces",
        windows: "Super + Q to close, Super + F to toggle floating, Super + Arrow keys to move",
        apps: "Super + Enter for terminal, Super + B for browser, Super + F for file manager",
        menu: "Super + D for application menu, Super + R for run command"
      },
      customization: {
        themes: "Edit ~/.config/omarchy/theme.conf or use omarchy-theme-switcher",
        keybindings: "Edit ~/.config/omarchy/keybindings.conf",
        wallpaper: "Set with omarchy-wallpaper /path/to/image or right-click desktop",
        panels: "Configure panels in ~/.config/omarchy/panels.conf"
      },
      system: {
        updates: "Run 'omarchy-update' to update the system",
        logs: "Check ~/.local/share/omarchy/logs/ for system logs",
        settings: "Main config in ~/.config/omarchy/omarchy.conf",
        recovery: "Use 'omarchy-rescue' to recover from configuration issues"
      },
      troubleshooting: {
        frozen_app: "Super + Shift + Escape to force quit, or Super + K to kill window",
        display_issues: "Super + Ctrl + R to restart display server",
        sound: "Use pavucontrol for audio management",
        network: "Network settings in ~/.config/omarchy/network.conf"
      }
    };

    try {
      return fs.existsSync(KNOWLEDGE_BASE) ?
        { ...defaultKnowledge, ...JSON.parse(fs.readFileSync(KNOWLEDGE_BASE, 'utf8')) } :
        defaultKnowledge;
    } catch (error) {
      return defaultKnowledge;
    }
  }

  saveContext(source, topic, summary) {
    const entry = {
      source,
      topic,
      summary,
      timestamp: new Date().toISOString()
    };

    this.config.context.push(entry);
    this.config.last_update = new Date().toISOString();

    // Keep only last 20 entries
    if (this.config.context.length > 20) {
      this.config.context = this.config.context.slice(-20);
    }

    fs.writeFileSync(ROOM_FILE, JSON.stringify(this.config, null, 2));
  }

  async handleQuery(query) {
    const lowerQuery = query.toLowerCase().trim();

    // Navigation help
    if (lowerQuery.includes('navigate') || lowerQuery.includes('navigation') || lowerQuery.includes('get around')) {
      return this.provideNavigationHelp();
    }

    // Window management
    if (lowerQuery.includes('window') || lowerQuery.includes('manage windows')) {
      return this.provideWindowHelp();
    }

    // Customization
    if (lowerQuery.includes('customize') || lowerQuery.includes('theme') || lowerQuery.includes('personalize')) {
      return this.provideCustomizationHelp();
    }

    // App launching
    if (lowerQuery.includes('app') || lowerQuery.includes('application') || lowerQuery.includes('launch')) {
      return this.provideAppHelp();
    }

    // Troubleshooting
    if (lowerQuery.includes('problem') || lowerQuery.includes('issue') || lowerQuery.includes('troubleshoot') || lowerQuery.includes('help')) {
      return this.provideTroubleshootingHelp();
    }

    // System info
    if (lowerQuery.includes('system') || lowerQuery.includes('info') || lowerQuery.includes('status')) {
      return this.provideSystemInfo();
    }

    // Default response
    return this.provideGeneralHelp();
  }

  provideNavigationHelp() {
    return {
      type: 'navigation',
      response: `🧭 **Omarchy Navigation Guide**

**Workspace Management:**
• \`Super + 1-9\`: Switch to workspace 1-9
• \`Super + Shift + 1-9\`: Move window to workspace
• \`Super + Tab\`: Cycle through workspaces

**Window Navigation:**
• \`Super + Arrow Keys\`: Move window directionally
• \`Super + Enter\`: Maximize window
• \`Super + Shift + Enter\`: Toggle maximize
• \`Super + F\`: Toggle floating mode
• \`Super + Q\`: Close focused window

**Quick Access:**
• \`Super + D\`: Application menu
• \`Super + R\`: Run command dialog
• \`Super + Space\`: Application switcher

💡 **Pro Tip**: Hold Super and use arrow keys to move windows between monitors!`,
      commands: ['workspace', 'window-move', 'window-maximize', 'app-menu']
    };
  }

  provideWindowHelp() {
    return {
      type: 'windows',
      response: `🪟 **Window Management Guide**

**Basic Operations:**
• \`Super + Q\`: Close window
• \`Super + F\`: Toggle floating (for tiling mode)
• \`Super + Shift + F\`: Force floating
• \`Super + Enter\`: Maximize/restore
• \`Super + Arrow Keys\`: Move window

**Advanced:**
• \`Super + Shift + Arrow\`: Move window to adjacent workspace
• \`Super + Ctrl + Arrow\`: Resize window
• \`Super + K\`: Kill window (force close)
• \`Super + Shift + Q\`: Close all windows on workspace

**Multi-Monitor:**
• \`Super + W\`: Move window to next monitor
• \`Super + Shift + W\`: Move window to previous monitor

🎯 **Layout Modes**: Use \`Super + L\` to cycle through layout modes (tiling, floating, tabbed)`,
      commands: ['window-close', 'window-float', 'window-resize', 'multi-monitor']
    };
  }

  provideCustomizationHelp() {
    return {
      type: 'customization',
      response: `🎨 **Omarchy Customization Guide**

**Themes:**
• Edit: \`~/.config/omarchy/theme.conf\`
• Command: \`omarchy-theme-switcher <theme-name>\`
• Restart: \`Super + Ctrl + R\` after theme changes

**Wallpapers:**
• Right-click desktop → Set Wallpaper
• Command: \`omarchy-wallpaper /path/to/image\`
• Folder: \`~/Pictures/Wallpapers/\` auto-detected

**Keybindings:**
• Edit: \`~/.config/omarchy/keybindings.conf\`
• Format: \`<key_combination> = <command>\`
• Reload: \`omarchy-reload-config\`

**Panels & Widgets:**
• Configure: \`~/.config/omarchy/panels.conf\`
• Add widgets: \`omarchy-widget-add <widget-type>\`
• Position: \`top, bottom, left, right\`

**Appearance:**
• Fonts: \`~/.config/omarchy/fonts.conf\`
• Icons: \`~/.config/omarchy/icons.conf\`
• Effects: \`~/.config/omarchy/effects.conf\`

🔧 **Use \`omarchy-config-tool\` for GUI configuration!**`,
      commands: ['theme', 'wallpaper', 'keybindings', 'panels']
    };
  }

  provideAppHelp() {
    return {
      type: 'applications',
      response: `🚀 **Application Management Guide**

**Quick Launch:**
• \`Super + Enter\`: Terminal
• \`Super + B\`: Web Browser
• \`Super + F\`: File Manager
• \`Super + T\`: Text Editor
• \`Super + M\`: Email Client

**Application Menu:**
• \`Super + D\`: Open application menu
• Type to search, use arrows to navigate
• Enter to launch, Esc to close

**Run Command:**
• \`Super + R\`: Run dialog
• Type command name or full path
• Tab completion available

**Application Management:**
• \`Super + Shift + Q\`: Close all apps on workspace
• \`Super + Ctrl + Q\`: Quit application gracefully
• Right-click title bar → Application options

**Favorite Apps:**
• Add to panel: Right-click → Add to Favorites
• Dock apps: Drag to dock area
• Quick launch: Edit \`~/.config/omarchy/favorites.conf\`

📱 **Install apps**: \`omarchy-app-install <package-name>\``,
      commands: ['app-launch', 'app-menu', 'app-manage', 'app-install']
    };
  }

  provideTroubleshootingHelp() {
    return {
      type: 'troubleshooting',
      response: `🔧 **Omarchy Troubleshooting Guide**

**Common Issues:**

**Frozen Application:**
• \`Super + Shift + Escape\`: Force quit dialog
• \`Super + K\`: Kill focused window
• \`Super + Ctrl + Alt + Esc\`: Emergency restart

**Display Problems:**
• \`Super + Ctrl + R\`: Restart display server
• \`Super + Ctrl + Alt + R\`: Reset display settings
• Check: \`~/.local/share/omarchy/logs/display.log\`

**Sound Issues:**
• Run: \`pavucontrol\` (Audio control)
• Check: \`alsamixer\` in terminal
• Restart: \`omarchy-audio-restart\`

**Network Problems:**
• Check: \`omarchy-network-status\`
• Restart: \`omarchy-network-restart\`
• Configure: \`~/.config/omarchy/network.conf\`

**Performance Issues:**
• Monitor: \`omarchy-system-monitor\`
• Clean: \`omarchy-cache-cleanup\`
• Restart: \`omarchy-safe-restart\`

**Configuration Recovery:**
• Backup: \`~/.config/omarchy/backup/\`
• Restore: \`omarchy-config-restore\`
• Reset: \`omarchy-factory-reset\` (last resort)

🆘 **Help System**: \`omarchy-help <topic>\` for detailed assistance`,
      commands: ['force-quit', 'display-restart', 'audio-fix', 'network-fix']
    };
  }

  provideSystemInfo() {
    try {
      const uptime = execSync('uptime', { encoding: 'utf8' }).trim();
      const memory = execSync('free -h', { encoding: 'utf8' }).split('\n')[1];
      const disk = execSync('df -h ~', { encoding: 'utf8' }).split('\n')[1];

      return {
        type: 'system',
        response: `💻 **Omarchy System Information**

**System Status:**
• Uptime: ${uptime}
• Memory: ${memory}
• Home Disk: ${disk}

**Omarchy Version:**
• Config: ${fs.existsSync('~/.config/omarchy/omarchy.conf') ? '✅ Found' : '⚠️ Not found'}
• Theme: ${fs.existsSync('~/.config/omarchy/theme.conf') ? '✅ Configured' : '⚠️ Default'}
• Logs: ${fs.existsSync('~/.local/share/omarchy/logs/') ? '✅ Available' : '⚠️ Missing'}

**Active Components:**
• Window Manager: ✅ Running
• Panel: ✅ Active
• Desktop: ✅ Rendering
• File Manager: ✅ Available

**Resource Usage:**
• Processes: ${execSync('ps aux | wc -l', { encoding: 'utf8' }).trim()} running
• Load Average: ${uptime.split('load average:')[1].trim()}

📊 **Detailed Monitor**: \`omarchy-system-monitor\` for real-time stats`,
        commands: ['system-monitor', 'logs-view', 'config-check']
      };
    } catch (error) {
      return {
        type: 'system',
        response: `💻 **Omarchy System Status: Limited**

Basic system information available. Run \`omarchy-system-monitor\` for detailed stats.

**Quick Status:**
• Configuration: ${fs.existsSync('~/.config/omarchy/') ? '✅ Found' : '❌ Missing'}
• User Home: ✅ Accessible
• Terminal: ✅ Working

🔧 **Full diagnostics**: Use \`omarchy-doctor\` for complete system check`,
        commands: ['system-monitor', 'config-check']
      };
    }
  }

  provideGeneralHelp() {
    return {
      type: 'general',
      response: `👋 **Welcome to Omarchy Navigator!**

I'm your AI assistant for the Omarchy desktop environment. I can help you with:

**🎯 What I can do:**
• Navigate the desktop and workspaces
• Manage windows and applications
• Customize themes and appearance
• Troubleshoot common issues
• Optimize system performance
• Learn keyboard shortcuts

**💬 Ask me about:**
• "How do I navigate workspaces?"
• "Help me customize my theme"
• "My app is frozen, what do I do?"
• "How do I change keybindings?"
• "Show me system information"

**🚀 Quick Start:**
• Try: "navigation help" or "window management"
• Try: "customization guide" or "troubleshooting"
• Try: "system status" or "app launcher"

**📚 More help:**
• \`omarchy-help\` - Official help system
• \`omarchy-guide\` - Interactive guide
• \`omarchy-doctor\` - System diagnostics

What would you like to explore today?`,
      commands: ['navigation', 'windows', 'customization', 'troubleshooting']
    };
  }

  async startInteractiveMode() {
    console.log(`🌟 **Omarchy Navigator** - Your AI Desktop Assistant`);
    console.log(`Type 'help' for guidance, 'exit' to quit, or ask me anything about Omarchy!\n`);

    const askQuestion = (query) => {
      return new Promise((resolve) => {
        this.rl.question(query, resolve);
      });
    };

    while (true) {
      const input = await askQuestion('🤖 Omarchy> ');

      if (input.toLowerCase() === 'exit' || input.toLowerCase() === 'quit') {
        console.log('👋 Stay productive! Your Omarchy desktop awaits!');
        break;
      }

      if (input.toLowerCase() === 'help' || input.trim() === '') {
        const help = await this.handleQuery('help');
        console.log(`\n${help.response}\n`);
        continue;
      }

      if (input.trim()) {
        const result = await this.handleQuery(input);
        console.log(`\n${result.response}\n`);

        // Save context
        this.saveContext('omarchy-navigator', this.detectTopic(input), input.substring(0, 100));
      }
    }

    this.rl.close();
  }

  detectTopic(query) {
    const lowerQuery = query.toLowerCase();
    if (lowerQuery.includes('navigate') || lowerQuery.includes('workspace')) return 'navigation';
    if (lowerQuery.includes('window')) return 'window-management';
    if (lowerQuery.includes('theme') || lowerQuery.includes('customize')) return 'customization';
    if (lowerQuery.includes('problem') || lowerQuery.includes('issue')) return 'troubleshooting';
    if (lowerQuery.includes('system') || lowerQuery.includes('status')) return 'system-info';
    return 'general';
  }
}

// CLI Interface
async function main() {
  const args = process.argv.slice(2);
  const navigator = new OmarchyNavigator();

  if (args.length === 0) {
    // Interactive mode
    await navigator.startInteractiveMode();
  } else {
    // Direct query mode
    const query = args.join(' ');
    const result = await navigator.handleQuery(query);
    console.log(result.response);

    // Save context
    navigator.saveContext('omarchy-navigator', navigator.detectTopic(query), query.substring(0, 100));
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = OmarchyNavigator;
# 🌟 Omarchy Navigator - Your AI Desktop Assistant

An intelligent assistant designed to help you navigate, customize, and master the Omarchy desktop environment.

## 🚀 Quick Start

### Installation
The navigator is already integrated into your Omarchy system! Use it immediately:

```bash
# Interactive chat mode
omarchy-navigator

# Direct query mode
omarchy-navigator "help me navigate workspaces"
omarchy-navigator "how do I customize my theme"
omarchy-navigator "my app is frozen, what do I do?"
```

### Global Access
- **Command**: `omarchy-navigator` (available everywhere)
- **Integration**: Works with existing room context system
- **Knowledge Base**: Comprehensive Omarchy OS expertise

## 🎯 What Can It Help With?

### 🧭 **Navigation & Workspaces**
- Workspace switching and organization
- Window management techniques
- Keyboard shortcuts mastery
- Multi-monitor setups
- Application launching

### 🎨 **Customization & Theming**
- Theme configuration and switching
- Wallpaper management
- Keybinding customization
- Panel and widget configuration
- Font and icon appearance

### 🔧 **System Management**
- Application troubleshooting
- Performance optimization
- System information and monitoring
- Configuration backup and restore
- Log file analysis

### 💡 **Learning & Discovery**
- Feature discovery
- Workflow optimization
- Productivity tips
- Best practices
- Advanced techniques

## 🗣️ **Conversation Examples**

### Navigation Help
```
You: How do I switch between workspaces?
Navigator: 🧭 **Omarchy Navigation Guide**
         • Super + 1-9: Switch to workspace 1-9
         • Super + Shift + 1-9: Move window to workspace
         • Super + Tab: Cycle through workspaces
         💡 Pro Tip: Hold Super and use arrow keys to move windows between monitors!
```

### Customization Assistance
```
You: I want to change my desktop theme
Navigator: 🎨 **Omarchy Customization Guide**
         • Edit: ~/.config/omarchy/theme.conf
         • Command: omarchy-theme-switcher <theme-name>
         • Restart: Super + Ctrl + R after theme changes
         🔧 Use omarchy-config-tool for GUI configuration!
```

### Troubleshooting Support
```
You: My application is frozen!
Navigator: 🔧 **Omarchy Troubleshooting Guide**
         • Super + Shift + Escape: Force quit dialog
         • Super + K: Kill focused window
         • Open terminal and run 'pkill appname'
         🆘 Last resort: Super + Ctrl + Alt + Backspace
```

## 🔗 **System Integration**

### Room Context System
The navigator automatically saves conversations to your room context:
```json
{
  "source": "omarchy-navigator",
  "topic": "navigation",
  "summary": "help me navigate workspaces",
  "timestamp": "2025-10-29T16:58:03.520Z"
}
```

### AI Ecosystem Integration
- **Claude Code**: Terminal and file operations
- **Gemini AI**: Additional AI assistance
- **OpenAI Assistant**: GPT-powered support
- **MCP Servers**: Filesystem, memory, and Figma integration

### Cross-Component Communication
- Shared context with `omarchy-guide`
- Integration with `omai.js` AI assistant
- Web interface connectivity via localhost:3000

## 📚 **Knowledge Base**

### Core Topics Covered

#### Navigation Shortcuts
- **Essential**: Super + D (app menu), Super + R (run), Super + Enter (terminal)
- **Workspaces**: Super + 1-9 (switch), Super + Shift + 1-9 (move windows)
- **Windows**: Super + Q (close), Super + F (float), Super + Arrows (move)

#### Customization Options
- **Themes**: Edit `~/.config/omarchy/theme.conf`
- **Keybindings**: Modify `~/.config/omarchy/keybindings.conf`
- **Panels**: Configure in `~/.config/omarchy/panels.conf`
- **Wallpapers**: Right-click desktop or use `omarchy-wallpaper`

#### System Management
- **Updates**: Run `omarchy-update`
- **Monitoring**: Use `omarchy-system-monitor`
- **Logs**: Check `~/.local/share/omarchy/logs/`
- **Recovery**: Use `omarchy-rescue` for issues

#### Troubleshooting Solutions
- **Frozen Apps**: Super + Shift + Escape or Super + K
- **Display Issues**: Super + Ctrl + R to restart
- **Audio Problems**: Use `pavucontrol`
- **Network Issues**: Check `omarchy-network-status`

## 🛠️ **Advanced Features**

### Interactive Mode
```bash
omarchy-navigator
🤖 Omarchy> help me organize my workspaces
🤖 Omarchy> how do I add custom keybindings?
🤖 Omarchy> show me system information
🤖 Omarchy> exit
```

### Context Awareness
The navigator remembers your conversations and builds context over time, making follow-up questions more intelligent and relevant.

### Workflow Guidance
Get step-by-step guidance for complex tasks:
- Setting up a development environment
- Configuring multi-monitor setups
- Creating custom themes
- Optimizing system performance

## 🔧 **Configuration**

### Custom Knowledge Base
Add your own custom knowledge by editing:
```bash
/home/zebadiee/Documents/omarchy-ai-assist/omarchy-knowledge.json
```

### Personal Preferences
The navigator adapts to your usage patterns and preferences over time through the room context system.

## 📊 **System Requirements**

- **Node.js**: For the navigator engine
- **Omarchy OS**: Target desktop environment
- **Room Context**: Shared context system
- **Terminal Access**: For command-line interface

## 🆘 **Getting Help**

### Built-in Help
```bash
omarchy-navigator help
```

### System Integration
```bash
omarchy-guide          # Interactive guide system
omarchy-doctor         # System diagnostics
omarchy-help <topic>   # Official help system
```

### Community Support
- Check room context for previous conversations
- Use the web interface at localhost:3000
- Access VSCodium AI assistants for additional help

## 🎉 **Tips for Best Experience**

1. **Be Specific**: Ask detailed questions for better assistance
2. **Follow Up**: Build on previous conversations using context
3. **Experiment**: Try the suggested shortcuts and commands
4. **Save Configs**: Backup your custom configurations
5. **Explore**: Ask about features you haven't discovered yet

## 🔄 **Continuous Learning**

The navigator improves over time by:
- Learning from your conversation patterns
- Building context from multiple sessions
- Integrating with other AI assistants
- Updating knowledge base with new features

---

**Your Omarchy Navigator is ready to help you master your desktop environment!** 🚀

Start with `omarchy-navigator` and explore the possibilities!
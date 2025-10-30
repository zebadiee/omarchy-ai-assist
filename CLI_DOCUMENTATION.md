# 🤖 Omarchy AI CLI Documentation

**Version:** 1.0.0
**Last Updated:** 2025-10-29
**Status:** ✅ **FULLY OPERATIONAL**

---

## 🎯 Overview

The Omarchy AI CLI system provides **provider-agnostic AI subagent workflows** that work seamlessly with multiple AI providers (LM Studio, Ollama, OpenRouter, OpenAI) through a unified command-line interface.

### 🚀 Key Features
- **Multi-Provider Support:** Works with LM Studio, Ollama, OpenRouter, OpenAI
- **Specialized Subagents:** Planner, Implementor, Knowledge extraction
- **Terminal Integration:** Native CLI experience with aliases
- **VS Code Integration:** Keybindings and tasks
- **Headless Operation:** systemd service support
- **Automatic Fallback:** Intelligent provider switching

---

## 🛠️ Installation & Setup

### 1. Quick Start
```bash
# Clone/extract the tools directory
cd /path/to/omarchy-ai-assist

# Load AI aliases
source tools/ai_aliases.sh

# Check system status
ai_check

# Start using AI subagents
pln "Plan a new feature implementation"
imp "Generate code for the feature"
knw "Extract patterns from the codebase"
```

### 2. Environment Setup
```bash
# Add to ~/.bashrc for permanent aliases
echo 'source /path/to/omarchy-ai-assist/tools/ai_aliases.sh' >> ~/.bashrc

# Reload shell
source ~/.bashrc

# Set preferred AI provider
export AI_PROVIDER=ollama  # or lmstudio, openrouter, openai
```

### 3. Provider Configuration

#### Ollama (Recommended - Works Immediately)
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama server
ollama serve

# Pull a model
ollama pull mistral

# Set as default provider
export AI_PROVIDER=ollama
```

#### LM Studio
```bash
# Launch LM Studio AppImage
~/Downloads/LM-Studio.AppImage

# Enable "OpenAI Compatible Server" in settings
# Note the port (usually 1234 or 41343)

# Configure environment
export LMSTUDIO_BASE_URL="http://127.0.0.1:41343/v1"
export LMSTUDIO_API_KEY="lm-studio"
export AI_PROVIDER=lmstudio
```

#### OpenRouter
```bash
# Get API key from https://openrouter.ai/
export OPENROUTER_API_KEY="your-api-key"
export AI_PROVIDER=openrouter
```

---

## 🎮 Command Reference

### 🤖 AI Subagent Commands

#### Planning (pln)
```bash
pln "Design a REST API structure"
pln "Plan the architecture of a microservices system"
pln "Create a deployment strategy for a cloud application"
```

#### Implementation (imp)
```bash
imp "Generate Go code for a web server"
imp "Create a React component for user authentication"
imp "Write a shell script for system monitoring"
```

#### Knowledge Extraction (knw)
```bash
knw "Extract patterns from this codebase"
knw "Analyze the system architecture for improvements"
knw "Identify optimization opportunities"
```

### 📊 System Commands

```bash
# Check provider availability
ai_check

# Show detailed status
ostatus          # Ollama status
lmsp             # LM Studio ping
ai_help          # Show help

# Switch providers
ai_ollama        # Switch to Ollama
ai_lmstudio      # Switch to LM Studio
ai_openrouter    # Switch to OpenRouter
```

### 🔧 Direct CLI Access

#### LM Studio CLI
```bash
lmsc "Chat with LM Studio"
lmsm                    # List models
lmsp                    # Ping server
lmse "Embed this text"
```

#### Ollama CLI
```bash
oai status              # Ollama status
oai chat mistral "Chat message"
oai planner "Planning task"
oai implementor "Implementation task"
oai knowledge "Knowledge task"
```

---

## ⌨️ VS Code Integration

### Keybindings (Ctrl+Alt combinations)
- `Ctrl+Alt+P` - Start planning command (`pln`)
- `Ctrl+Alt+I` - Start implementation command (`imp`)
- `Ctrl+Alt+K` - Start knowledge extraction (`knw`)
- `Ctrl+Alt+O` - Start Ollama AI command (`oai`)
- `Ctrl+Alt+L` - Start LM Studio chat (`lmsc`)
- `Ctrl+Alt+S` - Show system status (`ostatus`)
- `Ctrl+Alt+H` - Show help (`ai_help`)

### VS Code Tasks
Press `Ctrl+Shift+P` and run:
- `AI: Load Omarchy AI Aliases` - Load command aliases
- `AI: Check System Status` - Check provider availability
- `AI: Start Ollama` - Start Ollama server
- `AI: Start LM Studio` - Launch LM Studio
- `AI: Launch MCP Superagents` - Start advanced AI agents

---

## 🏗️ Architecture

### Multi-Tier System
```
Tier X1 (Premium)    → Claude-3.5-Sonnet | GPT-4O | Llama3.1:70b
Tier X0 (Standard)   → Claude-3.5-Haiku | GPT-4O-Mini | Llama3.1:8b
Tier Free (Basic)    → Gemma-2-9b | GPT-3.5 | Mistral
```

### Subagent Specializations
- **Planner (pln):** System architecture, strategic planning
- **Implementor (imp):** Code generation, technical implementation
- **Knowledge (knw):** Pattern extraction, analysis, synthesis

### Provider Fallback Chain
1. **Preferred Provider** (user-selected)
2. **Ollama** (local, reliable)
3. **OpenRouter** (cloud, diverse models)
4. **LM Studio** (local, advanced models)
5. **OpenAI** (cloud, GPT models)

---

## 🖥️ Headless Operation

### systemd Services

#### Enable Services
```bash
# Reload systemd daemon
systemctl --user daemon-reload

# Enable Ollama service
systemctl --user enable omarchy-ollama
systemctl --user start omarchy-ollama

# Enable AI Assist service
systemctl --user enable omarchy-ai-assist
systemctl --user start omarchy-ai-assist

# Check status
systemctl --user status omarchy-ollama
systemctl --user status omarchy-ai-assist
```

#### Service Logs
```bash
# View logs
journalctl --user -u omarchy-ollama -f
journalctl --user -u omarchy-ai-assist -f
```

---

## 📝 Examples & Workflows

### Complete Development Workflow
```bash
# 1. Plan the architecture
pln "Design a scalable API for user management"

# 2. Implement the backend
imp "Generate Go code for the user management API"

# 3. Create frontend components
imp "Create React components for user interface"

# 4. Extract patterns for future use
knw "Analyze the generated code for reusable patterns"

# 5. Get system status
ai_check
```

### Code Review Workflow
```bash
# Analyze existing code
knw "Review this Go file for optimization opportunities"

# Get implementation suggestions
imp "Refactor this code for better performance"

# Plan improvements
pln "Create a plan for implementing the optimizations"
```

### Learning Workflow
```bash
# Learn new concepts
knw "Explain microservices architecture"

# Get practical examples
imp "Show me a microservices implementation in Go"

# Plan learning path
pln "Create a learning roadmap for backend development"
```

---

## 🔍 Troubleshooting

### Common Issues

#### Provider Not Available
```bash
# Check all providers
ai_check

# Restart Ollama
systemctl --user restart omarchy-ollama

# Check network connectivity
curl -s $OLLAMA_BASE_URL/api/tags
```

#### Model Loading Issues
```bash
# List available models
ollama list

# Pull missing models
ollama pull mistral
ollama pull llama3.1

# Check model status
oai status
```

#### Permission Issues
```bash
# Make scripts executable
chmod +x tools/*.sh

# Check PATH
echo $PATH | grep -o '[^:]*' | xargs -I {} ls -la {}/ollama

# Reload shell
source ~/.bashrc
```

### Debug Mode
```bash
# Enable verbose output
export AI_DEBUG=1

# Check configuration
cat tools/ai_providers.yml

# Test individual providers
./tools/lms_cli.sh ping
./tools/ollama_ai.sh status
```

---

## 🚀 Advanced Features

### Custom System Prompts
Edit `tools/ai_providers.yml` to customize subagent behavior:

```yaml
subagents:
  planner:
    system_prompt: |
      You are an expert in Omarchy OS architecture...

  implementor:
    system_prompt: |
      You specialize in Go and JavaScript for Omarchy...
```

### Provider Chains
Configure custom fallback chains:

```yaml
fallback_chain:
  - ollama
  - lmstudio
  - openrouter
```

### Cost Optimization
```yaml
cost_optimization:
  enable_caching: true
  budget_alerts: true
  daily_budget: 10.00
```

---

## 📚 API Reference

### Direct API Usage

#### Ollama API
```bash
# Generate completion
curl -X POST $OLLAMA_BASE_URL/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"mistral","prompt":"Hello"}'

# List models
curl $OLLAMA_BASE_URL/api/tags
```

#### LM Studio API
```bash
# Chat completion
curl -X POST $LMSTUDIO_BASE_URL/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $LMSTUDIO_API_KEY" \
  -d '{"model":"local-model","messages":[{"role":"user","content":"Hello"}]}'
```

---

## 🤝 Contributing

### Development Setup
```bash
# Clone repository
git clone <repository-url>
cd omarchy-ai-assist

# Install dependencies
npm install

# Run tests
npm test

# Start development
source tools/ai_aliases.sh
```

### Adding New Providers
1. Update `tools/ai_providers.yml`
2. Add provider script in `tools/`
3. Update `tools/ai_aliases.sh`
4. Test with `ai_check`

---

## 📄 License

This project is part of the Omarchy OS ecosystem and follows the same licensing terms.

---

## 🆘 Support

### Quick Help
```bash
# Show all commands
ai_help

# Check system status
ai_check

# Get provider information
ostatus
lmsp
```

### Environment Variables
- `AI_PROVIDER` - Preferred AI provider
- `AI_DEBUG` - Enable debug output (0/1)
- `OLLAMA_BASE_URL` - Ollama endpoint
- `LMSTUDIO_BASE_URL` - LM Studio endpoint
- `OPENROUTER_API_KEY` - OpenRouter API key

### Log Locations
- **Ollama:** `journalctl --user -u omarchy-ollama`
- **AI Assist:** `journalctl --user -u omarchy-ai-assist`
- **LM Studio:** `~/.config/LM Studio/logs/`

---

## 🎉 Success Metrics

- ✅ **4 AI Providers Supported** (Ollama, LM Studio, OpenRouter, OpenAI)
- ✅ **3 Specialized Subagents** (Planner, Implementor, Knowledge)
- ✅ **Multi-Tier Architecture** (X1, X0, Free)
- ✅ **Terminal & VS Code Integration**
- ✅ **Headless systemd Services**
- ✅ **Automatic Fallback Mechanism**
- ✅ **Provider-Agnostic Design**

**The Omarchy AI CLI is fully operational and ready for production use!** 🚀

---

*Last updated: 2025-10-29 | Version: 1.0.0*
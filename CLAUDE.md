# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **omarchy-ai-assist**, a comprehensive Node.js AI collaboration ecosystem featuring multiple specialized assistants for Omarchy OS development and desktop customization. The system provides both a core CLI assistant and a suite of collaborative AI tools with knowledge persistence and cross-platform integration.

## Commands

### Core AI Assistant

```bash
# Interactive chat mode with model rotation
node omai.js

# Direct prompt with automatic model selection
node omai.js "your prompt here"

# Language-specific programming assistance
node omai.js --lang python "create a hello world program"
node omai.js --lang go "implement a system monitor"

# Save conversation to room context for other tools
node omai.js --handoff "customize this component"

# View token usage statistics
node omai.js --usage
```

### AI Team Collaboration Tools

```bash
# AI team management and task distribution
node ai-collaboration-hub.js status
node ai-collaboration-hub.js distribute "your task"

# Desktop navigation and Omarchy OS assistance
node omarchy-navigator.js "help me navigate workspaces"
node omarchy-navigator.js  # Interactive mode

# Multi-AI collaborative workflows
node collaborative-workflow.js list
node collaborative-workflow.js start desktop-customization "dark theme"

# LM Studio integration for deep analysis
node lm-studio-integration.js export --session=daily
node lm-studio-integration.js import

# Ollama local AI integration
node ollama-integration.js chat
node ollama-integration.js status

# AI team chat interface
node ai-team-chat.js
```

### Training and Knowledge Management

```bash
# Ecosystem training data management
node ecosystem-training-data.js generate
node ecosystem-training-data.js validate

# Go language training for Omarchy
node omarchy-go-training.js start

# Wagon wheel foundational training
node wagon-wheel-training.js phase --all
```

### MCP Superagent Management

```bash
# Launch MCP superagent servers
node mcp-superagent-launcher.js start all
node mcp-superagent-launcher.js status

# Individual MCP agents
node mcp-superagents/token-manager-mcp.js
node mcp-superagents/workflow-coordinator-mcp.js
node mcp-superagents/knowledge-mcp.js
```

### Development and Utilities

```bash
# Install dependencies
npm install

# System initialization
node omarchy-init.js

# Startup status check
node startup-check.js

# Currently no tests configured
npm test
```

## Architecture

### Core System Components

- **omai.js**: Main CLI AI assistant with automatic model rotation and token tracking
- **ai-collaboration-hub.js**: Central coordinator for multi-AI team collaboration
- **omarchy-navigator.js**: Specialized desktop environment assistant
- **collaborative-workflow.js**: Multi-AI workflow orchestration system
- **lm-studio-integration.js**: Bridge to LM Studio for deep analysis
- **token-tracker.js**: Usage monitoring and cost tracking across all AI models

### Knowledge and Training System

- **ecosystem-training-data.js**: Manages collective AI knowledge base
- **training-data/**: Structured learning data for AI patterns and workflows
- **knowledge-outbox/**: Exported knowledge for external AI analysis
- **omarchy-knowledge.json**: Core Omarchy OS knowledge repository

### Integration Layer

- **Room Context**: Shared conversation state at `/home/zebadiee/.npm-global/omarchy-wagon/room.json`
- **Environment Configuration**: Uses `/home/zebadiee/.npm-global/bin/.env`
- **MCP Superagents**: Specialized agents for token management, workflow coordination, and knowledge management

### Dependencies

Core dependencies for the main CLI:
- `@modelcontextprotocol/sdk`: MCP protocol support for superagent integration
- `dotenv`: Environment variable management
- `node-fetch`: HTTP client for API requests

### API Integration and Model Rotation

The system uses OpenRouter's API with intelligent model rotation:

**Model Configuration** (rotates automatically on rate limits):
- `OR_MODEL_1`: google/gemini-2.0-flash-exp:free (default)
- `OR_MODEL_2`: meta-llama/llama-3.2-3b-instruct:free
- `OR_MODEL_3`: meta-llama/llama-3.2-1b-instruct:free
- `OR_MODEL_4`: microsoft/phi-3-mini-128k-instruct:free
- `OR_MODEL_5`: qwen/qwen-2.5-7b-instruct:free

**API Configuration**:
- **Endpoint**: `OR_ENDPOINT` (defaults to OpenRouter chat completions)
- **API Key**: `OPENROUTER_API_KEY` (required)
- **Referer**: `OR_REFERER` (defaults to 'https://omarchy.local')
- **Title**: `OR_TITLE` (defaults to 'Omarchy Wagon Wheels')
- **Model Index**: `OR_CURRENT_MODEL_INDEX` (tracked for rotation)

### Key Features

#### Core AI Assistant (omai.js)
1. **Automatic Model Rotation**: Intelligently switches between 5 free models on rate limits
2. **Omarchy OS Expertise**: Deep knowledge of Omarchy OS syntax, APIs, and system architecture
3. **Interactive Chat Mode**: Full readline-based conversation with context memory
4. **Multi-language Support**: `--lang` flag for Python, Go, and other programming languages
5. **Token Usage Tracking**: Real-time monitoring and cost estimation
6. **Context Handoff**: `--handoff` flag saves conversations to shared room context
7. **Ecosystem Knowledge**: Loads enhanced training data from `ecosystem-training-prompt.txt`

#### AI Team Collaboration System
1. **Multi-AI Coordination**: Central hub manages 5 specialized AI assistants
2. **Task Distribution**: Intelligent routing to optimal AI for specific tasks
3. **Collaborative Workflows**: Multi-step workflows involving multiple AI agents
4. **Knowledge Persistence**: Cross-session learning and memory
5. **Desktop Integration**: Specialized Omarchy OS navigation and customization

#### External AI Integration
1. **LM Studio Bridge**: Export/import knowledge for deep local analysis
2. **Ollama Integration**: Local AI model support
3. **MCP Superagent Support**: Model Context Protocol for advanced integrations

### File Structure

```
omarchy-ai-assist/
├── Core AI Assistant
│   ├── omai.js                    # Main CLI with model rotation
│   ├── token-tracker.js           # Usage monitoring and cost tracking
│   └── ecosystem-training-prompt.txt  # Enhanced AI knowledge
│
├── AI Collaboration System
│   ├── ai-collaboration-hub.js    # Central AI team coordinator
│   ├── collaborative-workflow.js  # Multi-AI workflow orchestration
│   ├── ai-team-chat.js           # Team communication interface
│   └── mcp-superagent-launcher.js # MCP server management
│
├── Specialized Assistants
│   ├── omarchy-navigator.js       # Desktop environment expert
│   ├── lm-studio-integration.js   # LM Studio bridge
│   └── ollama-integration.js      # Local AI integration
│
├── Training and Knowledge
│   ├── ecosystem-training-data.js # Knowledge base management
│   ├── omarchy-go-training.js     # Go language training
│   ├── wagon-wheel-training.js    # Foundational training
│   ├── training-data/            # Structured learning data
│   └── knowledge-outbox/         # Exported knowledge for analysis
│
├── MCP Superagents
│   ├── mcp-superagents/          # Individual MCP agents
│   │   ├── token-manager-mcp.js
│   │   ├── workflow-coordinator-mcp.js
│   │   ├── implementor-mcp.js
│   │   └── knowledge-mcp.js
│   └── mcp-superagents.json      # MCP configuration
│
├── Tools and Utilities
│   ├── tools/                    # Shell scripts and utilities
│   │   ├── ai_aliases.sh
│   │   ├── universal_ai.sh
│   │   └── ollama_ai.sh
│   ├── omarchy-init.js          # System initialization
│   └── startup-check.js         # Status verification
│
├── Configuration
│   ├── package.json             # Node.js project configuration
│   ├── omarchy-knowledge.json   # Core Omarchy knowledge base
│   └── .env                     # Environment variables (external)
│
└── Documentation
    ├── CLAUDE.md                # This file
    ├── OMARCHY_NAVIGATOR_README.md
    ├── go-implementation-plan.md
    ├── COMPLETE_INTEGRATION_GUIDE.md
    └── various integration guides...
```

## Environment Setup

### Required Environment Variables
- `OPENROUTER_API_KEY`: OpenRouter API key (required)
- `OR_ENDPOINT`: API endpoint (optional, defaults to OpenRouter)
- `OR_MODEL_1` through `OR_MODEL_5`: Individual model configurations
- `OR_REFERER`: HTTP referer header (defaults to 'https://omarchy.local')
- `OR_TITLE`: X-Title header (defaults to 'Omarchy Wagon Wheels')
- `OR_CURRENT_MODEL_INDEX`: Current model index (managed automatically)

### Optional Integration Variables
- `TOKEN_MANAGER_PATH`: Path to token management system
- `TOKEN_BUDGET_FILE`: Token budget configuration
- `TOKEN_USER`: User identifier for tracking

### File Structure Dependencies
- Environment config: `/home/zebadiee/.npm-global/bin/.env`
- Room context: `/home/zebadiee/.npm-global/omarchy-wagon/room.json`
- Usage tracking: `../ai-token-manager/usage.json`

## Knowledge Management System

### Room Context and Session Management
The `--handoff` feature creates a shared knowledge pipeline:
1. Conversations are saved to room context with timestamps
2. Cross-tool communication through shared JSON files
3. AI team learning builds across sessions
4. Knowledge export to LM Studio for deep analysis

### Training Data Architecture
- **Foundational Training**: `training-data/` contains structured learning patterns
- **Ecosystem Knowledge**: `ecosystem-training-prompt.txt` provides enhanced capabilities
- **Continuous Learning**: AI interactions generate new training data
- **Cross-AI Memory**: Knowledge shared between all AI assistants

### External Knowledge Integration
- **LM Studio Export**: `knowledge-outbox/` contains exported AI interactions
- **Deep Analysis Pipeline**: Manual workflow for strategic insights
- **Import Enhancement**: LM Studio insights improve AI capabilities

## Omarchy OS Integration

### Desktop Environment Expertise
This system is specifically designed for Omarchy OS with comprehensive knowledge of:

- **Navigation Systems**: Workspace management, window controls, keyboard shortcuts
- **Customization Options**: Themes, wallpapers, keybindings, panels
- **System Management**: Troubleshooting, performance optimization, monitoring
- **Development Workflows**: Best practices for Omarchy OS development
- **Architecture**: Understanding of Omarchy OS system internals

### Specialized Assistance Patterns
- **Navigation Help**: Step-by-step guidance for workspace and window management
- **Customization Workflows**: Complete theming and configuration assistance
- **Troubleshooting Solutions**: Systematic problem diagnosis and resolution
- **Development Support**: Code generation for Omarchy OS extensions and tools

## Go Language Integration Strategy

### Development Setup
- Use `--lang go` flag for Go-specific code generation and assistance
- Access comprehensive Go implementation plan in `go-implementation-plan.md`
- Leverage AI team for Go development workflow coordination

### Integration Architecture
The system includes a detailed 3-phase Go integration plan:

1. **Phase 1**: Foundation setup with Go 1.22.5 system installation
2. **Phase 2**: Core integration with AI assistant backends in Go
3. **Phase 3**: Advanced AI-powered desktop features

### Go Development Support
- **API Clients**: HTTP clients for Omarchy OS services
- **System Integration**: cgo and syscall packages for OS-level operations
- **Performance Optimization**: Concurrent processing for desktop tools
- **Build Systems**: Integration with Go toolchain and Omarchy build processes

### Example Go Workflows
```bash
# Generate Go code for Omarchy OS
node omai.js --lang go "create a client for the Omarchy file system API"

# AI-assisted Go development
node ai-collaboration-hub.js distribute "implement Go-based system monitor"

# Collaborative Go development workflow
node collaborative-workflow.js start go-development "performance monitoring tool"
```

## AI Team Collaboration Architecture

### Multi-AI System Components
The system coordinates 5 specialized AI assistants:

1. **Claude Code** (current): Terminal operations, file management, analysis
2. **Gemini AI**: Research, content generation, creative tasks
3. **OpenAI Assistant**: Coding, problem-solving, explanations
4. **Codex Copilot**: Code completion, syntax patterns, refactoring
5. **Omarchy Navigator**: Desktop navigation, customization, troubleshooting

### Collaboration Patterns
- **Task Distribution**: Intelligent routing to optimal AI assistant
- **Knowledge Sharing**: Cross-AI learning and memory preservation
- **Workflow Orchestration**: Multi-AI coordination for complex tasks
- **Continuous Learning**: System improves with each interaction

### MCP Integration
- **Protocol Support**: Model Context Protocol for advanced integrations
- **Superagent Architecture**: Specialized agents for specific domains
- **Extensible Design**: Easy addition of new AI capabilities

## Development and Extension Guidelines

### Code Standards
- **Naming**: Hyphenated filenames (e.g., `ai-collaboration-hub.js`)
- **Indentation**: 2-space soft tabs
- **Structure**: Modular design with clear separation of concerns
- **Documentation**: Comprehensive README files for each component

### Extension Patterns
- **New AI Assistants**: Follow the established pattern in existing assistants
- **Workflow Integration**: Use `collaborative-workflow.js` for multi-step processes
- **Knowledge Management**: Leverage the training data system for persistence
- **External Integration**: Use LM Studio bridge for deep analysis capabilities

### Testing and Validation
- **Integration Testing**: Test cross-component communication
- **AI Validation**: Use AI team for code review and validation
- **Performance Monitoring**: Track token usage and response times
- **User Feedback**: Collect and incorporate user interaction patterns
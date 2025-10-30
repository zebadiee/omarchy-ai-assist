# GEMINI.md

## Project Overview

This repository contains the "Omarchy AI Assist" ecosystem, a suite of tools designed to provide a comprehensive, multi-provider AI assistant experience within a command-line environment and a custom desktop environment called "Omarchy OS".

The main components are:

*   **`omai.js`**: A Node.js-based CLI tool that serves as the primary interface for interacting with various AI models. It supports model rotation, context handoff, and token usage tracking. It uses OpenRouter to connect to models like Gemini, Llama, and others.
*   **CLI Tools & Aliases**: A collection of shell scripts and aliases (e.g., `pln`, `imp`, `knw`) provide a simplified interface for specialized AI subagents (Planner, Implementor, Knowledge). These are documented in `CLI_DOCUMENTATION.md`.
*   **`omarchy-launcher.go`**: A desktop launcher for the "Omarchy OS", written in Go. It uses `wofi` for the UI and provides quick access to system applications and the AI assistant tools.
*   **`omarchy-navigator`**: An AI assistant specifically designed to help users navigate and learn the "Omarchy OS" desktop environment.
*   **Web Dashboard**: A web-based interface, accessible at `http://localhost:3000`, which seems to provide system monitoring and AI-related dashboards.

The project is a multi-language environment, primarily using Node.js, Go, and shell scripts.

## Building and Running

### Node.js CLI (`omai.js`)

1.  **Install Dependencies:**
    ```bash
    npm install
    ```

2.  **Configure Environment:**
    Create a `.env` file in the project root or at `/home/zebadiee/.npm-global/bin/.env` and add your OpenRouter API key:
    ```
    OPENROUTER_API_KEY="your-openrouter-api-key"
    ```

3.  **Run the CLI:**
    You can run the CLI in two modes:

    *   **Direct Prompt:**
        ```bash
        node omai.js "Your prompt for the AI"
        ```

    *   **Interactive Chat Mode:**
        ```bash
        node omai.js
        ```

4.  **Use CLI Aliases:**
    Source the aliases to use the simplified commands:
    ```bash
    source tools/ai_aliases.sh
    # Now you can use pln, imp, knw, etc.
    pln "Plan a new feature"
    ```

### Go Launcher (`omarchy-launcher.go`)

1.  **Install Go:**
    Make sure you have Go installed (the project seems to be using version 1.22.5).

2.  **Build and Run:**
    ```bash
    go run omarchy-launcher.go
    ```
    This will launch the `wofi`-based launcher.

### Web Dashboard

The web dashboard is mentioned in several files and appears to be accessible at:
`http://localhost:3000`

The source code for this dashboard is not immediately apparent in the file listing, but it is a key component of the ecosystem.

## Development Conventions

*   **Node.js**: The Node.js code uses `commonjs` modules.
*   **Go**: The Go code is used for performance-critical components like the desktop launcher.
*   **Shell**: Shell scripts are used for CLI aliases and utility functions.
*   **Configuration**: Configuration files are found in various locations, including `.env` for API keys and `~/.config/omarchy/` for the launcher and other desktop components.
*   **AI Integration**: The system is designed to be multi-provider, with a preference for local models via Ollama and LM Studio, and cloud models via OpenRouter.

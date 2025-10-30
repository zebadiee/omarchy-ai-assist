#!/bin/bash

# Omarchy AI Collaboration System Dashboard
# Real-time monitoring and interaction script

clear
echo "🚀 OMARCHY AI COLLABORATION SYSTEM - LIVE DASHBOARD"
echo "=================================================="
echo ""

# Function to show team status
show_team_status() {
    echo "📊 TEAM STATUS"
    echo "---------------"
    if [ -f "knowledge-outbox/team-status/latest.json" ]; then
        local active=$(cat knowledge-outbox/team-status/latest.json | jq -r '.overview.activeAssistants')
        local total=$(cat knowledge-outbox/team-status/latest.json | jq -r '.overview.totalAssistants')
        local knowledge=$(cat knowledge-outbox/team-status/latest.json | jq -r '.overview.knowledgeEntries')
        local tasks=$(cat knowledge-outbox/team-status/latest.json | jq -r '.overview.pendingTasks')
        local last=$(cat knowledge-outbox/team-status/latest.json | jq -r '.overview.lastCollaboration')

        echo "🤖 Active Assistants: $active/$total"
        echo "🧠 Knowledge Entries: $knowledge"
        echo "📋 Pending Tasks: $tasks"
        echo "⏰ Last Collaboration: $last"
    else
        echo "❌ Team status data not available"
    fi
    echo ""
}

# Function to show system processes
show_processes() {
    echo "🔄 BACKGROUND PROCESSES"
    echo "----------------------"
    local ollama_count=$(ps aux | grep "ollama-integration" | grep -v grep | wc -l)
    local lmstudio_count=$(ps aux | grep "lm-studio-integration" | grep -v grep | wc -l)
    local ollama_model=$(ps aux | grep "ollama run" | grep -v grep | wc -l)

    echo "🧠 Ollama Analysis: $ollama_count running"
    echo "📡 LM Studio Sync: $lmstudio_count running"
    echo "🔧 Local Models: $ollama_model active"
    echo ""
}

# Function to show recent knowledge
show_knowledge() {
    echo "📚 KNOWLEDGE ACTIVITY"
    echo "-------------------"
    local latest_analysis=$(ls -t knowledge-outbox/ollama-insights/*.md 2>/dev/null | head -1)
    local latest_export=$(ls -t knowledge-outbox/omarchy-export-*.json 2>/dev/null | head -1)

    if [ -n "$latest_analysis" ]; then
        echo "🧠 Latest Analysis: $(basename $latest_analysis)"
        echo "   Generated: $(stat -c %y $latest_analysis | cut -d' ' -f1,2 | cut -d'.' -f1)"
    fi

    if [ -n "$latest_export" ]; then
        echo "📤 Latest Export: $(basename $latest_export)"
        echo "   Generated: $(stat -c %y $latest_export | cut -d' ' -f1,2 | cut -d'.' -f1)"
    fi
    echo ""
}

# Function to show available commands
show_commands() {
    echo "🎮 AVAILABLE COMMANDS"
    echo "-------------------"
    echo "1. 📊 Refresh Dashboard      - Press 'r'"
    echo "2. 🧠 Quick Analysis         - Press 'a'"
    echo "3. 📤 Export Knowledge       - Press 'e'"
    echo "4. 📥 Import Insights        - Press 'i'"
    echo "5. 🔄 Continuous Analysis    - Press 'c'"
    echo "6. 📋 Go Implementation      - Press 'g'"
    echo "7. ❌ Exit Dashboard         - Press 'q'"
    echo ""
}

# Function to run commands
run_command() {
    case $1 in
        "a")
            echo "🧠 Running quick analysis..."
            node ollama-integration.js analyze
            echo "✅ Analysis complete!"
            read -p "Press Enter to continue..."
            ;;
        "e")
            echo "📤 Exporting knowledge..."
            node lm-studio-integration.js export --session=manual
            echo "✅ Export complete!"
            read -p "Press Enter to continue..."
            ;;
        "i")
            echo "📥 Importing insights..."
            node lm-studio-integration.js import
            echo "✅ Import complete!"
            read -p "Press Enter to continue..."
            ;;
        "g")
            echo "📋 Running Go implementation analysis..."
            node ollama-integration.js analyze --context=go-implementation
            echo "✅ Go analysis complete!"
            read -p "Press Enter to continue..."
            ;;
        "c")
            echo "🔄 Starting continuous analysis (Ctrl+C to stop)..."
            node ollama-integration.js continuous --interval=3
            ;;
    esac
}

# Main dashboard loop
while true; do
    clear
    echo "🚀 OMARCHY AI COLLABORATION SYSTEM - LIVE DASHBOARD"
    echo "=================================================="
    echo "📅 $(date)"
    echo ""

    show_team_status
    show_processes
    show_knowledge
    show_commands

    echo "Enter your choice (r/a/e/i/g/c/q): "
    read -n 1 choice
    echo ""

    case $choice in
        "r"|"R")
            continue
            ;;
        "a"|"A")
            run_command "a"
            ;;
        "e"|"E")
            run_command "e"
            ;;
        "i"|"I")
            run_command "i"
            ;;
        "g"|"G")
            run_command "g"
            ;;
        "c"|"C")
            run_command "c"
            ;;
        "q"|"Q")
            echo "👋 Exiting dashboard..."
            exit 0
            ;;
        *)
            echo "❌ Invalid choice. Please try again."
            sleep 1
            ;;
    esac
done
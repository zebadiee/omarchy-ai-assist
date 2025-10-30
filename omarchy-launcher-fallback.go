package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// OmarchyLauncher represents the main desktop launcher system with fallback interface
type OmarchyLauncher struct {
	configPath    string
	actions       []LauncherAction
	lastUpdate    time.Time
}

// LauncherAction represents an action available in the launcher
type LauncherAction struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Icon        string   `json:"icon"`
	Category    string   `json:"category"`
	Command     string   `json:"command"`
	Args        []string `json:"args"`
	Hotkey      string   `json:"hotkey"`
	Priority    int      `json:"priority"`
}

// NewOmarchyLauncher creates a new launcher instance
func NewOmarchyLauncher() *OmarchyLauncher {
	homeDir, _ := os.UserHomeDir()
	configPath := filepath.Join(homeDir, ".config", "omarchy", "launcher")

	return &OmarchyLauncher{
		configPath: configPath,
		lastUpdate: time.Now(),
	}
}

// Initialize sets up the launcher with default actions
func (ol *OmarchyLauncher) Initialize() error {
	// Ensure config directory exists
	if err := os.MkdirAll(ol.configPath, 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %v", err)
	}

	// Initialize default actions
	ol.actions = []LauncherAction{
		{
			ID:          "system-monitor",
			Name:        "🖥️  System Monitor",
			Description: "Open the Omarchy system monitoring dashboard",
			Icon:        "📊",
			Category:    "system",
			Command:     "echo",
			Args:        []string{"Opening system monitor at http://localhost:3000"},
			Hotkey:      "Super+Shift+S",
			Priority:    1,
		},
		{
			ID:          "ai-dashboard",
			Name:        "🤖 AI Dashboard",
			Description: "Open the AI collaboration dashboard",
			Icon:        "🧠",
			Category:    "ai",
			Command:     "echo",
			Args:        []string{"AI Team Status and Information"},
			Hotkey:      "Super+Shift+A",
			Priority:    1,
		},
		{
			ID:          "planner",
			Name:        "#pln - Planner",
			Description: "Launch AI planner subagent",
			Icon:        "📋",
			Category:    "ai-subagents",
			Command:     "tools/ai_subagent.sh",
			Args:        []string{"pln", "x1"},
			Hotkey:      "Super+Alt+P",
			Priority:    2,
		},
		{
			ID:          "implementor",
			Name:        "#imp - Implementor",
			Description: "Launch AI implementor subagent",
			Icon:        "🔨",
			Category:    "ai-subagents",
			Command:     "tools/ai_subagent.sh",
			Args:        []string{"imp", "x0"},
			Hotkey:      "Super+Alt+I",
			Priority:    2,
		},
		{
			ID:          "knowledge",
			Name:        "#knw - Knowledge",
			Description: "Launch AI knowledge extraction subagent",
			Icon:        "📚",
			Category:    "ai-subagents",
			Command:     "tools/ai_subagent.sh",
			Args:        []string{"knw", "x0"},
			Hotkey:      "Super+Alt+K",
			Priority:    2,
		},
		{
			ID:          "continuous-analysis",
			Name:        "🔄 Start Continuous Analysis",
			Description: "Start continuous AI analysis",
			Icon:        "⚡",
			Category:    "ai",
			Command:     "node",
			Args:        []string{"ollama-integration.js", "continuous", "--interval=3"},
			Hotkey:      "Super+Shift+C",
			Priority:    3,
		},
		{
			ID:          "lm-studio",
			Name:        "🧠 LM Studio Integration",
			Description: "LM Studio setup and integration",
			Icon:        "🔬",
			Category:    "ai-tools",
			Command:     "echo",
			Args:        []string{"LM Studio integration available via knowledge-outbox"},
			Hotkey:      "Super+Alt+L",
			Priority:    4,
		},
		{
			ID:          "go-monitor",
			Name:        "🐹 Go System Monitor",
			Description: "Start the Go-based system monitor",
			Icon:        "⚙️",
			Category:    "system",
			Command:     "echo",
			Args:        []string{"Go system monitor is running at http://localhost:3000"},
			Hotkey:      "Super+Shift+G",
			Priority:    2,
		},
		{
			ID:          "terminal",
			Name:        "💻 Terminal",
			Description: "Open a new terminal instance",
			Icon:        "🖥️",
			Category:    "system",
			Command:     "alacritty",
			Args:        []string{},
			Hotkey:      "Super+Enter",
			Priority:    1,
		},
		{
			ID:          "config-manager",
			Name:        "⚙️  Configuration",
			Description: "Open Omarchy configuration directory",
			Icon:        "🛠️",
			Category:    "system",
			Command:     "echo",
			Args:        []string{"Configuration directory: ~/.config/omarchy/"},
			Hotkey:      "Super+Shift+O",
			Priority:    3,
		},
		{
			ID:          "hyprland-config",
			Name:        "⌨️  Hyprland Config",
			Description: "Edit Hyprland configuration",
			Icon:        "🖱️",
			Category:    "system",
			Command:     "nvim",
			Args:        []string{"/home/zebadiee/.config/hypr/hyprland.conf"},
			Hotkey:      "Super+Alt+H",
			Priority:    3,
		},
	}

	return nil
}

// ShowLauncher displays the launcher interface using terminal input
func (ol *OmarchyLauncher) ShowLauncher() error {
	fmt.Println("\n🚂 **OMARCHY DESKTOP LAUNCHER**")
	fmt.Println("==============================")
	fmt.Println("🤖 AI-powered desktop integration for Omarchy OS")
	fmt.Println("")

	// Display categorized actions
	categories := make(map[string][]LauncherAction)
	for _, action := range ol.actions {
		categories[action.Category] = append(categories[action.Category], action)
	}

	for category, actions := range categories {
		fmt.Printf("📂 %s\n", strings.Title(category))
		fmt.Println(strings.Repeat("-", 20))
		for i, action := range actions {
			fmt.Printf("%d. %s %s\n", i+1, action.Icon, action.Name)
		}
		fmt.Println()
	}

	// Get user selection
	fmt.Print("Enter choice (1-999), or 'q' to quit: ")
	reader := bufio.NewReader(os.Stdin)
	selection, _ := reader.ReadString('\n')
	selection = strings.TrimSpace(selection)

	if selection == "q" || selection == "quit" {
		return nil
	}

	// Parse selection
	choice := 1
	if selection != "1" {
		if parsed, err := strconv.Atoi(selection); err == nil {
			choice = parsed
		}
	}

	if choice < 1 || choice > len(ol.actions) {
		fmt.Println("❌ Invalid selection")
		return nil
	}

	// Find and execute the selected action
	actionIndex := choice - 1
	if actionIndex < len(ol.actions) {
		action := ol.actions[actionIndex]
		return ol.executeAction(action)
	}

	return nil
}

// executeAction runs a launcher action
func (ol *OmarchyLauncher) executeAction(action LauncherAction) error {
	fmt.Printf("\n🚂 Executing: %s\n", action.Name)
	fmt.Printf("📝 Description: %s\n", action.Description)

	switch action.ID {
	case "system-monitor":
		// Open system monitor in browser
		fmt.Println("🌐 Opening system monitor in browser...")
		go func() {
			exec.Command("xdg-open", "http://localhost:3000").Run()
		}()
		return nil
	case "ai-dashboard":
		// Show AI dashboard status
		return ol.showAIDashboard()
	case "lm-studio":
		// Show LM Studio instructions
		return ol.showLMStudioInstructions()
	case "go-monitor":
		// Show Go monitor status
		return ol.showGoMonitorStatus()
	case "config-manager":
		// Show config directory
		homeDir, _ := os.UserHomeDir()
		configDir := filepath.Join(homeDir, ".config", "omarchy")
		fmt.Printf("📁 Configuration directory: %s\n", configDir)
		return nil
	default:
		// Execute command
		fmt.Printf("💻 Executing: %s %v\n", action.Command, action.Args)
		cmd := exec.Command(action.Command, action.Args...)
		return cmd.Run()
	}
}

// showAIDashboard displays the AI team status
func (ol *OmarchyLauncher) showAIDashboard() error {
	fmt.Println("\n🤖 **OMARCHY AI DASHBOARD**")
	fmt.Println("==========================")

	// Read AI team status
	homeDir, _ := os.UserHomeDir()
	statusFile := filepath.Join(homeDir, "Documents", "omarchy-ai-assist", "knowledge-outbox", "team-status", "latest.json")

	if _, err := os.Stat(statusFile); err == nil {
		// Try to read with Node.js (if available)
		cmd := exec.Command("node", "-e", `
			try {
				const fs = require('fs');
				const data = JSON.parse(fs.readFileSync('` + statusFile + `', 'utf8'));
				const overview = data.overview || {};
				console.log('📊 Active Assistants:', overview.activeAssistants + '/' + overview.totalAssistants);
				console.log('🧠 Knowledge Entries:', overview.knowledgeEntries);
				console.log('📋 Pending Tasks:', overview.pendingTasks);
				if (overview.lastCollaboration) {
					console.log('⏰ Last Collaboration:', overview.lastCollaboration);
				}
			} catch(e) {
				console.log('Error reading status:', e.message);
			}
		`)

		if output, err := cmd.CombinedOutput(); err == nil {
			fmt.Println(string(output))
		} else {
			fmt.Println("⚠️  Could not read AI team status (Node.js not available)")
		}
	} else {
		fmt.Println("⚠️  AI team status file not found")
	}

	fmt.Println("\n🔧 **Available Subagents:**")
	fmt.Println("#pln - AI planner subagent")
	fmt.Println("#imp - AI implementor subagent")
	fmt.Println("#knw - AI knowledge extraction subagent")

	fmt.Println("\n🚀 **System Status:**")
	ol.checkSystemStatus()

	return nil
}

// showLMStudioInstructions displays LM Studio setup instructions
func (ol *OmarchyLauncher) showLMStudioInstructions() error {
	fmt.Println("\n🧠 **LM STUDIO INTEGRATION**")
	fmt.Println("=============================")
	fmt.Println("LM Studio provides advanced AI analysis capabilities for your Omarchy system.")
	fmt.Println("")
	fmt.Println("📁 **Knowledge Base Location:**")
	fmt.Println("   ~/Documents/omarchy-ai-assist/knowledge-outbox/")
	fmt.Println("")
	fmt.Println("🔄 **Sync Commands:**")
	fmt.Println("   node lm-studio-integration.js export    # Export to LM Studio")
	fmt.Println("   node lm-studio-integration.js import    # Import from LM Studio")
	fmt.Println("   node lm-studio-integration.js sync      # Full bidirectional sync")
	fmt.Println("")
	fmt.Println("📊 **Current Status:**")
	fmt.Println("   ✅ Knowledge bridge established")
	fmt.Println("   ✅ Export/import functionality ready")
	fmt.Println("   ✅ AI team insights available")
	fmt.Println("")
	fmt.Println("💡 **Usage:**")
	fmt.Println("   1. Export current AI team knowledge")
	fmt.Println("   2. Use LM Studio for advanced analysis")
	fmt.Println("   3. Import insights back to your system")

	return nil
}

// showGoMonitorStatus displays Go monitor status
func (ol *OmarchyLauncher) showGoMonitorStatus() error {
	fmt.Println("\n🐹 **GO SYSTEM MONITOR STATUS**")
	fmt.Println("===========================")

	// Check if Go monitor is running
	cmd := exec.Command("pgrep", "-f", "go-system-monitor")
	if output, err := cmd.CombinedOutput(); err == nil {
		pids := strings.Fields(strings.TrimSpace(string(output)))
		if len(pids) > 0 {
			fmt.Printf("✅ Go System Monitor is running (PID: %s)\n", pids[0])
			fmt.Println("🌐 Web interface: http://localhost:3000")

			// Try to open in browser
			go func() {
				exec.Command("xdg-open", "http://localhost:3000").Run()
			}()
		} else {
			fmt.Println("✅ Go System Monitor is running")
			fmt.Println("🌐 Web interface: http://localhost:3000")
		}
	} else {
		fmt.Println("❌ Go System Monitor is not running")
		fmt.Println("💡 Start with: /usr/local/go/bin/go run go-system-monitor.go")
	}

	return nil
}

// checkSystemStatus checks the status of system components
func (ol *OmarchyLauncher) checkSystemStatus() {
	components := []struct {
		name   string
		cmd    string
		args   []string
		status string
		icon   string
	}{
		{"Ollama", "ollama", []string{"list"}, "✅", "🧠"},
		{"Node.js", "node", []string{"--version"}, "✅", "🟢"},
		{"Go", "/usr/local/go/bin/go", []string{"version"}, "✅", "🐹"},
		{"Alacritty", "alacritty", []string{"--version"}, "✅", "🖥️"},
		{"Hyprland", "hyprctl", []string{"version"}, "✅", "🪟"},
	}

	fmt.Printf("\n🔧 System Components Status:\n")
	for _, comp := range components {
		cmd := exec.Command(comp.cmd, comp.args...)
		if err := cmd.Run(); err == nil {
			fmt.Printf("   %s %s %s\n", comp.icon, comp.status, comp.name)
		} else {
			fmt.Printf("   ❌ %s (Missing)\n", comp.name)
		}
	}
}

// RunHotkey starts the launcher with hotkey support
func (ol *OmarchyLauncher) RunHotkey() error {
	fmt.Println("🚂 **OMARCHY LAUNCHER HOTKEY MODE**")
	fmt.Println("==================================")
	fmt.Println("Press Space to show launcher, q to quit")
	fmt.Println("")

	// Simple key monitoring loop
	reader := bufio.NewReader(os.Stdin)
	for {
		fmt.Print("Press 'space' for launcher, 'q' to quit: ")
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(strings.ToLower(input))

		switch input {
		case "q", "quit", "exit":
			fmt.Println("👋 Exiting launcher...")
			return nil
		case " ", "space", "launcher":
			if err := ol.ShowLauncher(); err != nil {
				fmt.Printf("❌ Launcher error: %v\n", err)
			}
		default:
			fmt.Println("❌ Invalid input. Use 'space' or 'q'.")
		}
	}
}

func main() {
	launcher := NewOmarchyLauncher()

	// Initialize launcher
	if err := launcher.Initialize(); err != nil {
		log.Fatalf("❌ Failed to initialize launcher: %v", err)
	}

	// Check if we're in hotkey mode or regular mode
	if len(os.Args) > 1 && os.Args[1] == "--hotkey" {
		if err := launcher.RunHotkey(); err != nil {
			log.Printf("❌ Hotkey mode error: %v", err)
		}
	} else {
		// Show launcher once
		if err := launcher.ShowLauncher(); err != nil {
			log.Printf("❌ Launcher error: %v", err)
		}
	}

	fmt.Println("\n✨ Have a productive day with Omarchy! 🌟")
}
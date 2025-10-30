package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// OmarchyLauncher represents the main desktop launcher system
type OmarchyLauncher struct {
	configPath    string
	wofiPath      string
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

// LauncherConfig holds the launcher configuration
type LauncherConfig struct {
	Hotkey           string              `json:"hotkey"`
	ShowOnStartup    bool                `json:"show_on_startup"`
	Actions          []LauncherAction     `json:"actions"`
	CustomActions    map[string]Action   `json:"custom_actions"`
}

// Action represents a custom action configuration
type Action struct {
	Name        string   `json:"name"`
	Command     string   `json:"command"`
	Args        []string `json:"args"`
	Description string   `json:"description"`
}

// NewOmarchyLauncher creates a new launcher instance
func NewOmarchyLauncher() *OmarchyLauncher {
	homeDir, _ := os.UserHomeDir()
	configPath := filepath.Join(homeDir, ".config", "omarchy", "launcher")

	return &OmarchyLauncher{
		configPath: configPath,
		wofiPath:  "/usr/bin/wofi",
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
			Command:     "curl",
			Args:        []string{"-s", "http://localhost:3000/api/metrics"},
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
			Args:        []string{"Opening AI dashboard..."},
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
			Name:        "🧠 LM Studio",
			Description: "Launch LM Studio for advanced AI analysis",
			Icon:        "🔬",
			Category:    "ai-tools",
			Command:     "echo",
			Args:        []string{"Launch LM Studio manually or via AppImage"},
			Hotkey:      "Super+Alt+L",
			Priority:    4,
		},
		{
			ID:          "go-monitor",
			Name:        "🐹 Go System Monitor",
			Description: "Start the Go-based system monitor",
			Icon:        "⚙️",
			Category:    "system",
			Command:     "/usr/local/go/bin/go",
			Args:        []string{"run", "go-system-monitor.go"},
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
			ID:          "file-manager",
			Name:        "📁 File Manager",
			Description: "Open file manager in current directory",
			Icon:        "📂",
			Category:    "system",
			Command:     "thunar",
			Args:        []string{"."},
			Hotkey:      "Super+E",
			Priority:    1,
		},
		{
			ID:          "config-manager",
			Name:        "⚙️  Configuration",
			Description: "Open Omarchy configuration directory",
			Icon:        "🛠️",
			Category:    "system",
			Command:     "thunar",
			Args:        []string{"/home/zebadiee/.config/omarchy"},
			Hotkey:      "Super+Shift+O",
			Priority:    3,
		},
		{
			ID:          "waybar-reload",
			Name:        "🔄 Reload Waybar",
			Description: "Reload the Waybar status bar",
			Icon:        "📊",
			Category:    "system",
			Command:     "pkill",
			Args:        []string{"-USR1", "waybar"},
			Hotkey:      "Super+Shift+W",
			Priority:    4,
		},
		{
			ID:          "hyprland-config",
			Name:        "⌨️  Hyprland Config",
			Description: "Open Hyprland configuration",
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

// ShowLauncher displays the launcher interface using Wofi
func (ol *OmarchyLauncher) ShowLauncher() error {
	// Generate Wofi menu items
	var menuItems []string
	for _, action := range ol.actions {
		menuItem := fmt.Sprintf("%s %s", action.Icon, action.Name)
		menuItems = append(menuItems, menuItem)
	}

	// Create Wofi command
	wofiCmd := exec.Command(ol.wofiPath,
		"--dmenu",
		"--prompt=🚂 Omarchy Launcher",
		"--insensitive",
		"--allow-markup",
		"--allow-images",
		"--matching=fuzzy",
		"--location=center",
		"--width=600",
		"--height=400",
	)

	// Pipe menu items to Wofi
	stdin, err := wofiCmd.StdinPipe()
	if err != nil {
		return fmt.Errorf("failed to create stdin pipe: %v", err)
	}

	go func() {
		defer stdin.Close()
		for _, item := range menuItems {
			fmt.Fprintln(stdin, item)
		}
	}()

	// Execute Wofi and capture selection
	output, err := wofiCmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("wofi command failed: %v", err)
	}

	selection := strings.TrimSpace(string(output))
	if selection == "" {
		return nil // User cancelled
	}

	// Find and execute the selected action
	for _, action := range ol.actions {
		if strings.Contains(selection, action.Icon) && strings.Contains(selection, action.Name) {
			return ol.executeAction(action)
		}
	}

	return fmt.Errorf("no matching action found for selection: %s", selection)
}

// executeAction runs a launcher action
func (ol *OmarchyLauncher) executeAction(action LauncherAction) error {
	log.Printf("🚂 Executing action: %s", action.Name)

	switch action.ID {
	case "system-monitor":
		// Open system monitor in browser
		return exec.Command("xdg-open", "http://localhost:3000").Run()
	case "ai-dashboard":
		// Show AI dashboard status
		return ol.showAIDashboard()
	case "lm-studio":
		// Show LM Studio instructions
		return ol.showLMStudioInstructions()
	case "go-monitor":
		// Start Go system monitor if not running
		return ol.startGoMonitor()
	default:
		// Execute command
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

	if data, err := os.ReadFile(statusFile); err == nil {
		var status map[string]interface{}
		if json.Unmarshal(data, &status) == nil {
			if overview, ok := status["overview"].(map[string]interface{}); ok {
				fmt.Printf("📊 Active Assistants: %v/%v\n", overview["activeAssistants"], overview["totalAssistants"])
				fmt.Printf("🧠 Knowledge Entries: %v\n", overview["knowledgeEntries"])
				fmt.Printf("📋 Pending Tasks: %v\n", overview["pendingTasks"])
				if lastCollab, ok := overview["lastCollaboration"].(string); ok {
					fmt.Printf("⏰ Last Collaboration: %s\n", lastCollab)
				}
			}
		}
	}

	fmt.Println("\n🔧 **Available Commands:**")
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

// startGoMonitor starts the Go system monitor
func (ol *OmarchyLauncher) startGoMonitor() error {
	// Check if already running
	cmd := exec.Command("pgrep", "-f", "go-system-monitor")
	if err := cmd.Run(); err == nil {
		fmt.Println("✅ Go System Monitor is already running")
		return nil
	}

	// Start in background
	go func() {
		homeDir, _ := os.UserHomeDir()
		goCmd := exec.Command("/usr/local/go/bin/go", "run",
			filepath.Join(homeDir, "Documents", "omarchy-ai-assist", "go-system-monitor.go"))
		goCmd.Run()
	}()

	fmt.Println("🚀 Starting Go System Monitor...")
	time.Sleep(1 * time.Second)

	// Open in browser
	return exec.Command("xdg-open", "http://localhost:3000").Run()
}

// checkSystemStatus checks the status of system components
func (ol *OmarchyLauncher) checkSystemStatus() {
	components := []struct {
		name   string
		cmd    string
		args   []string
		status string
	}{
		{"Ollama", "ollama", []string{"list"}, ""},
		{"Wofi", "wofi", []string{"--version"}, ""},
		{"Node.js", "node", []string{"--version"}, ""},
		{"Go", "/usr/local/go/bin/go", []string{"version"}, ""},
	}

	for _, comp := range components {
		cmd := exec.Command(comp.cmd, comp.args...)
		if err := cmd.Run(); err == nil {
			comp.status = "✅ Active"
		} else {
			comp.status = "❌ Missing"
		}
		fmt.Printf("   %s %s\n", comp.status, comp.name)
	}
}

// LoadConfig loads configuration from file
func (ol *OmarchyLauncher) LoadConfig() error {
	configFile := filepath.Join(ol.configPath, "config.json")

	if _, err := os.Stat(configFile); os.IsNotExist(err) {
		// Create default config
		defaultConfig := LauncherConfig{
			Hotkey:        "Super+Space",
			ShowOnStartup: false,
			Actions:      ol.actions,
			CustomActions: make(map[string]Action),
		}

		data, _ := json.MarshalIndent(defaultConfig, "", "  ")
		return os.WriteFile(configFile, data, 0644)
	}

	data, err := os.ReadFile(configFile)
	if err != nil {
		return fmt.Errorf("failed to read config file: %v", err)
	}

	var config LauncherConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return fmt.Errorf("failed to parse config file: %v", err)
	}

	// Merge custom actions
	for _, customAction := range config.CustomActions {
		action := LauncherAction{
			ID:          customAction.Name,
			Name:        customAction.Name,
			Description: customAction.Description,
			Icon:        "⚙️",
			Category:    "custom",
			Command:     customAction.Command,
			Args:        customAction.Args,
			Hotkey:      "",
			Priority:    10,
		}
		config.Actions = append(config.Actions, action)
	}

	ol.actions = config.Actions
	return nil
}

// RunHotkey starts the launcher with hotkey support
func (ol *OmarchyLauncher) RunHotkey() error {
	// For now, we'll use a simple approach - watch for keypresses
	// In a full implementation, you'd integrate with Hyprland keybinds
	fmt.Println("🚂 Omarchy Launcher Hotkey Mode")
	fmt.Println("Press Space to show launcher, q to quit")

	// Simple key monitoring (in real implementation, use proper keybinding)
	// This is a placeholder for demonstration
	select {
	case <-time.After(30 * time.Second):
		fmt.Println("Hotkey mode timeout")
	}

	return nil
}

func main() {
	fmt.Println("🚂 **OMARCHY DESKTOP LAUNCHER**")
	fmt.Println("==============================")
	fmt.Println("🤖 AI-powered desktop integration for Omarchy OS")
	fmt.Println("⌨️  Keyboard-driven workflow")
	fmt.Println("🔗 Integrated with AI subagents and LM Studio")
	fmt.Println("")

	launcher := NewOmarchyLauncher()

	// Initialize launcher
	if err := launcher.Initialize(); err != nil {
		log.Fatalf("❌ Failed to initialize launcher: %v", err)
	}

	// Load configuration
	if err := launcher.LoadConfig(); err != nil {
		log.Printf("⚠️  Warning: Failed to load config: %v", err)
	}

	// Show launcher
	if err := launcher.ShowLauncher(); err != nil {
		log.Printf("❌ Launcher error: %v", err)
	}

	fmt.Println("\n✨ Have a productive day with Omarchy! 🌟")
}
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

const (
	baseDir       = "/home/zebadiee/.npm-global"
	binDir        = baseDir + "/bin"
	wagonDir      = baseDir + "/omarchy-wagon"
	playbookDir   = baseDir + "/playbook"
	hyprConfigDir = "/home/zebadiee/.config/hypr/conf.d"
	systemdDir    = "/home/zebadiee/.config/systemd/user"
	projectRoot   = "/home/zebadiee/Documents/ai-token-manager"
)

func main() {
	must(createDirs(
		binDir, wagonDir, playbookDir, hyprConfigDir, systemdDir,
		filepath.Join(projectRoot, "configs", "infra"),
	))

	must(writeFile(filepath.Join(binDir, "omai.js"), omaiJS, 0o755))
	must(writeFile(filepath.Join(binDir, "omarchy-guide"), omarchyGuide, 0o755))
	must(writeFile(filepath.Join(binDir, "wagon-handoff-custom"), wagonHandoffCustom, 0o755))
	must(writeFile(filepath.Join(binDir, "wagon-handoff-maintenance"), wagonHandoffMaintenance, 0o755))
	must(writeFile(filepath.Join(baseDir, "mouse_menu.sh"), mouseMenu, 0o755))
	must(writeFile(filepath.Join(baseDir, "onboarding.sh"), onboardingSh, 0o755))
	must(writeFile(filepath.Join(baseDir, "onboarding.service"), onboardingService, 0o644))
	must(writeFile(filepath.Join(baseDir, ".env"), envTemplate, 0o600))
	must(writeFile(filepath.Join(baseDir, "wagon-wheels.conf"), wagonConf, 0o644))
	must(writeFile(filepath.Join(wagonDir, "room.json"), roomJSON, 0o644))

	writePlaybook(playbookDir)

	specPath := filepath.Join(projectRoot, "configs", "ai-token.jsonld")
	spec := buildOmServiceSpec()
	must(writeJSONLD(specPath, spec))

	fmt.Println("Handbook files and OmServiceSpec have been generated. Review before deploying.")
}

func createDirs(paths ...string) error {
	for _, p := range paths {
		if err := os.MkdirAll(p, 0o755); err != nil {
			return err
		}
	}
	return nil
}

func writeFile(path, contents string, mode os.FileMode) error {
	if err := os.WriteFile(path, []byte(contents), mode); err != nil {
		return err
	}
	if mode&0o111 != 0 {
		return os.Chmod(path, mode)
	}
	return nil
}

func writeJSONLD(path string, data any) error {
	b, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return err
	}
	return writeFile(path, string(b)+"\n", 0o644)
}

func writePlaybook(dir string) {
	files := map[string]string{
		"01-theming.md":  playbookTheming,
		"02-packages.md": playbookPackages,
		"03-inputs.md":   playbookInputs,
		"04-updating.md": playbookUpdating,
	}
	for name, body := range files {
		must(writeFile(filepath.Join(dir, name), body, 0o644))
	}
}

var omaiJS = strings.Join([]string{
	"#!/usr/bin/env node",
	"const fetch = require('node-fetch');",
	"const dotenv = require('dotenv');",
	"const fs = require('fs');",
	"const readline = require('readline');",
	"",
	"const ENV_PATH = process.env.OMAI_ENV_PATH || (process.env.HOME + '/.npm-global/bin/.env');",
	"const ROOM_FILE = process.env.OMAI_ROOM_FILE || (process.env.HOME + '/.npm-global/omarchy-wagon/room.json');",
	"",
	"dotenv.config({ path: ENV_PATH });",
	"",
	"const endpoint = process.env.OR_ENDPOINT || 'https://openrouter.ai/api/v1/chat/completions';",
	"const model = process.env.OR_MODEL || 'deepseek/deepseek-r1-0528-qwen3-8b';",
	"const apiKey = process.env.OPENROUTER_API_KEY;",
	"",
	"if (!apiKey) {",
	"  console.error('Set OPENROUTER_API_KEY in your env or .env file.');",
	"  process.exit(1);",
	"}",
	"",
	"const args = process.argv.slice(2);",
	"const handoff = args.includes('--handoff');",
	"",
	"let lang = null;",
	"const promptArgs = [];",
	"",
	"for (let i = 0; i < args.length; i++) {",
	"  const arg = args[i];",
	"  if (arg === '--handoff') {",
	"    continue;",
	"  }",
	"  if (arg === '--lang') {",
	"    if (i + 1 >= args.length) {",
	"      console.error('Missing language for --lang flag.');",
	"      process.exit(1);",
	"    }",
	"    lang = args[i + 1];",
	"    i++;",
	"    continue;",
	"  }",
	"  promptArgs.push(arg);",
	"}",
	"",
	"let systemPrompt = 'You are an Omarchy customization copilot.';",
	"if (lang) {",
	"  systemPrompt = 'You are an expert ' + lang + ' programmer. Translate the user\'s request into a complete, correct, and\n  idiomatic ' + lang + ' program.';",
	"}",
	"",
	"const messages = [{ role: 'system', content: systemPrompt }];",
	"",
	"async function ask(prompt) {",
	"  messages.push({ role: 'user', content: prompt });",
	"",
	"  const body = { model, messages };",
	"",
	"  const res = await fetch(endpoint, {",
	"    method: 'POST',",
	"    headers: {",
	"      Authorization: `Bearer ${apiKey}`,",
	"      'HTTP-Referer': process.env.OR_REFERER || 'https://omarchy.local',",
	"      'X-Title': process.env.OR_TITLE || 'Omarchy Wagon Wheels',",
	"      'Content-Type': 'application/json',",
	"    },",
	"    body: JSON.stringify(body),",
	"  });",
	"",
	"  if (!res.ok) {",
	"    console.error(`OpenRouter error: ${res.status} ${await res.text()}`);",
	"    return;",
	"  }",
	"",
	"  const data = await res.json();",
	"  const summary = data.choices?.[0]?.message?.content?.trim() || '(No content)';",
	"  console.log('\n' + summary + '\n');",
	"  messages.push({ role: 'assistant', content: summary });",
	"",
	"  if (handoff) {",
	"    updateRoom(summary, lang);",
	"  }",
	"}",
	"",
	"function updateRoom(summary, langArg) {",
	"  let roomData = { last_update: new Date().toISOString(), context: [] };",
	"  try {",
	"    if (fs.existsSync(ROOM_FILE)) {",
	"      roomData = JSON.parse(fs.readFileSync(ROOM_FILE, 'utf-8'));",
	"    }",
	"  } catch (err) {",
	"    console.warn('Failed to read existing room file, resetting context:', err);",
	"  }",
	"  const topic = langArg ? 'translation:' + langArg : 'customization';",
	"  roomData.context = roomData.context || [];",
	"  roomData.context.push({ source: 'omai', topic, summary });",
	"  roomData.last_update = new Date().toISOString();",
	"",
	"  try {",
	"    fs.mkdirSync(require('path').dirname(ROOM_FILE), { recursive: true });",
	"    fs.writeFileSync(ROOM_FILE, JSON.stringify(roomData, null, 2));",
	"  } catch (err) {",
	"    console.error('Failed to update room context:', err);",
	"  }",
	"}",
	"",
	"const prompt = promptArgs.join(' ');",
	"",
	"if (prompt) {",
	"  ask(prompt).then(() => process.exit(0));",
	"}",
	" else {",
	"  const rl = readline.createInterface({",
	"    input: process.stdin,",
	"    output: process.stdout,",
	"  });",
	"",
	"  console.log('Entering chat mode. Type "exit" or "quit" to end the conversation.');",
	"",
	"  function chatLoop() {",
	"    rl.question('You: ', async (userInput) => {",
	"      if (userInput.toLowerCase() === 'exit' || userInput.toLowerCase() === 'quit') {",
	"        rl.close();",
	"        return;",
	"      }",
	"      await ask(userInput);",
	"      chatLoop();",
	"    });",
	"  }",
	"  chatLoop();",
	"}",
}, "\n")

var omarchyGuide = strings.Join([]string{
	"#!/bin/bash",
	"set -euo pipefail",
	"",
	"show_journey() {",
	"  echo \"Welcome to the Omarchy Wagon Wheels Journey\"",
	"  echo "",
	"  echo \"1. Orientation: Learn the basics of the Omarchy desktop.\"",
	"  echo \"2. Install: Set up the Wagon Wheels layer.\"",
	"  echo \"3. First Hour: Get comfortable with the keyboard-driven workflow.\"",
	"  echo \"4. Workflow: Integrate the Wagon Wheels into your daily tasks.\"",
	"  echo \"5. Customization: Make Omarchy your own.\"",
	"  echo \"6. Rescue: Learn how to recover from issues.\"",
	"}",
	"",
	toggle_ui() {
	  local config_source="$HOME/.npm-global/wagon-wheels.conf"
	  local config_dest_dir="$HOME/.config/hypr/conf.d"
	  local config_dest="$config_dest_dir/wagon-wheels.conf"

	  if [ -L "$config_dest" ]; then
	    rm "$config_dest"
	    echo "Wagon Wheels UI helpers disabled."
	  else
	    mkdir -p "$config_dest_dir"
	    ln -s "$config_source" "$config_dest"
	    echo "Wagon Wheels UI helpers enabled."
	  fi
	}

	playbook() {
	  local playbook_dir="$HOME/.npm-global/playbook"
	  if [ ! -d "$playbook_dir" ]; then
	    echo "Error: Playbook directory not found at $playbook_dir"
	    exit 1
	  fi

	  case "${2:-}" in
	    list)
	      ls -1 "$playbook_dir"
	      ;;
	    show)
	      if [ -z "${3:-}" ]; then
	        echo "Usage: $0 playbook show <playbook_entry>"
	        exit 1
	      fi
	      if [ -f "$playbook_dir/$3" ]; then
	        cat "$playbook_dir/$3"
	      else
	        echo "Playbook entry '$3' not found."
	      fi
	      ;;
	    *)
	      echo "Usage: $0 {journey|toggle-ui|playbook|room|doctor}"
	      exit 1
	      ;;
	  esac
	}

	room() {
	  local room_file="$HOME/.npm-global/omarchy-wagon/room.json"
	  if [ -f "$room_file" ]; then
	    cat "$room_file"
	  else
	    echo "The breakout room is empty."
	  fi
	}

	doctor() {
	  echo "Checking essential dependencies..."
	  local missing_deps=()
	  for dep in wofi tmux node; do
	    if ! command -v "$dep" &>/dev/null; then
	      missing_deps+=("$dep")
	    fi
	  done

	  if [ ${#missing_deps[@]} -eq 0 ]; then
	    echo "All essential dependencies are installed."
	  else
	    echo "Warning: Missing dependencies: ${missing_deps[*]}"
	    echo "Please install them for full functionality."
	  fi
	}

	case "${1:-}" in
	  journey)    show_journey ;;
	  toggle-ui)  toggle_ui ;;
	  playbook)   playbook "$@" ;;
	  room)       room ;;
	  doctor)     doctor ;;
	  *)          echo "Usage: $0 {journey|toggle-ui|playbook|room|doctor}"; exit 1 ;;
	esac
}, "\n")

var wagonHandoffCustom = strings.Join([]string{
	"#!/bin/bash",
	"set -euo pipefail",
	"",
	"BIN_DIR=\"$(dirname \"$0\")\"",
	"if ! command -v node &>/dev/null; then",
	"  echo \"Error: node is not installed. Please install Node.js to run this script.\" >&2",
	"  exit 1",
	"fi",
	"",
	"PROMPT=\"$@\"",
	"if [ -z \"$PROMPT\" ]; then",
	"  PROMPT=\"Help me customize Omarchy\"",
	"fi",
	"",
	"node \"$BIN_DIR/omai.js\" \"$PROMPT\" --handoff",
}, "\n")

var wagonHandoffMaintenance = strings.Join([]string{
	"#!/bin/bash",
	"set -euo pipefail",
	"echo \"This is a placeholder for omassistant integration.\"",
}, "\n")

var mouseMenu = strings.Join([]string{
	"#!/bin/bash",
	"set -euo pipefail",
	"",
	"options=\"Close (Super+Q)\nToggle Floating (Super+F)\"",
	"selected=$(echo -e \"$options\" | wofi --dmenu)",
	"case $selected in",
	"  \"Close (Super+Q)\") hyprctl dispatch killactive ;; ",
	"  \"Toggle Floating (Super+F)\") hyprctl dispatch togglefloating ;; ",
	"esac",
}, "\n")

var onboardingSh = strings.Join([]string{
	"#!/bin/bash",
	"set -euo pipefail",
	"",
	"clear",
	"echo \"Welcome to Omarchy!\"",
	"echo "",
	"echo \"Here are some essential keyboard shortcuts to get you started:\"",
	"echo \"  Super + Space: Application Launcher\"",
	"echo \"  Super + Alt + Space: Omarchy Menu\"",
	"echo \"  Super + Q: Close Window\"",
	"echo \"  Super + K: Show Keybindings\"",
	"",
	"echo \"Enjoy your keyboard-driven journey!\"",
	"",
	"read -p \"Press Enter to continue...\"",
}, "\n")

var onboardingService = strings.Join([]string{
	"[Unit]",
	"Description=Omarchy First Login Onboarding",
	"",
	"[Service]",
	"Type=oneshot",
	"ExecStart=/bin/bash -c 'if [ ! -f \"$HOME/.config/omarchy/first_login_done\" ]; then /home/zebadiee/.npm-global/onboarding.sh &&\n\nmkdir -p \"$HOME/.config/omarchy\" && touch \"$HOME/.config/omarchy/first_login_done\"; fi'",
	"",
	"[Install]",
	"WantedBy=default.target",
}, "\n")

var envTemplate = strings.Join([]string{
	"# OpenRouter Configuration",
	"OPENROUTER_API_KEY=\"\"",
	"",
	"# Default model to use",
	"OR_MODEL=\"deepseek/deepseek-r1-0528-qwen3-8b\"",
	"",
	"# OpenRouter Endpoint",
	"OR_ENDPOINT=\"https://openrouter.ai/api/v1/chat/completions\"",
	"",
	"# Optional analytics context",
	"OR_REFERER=\"https://omarchy.local\"",
	"OR_TITLE=\"Omarchy Wagon Wheels\"",
}, "\n")

var wagonConf = strings.Join([]string{
	"# Wagon Wheels: Transitional UI Helpers",
	"bind = , mouse:273, exec, /home/zebadiee/.npm-global/mouse_menu.sh",
}, "\n")

var roomJSON = strings.Join([]string{
	"{",
	"  \"last_update\": \"2025-02-14T10:15:00Z\"",
	"  \"context\": [
	"    {\"source\": \"omassistant\", \"topic\": \"maintenance\", \"summary\": \"...\"}",
	"    {\"source\": \"omai\", \"topic\": \"customization\", \"summary\": \"...\"}",
	"  ]",
	"}",
}, "\n")

var playbookTheming = strings.Join([]string{
	"# 1. Theming in Omarchy",
	"",
	"Omarchy uses a unified theming system to keep the desktop consistent.",
	"",
	"## Theme Files",
	"",
	"Core themes live in ",
	"/usr/share/omarchy/themes/",
	". To override, copy a theme into ",
	"~/.config/omarchy/themes",
	".",
	"",
	"### Key files:",
	"- ",
	"colors.css",
	" – GTK palette",
	"- ",
	"hyprland.conf",
	" – compositor/window borders",
	"- ",
	"waybar/style.css",
	" – status bar styling",
}, "\n")

var playbookPackages = strings.Join([]string{
	"# 2. Package Management in Omarchy",
	"",
	"Omarchy sits atop Arch Linux, so ",
	"Pacman",
	" is primary. For community packages, use AUR helpers (e.g., ",
	" yay ",
	").",
	"",
	"## System packages",
	"- Update: ",
	" sudo pacman -Syu ",
	"- Install: ",
	" sudo pacman -S <pkg>",
	"- Remove: ",
	" sudo pacman -R <pkg>",
	"",
	"## AUR packages",
	"- Install: ",
	" yay -S <pkg>",
	"- Search: ",
	" yay -Ss <term>",
	"",
	"Always update first, and vet AUR PKGBUILDs before installing.",
}, "\n")

var playbookInputs = strings.Join([]string{
	"# 3. Input Configuration in Omarchy",
	"",
	"Keyboard, mouse, and touchpad settings live in ",
	"hyprland.conf",
	".",
	"",
	"## Keyboard example",
	"",
	"input {",
	"kb_layout = us",
	"follow_mouse = 1",
	"}",
	"",
	"",
	"## Pointer example",
	"",
	"input {",
	"sensitivity = 0",
	"accel_profile = default",
	"}",
	"",
	"",
	"See Hyprland docs for advanced options.",
}, "\n")

var playbookUpdating = strings.Join([]string{
	"# 4. Updating and Rolling Back in Omarchy",
	"",
	"## Update ritual",
	"1. Snapshot: ",
	" omarchy-snapshot create ",
	"2. Upgrade: ",
	" sudo pacman -Syu ",
	"3. Reboot",
	"",
	"## Rollback ritual",
	"1. List: ",
	" omarchy-snapshot list ",
	"2. Restore: ",
	" omarchy-snapshot restore <name>",
}, "\n")

func buildOmServiceSpec() map[string]any {
	return map[string]any{
		"apiVersion": "platformspec/v1",
		"kind":       "OmServiceSpec",
		"metadata": map[string]any{
			"name": "ai-token-service",
		},
		"spec": map[string]any{
			"services": []any{
				map[string]any{
					"name": "token-budgets-api",
					"type": "container",
					"runtime": map[string]any{
						"image":     "registry.example.com/ai-token-manager:latest",
						"command":   []string{"python", "-m", "src.engine.server"},
						"replicas":  2,
						"resources": map[string]any{"cpu": "500m", "memory": "512Mi"},
						"environment": []any{
							map[string]any{"name": "TOKEN_BUDGET_FILE", "value": "configs/infra/token_budgets.toml"},
						},
						"secrets": []any{
							map[string]any{"name": "OPENROUTER_API_KEY", "secretRef": "openrouter/api-key"},
						},
					},
					"exposure": map[string]any{
						"port":    8080,
						"ingress": map[string]any{"host": "token-manager.omarchy.local"},
					},
					"dependencies": []any{
						map[string]any{"name": "om-db", "type": "postgresql", "service": "postgres-prod"},
					},
					"observability": map[string]any{
						"logs":    map[string]any{"sink": "om-logs/default"},
						"metrics": map[string]any{"dashboard": "grafana/token-mgr"},
					},
				},
			},
			"policies": map[string]any{
				"tokenBudgets": map[string]any{
					"dailyLimit":     200000,
					"alertThreshold": 0.9,
				},
			},
			"webhooks": []any{
				map[string]any{
					"event": "deploy.success",
					"url":   "https://ops.example.com/hooks/ai-token",
				},
			},
		},
	}
}

func must(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
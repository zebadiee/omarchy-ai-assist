#!/usr/bin/env python3
"""
Omarchy Launcher Waybar Module
Displays launcher status and quick access to AI subagents
"""

import json
import os
import subprocess
import time
from pathlib import Path


class OmarchyLauncherModule:
    def __init__(self):
        self.home_dir = Path.home()
        self.config_dir = self.home_dir / ".config" / "omarchy" / "launcher"
        self.status_file = self.config_dir / "status.json"
        self.last_update = 0
        self.ai_status = {}

    def get_ai_status(self):
        """Get current AI team status"""
        if time.time() - self.last_update < 30:  # Cache for 30 seconds
            return self.ai_status

        try:
            # Read AI team status
            status_file = self.home_dir / "Documents" / "omarchy-ai-assist" / "knowledge-outbox" / "team-status" / "latest.json"
            if status_file.exists():
                with open(status_file, 'r') as f:
                    data = json.load(f)
                    overview = data.get('overview', {})
                    self.ai_status = {
                        'active': overview.get('activeAssistants', 0),
                        'total': overview.get('totalAssistants', 0),
                        'knowledge': overview.get('knowledgeEntries', 0),
                        'tasks': overview.get('pendingTasks', 0)
                    }
        except Exception:
            self.ai_status = {'active': 0, 'total': 0, 'knowledge': 0, 'tasks': 0}

        self.last_update = time.time()
        return self.ai_status

    def get_launcher_status(self):
        """Get launcher status"""
        try:
            if self.status_file.exists():
                with open(self.status_file, 'r') as f:
                    data = json.load(f)
                    return data.get('status', 'ready')
        except Exception:
            pass
        return 'ready'

    def get_text(self):
        """Get module text"""
        ai_status = self.get_ai_status()
        launcher_status = self.get_launcher_status()

        if ai_status['active'] > 0:
            return f"🤖 {ai_status['active']}/{ai_status['total']} | 🧠 {ai_status['knowledge']} | 📋 {ai_status['tasks']} | 🚂 {launcher_status}"
        else:
            return f"🚂 {launcher_status}"

    def get_tooltip(self):
        """Get module tooltip"""
        ai_status = self.get_ai_status()
        launcher_status = self.get_launcher_status()

        tooltip = "Omarchy AI Collaboration System\n"
        tooltip += f"Launcher Status: {launcher_status}\n"
        tooltip += f"Active AI Assistants: {ai_status['active']}/{ai_status['total']}\n"
        tooltip += f"Knowledge Entries: {ai_status['knowledge']}\n"
        tooltip += f"Pending Tasks: {ai_status['tasks']}\n\n"
        tooltip += "Hotkeys:\n"
        tooltip += "Super+Space: Show launcher\n"
        tooltip += "Super+Alt+P: AI Planner\n"
        tooltip += "Super+Alt+I: AI Implementor\n"
        tooltip += "Super+Alt+K: AI Knowledge\n"
        tooltip += "Super+Shift+S: System Monitor"

        return tooltip

    def output(self):
        """Output module data in waybar format"""
        text = self.get_text()
        tooltip = self.get_tooltip()

        print(json.dumps({
            "text": text,
            "tooltip": tooltip,
            "class": "omarchy-launcher",
            "percentage": 100 if self.get_launcher_status() == 'ready' else 0
        }))


if __name__ == "__main__":
    module = OmarchyLauncherModule()
    module.output()
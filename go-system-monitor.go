package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime"
	"time"
)

// SystemMonitor represents the main monitoring system
type SystemMonitor struct {
	startTime   time.Time
	aiEndpoint  string
	nodejsPort  int
}

// SystemMetrics holds current system metrics
type SystemMetrics struct {
	Timestamp    time.Time `json:"timestamp"`
	Uptime       string    `json:"uptime"`
	MemoryUsage  MemInfo   `json:"memory_usage"`
	CPUUsage     CPUInfo   `json:"cpu_usage"`
	GoRoutines   int       `json:"go_routines"`
	AIStatus     AIStatus  `json:"ai_status"`
}

// MemInfo holds memory information
type MemInfo struct {
	Alloc      uint64 `json:"alloc"`
	TotalAlloc uint64 `json:"total_alloc"`
	Sys        uint64 `json:"sys"`
	NumGC      uint32 `json:"num_gc"`
}

// CPUInfo holds CPU information
type CPUInfo struct {
	NumCPU     int    `json:"num_cpu"`
	GoVersion  string `json:"go_version"`
	OS         string `json:"os"`
	Arch       string `json:"arch"`
}

// AIStatus holds AI team status
type AIStatus struct {
	ActiveAssistants int    `json:"active_assistants"`
	TotalAssistants  int    `json:"total_assistants"`
	KnowledgeEntries int    `json:"knowledge_entries"`
	LastUpdate       string `json:"last_update"`
	Health           string `json:"health"`
}

// NewSystemMonitor creates a new system monitor instance
func NewSystemMonitor() *SystemMonitor {
	return &SystemMonitor{
		startTime:   time.Now(),
		aiEndpoint:  "http://localhost:3000/api/status",
		nodejsPort:  3001,  // Changed from 3000 to avoid conflicts
	}
}

// collectMetrics gathers current system metrics
func (sm *SystemMonitor) collectMetrics() SystemMetrics {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	// Get AI team status
	aiStatus := sm.getAIStatus()

	return SystemMetrics{
		Timestamp:   time.Now(),
		Uptime:      time.Since(sm.startTime).String(),
		MemoryUsage: MemInfo{
			Alloc:      m.Alloc,
			TotalAlloc: m.TotalAlloc,
			Sys:        m.Sys,
			NumGC:      m.NumGC,
		},
		CPUUsage: CPUInfo{
			NumCPU:    runtime.NumCPU(),
			GoVersion: runtime.Version(),
			OS:        runtime.GOOS,
			Arch:      runtime.GOARCH,
		},
		GoRoutines: runtime.NumGoroutine(),
		AIStatus:   aiStatus,
	}
}

// getAIStatus fetches AI team status from the Node.js integration
func (sm *SystemMonitor) getAIStatus() AIStatus {
	// Default values
	status := AIStatus{
		ActiveAssistants: 3,
		TotalAssistants:  5,
		KnowledgeEntries: 13,
		LastUpdate:       time.Now().Format(time.RFC3339),
		Health:           "healthy",
	}

	// Try to read from the latest AI team status file
	if data, err := os.ReadFile("../knowledge-outbox/team-status/latest.json"); err == nil {
		var teamStatus map[string]interface{}
		if json.Unmarshal(data, &teamStatus) == nil {
			if overview, ok := teamStatus["overview"].(map[string]interface{}); ok {
				if active, ok := overview["activeAssistants"].(float64); ok {
					status.ActiveAssistants = int(active)
				}
				if total, ok := overview["totalAssistants"].(float64); ok {
					status.TotalAssistants = int(total)
				}
				if knowledge, ok := overview["knowledgeEntries"].(float64); ok {
					status.KnowledgeEntries = int(knowledge)
				}
				if lastCollab, ok := overview["lastCollaboration"].(string); ok {
					status.LastUpdate = lastCollab
				}
			}
		}
	}

	// Determine health status
	if status.ActiveAssistants >= 3 {
		status.Health = "healthy"
	} else if status.ActiveAssistants >= 1 {
		status.Health = "degraded"
	} else {
		status.Health = "offline"
	}

	return status
}

// startWebServer starts the HTTP server for monitoring dashboard
func (sm *SystemMonitor) startWebServer() {
	http.HandleFunc("/", sm.handleIndex)
	http.HandleFunc("/api/metrics", sm.handleMetrics)
	http.HandleFunc("/api/health", sm.handleHealth)

	log.Printf("🚀 Omarchy System Monitor starting on port %d", sm.nodejsPort)
	log.Printf("📊 Dashboard: http://localhost:%d", sm.nodejsPort)
	log.Printf("📡 Metrics API: http://localhost:%d/api/metrics", sm.nodejsPort)

	if err := http.ListenAndServe(fmt.Sprintf(":%d", sm.nodejsPort), nil); err != nil {
		log.Fatal("❌ Failed to start web server:", err)
	}
}

// handleIndex serves the main dashboard
func (sm *SystemMonitor) handleIndex(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html")

	html := `<!DOCTYPE html>
<html>
<head>
    <title>🚂 Omarchy System Monitor</title>
    <meta charset="utf-8">
    <style>
        body { font-family: system-ui, sans-serif; margin: 0; background: #1a1a1a; color: #fff; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .metric-card { background: #2a2a2a; border-radius: 8px; padding: 20px; border-left: 4px solid #4CAF50; }
        .metric-title { font-size: 14px; color: #888; margin-bottom: 8px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #4CAF50; }
        .status-healthy { border-left-color: #4CAF50; }
        .status-degraded { border-left-color: #FF9800; }
        .status-offline { border-left-color: #f44336; }
        .refresh-btn { background: #4CAF50; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; }
        .refresh-btn:hover { background: #45a049; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚂 Omarchy System Monitor</h1>
            <p>Real-time AI team and system performance monitoring</p>
            <button class="refresh-btn" onclick="location.reload()">🔄 Refresh</button>
        </div>
        <div class="metrics-grid" id="metrics-container">
            <div class="metric-card">
                <div class="metric-title">System Uptime</div>
                <div class="metric-value" id="uptime">Loading...</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Memory Usage</div>
                <div class="metric-value" id="memory">Loading...</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Go Routines</div>
                <div class="metric-value" id="goroutines">Loading...</div>
            </div>
            <div class="metric-card" id="ai-status-card">
                <div class="metric-title">AI Team Status</div>
                <div class="metric-value" id="ai-status">Loading...</div>
            </div>
        </div>
    </div>
    <script>
        function formatBytes(bytes) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }

        async function updateMetrics() {
            try {
                const response = await fetch('/api/metrics');
                const data = await response.json();

                document.getElementById('uptime').textContent = data.uptime;
                document.getElementById('memory').textContent = formatBytes(data.memory_usage.alloc);
                document.getElementById('goroutines').textContent = data.go_routines;

                const aiStatus = document.getElementById('ai-status');
                const aiCard = document.getElementById('ai-status-card');
                aiStatus.textContent = data.ai_status.active_assistants + "/" + data.ai_status.total_assistants + " Active";

                // Update card color based on health
                aiCard.className = 'metric-card status-' + data.ai_status.health;
            } catch (error) {
                console.error('Failed to fetch metrics:', error);
            }
        }

        // Update metrics immediately and then every 5 seconds
        updateMetrics();
        setInterval(updateMetrics, 5000);
    </script>
</body>
</html>`

	fmt.Fprint(w, html)
}

// handleMetrics serves the metrics as JSON
func (sm *SystemMonitor) handleMetrics(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	metrics := sm.collectMetrics()
	json.NewEncoder(w).Encode(metrics)
}

// handleHealth serves health check endpoint
func (sm *SystemMonitor) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	metrics := sm.collectMetrics()
	health := map[string]interface{}{
		"status":    "healthy",
		"timestamp": metrics.Timestamp,
		"uptime":    metrics.Uptime,
		"ai_team":   metrics.AIStatus.Health,
	}

	if metrics.AIStatus.Health == "offline" {
		health["status"] = "degraded"
	}

	json.NewEncoder(w).Encode(health)
}

func main() {
	fmt.Println("🚂 **OMARCHY SYSTEM MONITOR - PHASE 1**")
	fmt.Println("=====================================")
	fmt.Println("🐹 Go-based system monitoring for AI team")
	fmt.Println("📊 Real-time metrics and health monitoring")
	fmt.Println("🔗 Integrates with Node.js AI collaboration hub")
	fmt.Println("")

	monitor := NewSystemMonitor()

	// Log startup information
	fmt.Printf("✅ System Monitor initialized\n")
	fmt.Printf("⏰ Started: %s\n", monitor.startTime.Format(time.RFC3339))
	fmt.Printf("🧠 Go Runtime: %s\n", runtime.Version())
	fmt.Printf("💻 Platform: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	fmt.Printf("🔌 CPUs: %d\n", runtime.NumCPU())
	fmt.Println("")

	// Start the web server
	monitor.startWebServer()
}
package main

import (
	"bufio"
	"encoding/json"
	"html/template"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

type Usage struct {
	Time    string `json:"time,omitempty"`
	Event   string `json:"event,omitempty"`
	Agent   string `json:"agent,omitempty"`
	Purpose string `json:"purpose,omitempty"`
	Model   string `json:"model,omitempty"`
	Tokens  int    `json:"tokens,omitempty"`
	Cache   string `json:"cache,omitempty"` // hit/miss
}

type MDL struct {
	Timestamp string  `json:"timestamp"`
	MDL       float64 `json:"mdl"`
	Delta     float64 `json:"delta"`
}

func tailJSONL(p string, max int) []json.RawMessage {
	f, err := os.Open(p)
	if err != nil {
		return nil
	}
	defer f.Close()
	var lines []json.RawMessage
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		var raw json.RawMessage
		if json.Unmarshal([]byte(sc.Text()), &raw) == nil {
			lines = append(lines, raw)
		}
	}
	if len(lines) > max {
		lines = lines[len(lines)-max:]
	}
	return lines
}

func main() {
	root := os.Getenv("OMARCHY_ROOT")
	if root == "" {
		home, _ := os.UserHomeDir()
		root = filepath.Join(home, ".omarchy", "current")
	}
	usage := filepath.Join(root, "logs", "usage.jsonl")
	mdl := filepath.Join(root, "logs", "mdl.jsonl") // write your MDL snapshots here

	type Metrics struct {
		Now         string           `json:"now"`
		UsageRecent []json.RawMessage `json:"usage_recent"`
		MDLRecent   []json.RawMessage `json:"mdl_recent"`
	}

	http.HandleFunc("/metrics.json", func(w http.ResponseWriter, r *http.Request) {
		m := Metrics{
			Now:         time.Now().UTC().Format(time.RFC3339),
			UsageRecent: tailJSONL(usage, 200),
			MDLRecent:   tailJSONL(mdl, 200),
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(m)
	})

	tmpl := template.Must(template.New("dash").Parse(`
<!doctype html><meta charset="utf-8">
<title>Quantum-Forge Monitor</title>
<h1>Quantum-Forge Monitor</h1>
<p><code>/metrics.json</code> provides recent usage + MDL. Auto-refreshing every 5s.</p>
<pre id="out">loading…</pre>
<script>
async function tick(){
  const r = await fetch('metrics.json', {cache:'no-store'});
  const j = await r.json();
  document.getElementById('out').textContent = JSON.stringify(j,null,2);
}
tick(); setInterval(tick, 5000);
</script>`))
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_ = tmpl.Execute(w, nil)
	})

	addr := ":8088"
	log.Printf("Quantum-Forge monitor listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
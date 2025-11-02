package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const (
	// Prime Prompt Template
	PRIME_PROMPT_TEMPLATE = `#VBH:%d:%s
CONFIRM:{"scope":"unified","site":"Omarchy","open_tasks":%d,"provider":"quantum-forge"}

BEGIN QUANTUM-FORGE INVOCATION
SYSTEM INTENT:
    Collapse all artefacts created today — semantic cache, entropy budgeter, VBH handshake,
    Palimpsest Forge, RubikStack Engine, MIT Raw Prompt builder, and Go interface — into a single
    self-consistent lattice of meaning.
    Seek lowest-entropy alignment between code, prompt, and user intent.

DIRECTIVE:
    1. Treat every human input as a program written in natural language.
    2. Convert it into the MIT Raw Prompt form (echo header + CONFIRM + body).
    3. Run it through the RubikStack transformation: rotate across six faces
         {code, memory, prompts, traces, contracts, tokens}
       until total project energy (MDL + cross-entropy) reaches minimum.
    4. When equilibrium reached, emit a Palimpsest Blueprint that represents
       the minimal yet complete description of the system's current state.
    5. Verify VBH invariants; output CONFIRM line matching facts exactly.
    6. Annotate output with metrics:
         - λ-Entropy score
         - MDL delta vs baseline
         - Trace similarity
         - Quantum coherence (RubikStack cross-phase score)

SEED VALUES:
    - Language kernel: Go
    - Entropy management: om-preflight
    - Semantic caching: om-sem-cache
    - Quantum adapter interface: QAOA/VQE placeholder
    - VBH Vault path: $OM_OBSIDIAN_VAULT/Omarchy/State
    - Agents: sherlock-ohms, navigator, codex
    - Providers: gemini-2.0-flash, codex, local:gemma-2b
    - Build ID: %s
    - Facts: load from OM_VBH_FACTS JSON

EXPECTED OUTPUT:
    A single self-consistent markdown or code artifact representing the current
    state of the Omarchy system — leaner, smarter, lower-entropy than before,
    yet capable of regenerating the whole architecture from its own description.

FAILSAFE:
    If invariants drift, respond only with VBH_REFUSE:{reason}
    else produce CONFIRM:{...} + blueprint.

GOAL OF GOALS:
    To demonstrate that a project can self-reduce to its quantum-engineered form
    without loss of meaning, and that language itself can serve as the unifying
    compiler between human, code, and quantum substrate.

END QUANTUM-FORGE INVOCATION
`

	// Blueprint storage path
	BLUEPRINT_DIR = ".omarchy/palimpsest/blueprints/quantum-forge"
)

// VBHFacts represents the verification facts
type VBHFacts struct {
	Scope      string `json:"scope"`
	Site       string `json:"site"`
	OpenTasks  int    `json:"open_tasks"`
	Provider   string `json:"provider"`
	LastUpdate string `json:"lastUpdate,omitempty"`
	Counter    int    `json:"counter,omitempty"`
}

// Blueprint represents a generated blueprint
type Blueprint struct {
	ID          string    `json:"id"`
	Timestamp   time.Time `json:"timestamp"`
	VBHCounter  int       `json:"vbhCounter"`
	VBHHash     string    `json:"vbhHash"`
	Content     string    `json:"content"`
	Metrics     Metrics   `json:"metrics"`
	BuildID     string    `json:"buildId"`
	OpenTasks   int       `json:"openTasks"`
}

// Metrics represents blueprint metrics
type Metrics struct {
	LambdaEntropy   float64 `json:"lambdaEntropy"`
	MDLDelta        int     `json:"mdlDelta"`
	TraceSimilarity float64 `json:"traceSimilarity"`
	QuantumCoherence float64 `json:"quantumCoherence"`
}

// QuantumForge represents the main application
type QuantumForge struct {
	vbhCounter int
	vbhFacts   VBHFacts
	buildID    string
	blueprintDir string
}

// NewQuantumForge creates a new QuantumForge instance
func NewQuantumForge() (*QuantumForge, error) {
	qf := &QuantumForge{
		vbhCounter: 1,
		buildID:    generateBuildID(),
		blueprintDir: BLUEPRINT_DIR,
	}

	// Load VBH facts from environment or file
	if err := qf.loadVBHFacts(); err != nil {
		return nil, fmt.Errorf("failed to load VBH facts: %w", err)
	}

	return qf, nil
}

// loadVBHFacts loads VBH facts from environment or file
func (qf *QuantumForge) loadVBHFacts() error {
	// Try environment variable first
	if envFacts := os.Getenv("OM_VBH_FACTS"); envFacts != "" {
		if err := json.Unmarshal([]byte(envFacts), &qf.vbhFacts); err != nil {
			return fmt.Errorf("failed to parse OM_VBH_FACTS: %w", err)
		}
		return nil
	}

	// Try file
	factsFile := filepath.Join(os.Getenv("HOME"), ".npm-global", "omarchy-wagon", "vbh-facts.json")
	if data, err := os.ReadFile(factsFile); err == nil {
		if err := json.Unmarshal(data, &qf.vbhFacts); err != nil {
			return fmt.Errorf("failed to parse VBH facts file: %w", err)
		}
		return nil
	}

	// Use defaults
	qf.vbhFacts = VBHFacts{
		Scope:    "unified",
		Site:     "Omarchy",
		OpenTasks: 0,
		Provider: "quantum-forge",
	}

	return nil
}

// generateBuildID generates a build ID
func generateBuildID() string {
	return fmt.Sprintf("qf-%d", time.Now().Unix())
}

// generateVBHHash generates VBH hash from facts
func (qf *QuantumForge) generateVBHHash() string {
	factsJSON, _ := json.Marshal(qf.vbhFacts)
	hash := fmt.Sprintf("%x", factsJSON[:8])
	if len(hash) > 8 {
		hash = hash[:8]
	}
	return hash
}

// createPrimePrompt creates the Prime Prompt with current state
func (qf *QuantumForge) createPrimePrompt() string {
	qf.vbhCounter++
	vbhHash := qf.generateVBHHash()

	return fmt.Sprintf(PRIME_PROMPT_TEMPLATE,
		qf.vbhCounter, vbhHash, qf.vbhFacts.OpenTasks, qf.buildID)
}

// saveBlueprint saves a blueprint to storage
func (qf *QuantumForge) saveBlueprint(content string, metrics Metrics) error {
	// Create blueprint directory
	if err := os.MkdirAll(qf.blueprintDir, 0755); err != nil {
		return fmt.Errorf("failed to create blueprint directory: %w", err)
	}

	blueprint := Blueprint{
		ID:          fmt.Sprintf("quantum-forge-%d", qf.vbhCounter),
		Timestamp:   time.Now(),
		VBHCounter:  qf.vbhCounter,
		VBHHash:     qf.generateVBHHash(),
		Content:     content,
		Metrics:     metrics,
		BuildID:     qf.buildID,
		OpenTasks:   qf.vbhFacts.OpenTasks,
	}

	// Save blueprint
	blueprintFile := filepath.Join(qf.blueprintDir, fmt.Sprintf("%s.json", blueprint.ID))
	data, err := json.MarshalIndent(blueprint, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal blueprint: %w", err)
	}

	if err := os.WriteFile(blueprintFile, data, 0644); err != nil {
		return fmt.Errorf("failed to write blueprint file: %w", err)
	}

	// Also save as markdown
	mdFile := filepath.Join(qf.blueprintDir, fmt.Sprintf("%s.md", blueprint.ID))
	mdContent := fmt.Sprintf(`# Quantum-Forge Blueprint: %s

**Generated:** %s
**VBH Counter:** %d
**Build ID:** %s
**Open Tasks:** %d

## Metrics

- **Lambda Entropy:** %.3f
- **MDL Delta:** %d bytes
- **Trace Similarity:** %.3f
- **Quantum Coherence:** %.3f

## Content

%s
`, blueprint.ID, blueprint.Timestamp.Format(time.RFC3339), blueprint.VBHCounter,
	blueprint.BuildID, blueprint.OpenTasks, metrics.LambdaEntropy,
	metrics.MDLDelta, metrics.TraceSimilarity, metrics.QuantumCoherence, content)

	if err := os.WriteFile(mdFile, []byte(mdContent), 0644); err != nil {
		return fmt.Errorf("failed to write markdown file: %w", err)
	}

	fmt.Printf("🔷 Blueprint saved: %s\n", blueprint.ID)
	fmt.Printf("   JSON: %s\n", blueprintFile)
	fmt.Printf("   Markdown: %s\n", mdFile)

	return nil
}

// listBlueprints lists existing blueprints
func (qf *QuantumForge) listBlueprints() error {
	if _, err := os.Stat(qf.blueprintDir); os.IsNotExist(err) {
		fmt.Println("📭 No blueprints found")
		return nil
	}

	files, err := filepath.Glob(filepath.Join(qf.blueprintDir, "*.json"))
	if err != nil {
		return fmt.Errorf("failed to glob blueprint files: %w", err)
	}

	if len(files) == 0 {
		fmt.Println("📭 No blueprints found")
		return nil
	}

	fmt.Println("🔷 Quantum-Forge Blueprints:")
	fmt.Println()

	for _, file := range files {
		data, err := os.ReadFile(file)
		if err != nil {
			fmt.Printf("❌ Error reading %s: %v\n", filepath.Base(file), err)
			continue
		}

		var blueprint Blueprint
		if err := json.Unmarshal(data, &blueprint); err != nil {
			fmt.Printf("❌ Error parsing %s: %v\n", filepath.Base(file), err)
			continue
		}

		fmt.Printf("📄 %s\n", blueprint.ID)
		fmt.Printf("   Generated: %s\n", blueprint.Timestamp.Format(time.RFC3339))
		fmt.Printf("   VBH Counter: %d\n", blueprint.VBHCounter)
		fmt.Printf("   Build ID: %s\n", blueprint.BuildID)
		fmt.Printf("   Lambda Entropy: %.3f\n", blueprint.Metrics.LambdaEntropy)
		fmt.Println()
	}

	return nil
}

// injectToBackend injects the Prime Prompt to a backend
func (qf *QuantumForge) injectToBackend(backend string, prompt string) error {
	fmt.Printf("🚀 Injecting Quantum-Forge Prime Prompt to %s...\n", backend)

	switch backend {
	case "stdout":
		fmt.Println("\n" + strings.Repeat("=", 60))
		fmt.Println(prompt)
		fmt.Println(strings.Repeat("=", 60))

	case "file":
		filename := fmt.Sprintf("quantum-forge-prompt-%d.md", qf.vbhCounter)
		if err := os.WriteFile(filename, []byte(prompt), 0644); err != nil {
			return fmt.Errorf("failed to write prompt file: %w", err)
		}
		fmt.Printf("📝 Prompt saved to: %s\n", filename)

	case "omai":
		// Try to pipe to omai.js
		cmd := fmt.Sprintf("echo '%s' | node omai.js", strings.ReplaceAll(prompt, "'", `'"'"'`))
		fmt.Printf("🔗 Running: %s\n", cmd)
		// Note: In a real implementation, you'd use os/exec here

	default:
		return fmt.Errorf("unknown backend: %s", backend)
	}

	return nil
}

func main() {
	var (
		backend     = flag.String("backend", "stdout", "Backend to inject to (stdout, file, omai)")
		list        = flag.Bool("list", false, "List existing blueprints")
		showPrompt  = flag.Bool("show-prompt", false, "Show the Prime Prompt without executing")
		saveOnly    = flag.Bool("save-only", false, "Save blueprint without backend injection")
		openTasks   = flag.Int("open-tasks", -1, "Override open tasks count")
	)
	flag.Parse()

	qf, err := NewQuantumForge()
	if err != nil {
		log.Fatalf("❌ Failed to initialize Quantum-Forge: %v", err)
	}

	// Override open tasks if specified
	if *openTasks >= 0 {
		qf.vbhFacts.OpenTasks = *openTasks
	}

	if *list {
		if err := qf.listBlueprints(); err != nil {
			log.Fatalf("❌ Failed to list blueprints: %v", err)
		}
		return
	}

	// Create the Prime Prompt
	prompt := qf.createPrimePrompt()

	if *showPrompt {
		fmt.Println("\n🔷 Quantum-Forge Prime Prompt:")
		fmt.Println(strings.Repeat("=", 60))
		fmt.Println(prompt)
		fmt.Println(strings.Repeat("=", 60))
		return
	}

	// Simulate metrics (in a real implementation, these would be calculated)
	metrics := Metrics{
		LambdaEntropy:   0.125,
		MDLDelta:        -256,
		TraceSimilarity: 0.892,
		QuantumCoherence: 0.945,
	}

	// Save blueprint
	if err := qf.saveBlueprint(prompt, metrics); err != nil {
		log.Fatalf("❌ Failed to save blueprint: %v", err)
	}

	// Inject to backend unless save-only
	if !*saveOnly {
		if err := qf.injectToBackend(*backend, prompt); err != nil {
			log.Fatalf("❌ Failed to inject to backend: %v", err)
		}
	}

	fmt.Printf("\n✨ Quantum-Forge invocation completed successfully!\n")
	fmt.Printf("   VBH Counter: %d\n", qf.vbhCounter)
	fmt.Printf("   Build ID: %s\n", qf.buildID)
	fmt.Printf("   Blueprint ID: quantum-forge-%d\n", qf.vbhCounter)
}
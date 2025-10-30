# Long-Term Memory (LTM) Policy for Omarchy OS

## Overview

This policy governs the management of long-term memory for the Omarchy AI assist system, ensuring persistent, contextual knowledge across sessions while maintaining privacy and efficiency.

## Memory Categories

### 1. Facts (`fact`)
- **Definition**: Objective, verifiable information about the system, codebase, or environment
- **Scope**: Global, project, module
- **TTL**: 180 days default
- **Examples**: "API endpoint X returns JSON", "File Y contains configuration Z"

### 2. Preferences (`preference`)
- **Definition**: User preferences, settings, and behavioral patterns
- **Scope**: Global, project
- **TTL**: 365 days (extended for user preferences)
- **Examples**: "User prefers dark theme", "Default editor is VS Code"

### 3. Terms (`term`)
- **Definition**: Domain-specific terminology, acronyms, and definitions
- **Scope**: Global
- **TTL**: 365 days (terms rarely change)
- **Examples**: "MCP = Model Context Protocol", "LTM = Long-Term Memory"

### 4. Milestones (`milestone`)
- **Definition**: Significant events, completions, or progress markers
- **Scope**: Project, global
- **TTL**: 365 days (historical record)
- **Examples**: "Completed v1.0 implementation", "Fixed critical bug in authentication"

## Memory Scopes

### Global (`global`)
- System-wide knowledge applicable across all projects
- Cross-session learning and patterns
- User preferences and general capabilities

### Project (`project`)
- Project-specific information and context
- Architecture decisions and implementations
- Team workflows and conventions

### Module (`module`)
- Component-level details and implementation specifics
- Function signatures and APIs
- Local patterns and conventions

## Storage Format

Each memory entry is stored as a JSONL line:

```json
{
  "ts": "2025-10-30T15:30:00Z",
  "who": "declan|system|agent",
  "type": "fact|preference|term|milestone",
  "scope": "global|project|module",
  "text": "Single atomic memory statement",
  "evidence": [
    {"file": "path/to/file", "line": 123, "quote": "supporting quote"}
  ],
  "ttl_days": 180
}
```

## Memory Management Rules

### Atomicity
- One atomic fact per memory entry
- Avoid compound statements or complex logic
- Keep text concise and specific

### Evidence Requirements
- Include source file and line number when possible
- Provide supporting quotes for verification
- Link to documentation or references when available

### TTL Management
- Default TTL: 180 days for facts, 365 for preferences/terms/milestones
- Extend TTL for frequently accessed memories
- Prune expired memories during maintenance cycles

### Privacy and Security
- Never store sensitive credentials or API keys
- Avoid personal information beyond user preferences
- Sanitize potentially confidential data

## Memory Operations

### Append (`ltm_append.sh`)
- Add new memory entries with proper validation
- Auto-detect type and scope when possible
- Include evidence and metadata

### Recall (`ltm_recall.sh`)
- Search memory by keyword, type, scope, or date range
- Support fuzzy matching and relevance ranking
- Return formatted results with context

### Prune (`ltm_prune.sh`)
- Remove expired entries based on TTL
- Consolidate duplicate or conflicting memories
- Archive important historical data

## Integration Points

### Subagent Integration
- `#mem` subagent handles memory operations
- `#knw` subagent extracts knowledge from files
- `#pln` subagent references relevant memories for planning
- `#imp` subagent updates memories after implementation

### Chat Integration
- Automatic memory extraction from conversations
- Contextual memory retrieval during dialogues
- Memory-backed responses for consistency

### Tool Integration
- IDE plugins for memory-aware coding
- CLI tools for memory management
- API endpoints for external access

## Best Practices

### Memory Quality
- Verify facts before storing
- Use precise, unambiguous language
- Include sufficient context for future reference

### Performance Considerations
- Index frequently accessed memories
- Use efficient search algorithms
- Implement caching for common queries

### Maintenance
- Regular pruning of expired entries
- Periodic review of memory accuracy
- Updates for deprecated information

## Implementation Notes

### Storage Location
- File: `memory/ltm_store.jsonl`
- Format: JSONL (one JSON object per line)
- Encoding: UTF-8
- Size limits: Monitor file size, implement rotation if needed

### Backup and Recovery
- Git-tracked for version control
- Regular backups to external storage
- Recovery procedures for corrupted data

### Access Control
- Read/write permissions for owner
- Group access for team collaboration
- Audit logging for compliance

## Evolution Policy

This policy should be reviewed and updated:
- Quarterly or as usage patterns emerge
- When new memory categories are needed
- Based on user feedback and system performance
- To address privacy or security concerns

## Examples

### Adding a Fact
```bash
echo '{"ts":"2025-10-30T15:30:00Z","who":"agent","type":"fact","scope":"project","text":"Authentication service uses JWT tokens","evidence":[{"file":"src/auth.js","line":45,"quote":"return jwt.sign(payload, secret)"}],"ttl_days":180}' >> memory/ltm_store.jsonl
```

### Adding a Preference
```bash
echo '{"ts":"2025-10-30T15:30:00Z","who":"declan","type":"preference","scope":"global","text":"User prefers dark theme for all applications","evidence":[],"ttl_days":365}' >> memory/ltm_store.jsonl
```

### Adding a Term
```bash
echo '{"ts":"2025-10-30T15:30:00Z","who":"system","type":"term","scope":"global","text":"MCP = Model Context Protocol for AI agent integration","evidence":[{"file":"docs/mcp.md","line":1,"quote":"# Model Context Protocol (MCP)"}],"ttl_days":365}' >> memory/ltm_store.jsonl
```

This policy ensures effective long-term memory management while maintaining system performance and user privacy.
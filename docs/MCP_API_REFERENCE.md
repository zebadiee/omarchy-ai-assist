# MCP Tools API Reference

## Overview

This document provides comprehensive API documentation for all Model Context Protocol (MCP) tools available in the Quantum-Forge enhanced Omarchy system.

## Table of Contents

- [Workflow Coordinator MCP](#workflow-coordinator-mcp)
- [Knowledge Superagent MCP](#knowledge-superagent-mcp)
- [Token Manager MCP](#token-manager-mcp)
- [Enhanced Capabilities](#enhanced-capabilities)
- [Usage Examples](#usage-examples)
- [Error Handling](#error-handling)

---

## Workflow Coordinator MCP

### Server Information
- **Name**: `omarchy-workflow-coordinator`
- **Version**: `1.0.0`
- **File**: `mcp-superagents/workflow-coordinator-mcp.js`

### Available Tools

#### 1. `coordinate_distributed_workflow`

Coordinates a distributed workflow across multiple superagents with intelligent task distribution and execution strategies.

**Parameters**:
```typescript
{
  workflowId: string;           // Unique identifier for the workflow
  tasks: Task[];                // Array of tasks to execute
  strategy: ExecutionStrategy;   // Execution strategy
}
```

**Task Schema**:
```typescript
interface Task {
  id: string;                   // Unique task identifier
  type: TaskType;               // Type of task
  priority: Priority;           // Task priority level
  dependencies?: string[];      // Task dependencies
  input?: Record<string, any>;  // Task input data
  estimatedTokens?: number;     // Estimated token usage
}
```

**Task Types**:
- `planning` - Strategic planning and task decomposition
- `implementation` - Code implementation and problem solving
- `knowledge` - Information retrieval and learning
- `analysis` - Data analysis and insights
- `coordination` - Multi-agent coordination

**Priority Levels**:
- `low` - Low priority tasks
- `medium` - Normal priority tasks
- `high` - High priority tasks
- `critical` - Critical priority tasks

**Execution Strategies**:
- `sequential` - Execute tasks one after another
- `parallel` - Execute tasks in parallel where possible
- `hybrid` - Mix of sequential and parallel execution
- `adaptive` - Dynamically choose optimal strategy

**Response**:
```typescript
{
  content: [{
    type: "text";
    text: string;  // Detailed workflow execution report
  }];
}
```

**Example**:
```json
{
  "workflowId": "system-optimization-001",
  "tasks": [
    {
      "id": "task-1",
      "type": "planning",
      "priority": "high",
      "estimatedTokens": 2000,
      "input": { "goal": "optimize system performance" }
    },
    {
      "id": "task-2",
      "type": "implementation",
      "priority": "medium",
      "dependencies": ["task-1"],
      "estimatedTokens": 5000
    }
  ],
  "strategy": "hybrid"
}
```

#### 2. `monitor_workflow_status`

Monitors the status of active workflows and provides real-time progress information.

**Parameters**:
```typescript
{
  workflowId?: string;  // Optional specific workflow ID to monitor
}
```

**Response**:
```typescript
{
  content: [{
    type: "text";
    text: string;  // Workflow status report with progress, metrics, and issues
  }];
}
```

#### 3. `optimize_task_distribution`

Optimizes the distribution of tasks across available superagents based on workload and performance.

**Parameters**:
```typescript
{
  rebalance?: boolean;     // Force rebalancing of tasks
  strategy?: string;       // Optimization strategy
}
```

**Response**:
```typescript
{
  content: [{
    type: "text";
    text: string;  // Optimization report with before/after metrics
  }];
}
```

#### 4. `rubikstack_optimize_workflow` ⭐ **NEW**

Optimizes workflow using RubikStack cube transformations for MDL (Minimum Description Length) reduction.

**Parameters**:
```typescript
{
  workflowId: string;           // Workflow identifier
  tasks: Task[];                // Tasks to optimize
  maxIterations?: number;       // Maximum optimization iterations (default: 10)
}
```

**Response**:
```typescript
{
  content: [{
    type: "text";
    text: string;  // Comprehensive optimization report including:
      // - Initial vs Final MDL
      // - Improvement percentage
      // - Rotation sequence applied
      // - Face entropy breakdown
      // - Optimization metrics
  }];
}
```

**RubikStack Metrics**:
- **Lambda Entropy**: Information entropy measurement
- **MDL Delta**: Reduction in minimum description length
- **Trace Similarity**: Similarity to expected patterns
- **Quantum Coherence**: Cross-phase coherence score
- **Face Balance**: Entropy distribution across 6 faces

**Face Mapping**:
- **Code** (Front): Implementation tasks and code structures
- **Memory** (Up): Knowledge storage and retrieval
- **Prompts** (Right): Query optimization and patterns
- **Traces** (Left): Activity logging and monitoring
- **Contracts** (Back): Coordination and agreements
- **Tokens** (Down): Resource usage and optimization

#### 5. `scale_superagent_capacity`

Dynamically adjusts the capacity of superagent pools based on workload.

**Parameters**:
```typescript
{
  superagentType: string;      // Type of superagent to scale
  change: number;              // Capacity change (+/-)
  reason?: string;             // Reason for scaling
}
```

#### 6. `handle_failover`

Handles failover scenarios when superagents become unavailable.

**Parameters**:
```typescript
{
  failedSuperagent: string;     // ID of failed superagent
  affectedTasks: string[];      // Tasks affected by failure
  failoverStrategy: string;     // Failover strategy to use
}
```

---

## Knowledge Superagent MCP

### Server Information
- **Name**: `omarchy-knowledge-superagent`
- **Version**: `1.0.0`
- **File**: `mcp-superagents/knowledge-mcp.js`

### Enhanced Capabilities ⭐ **ENHANCED**

The Knowledge MCP has been enhanced with:
- **VBH Compliance**: All responses include VBH headers and CONFIRM lines
- **Semantic Caching**: 12-hour cache for pattern extraction results
- **MDL Tracking**: Automatic complexity measurement for analyzed content

### Available Tools

#### 1. `extract_omarchy_patterns`

Extracts and analyzes Omarchy OS patterns from code and documentation with semantic caching.

**Parameters**:
```typescript
{
  content: string;             // Content to analyze
  patternTypes?: string[];     // Types of patterns to extract
  options?: {
    bypassCache?: boolean;     // Skip semantic cache
    analysisDepth?: string;    // Analysis depth level
  }
}
```

**Pattern Types**:
- `architecture` - System architecture patterns
- `configuration` - Configuration patterns
- `integration` - Integration patterns
- `workflow` - Workflow patterns
- `best-practices` - Best practice patterns

**Response**:
```typescript
{
  content: [{
    type: "text";
    text: string;  // VBH-compliant response with:
      // VBH header and CONFIRM line
      // Extracted patterns with confidence scores
      // Analysis results and recommendations
      // Cache hit/miss status
  }];
}
```

**Enhanced Response Format**:
```
#VBH:3:a1b2c3d4
CONFIRM:{"scope":"unified","site":"Omarchy","open_tasks":0,"provider":"knowledge-mcp"}

## Pattern Analysis Results

### Cache Status: HIT (cached 2 hours ago)
### Content Length: 15,234 bytes
### Analysis Duration: 45ms

### Extracted Patterns (8 found):

#### 1. Configuration Pattern (Confidence: 0.92)
- **Type**: File-based configuration
- **Location**: Lines 45-67
- **Description**: JSON configuration with nested settings
- **Frequency**: High (appears 12 times in corpus)

#### 2. Architecture Pattern (Confidence: 0.87)
- **Type**: Service-oriented architecture
- **Location**: Lines 120-145
- **Description**: Modular service composition
- **Dependencies**: 3 services identified

### MDL Analysis:
- **Entropy**: 4.2 bits
- **Complexity**: 78.5
- **MDL Score**: 234.7
```

#### 2. `verify_omarchy_compliance`

Verifies content against Omarchy standards and best practices.

**Parameters**:
```typescript
{
  content: string;             // Content to verify
  standards?: string[];        // Specific standards to check
  strictMode?: boolean;        // Enable strict verification
}
```

**Response**:
```typescript
{
  content: [{
    type: "text";
    text: string;  // VBH-compliant compliance report
  }];
}
```

#### 3. `synthesize_knowledge`

Synthesizes knowledge from multiple sources into coherent insights.

**Parameters**:
```typescript
{
  sources: string[];           // Source content to synthesize
  synthesisType: string;       // Type of synthesis to perform
  focus?: string;              // Specific focus area
}
```

---

## Token Manager MCP

### Server Information
- **Name**: `omarchy-token-manager`
- **Version**: `1.0.0`
- **File**: `mcp-superagents/token-manager-mcp.js`

### Available Tools

#### 1. `track_token_usage`

Tracks and analyzes token usage across the system.

**Parameters**:
```typescript
{
  timeframe?: string;          // Timeframe for analysis (day/week/month)
  model?: string;              // Specific model to track
  aggregation?: string;        // Aggregation level
}
```

**Response**:
```typescript
{
  content: [{
    type: "text";
    text: string;  // Token usage report with statistics and trends
  }];
}
```

#### 2. `optimize_token_usage`

Provides recommendations for token usage optimization.

**Parameters**:
```typescript
{
  target?: string;             // Optimization target (cost/speed/quality)
  constraints?: Record<string, any>;  // Usage constraints
}
```

#### 3. `set_token_budget`

Sets and manages token usage budgets.

**Parameters**:
```typescript
{
  budget: number;              // Token budget amount
  period: string;              // Budget period (day/week/month)
  alerts?: boolean;            // Enable budget alerts
}
```

---

## Enhanced Capabilities ⭐ **NEW**

### VBH Compliance Integration

All MCP responses now include VBH (Verification and Behavioral Hashing) compliance:

**VBH Header Format**: `#VBH:<counter>:<hash>`
**CONFIRM Line Format**: `CONFIRM:{"scope":"...","site":"...","open_tasks":N,"provider":"..."}`

**Benefits**:
- **Traceability**: Every response can be traced back to its origin
- **Integrity**: Hash verification ensures content integrity
- **Compliance**: Standardized format across all responses
- **Auditing**: Complete audit trail for all operations

### Semantic Caching

Intelligent caching system that reduces redundant processing:

**Cache Key Generation**: Based on query content, agent, purpose, and scope
**Cache Duration**: 12-24 hours depending on content type
**Cache Invalidation**: Automatic cleanup of expired entries

**Performance Benefits**:
- 60-80% cache hit rates for repeated operations
- Sub-100ms response times for cached results
- Reduced API costs and improved user experience

### MDL Integration

Automatic complexity measurement for all processed content:

**MDL Components**:
- **Entropy**: Information entropy measurement
- **Complexity**: Code structure and pattern complexity
- **Description Length**: Minimal description length calculation
- **Trend Analysis**: Historical complexity tracking

---

## Usage Examples

### Basic Workflow Coordination

```typescript
// Start a distributed workflow
const workflowResult = await mcpClient.call('coordinate_distributed_workflow', {
  workflowId: 'optimization-001',
  tasks: [
    {
      id: 'analyze',
      type: 'analysis',
      priority: 'high',
      estimatedTokens: 2000,
      input: { system: 'production', metrics: ['performance', 'cost'] }
    },
    {
      id: 'optimize',
      type: 'implementation',
      priority: 'medium',
      dependencies: ['analyze'],
      estimatedTokens: 5000
    }
  ],
  strategy: 'adaptive'
});
```

### RubikStack Optimization

```typescript
// Apply RubikStack optimization
const optimizationResult = await mcpClient.call('rubikstack_optimize_workflow', {
  workflowId: 'optimization-001',
  tasks: workflowTasks,
  maxIterations: 15
});

// Result includes:
// - MDL improvement percentage
// - Applied rotation sequence
// - Face entropy breakdown
// - Optimization metrics
```

### Knowledge Extraction with Caching

```typescript
// Extract patterns (first call - cache miss)
const patterns1 = await mcpClient.call('extract_omarchy_patterns', {
  content: systemCode,
  patternTypes: ['architecture', 'configuration'],
  options: { analysisDepth: 'deep' }
});

// Extract similar patterns (second call - cache hit)
const patterns2 = await mcpClient.call('extract_omarchy_patterns', {
  content: similarSystemCode,
  patternTypes: ['architecture', 'configuration'],
  options: { analysisDepth: 'deep' }
});

// Second call returns immediately from cache
```

### Token Management

```typescript
// Track token usage
const usageReport = await mcpClient.call('track_token_usage', {
  timeframe: 'week',
  model: 'gemini-2.0-flash',
  aggregation: 'daily'
});

// Set budget and get optimization tips
const budgetResult = await mcpClient.call('set_token_budget', {
  budget: 100000,
  period: 'month',
  alerts: true
});
```

---

## Error Handling

### Standard Error Format

All MCP tools follow consistent error handling:

```typescript
{
  content: [{
    type: "text";
    text: "❌ Error: Description of the error\n\nDetails: Additional context";
  }];
  isError: true;
}
```

### Common Error Types

1. **Validation Errors**: Invalid input parameters
2. **Resource Errors**: Unavailable resources or timeouts
3. **Permission Errors**: Insufficient permissions
4. **System Errors**: Internal system failures

### Error Recovery

- **Automatic Retry**: Built-in retry logic for transient failures
- **Fallback Strategies**: Classical algorithms when quantum features unavailable
- **Graceful Degradation**: Partial functionality when components fail
- **Circuit Breakers**: Prevent cascade failures

---

## Performance Considerations

### Response Times

- **Cache Hits**: <50ms
- **Cache Misses**: 100-500ms depending on complexity
- **RubikStack Optimization**: 1-2 seconds for complex workflows
- **Knowledge Extraction**: 200-800ms depending on content size

### Resource Usage

- **Memory**: ~50MB baseline + 10MB per active workflow
- **CPU**: Minimal for cached operations, moderate for complex analysis
- **Disk**: ~5MB for cache storage (100 entries)
- **Network**: No external dependencies required

### Scaling

- **Concurrent Workflows**: Up to 10 simultaneous workflows
- **Cache Size**: Automatically managed with 1000 entry limit
- **Token Tracking**: Real-time with minimal overhead
- **MCP Connections**: Standard MCP connection limits apply

---

## Integration Examples

### Client Setup

```typescript
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

const transport = new StdioClientTransport();
const client = new Client(
  {
    name: 'quantum-forge-client',
    version: '1.0.0'
  },
  {
    capabilities: {}
  }
);

await client.connect(transport);
```

### Complete Workflow Example

```typescript
async function optimizedWorkflow() {
  // 1. Start with RubikStack optimization
  const optimization = await client.call('rubikstack_optimize_workflow', {
    workflowId: 'example-001',
    tasks: getWorkflowTasks(),
    maxIterations: 10
  });

  console.log('Optimization Results:', optimization.content[0].text);

  // 2. Execute optimized workflow
  const execution = await client.call('coordinate_distributed_workflow', {
    workflowId: 'example-001',
    tasks: getOptimizedTasks(),
    strategy: 'adaptive'
  });

  console.log('Execution Results:', execution.content[0].text);

  // 3. Extract knowledge from results
  const knowledge = await client.call('extract_omarchy_patterns', {
    content: execution.content[0].text,
    patternTypes: ['workflow', 'best-practices']
  });

  console.log('Knowledge Extracted:', knowledge.content[0].text);

  // 4. Track token usage
  const usage = await client.call('track_token_usage', {
    timeframe: 'session'
  });

  console.log('Token Usage:', usage.content[0].text);
}
```

---

## Version History

### v1.0.0 (Current)
- Initial release with core workflow coordination
- Knowledge extraction and pattern analysis
- Token management and budgeting
- Enhanced with VBH compliance
- Integrated semantic caching
- Added RubikStack optimization engine
- MDL tracking and analysis

### Future Versions (Roadmap)
- v1.1.0: Quantum adapter integration
- v1.2.0: Advanced telemetry and monitoring
- v1.3.0: Auto-promotion and build registry
- v2.0.0: Distributed architecture support

---

## Support and Documentation

- **Main Documentation**: `QUANTUM_FORGE_INTEGRATION.md`
- **API Examples**: See code repository for integration examples
- **Troubleshooting**: Run `./scripts/health-check.sh` for system diagnostics
- **Changelog**: `docs/CHANGELOG_QUANTUM_FORGE.md`
- **Roadmap**: `docs/ROADMAP_PHASE2.md`

---

**Last Updated**: 2025-11-01
**API Version**: 1.0.0
**MCP Protocol Version**: Latest
**Maintainer**: Omarchy AI Team
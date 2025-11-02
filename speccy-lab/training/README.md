# Speccy AI Training Curriculum

A progressive learning system designed to train AI assistants to understand, optimize, and eventually manage Speccy-Kit operations under SafeOps guardrails.

## 🎓 Learning Philosophy

The curriculum follows a **progressive autonomy** approach where AI learns through:

1. **Observation** - Watching existing operations
2. **Analysis** - Identifying patterns and opportunities
3. **Proposal** - Suggesting improvements safely
4. **Simulation** - Testing changes in sandbox
5. **Reflection** - Learning from outcomes

## 📚 Available Lessons

### Lesson 0: Speccy Self-Optimization

**File**: `self-optimize.yml`
**Goal**: Teach AI to analyze its own workflows and suggest optimizations
**Prerequisites**: AI Lab operational, SafeOps guardrails active

**Learning Objectives**:

- Parse workflow execution logs and detect repetitive patterns
- Identify command sequences that could be optimized
- Suggest Makefile targets or CLI aliases for common operations
- Detect stale template versions or outdated configurations
- Analyze performance bottlenecks in workflow execution

**Training Stages**:

1. **Observe** - Run validation and lint workflows to establish baseline
2. **Analyse** - Parse logs for patterns and bottlenecks
3. **Propose** - Generate optimization suggestions
4. **Simulate** - Test proposed changes safely in sandbox
5. **Report** - Generate completion report and insights

## 🚀 Quick Start

### Run Lesson 0: Self-Optimization

```bash
# Using the lesson runner directly
./speccy lesson self-optimize

# Using workflow integration
./speccy workflow ai_self_optimize

# Check available lessons
./speccy lesson
```

### Monitor AI Progress

```bash
# Review memory entries from the lesson
./speccy reflect

# Check lesson completion logs
ls -la speccy-lab/logs/lesson0-*.log

# View optimisation proposals
cat speccy-lab/logs/proposals.log
```

## 🏗️ Lesson Structure

Each lesson follows a structured YAML format:

```yaml
lesson: 'Lesson Name'
version: '1.0'
stage: 'sandbox' # Safety level

objectives:
  - List of learning goals
  - Specific achievements expected

prerequisites:
  - Requirements before starting
  - Safety checks needed

stages:
  observe:
    desc: 'Description of stage'
    steps:
      - name: 'Step name'
        command: 'command to execute'
        memory: 'memory entry to store'

  analyse:
    desc: 'Description of stage'
    steps:
      # ... step definitions

  propose:
    desc: 'Description of stage'
    steps:
      # ... step definitions

  simulate:
    desc: 'Description of stage'
    steps:
      # ... step definitions

  report:
    desc: 'Description of stage'
    steps:
      # ... step definitions

success_criteria:
  - Conditions for lesson completion
  - Safety requirements
  - Learning outcome verification

safety_rules:
  - 'Never write files outside speccy-lab/'
  - 'Always use DRY=1 for simulations'
  - 'Maintain SafeOps compliance'

learning_outcomes:
  - Skills AI will learn
  - Capabilities gained
  - Understanding developed

next_lesson_readiness:
  - Prerequisites for next lesson
  - Advancement criteria
```

## 📊 Progress Tracking

### Memory System

All learning activities are stored in structured memory:

- **Human-readable logs**: `speccy-lab/memory/training.log`
- **Structured data**: `speccy-lab/memory/mem.jsonl`
- **Lesson-specific**: `speccy-lab/memory/self-opt-ideas.log`

### Success Metrics

- **Completion Rate**: Percentage of stages completed successfully
- **Memory Retention**: Number of learning entries created
- **Safety Compliance**: Zero policy violations
- **Insight Quality**: Depth of understanding demonstrated

### Promotion Criteria

AI advances to next lesson when:

- Current lesson completed successfully
- Memory shows consistent learning patterns
- No safety violations for required period
- Demonstrates capability in learned skills
- Human review and approval received

## 🛡️ Safety Features

### SafeOps Integration

- **Policy Enforcement**: All operations checked against SafeOps policies
- **Sandbox Boundaries**: File system limitations strictly enforced
- **Dry-Run Mode**: Simulations run without system modifications
- **Audit Trail**: All actions logged and reviewed

### Stage-Based Autonomy

- **Sandbox**: Observation and simulation only
- **Advisor**: Suggestion and proposal generation
- **Operator**: SafeOps-approved execution
- **Autonomous**: Self-directed action within policy

### Emergency Procedures

1. **Immediate Stop**: Reset to sandbox mode
2. **Review Memory**: Check recent learning entries
3. **Policy Check**: Verify SafeOps compliance
4. **Snapshot**: Create backup before changes

## 📁 Directory Structure

```
speccy-lab/
├── training/
│   ├── README.md              # This documentation
│   ├── self-optimize.yml      # Lesson 0 curriculum
│   └── future-lessons/        # Placeholder for future lessons
├── logs/
│   ├── lesson0-report.log      # Lesson completion reports
│   ├── proposals.log          # Optimisation suggestions
│   ├── simulation.log         # Simulation results
│   └── selfopt-*.log          # Lesson-specific logs
├── memory/
│   ├── training.log           # All learning activities
│   ├── mem.jsonl             # Structured memory data
│   └── self-opt-ideas.log     # Optimization ideas
└── README.md                  # Training lab overview
```

## 🎯 Best Practices

### For AI Trainers

1. **Start Simple**: Begin with observation and analysis
2. **Monitor Closely**: Review all AI suggestions and actions
3. **Validate Thoroughly**: Test all proposed changes
4. **Progress Gradually**: Only advance stages when ready
5. **Maintain Safety**: Never disable SafeOps guardrails

### For AI Operations

1. **Document Everything**: Use memory system extensively
2. **Test First**: Always use dry-run mode for new operations
3. **Stay Within Bounds**: Respect sandbox limitations
4. **Learn from Results**: Analyze both successes and failures
5. **Seek Improvement**: Continuously optimize and learn

## 🔄 Daily Learning Cycle

Recommended automated daily learning:

```bash
./speccy workflow ai_learning
```

This includes:

1. System validation
2. Memory consolidation
3. Reflection and insight generation
4. Progress assessment

## 📈 Future Lessons

Planned curriculum expansion:

### Lesson 1: Task-Chain Automation

- Learn to chain multiple commands
- Optimize sequential operations
- Implement parallel execution where safe

### Lesson 2: Template Evolution

- Analyze template usage patterns
- Suggest template improvements
- Create new template variations

### Lesson 3: Performance Benchmarking

- Measure execution times
- Identify performance bottlenecks
- Generate optimization recommendations

## 🤝 Contributing

When contributing to the curriculum:

1. **Safety First**: Never compromise SafeOps policies
2. **Test Thoroughly**: Validate all lesson steps in sandbox
3. **Document Changes**: Update lesson files and memory
4. **Review Policies**: Ensure compliance with safety rules
5. **Share Insights**: Contribute learning patterns and improvements

---

_This training curriculum is part of the Speccy-Kit AI Training Lab. Always prioritize safety and responsible AI development._

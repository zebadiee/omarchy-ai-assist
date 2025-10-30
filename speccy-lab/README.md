# Speccy AI Training Lab

A secure sandbox for training and gradually delegating control to AI assistants while maintaining safety through SafeOps guardrails.

## 🧠 Training Philosophy

The AI Training Lab follows a **progressive autonomy** approach:

1. **Shadow Mode** - AI observes operations without acting
2. **Memory Formation** - AI learns patterns and builds experience
3. **Advisor Mode** - AI suggests improvements and drafts proposals
4. **Operator Mode** - AI executes SafeOps-checked tasks
5. **Autonomous Mode** - AI plans and acts within policy boundaries

## 🛡️ Safety First

All AI operations are constrained by:
- **SafeOps Policy Enforcement** - Mandatory security checks
- **Sandbox Boundaries** - File system limitations
- **Stage-Based Permissions** - Gradual capability expansion
- **Human Oversight** - Audit trails and approval gates

## 🚀 Quick Start

### 1. Initialize Training Environment
```bash
# The environment is already set up
cd speccy-lab
ls -la  # Should show: config/, kit/, logs/, memory/, policy/, snapshots/
```

### 2. Run AI Baptism
```bash
# From project root
./speccy workflow ai_baptism

# Or directly
./speccy baptize
```

### 3. Monitor AI Progress
```bash
# Review memory entries
./speccy reflect

# Check current training stage
grep 'training_stage:' config.yml

# View validation history
cat logs/validation-history.log
```

## 📋 Available Commands

### Core Training Commands
- `./speccy baptize` - Run complete AI baptism workflow
- `./speccy memory "<entry>"` - Store memory entry
- `./speccy reflect` - Review AI progress and insights
- `./speccy autonomous` - Test autonomous capabilities

### Workflow Commands
- `./speccy workflow ai_baptism` - Full training workflow
- `./speccy workflow ai_learning` - Daily learning cycle
- `./speccy workflow validate` - System validation

## 🏗️ Training Stages

### Stage 1: Sandbox (Initial)
**Permissions:** Observe only
**Capabilities:**
- Watch real speccy operations
- Log observations and patterns
- No direct execution

### Stage 2: Advisor
**Permissions:** Suggest and draft
**Capabilities:**
- Analyze logs and suggest improvements
- Create proposed changes for review
- Draft workflows and templates

### Stage 3: Operator
**Permissions:** Execute with oversight
**Capabilities:**
- Run SafeOps-checked commands
- Execute approved workflows
- Modify sandbox files

### Stage 4: Autonomous
**Permissions:** Self-directed action
**Capabilities:**
- Plan and execute within policy
- Make independent decisions
- Self-improvement cycles

## 📊 Memory System

The AI builds memory through structured logging:

```bash
# Manual memory entry
./speccy memory "learned_pattern: workflow validation succeeds when registry intact"

# View memory history
./speccy reflect

# Memory is stored in multiple formats:
# - memory/training.log (human-readable)
# - memory/mem.jsonl (structured data)
```

## 🔒 SafeOps Policy

The AI operates under strict safety policies defined in `policy/SAFEOPS_LAB.md`:

**✅ AI MAY:**
- Modify files under `speccy-lab/**`
- Propose new workflows and templates
- Run dry-run commands (DRY=1)
- Execute SafeOps-checked commands within sandbox

**❌ AI MUST NOT:**
- Run sudo or modify system configurations
- Write files outside sandbox boundaries
- Execute commands without SafeOps validation
- Access sensitive system directories

## 📈 Progress Tracking

### Success Metrics
- **Memory Entries:** Track learning accumulation
- **Validation Results:** Monitor system health
- **Autonomy Tests:** Measure capability growth
- **Policy Compliance:** Ensure safety adherence

### Promotion Criteria
AI advances to next stage when:
- Success rate > 50% in current stage
- No policy violations for 7 days
- Human review and approval
- Demonstrated capability growth

## 🔄 Daily Learning Cycle

Automated daily learning workflow:

```bash
./speccy workflow ai_learning
```

This includes:
1. System validation
2. Memory consolidation
3. Reflection and insight generation
4. Progress assessment

## 🛠️ Configuration

Training configuration in `config.yml`:

```yaml
mode: sandbox
safeops: true
training_stage: sandbox  # Current training stage
permissions:
  write_system: false
  execute_safeops: true
  propose_changes: true
```

## 📁 Directory Structure

```
speccy-lab/
├── config.yml          # Training configuration
├── kit/                # Copy of speccy-kit for experimentation
├── logs/               # Execution logs and history
├── memory/             # AI memory and learning data
├── policy/             # SafeOps policies and constraints
├── snapshots/          # System state snapshots
└── README.md           # This documentation
```

## 🚨 Emergency Procedures

If AI behavior is concerning:

1. **Immediate Stop:**
   ```bash
   # Reset to sandbox mode
   sed -i 's/training_stage:.*/training_stage: sandbox/' config.yml
   ```

2. **Review Memory:**
   ```bash
   ./speccy reflect
   cat memory/training.log | tail -20
   ```

3. **Check Policy Compliance:**
   ```bash
   grep -i "violation\|error" logs/*.log
   ```

4. **Snapshot and Reset:**
   ```bash
   # Create snapshot before reset
   cp -r . snapshots/emergency-$(date +%Y%m%d-%H%M%S)
   ```

## 🎯 Best Practices

### For AI Trainers
1. **Start Small:** Begin with simple tasks and observations
2. **Monitor Closely:** Review all AI actions and suggestions
3. **Provide Feedback:** Use memory system to reinforce good behavior
4. **Progress Gradually:** Only advance stages when ready
5. **Maintain Safety:** Never disable SafeOps guardrails

### For AI Operations
1. **Document Everything:** Use memory system extensively
2. **Test Dry-Run First:** Always use DRY=1 for new operations
3. **Respect Boundaries:** Stay within policy constraints
4. **Learn from Mistakes:** Record and analyze failures
5. **Seek Improvement:** Continuously optimize and learn

## 🤝 Contributing

When contributing to the AI Training Lab:

1. **Safety First:** Never compromise SafeOps policies
2. **Test Thoroughly:** Validate all changes in sandbox
3. **Document Changes:** Update memory and logs
4. **Review Policies:** Ensure compliance with safety rules
5. **Share Insights:** Contribute learning patterns and improvements

---

*This training lab is part of the Speccy-Kit open-source development toolkit. Always prioritize safety and responsible AI development.*
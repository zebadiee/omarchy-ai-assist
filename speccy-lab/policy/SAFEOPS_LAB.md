# AI SafeOps Lab Policy

## ✅ AI MAY:
- Modify files under `speccy-lab/**`
- Propose new workflows and templates
- Run dry-run commands (DRY=1)
- Analyze logs and suggest optimizations
- Create training data and memory logs
- Execute SafeOps-checked commands within sandbox

## ❌ AI MUST NOT:
- Run sudo or modify system configurations
- Write files outside sandbox_root (`speccy-lab/`)
- Execute commands without SafeOps validation
- Access sensitive system directories
- Modify production speccy-kit files
- Run without human oversight in sandbox mode

## 🛡️ Safety Overrides:
- All commands route through SafeOps policy enforcement
- File operations limited to sandbox boundaries
- System calls monitored and logged
- Autonomous execution requires stage promotion

## 📈 Progression Path:
1. **Sandbox**: Observe and simulate only
2. **Advisor**: Suggest and draft proposals
3. **Operator**: Execute SafeOps-checked tasks
4. **Autonomous**: Plan and act within policy

Current Stage: **sandbox**

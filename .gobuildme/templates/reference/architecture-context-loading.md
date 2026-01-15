# Architecture Context Loading - Detailed Reference

> **Purpose**: Complete instructions for loading architecture context before command execution.
> **Used by**: specify.md, plan.md, implement.md, tests.md, review.md

---

## Quick Reference (Inline in Templates)

```markdown
**Architecture Context** (MANDATORY): Load from `.gobuildme/docs/technical/architecture/`.
If missing and codebase exists, run `/gbm.architecture` first.
```

---

## Detailed Steps

### Step 1: Determine If Architecture Is Required

**Architecture REQUIRED when**:
- Codebase exists outside `.gobuildme/` directory
- Any source files present (*.py, *.js, *.ts, *.go, etc.)

**Architecture OPTIONAL when**:
- New/empty project (no existing code)
- Only `.gobuildme/` files exist

### Step 2: Verify Architecture Documentation Exists

Check for these files in `.gobuildme/docs/technical/architecture/`:

| File | Contains | Required |
|------|----------|----------|
| system-analysis.md | Architectural style, patterns, decisions | Yes |
| technology-stack.md | Languages, frameworks, dependencies | Yes |
| security-architecture.md | Auth patterns, security controls | Yes |
| integration-landscape.md | External services, APIs | If integrations exist |
| data-architecture.md | Database patterns, data models | If data layer exists |
| feature-context.md | Feature-specific architecture | Per feature |

### Step 3: If Architecture Documentation MISSING

**For existing codebases** (BLOCKING):
1. Stop current command execution
2. Display error: "❌ Architecture documentation required. Run `/gbm.architecture` first."
3. Do not proceed until documentation exists

**For new/empty projects**:
- Skip architecture loading
- Proceed with command

### Step 4: Load Architecture Documentation

Read and internalize:
1. **system-analysis.md**: Understand codebase style, patterns, key decisions
2. **technology-stack.md**: Know available technologies and versions
3. **security-architecture.md**: Understand auth/authz patterns
4. **integration-landscape.md**: Know external dependencies
5. **data-architecture.md**: Understand data models and access patterns

### Step 5: Load Feature-Specific Context

If working on a feature:
- Check `.gobuildme/specs/<feature>/docs/technical/architecture/feature-context.md`
- Load feature-specific patterns and decisions
- Note any deviations from global architecture

### Step 6: Validation

Before proceeding, confirm:
- [ ] All required architecture files loaded
- [ ] Patterns and conventions understood
- [ ] Technology constraints noted
- [ ] Security requirements identified

---

## Error Messages

| Condition | Message |
|-----------|---------|
| Missing system-analysis.md | "❌ Architecture required: Run `/gbm.architecture` to analyze codebase" |
| Missing technology-stack.md | "❌ Tech stack documentation missing: Run `/gbm.architecture`" |
| Feature context missing | "⚠️ Feature architecture not found: Consider running `/gbm.architecture` for this feature" |

---

## Shell Script Integration

Scripts that support architecture loading:
- `scripts/bash/get-architecture-context.sh`
- `scripts/powershell/get-architecture-context.ps1`

These scripts return JSON with architecture file paths and status.

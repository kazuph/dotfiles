---
name: code-coupling-analysis
description: |
  Analyze code coupling using Vlad Khononov's Balanced Coupling framework.
  Generates interactive HTML reports with D3.js dependency graphs.
  Use when analyzing architecture health, identifying risky dependencies,
  or preparing for refactoring decisions. Language-agnostic design.
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
---

# Coupling Analysis Skill

Analyze code coupling across three dimensions and generate actionable HTML reports.

## Framework: Balanced Coupling (Vlad Khononov)

Three key dimensions determine coupling risk:

### 1. Integration Strength (How tightly modules connect)
| Level | Score | Detection Pattern |
|-------|-------|-------------------|
| Intrusive | 1.00 | Direct property access, internal state manipulation |
| Functional | 0.75 | Function/component usage, hooks, methods |
| Model | 0.50 | Data type imports, interfaces used as data |
| Contract | 0.25 | Pure interface/type imports |

### 2. Distance (Where dependencies live)
| Level | Score | Detection Pattern |
|-------|-------|-------------------|
| Same Module | 0.25 | Same directory (`./Component`) |
| Sibling Module | 0.50 | Sibling directory (`../utils`) |
| Distant Module | 0.75 | Different top-level (`@/contexts`, `~/lib`) |
| External | 1.00 | External packages (`react`, `lodash`) |

### 3. Volatility (Change frequency from Git history)
| Level | Score | Changes (6 months) |
|-------|-------|-------------------|
| Low | 0.00 | 0-2 changes |
| Medium | 0.50 | 3-10 changes |
| High | 1.00 | 11+ changes |

### Balance Score Formula
```
balance = (strength × volatility) × 0.6 + |strength - (1 - distance)| × 0.4
```

**Interpretation:**
- 0.0 - 0.2: Well balanced (ideal)
- 0.2 - 0.4: Acceptable
- 0.4 - 0.6: Needs attention
- 0.6+: Risky, consider refactoring

## Execution Steps

### Step 1: Identify Target Directory and Language

Determine the primary language by checking for:
- `tsconfig.json` or `*.ts`/`*.tsx` → TypeScript
- `pyproject.toml` or `*.py` → Python
- `go.mod` or `*.go` → Go
- `Cargo.toml` or `*.rs` → Rust
- `package.json` with `*.js`/`*.jsx` → JavaScript

### Step 2: Gather File List

```bash
# TypeScript/JavaScript
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -name "*.d.ts" \
  -not -name "*.stories.*" \
  -not -name "*.test.*" \
  -not -name "*.spec.*"

# Python
find . -type f -name "*.py" \
  -not -path "*/.venv/*" \
  -not -path "*/venv/*" \
  -not -path "*/__pycache__/*" \
  -not -name "*_test.py" \
  -not -name "test_*.py"

# Go
find . -type f -name "*.go" \
  -not -path "*/vendor/*" \
  -not -name "*_test.go"
```

### Step 3: Extract Import Dependencies

For each source file, extract imports using language-specific patterns:

**TypeScript/JavaScript:**
```regex
import\s+(?:(?:\{[^}]+\}|\*\s+as\s+\w+|\w+)\s+from\s+)?['"]([^'"]+)['"]
```

**Python:**
```regex
(?:from\s+(\S+)\s+import|import\s+(\S+))
```

**Go:**
```regex
import\s+(?:\w+\s+)?["']([^"']+)["']
```

### Step 4: Calculate Git Volatility

```bash
# Get change count for each file (last 6 months)
git log --since="6 months ago" --name-only --pretty=format: -- "*.ts" "*.tsx" | \
  grep -v '^$' | sort | uniq -c | sort -rn
```

### Step 5: Analyze Each Coupling

For each import relationship:
1. Determine **strength** from import pattern
2. Calculate **distance** from file paths
3. Look up **volatility** from git history
4. Compute **balance score**

### Step 6: Generate HTML Report

The report MUST include these sections:

#### Summary Statistics Card
- Total files analyzed
- Total couplings found
- Average strength, distance, volatility
- Overall balance score with color indicator

#### Most Frequently Changed Files
- Top 10 files by change count
- Badge indicating volatility level (High/Medium/Low)

#### Two-Column Layout

**Left Column:**
- Risky Couplings (score ≥ 0.4) with:
  - Score badge
  - Volatility indicator
  - Strength type
  - File path → dependency path
  - Warning box explaining WHY it's risky
  - Action box with specific refactoring suggestions

- Well-Balanced Couplings (score < 0.2) with:
  - Score badge
  - Pattern explanation

**Right Column:**
- D3.js Force-Directed Dependency Graph:
  - Nodes colored by volatility (red=high, yellow=medium, green=low)
  - Node size by dependency count
  - Edges showing coupling relationships
  - Filters for strength and volatility
  - Zoom and pan support

#### Legend Section
- Strength levels with scores
- Distance levels with scores
- Balance score interpretation guide

### Step 7: Provide "So What?" Context

Every metric MUST include explanatory text:

**BAD (raw numbers only):**
```
Average Strength: 0.74
```

**GOOD (with context):**
```
Average Strength: 0.74
→ Component usage is central (Functional level)
→ Most dependencies are function/hook calls, not loose contracts
```

## Output Location

Save the HTML report to:
```
<project-root>/coupling-analysis.html
```

Or if analyzing a specific package:
```
<package-dir>/coupling-analysis.html
```

## Example Insights to Include

For AuthContext-like patterns (high volatility + many dependents):
```
⚠️ Warning: AuthContextは16回変更されており、12以上のファイルから依存されています。
変更のたびに広範囲に影響が及ぶリスクがあります。

💡 Action:
- 認証状態（isAuthenticated）と認証操作（signIn/signOut）を分離検討
- 状態のみのuseAuthStateと操作のみのuseAuthActionsに分割
- カスタムフックで必要な部分だけを公開
```

## Anti-Patterns to Detect

1. **God Module**: Single file with 10+ dependents AND high volatility
2. **Shotgun Surgery**: One change requires modifying many files
3. **Distant Intrusive**: High strength (0.75+) combined with high distance (0.75+)
4. **Volatile Core**: Core utilities with 10+ changes in 6 months

## Report Quality Checklist

- [ ] Two-column responsive layout
- [ ] D3.js interactive graph with filters
- [ ] Every metric has "So What?" explanation
- [ ] Risky couplings have Warning + Action boxes
- [ ] Color-coded badges (red/yellow/green)
- [ ] Dark theme (GitHub-style)
- [ ] Japanese explanations for Japanese codebases
- [ ] Mobile-responsive design

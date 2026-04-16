<img src="logo.png" width="256" />

# Forge Framework

A fully autonomous university assignment solving and reviewing system powered by OpenCode agents and commands.

**2 actions** — run `forge init`, then run `/solve`. Everything else is handled by Forge's global OpenCode commands and agents.

## Features

- **Guide Parsing** — automatically extracts requirements from PDF
- **Problem Solving** — code (C++, Python, ...) and/or math
- **Charts & Screenshots** — automatic generation and capture
- **Typst Reports** — beautiful GOST-compliant PDF with title page
- **Self-Verification** — compiles, checks, and fixes errors
- **Study Materials** — theory + test questions with answers

## Installation

```bash
git clone https://github.com/ehlvg/forge
cd forge
./install.sh
```

The script:
- Copies skills, custom commands, and subagents
- Lets you choose OpenCode models for Forge agents during installation
- Installs the global `forge` CLI
- Installs Typst CLI (if not already installed)

Forge installs custom `/init`, `/solve`, and `/study` commands for OpenCode. The Forge `/init` command intentionally overrides OpenCode's built-in `/init`.

Model selection:
- During `./install.sh`, you can set one model for all Forge agents or separate models for `planner`, `solver`, `writer`, and `reviewer`.
- If `opencode` is installed, the installer can search through `opencode models`: type a search term, `?` to show all models, or a number to select from filtered results.
- If you leave a model empty, that agent inherits the current OpenCode model.
- For non-interactive install, use env vars: `FORGE_MODEL_ALL`, `FORGE_MODEL_PLANNER`, `FORGE_MODEL_SOLVER`, `FORGE_MODEL_WRITER`, `FORGE_MODEL_REVIEWER`.

Example non-interactive install:

```bash
FORGE_MODEL_ALL=openai/gpt-5.1-codex ./install.sh
```

```bash
FORGE_MODEL_PLANNER=anthropic/claude-sonnet-4-20250514 \
FORGE_MODEL_SOLVER=openai/gpt-5.1-codex \
FORGE_MODEL_WRITER=anthropic/claude-sonnet-4-20250514 \
FORGE_MODEL_REVIEWER=openai/gpt-5.1-codex \
./install.sh
```

## Usage

### CLI

```bash
forge init
forge init ~/labs/lab3
forge sync ~/labs/lab3
```

What it does:
- `forge init [path]` opens OpenCode in the target folder with Forge `/init` preloaded.
- `forge sync [path]` refreshes Forge-managed templates and reference files in an existing project without touching `forge.yaml` or `docs/report.typ`.

`forge init` drops you straight into the Forge `/init` flow inside OpenCode.

### Each assignment — just 2 actions:

```bash
# 1. Create a project and complete Forge /init in OpenCode
forge init lab3-probability

# 2. Add the guide and run the solver
cd lab3-probability
cp ~/Downloads/guide.pdf ./guide.pdf
> /solve guide.pdf

# Done! Report PDF → docs/report.pdf
```

### First Run

During Forge `/init`, OpenCode asks for:
- Full student name
- Group
- University and city

This data is saved to `~/.forge.yaml` and won't be asked again.

### Study Materials

```bash
> /study
# Creates STUDY_MATERIAL.md with theory and test questions
```

## Project Structure (after Forge `/init`)

```
lab3-probability/
├── forge.yaml             ← project configuration
├── AGENTS.md             ← OpenCode project context
├── TASK.md               ← requirements (created by /solve)
├── src/                  ← source code
├── notebooks/            ← Jupyter notebooks (if needed)
├── images/               ← screenshots and charts
├── docs/
│   ├── template.typ      ← report template (GOST, with student data)
│   ├── titlepage.typ     ← title page
│   ├── report.typ        ← report (filled by writer agent)
│   └── report.pdf        ← final PDF
└── STUDY_MATERIAL.md     ← study materials (optional)
```

## The /solve Pipeline

```mermaid
flowchart LR
    A[Guide PDF] --> B[Planner]
    B --> C[Solver]
    C --> D[Writer]
    D --> E[Reviewer]
    E --> F[docs/report.pdf]

    B:::planner
    C:::solver
    D:::writer
    E:::reviewer

    classDef planner fill:#2563eb,color:#fff
    classDef solver fill:#16a34a,color:#fff
    classDef writer fill:#9333ea,color:#fff
    classDef reviewer fill:#ea580c,color:#fff
```

Where:
- **Planner** — Parses PDF, creates TASK.md
- **Solver** — Solves tasks, code, charts
- **Writer** — Writes report in Typst
- **Reviewer** — Compiles Typst, verifies PDF

## Configuration

### Global (~/.forge.yaml)
```yaml
student:
  name: "Ivanov Ivan Ivanovich"
  group: "IU7-43B"
university:
  name: "Bauman Moscow State Technical University"
  short: "MSTU"
  city: "Moscow"
```

### Project (./forge.yaml)
```yaml
# Inherits from global +
subject:
  name: "Probability Theory"
  teacher: "Petrov P.P."
lab:
  number: 3
  title: "Random Variables"  # auto-filled from PDF
  variant: 12
  type: "math"              # math | code | mixed
  code_language: "python"
```

## Lab Types

- **code** — programming (C++, Python, etc.). Creates code, compiles, takes screenshots.
- **math** — computations. Python scripts with formulas, charts, tables.
- **mixed** — both code and computations.

## License

MIT

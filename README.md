![Forge Framework Logo](logo.png)

# Forge Framework

A fully autonomous university assignment solving and reviewing system powered by AI agents.

**2 actions** — and your task is done: initialize the project + run the solver. Everything else is handled by the agents.

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
- Copies skills and subagents
- Installs Typst CLI (if not already installed)

## Usage

### Each assignment — just 2 actions:

```bash
# 1. Create and initialize a project
mkdir lab3-probability && cd lab3-probability
claude    # or opencode
> /init

# 2. Drop in the guide PDF and run
cp ~/Downloads/guide.pdf ./guide.pdf
> /solve guide.pdf

# Done! Report PDF → docs/report.pdf
```

### First Run

On first `/init`, the system will ask for:
- Full student name
- Group
- University and city

This data is saved to `~/.forge.yaml` and won't be asked again.

### Study Materials

```bash
> /study
# Creates STUDY_MATERIAL.md with theory and test questions
```

## Project Structure (after /init)

```
lab3-probability/
├── forge.yaml             ← project configuration
├── CLAUDE.md             ← agent context
├── TASK.md               ← requirements (created by /solve)
├── src/                  ← source code
├── notebooks/            ← Jupyter notebooks (if needed)
├── images/               ← screenshots and charts
├── docs/
│   ├── template.typ      ← report template (GOST, with student data)
│   ├── titlepage.typ     ← title page
│   ├── report.typ        ← report (filled by agent)
│   └── report.pdf        ← final PDF
├── STUDY_MATERIAL.md     ← study materials (optional)
└── .claude/
    ├── skills/           ← skills (copied during init)
    └── agents/           ← subagents
```

## The /solve Pipeline

```
Guide PDF
     │
     ▼
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌──────────┐
│ Planner │ ──▶ │ Solver  │ ──▶ │ Writer  │ ──▶ │ Reviewer │
│         │     │         │     │         │     │          │
│ Parses  │     │ Solves  │     │ Writes  │     │Compiles  │
│ PDF,    │     │ tasks,  │     │ report  │     │ Typst,   │
│ creates │     │ code,   │     │ in Typst│     │ verifies │
│ TASK.md │     │ charts  │     │         │     │ PDF      │
└─────────┘     └─────────┘     └─────────┘     └──────────┘
                                                      │
                                                      ▼
                                                docs/report.pdf
```

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

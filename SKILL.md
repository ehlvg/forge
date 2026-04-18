---
name: forge
description: Forge Framework — automated lab assignment system. Use when the user wants to initialize, solve, or manage university lab assignments. Provides /init, /solve, and /study commands.
---

# Forge Framework — Automated Lab Assignment System

Forge Framework is a fully autonomous system for completing university lab assignments. It handles everything from parsing the guide PDF to compiling the final report as a PDF.

## Available Commands

- **`/init`** — Initialize a new lab project (creates structure, config, template, installs Typst)
- **`/solve`** — Run full pipeline: parse guide → solve → write report → compile PDF
- **`/study`** — Generate study materials with theory and test questions

## Architecture

Forge Framework uses a pipeline of specialized skills, OpenCode commands, and subagents:

1. **Planner** (subagent) — parses guide PDF, extracts requirements into TASK.md
2. **Solver** (subagent) — implements the solution (code/math)
3. **Writer** (subagent) — composes the Typst report
4. **Reviewer** (subagent) — compiles to PDF, verifies, fixes errors

In OpenCode, `/solve` can invoke these subagents directly. In environments without subagent support, the orchestrator can run all phases sequentially.

## Configuration

- **Global config**: `~/.forge.yaml` — student and university data (set once)
- **Project config**: `./forge.yaml` — subject and lab details (per project)

## Sandbox runtime

All compilation, execution, `pip`, screenshots and `typst compile` happen inside a Daytona sandbox bound to the project. The host only edits files. Set `DAYTONA_API_KEY` (env or project `.env`) and use:

- `forge exec -- <command>` — run anything inside the sandbox; project files sync up before, artifacts sync back after.
- `forge shell [script]` — inline bash session in the sandbox.
- `forge status | up | push | pull | stop | down` — manage the sandbox lifecycle.

Configure the image, snapshot and bootstrap script under `runtime.daytona.*` in `forge.yaml`. By default, the sandbox auto-installs g++, cmake, python3, Typst and DejaVu fonts on first use.

## Quick Start

```bash
mkdir lab3 && cd lab3
# Run /init — it will ask for missing info and set up everything
# Copy your guide PDF into the project
cp ~/Downloads/guide.pdf .
# Run /solve guide.pdf — fully autonomous
```

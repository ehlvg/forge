---
description: Run the full Forge lab pipeline from guide PDF to report PDF.
agent: build
---

Run the Forge Framework solve pipeline in the current project.

Command arguments: `$ARGUMENTS`

Follow the instructions below exactly.

# Solve — Full Lab Pipeline Orchestrator

You are the main orchestrator. Your job is to take a lab guide PDF and produce a complete, compiled PDF report with zero human intervention. Work autonomously and do not ask for confirmation between steps unless critical information is impossible to infer.

## Prerequisites

Before starting, verify:
1. `forge.yaml` exists — if not, tell the user to run `/init` first.
2. The guide PDF is available — either passed as `$ARGUMENTS` or found in the project root.
3. The Daytona sandbox runtime is reachable: `DAYTONA_API_KEY` is set (env or project `.env`) and `forge status` returns without error. **All builds, runs, `pip`, `typst`, etc. happen inside the sandbox via `forge exec --` — never on the host.**

## Pipeline

Execute these phases in order. Each phase produces artifacts consumed by the next.

### Phase 1: PLAN

Goal: extract all requirements from the guide PDF into a structured `TASK.md`.

If Forge OpenCode agents are installed, delegate to `@planner`. Otherwise do it yourself:
- Read the guide PDF thoroughly.
- Extract the lab title, objective, theory, task requirements, variant data, report structure, required formulas or algorithms, and figure requirements.
- Update `forge.yaml` and fill in `lab.title` if it is empty.
- Write `TASK.md` with objective, theory, task, report structure, implementation requirements, and report requirements.

### Phase 2: SOLVE

Goal: produce a working solution.

Read `TASK.md` and `forge.yaml` to determine the lab type.

If Forge OpenCode agents are installed, delegate to `@solver`. Otherwise do it yourself:
- For `code` or `mixed`: implement the solution in `src/`, then build and run it inside the sandbox: `forge exec -- bash -lc 'mkdir -p build && g++ -std=c++23 -Wall -Wextra -o build/main src/*.cpp'`, then `forge exec -- ./build/main`.
- For `math` or `mixed`: create scripts or notebooks, then `forge exec -- python3 src/solve.py`. Save plots into `images/`.
- Install missing Python packages with `forge exec -- pip install ... --break-system-packages -q`.
- Prepare formulas and tables for the report if needed.

### Phase 3: WRITE

Goal: write the complete report in `docs/report.typ`.

If Forge OpenCode agents are installed, delegate to `@writer`. Otherwise do it yourself:
- Mirror the section structure from `TASK.md`.
- Start the report with `#import "template.typ": *` and `#show: init`.
- Do not use `lab-report.with(...)`.
- Include code with `raw(read(...))`, figures with `image(...)`, and formulas with Typst math syntax.

### Phase 4: REVIEW

Goal: compile and verify the report.

If Forge OpenCode agents are installed, delegate to `@reviewer`. Otherwise do it yourself:
- Compile inside the sandbox: `forge exec -- bash -lc 'cd docs && typst compile report.typ report.pdf'`. The PDF is synced back to `docs/report.pdf` on the host.
- Fix Typst errors and retry as needed.
- Verify that all required sections, code listings, figures, and formulas are present.

## Completion

Finish only when `docs/report.pdf` exists, compiles successfully, and the report is complete.

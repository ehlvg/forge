# Forge — project overview

**Source:** [github.com/ehlvg/forge](https://github.com/ehlvg/forge)  
**License:** MIT  
**GitHub description:** *(none set on the repository; summary below is from the README and codebase.)*

---

## 1. What the project is about

**Forge** (Forge Framework) is a system for **autonomous university lab work**: it is designed to run inside **OpenCode** (an AI coding environment) using **skills** and **subagents** so that, after minimal setup, a user can point the workflow at a **lab guide PDF** and get a **compiled report PDF** plus supporting artifacts.

The README positions it as: *“A fully autonomous university assignment solving and reviewing system powered by AI agents.”* The intended workflow is two high-level actions: **`/init`** (create and configure a lab project) and **`/solve`** (run the full pipeline on a guide PDF). Optional **`/study`** generates study materials.

Typical outcomes for an initialized project include:

- Parsed requirements in `TASK.md`
- Code and/or math solutions under `src/` (and optionally notebooks)
- Figures and screenshots under `images/`
- A **GOST-style** academic report written in **Typst** under `docs/`, ending in `docs/report.pdf`
- Optional `STUDY_MATERIAL.md` for theory and test-style Q&A

Global student and university data are stored in `~/.forge.yaml` after first `/init`; per-project settings live in `./forge.yaml`.

---

## 2. Main technologies used

| Area | Technologies and dependencies |
|------|--------------------------------|
| **Repository languages** | **Typst** (templates and report layout), **Shell** (`install.sh`); GitHub’s language breakdown reflects mostly Typst + shell in this repo. |
| **Report generation** | **Typst** — templates in `templates/` (`template.typ`, `titlepage.typ`); **`typst` CLI** installed by `install.sh` if missing (downloaded from official Typst releases). |
| **Orchestration host** | **OpenCode** — skills install to `~/.config/opencode/skills` and agents to `~/.config/opencode/agents` (paths overridable via `OPENCODE_SKILLS_DIR` / `OPENCODE_AGENTS_DIR`). |
| **Configuration** | **YAML** — `config.example.yaml` documents `~/.forge.yaml` and `./forge.yaml` (student, university, subject, lab type, language, code language, etc.). |
| **PDF ingestion** | Documented approaches include **`pdftotext`**, **Python** with **PyMuPDF (`fitz`)** or similar, per planner/solve skill instructions. |
| **Lab work** | Solutions may use **Python**, **C++**, or other languages depending on `forge.yaml` / guide; **Jupyter** notebooks are part of the documented project layout when needed. |
| **Versioning during runs** | The solve pipeline encourages **git** checkpoints after each phase for traceability and rollback. |

**Note:** The “AI” layer is provided by the OpenCode environment and configured **models** (e.g. planner agent metadata references a capable model); the repo itself ships **prompts, skills, and agent definitions**, not a standalone application server.

---

## 3. Project structure (this repository)

| Path | Purpose |
|------|---------|
| **`README.md`** | User-facing documentation: features, install, usage, post-`/init` layout, `/solve` pipeline diagram, configuration examples. |
| **`install.sh`** | Copies skills and agent markdown into OpenCode config dirs, copies Typst templates and `AGENTS.md.template`, installs Typst if absent. |
| **`SKILL.md`** | Top-level **forge** skill: describes `/init`, `/solve`, `/study`, architecture, and config locations. |
| **`skills/`** | Per-command skills: **`init`**, **`solve`**, **`coder`**, **`math`**, **`writer`**, **`reviewer`**, **`study`** — each with its own `SKILL.md` defining behavior. |
| **`agents/`** | Subagent definitions: **`planner.md`**, **`solver.md`**, **`writer.md`**, **`reviewer.md`** — specialized roles in the pipeline (PDF → plan → solve → Typst → verify PDF). |
| **`templates/`** | **Typst** report scaffolding (`template.typ`, `titlepage.typ`) for GOST-oriented output. |
| **`AGENTS.md.template`** | Template for project-level agent context in an initialized lab folder. |
| **`config.example.yaml`** | Example global + project YAML schema. |
| **`LICENSE`** | MIT |

After **`/init`** in a new directory, the README describes a lab project layout (`forge.yaml`, `AGENTS.md`, `TASK.md`, `src/`, `notebooks/`, `images/`, `docs/`, `.opencode/skills`, `.opencode/agents`, etc.) — that structure is **created in the user’s lab directory**, not fully duplicated inside this framework repo.

---

## 4. Key features or functionality

1. **Guide-driven workflow** — Planner phase reads the lab PDF and produces structured **`TASK.md`** (and can fill **`lab.title`** in `forge.yaml` when empty).

2. **Multi-phase pipeline (`/solve`)** — **Planner → Solver → Writer → Reviewer**: extract requirements, implement solution (code/math/mixed), write the Typst report, compile and verify PDF. Can delegate to subagents when available, or run sequentially as one orchestrator.

3. **Lab types** — **`math`**, **`code`**, **`mixed`**, with configurable **`code_language`** and report **`language`** (e.g. Russian per examples).

4. **Outputs beyond the report** — Charts, screenshots, optional **Jupyter** notebooks, and **`/study`** for theory + test questions in **`STUDY_MATERIAL.md`**.

5. **Self-checking loop** — Reviewer phase focuses on **Typst compilation**, validation, and fixing issues so **`docs/report.pdf`** is the deliverable.

6. **Reproducibility and audit trail** — Solve skill documents **git checkpoints** after each phase with a consistent commit message pattern for reviewing or rolling back automated changes.

7. **Installer** — One script to sync Forge assets into OpenCode’s skill/agent directories and ensure **Typst** is on the PATH.

---

*This file was generated for overview and can be imported into Notion via **Import → Markdown** or copied into a new page.*

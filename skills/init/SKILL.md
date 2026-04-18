---
name: init
description: Initialize a new Forge Framework lab project. Use when starting a new lab assignment. Creates project structure, config, Typst template, installs dependencies. Run as /init or /init <subject> <lab_number>.
argument-hint: "[subject] [lab_number]"
---

# Init — Forge Framework Project Initializer

You are setting up a new lab assignment project. Your goal is to create everything the student needs so that the Forge `/solve` command can run fully autonomously afterward.

## Step 1: Gather Configuration

Check if `~/.forge.yaml` exists.

**If it exists:** read student and university data from it.
**If it does NOT exist:** ask the user for:
- Full name
- Short name (initials + surname, e.g. "V.D. Pankov")
- Group number
- University name and short name
- Department/faculty
- City

Then save to `~/.forge.yaml` so it's never asked again.

Check if arguments were provided (`$ARGUMENTS`). Parse them for subject name and lab number.

If subject/lab info is missing, ask the user:
- Subject name
- Teacher name — optional
- Teacher position/degree — optional
- Lab number
- Variant number (0 if not applicable)
- Lab type: `math`, `code`, or `mixed`
- Programming language (if code/mixed) — default C++23

## Step 2: Verify the sandbox runtime

All compilation, execution, and Typst happen inside a Daytona sandbox bound to this project. Make sure:

- `uv` is installed on the host (the `forge` CLI uses it to run the runtime).
- `DAYTONA_API_KEY` is exported in the shell or stored in the project's `.env` (gitignored). Optionally set `DAYTONA_API_URL`, `DAYTONA_TARGET`, `FORGE_DAYTONA_SNAPSHOT`, or `FORGE_DAYTONA_IMAGE`.
- `forge status` runs without error.

The sandbox auto-installs g++, cmake, python3, Typst and DejaVu fonts on first start. No host-side Typst install is required.

## Step 3: Create Project Structure

Create these directories and files:

```
./
├── forge.yaml
├── AGENTS.md
├── src/
├── notebooks/
├── images/
├── docs/
│   ├── report.typ
│   ├── template.typ
│   └── titlepage.typ
└── .gitignore
```

## Step 4: Generate forge.yaml

Write `forge.yaml` in the project root with all gathered data:

```yaml
student:
  name: "<full name>"
  name_short: "<initials + surname, e.g. V.D. Pankov>"
  group: "<group>"
university:
  name: "<university full name>"
  short: "<short name>"
  department: "<department/faculty>"
  city: "<city>"
subject:
  name: "<subject>"
  teacher: "<teacher initials + surname>"
  teacher_position: "<position, degree — optional, empty string if unknown>"
lab:
  number: <N>
  title: ""
  variant: <V>
  type: "<type>"
  language: "russian"
  code_language: "<lang>"
```

When generating `name_short` from the full name: "Pankov Vasiliy Dmitrievich" → "V.D. Pankov".

## Step 5: Set Up Typst Template

The template consists of TWO files: `docs/titlepage.typ` and `docs/template.typ`.

**Copy both from the Forge Framework installation** — look in these locations (in order):
1. `../../templates/titlepage.typ` and `../../templates/template.typ` (relative to this skill file)
2. `~/.config/opencode/skills/forge/templates/titlepage.typ` and `template.typ`
3. `~/.claude/skills/forge/templates/titlepage.typ` and `template.typ` (legacy fallback only)

If not found, the template content is embedded below for reference — generate the files from it.

After copying, **fill in the placeholders** in `docs/template.typ` by replacing `__PLACEHOLDER__` strings with real values from `forge.yaml`:

| Placeholder | Source |
|---|---|
| `__AUTHOR__` | `student.name_short` |
| `__CITY__` | `university.city` |
| `__DEPARTMENT__` | `university.department` |
| `__EDUCATION__` | `university.name` |
| `__GROUP__` | `student.group` |
| `__TEACHER__` | `subject.teacher` |
| `__POSITION__` | `subject.teacher_position` |
| `__TITLE__` | leave empty for now — writer agent fills it from TASK.md |
| `__SUBJECT__` | `subject.name` |

Use `sed` to replace:
```bash
sed -i "s/__AUTHOR__/$NAME_SHORT/g" docs/template.typ
sed -i "s/__CITY__/$CITY/g" docs/template.typ
sed -i "s/__DEPARTMENT__/$DEPARTMENT/g" docs/template.typ
sed -i "s/__EDUCATION__/$EDUCATION/g" docs/template.typ
sed -i "s/__GROUP__/$GROUP/g" docs/template.typ
sed -i "s/__TEACHER__/$TEACHER/g" docs/template.typ
sed -i "s/__POSITION__/$POSITION/g" docs/template.typ
sed -i "s/__SUBJECT__/$SUBJECT/g" docs/template.typ
```

Then create `docs/report.typ`:

```typst
#import "template.typ": *

#show: init

// Sections will be filled by the writer agent
```

**IMPORTANT:** The report uses `#show: init` (NOT `lab-report.with(...)`). All metadata is baked into `template.typ` from `forge.yaml`. The `ch(content)` function is available for centered unnumbered headings.

## Step 6: Generate AGENTS.md

Create `AGENTS.md` in the project root with:
- Project type and structure overview
- Subject and lab context
- Instructions for OpenCode agents
- Available OpenCode commands (/solve, /study) from the global Forge installation
- Note that `docs/report.typ` uses `#show: init` and headings use `= Heading` / `== Subheading` syntax
- Note that `docs/template.typ` has the `ch()` function for centered unnumbered headings

Do not copy Forge skills or agents into the project. Use the global OpenCode installation managed by Forge.

## Step 7: Create .gitignore

```
docs/report.pdf
*.pyc
__pycache__/
.ipynb_checkpoints/
build/
*.o
*.exe
/tmp/
.env
.forge/
```

## Step 8: Initialize Git

```bash
git init
git add -A
git commit -m "init: forge project for <subject> lab <N>"
```

## Step 9: Final Summary

Print a summary:
```
✅ Forge Framework project initialized!

📁 Project: <subject> — Lab <N>
👤 Student: <name> (<group>)
🏫 University: <university>
📝 Type: <type>

Next steps:
1. Place the guide PDF in the project root
2. Run: /solve guide.pdf
```

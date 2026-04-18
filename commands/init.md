---
description: Initialize a new Forge Framework lab project.
agent: build
---

Run the Forge Framework project initialization flow in the current directory.

Command arguments: `$ARGUMENTS`

Follow the instructions below exactly.

# Init — Forge Framework Project Initializer

You are setting up a new lab assignment project. Your goal is to create everything the student needs so that the Forge `/solve` command can run fully autonomously afterward.

## Step 1: Gather Configuration

Check if `~/.forge.yaml` exists.

If it exists: read student and university data from it.
If it does not exist: ask the user for:
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
- Report language: `russian` or `english` — default `russian`

## Step 2: Install Typst (if needed)

Check if `typst` is available.

If not found, install it for the current OS and verify with `typst --version`.

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
  language: "<russian|english>"
  code_language: "<lang>"
```

When generating `name_short` from the full name: "Pankov Vasiliy Dmitrievich" → "V.D. Pankov".

Supported `language` values: `russian` or `english`.

## Step 5: Set Up Typst Template

Copy `docs/titlepage.typ` and `docs/template.typ` from the Forge installation.

**Select the language-appropriate templates:**

- If `language` is `russian`: copy `gost.typ.ru` → `docs/template.typ` and `titlepage.typ.ru` → `docs/titlepage.typ`
- If `language` is `english`: copy `template.typ` → `docs/template.typ` and `titlepage.typ` → `docs/titlepage.typ`

After copying, fill in the placeholders in `docs/template.typ` from `forge.yaml`.

Then create `docs/report.typ`:

```typst
#import "template.typ": *

#show: init

// Sections will be filled by the writer agent
```

The report uses `#show: init`. Do not add `lab-report.with(...)`.

## Step 6: Generate AGENTS.md

Create `AGENTS.md` in the project root with:
- Project type and structure overview
- Subject and lab context
- Instructions for OpenCode agents
- Available OpenCode commands (`/solve`, `/study`) from the global Forge installation
- Note that `docs/report.typ` uses `#show: init`
- Note that `docs/template.typ` has the `ch()` helper for centered unnumbered headings

Do not copy Forge skills or agents into the project. Use the global OpenCode installation managed by Forge.

## Step 7: Create .gitignore

Use:

```
docs/report.pdf
*.pyc
__pycache__/
.ipynb_checkpoints/
build/
*.o
*.exe
/tmp/
```

## Step 8: Initialize Git

If git is not initialized, initialize it and create the first commit.

## Step 9: Final Summary

Print a summary with the project, student, university, lab type, and the next step: run `/solve guide.pdf`.

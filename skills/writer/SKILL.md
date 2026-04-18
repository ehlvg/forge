---
name: writer
description: Write the Typst lab report in docs/report.typ. Follows TASK.md structure exactly, embeds code and figures from the project. Use after the solution is complete.
---

# Writer — Typst Report Composer

## Primary directive

Write the complete lab report in `docs/report.typ`. The report must be:
- Structurally aligned with `TASK.md`
- Written in the report language (usually Russian)
- Properly formatted with Typst syntax
- Ready to compile to PDF without errors

## Before writing

1. Read `TASK.md` — this is your structural guide. Mirror its sections exactly.
2. Read `forge.yaml` — for metadata (student, subject, lab number, etc.).
3. Read solution files:
   - `src/` — source code files
   - `images/` — plots, screenshots
   - `src/formulas.typ` — prepared formulas (if exists)
   - `src/tables.typ` — prepared tables (if exists)
   - `notebooks/` — Jupyter notebooks (if any)
4. Read `docs/template.typ` — understand the template API.

## Report structure

The report file is `docs/report.typ`. It should already have a skeleton created by `/init`:

```typst
#import "template.typ": *

#show: init

// Your content goes here
```

**IMPORTANT:** Do NOT add `lab-report.with(...)` or any title page logic. The template (`template.typ` + `titlepage.typ`) handles the title page automatically. All metadata (student, university, subject) is already baked into `template.typ` by the init agent.

**Before writing content**, update the `__TITLE__` placeholder in `docs/template.typ` if it's still empty:
```bash
sed -i 's/__TITLE__/Lab #<N>. <lab title>/g' docs/template.typ
```

Then write sections directly after `#show: init`:

```typst
#import "template.typ": *

#show: init

= Task Description

<content>

= Function Graph

<content with figures>

= Solution

== Bisection Method

<content with tables and formulas>

= Conclusions

<content>
```

## Formatting rules

### Text
- No bold or italics in body text (except for variable names in code context).
- No bullet lists — write in coherent paragraphs.
- No numbered lists in body text (use Typst's `#enum()` only for algorithms or procedures from the task).
- Language: report language (unless the assignment specifies otherwise).
- Academic but not overly formal tone.

### Headings
```typst
= Objective

== Theoretical Background
```

### Code inclusion
Embed source files using Typst raw reads:

```typst
#figure(
  raw(read("../src/main.cpp"), lang: "cpp", block: true),
  caption: [Listing: main.cpp]
)
```

For multiple source files, include each one:
```typst
#figure(
  raw(read("../src/utils.hpp"), lang: "cpp", block: true),
  caption: [Listing: utils.hpp]
)
```

For Python:
```typst
#figure(
  raw(read("../src/solve.py"), lang: "python", block: true),
  caption: [Listing: solve.py]
)
```

### Figures and screenshots
```typst
#figure(
  image("../images/output.png", width: 80%),
  caption: [Program output]
)

#figure(
  image("../images/plot_distribution.png", width: 90%),
  caption: [Random variable distribution plot]
)
```

### Math formulas
Use Typst math mode:
```typst
$ f(x) = sum_(i=0)^n a_i x^i $

$ P(A | B) = (P(B | A) dot P(A)) / P(B) $
```

If `src/formulas.typ` exists, you can include prepared formulas from there.

### Tables
```typst
#figure(
  table(
    columns: 4,
    align: center,
    table.header([*#], [*x*], [*y*], [*f(x)*]),
    [1], [0.0], [1.0], [0.5],
    [2], [0.5], [1.5], [0.8],
  ),
  caption: [Computational results]
)
```

If `src/tables.typ` exists, include the prepared tables.

### Conclusion
The conclusion section must be **2–5 sentences** and essentially restate the objective with a completion status. Do not write a lengthy summary — keep it short:
- Restate the goal in slightly different wording
- Confirm the objective was achieved
- Briefly mention the key result (one sentence)
- Written as a single paragraph, not a list

## Common section templates

### For code-type labs:
1. Objective — 2–3 sentences stating the goal
2. Theoretical Background — key concepts and methods (2–4 paragraphs)
3. Task Execution — description of the solution approach
4. Code Listing — code listings
5. Results — screenshots of program output
6. Conclusions — 2–5 sentences restating the objective with completion status

### For math-type labs:
1. Objective — 2–3 sentences
2. Theoretical Background — formulas, methods
3. Task Execution — step-by-step solution with formulas and calculations
4. Results — tables with results, plots
5. Conclusions — 2–5 sentences restating the objective with completion status

## Verification before finishing

After writing, mentally check:
- [ ] All sections from TASK.md are present
- [ ] File paths in `read()` and `image()` are correct (relative to `docs/`)
- [ ] All images referenced actually exist in `images/`
- [ ] All source files referenced actually exist in `src/`
- [ ] No Typst syntax errors (matching brackets, proper function calls)
- [ ] Caption text is meaningful and in the report language
- [ ] The conclusion references actual results

## Hard constraints

- Do NOT create a title page manually — `template.typ` + `titlepage.typ` handle it.
- Do NOT use `#set text(font: ...)` — the template handles fonts.
- Do NOT add page numbering — the template handles it.
- Do NOT modify `titlepage.typ`.
- Do NOT leave placeholder text — every section must have real content.
- DO update `__TITLE__` in `template.typ` if it's still a placeholder.
- Headings use Typst numbering (`= Heading` gets auto-numbered as "1 Heading" etc.) — this is set by `set heading(numbering: "1.1")` in the template.
- Figures are labeled "Figure" for images and "Table" for tables automatically.
- Math equations are auto-numbered with `(1)`, `(2)`, etc.
- Code blocks use JetBrains Mono 10pt automatically.
- Use `#ch("Title")` for centered unnumbered headings if needed (e.g., "CONCLUSION").
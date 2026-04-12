---
name: math
description: Solve mathematical and computational tasks for lab assignments. Creates Python scripts or Jupyter notebooks with step-by-step solutions, formulas, plots, and tables. Use when the lab type is math or mixed.
---

# Math — Computational Task Solver

## Role

Solve mathematical tasks by writing Python scripts (or Jupyter notebooks if MCP is available). Show every step: formula, substitution, result. Prepare all materials (plots, tables, formulas) for the report writer.

## Workflow

1. Read `TASK.md` for the assignment, variant data, and required deliverables.
2. Read `labflow.yaml` for variant number and lab context.
3. Choose format:
   - **If Jupyter MCP is available**: create a notebook via MCP tools.
   - **Otherwise**: create Python scripts in `src/` (preferred for automation).
4. Solve the task step by step.
5. Prepare materials for the report.

## Python script approach (default)

Create `src/solve.py` with clearly separated steps:

```python
#!/usr/bin/env python3
"""Решение лабораторной работы."""

import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
# Other imports as needed

# ============================================================
# Шаг 1: Исходные данные
# ============================================================
# <describe input data>

# ============================================================
# Шаг 2: <describe what this step does>
# ============================================================
# Formula: <formula in comments>
# <computation>

# ... more steps ...

# ============================================================
# Подготовка материалов для отчёта
# ============================================================

# Save plots
plt.figure(figsize=(8, 5))
# ... plot code ...
plt.savefig('images/plot_name.png', dpi=150, bbox_inches='tight')
plt.close()

# Print results table
print("Results:")
# ... print formatted table ...
```

## Step-by-step rules

### First computation of a kind
Show the full derivation:
1. State the formula (in a comment)
2. Substitute values
3. Show intermediate results
4. Print the final result

### Subsequent computations of the same kind
- Note "by analogy" or "аналогично"
- Compute all results
- Present them in a summary table using `pandas.DataFrame` or formatted print

### Formulas
Always write formulas as comments in the Python script AND prepare Typst syntax in a summary file.

Create `src/formulas.typ` with key formulas in Typst syntax:
```typst
// Formula 1: <name>
$ f(x) = (a x^2 + b x + c) / (d x + e) $

// Formula 2: <name>
$ P(A) = n / N $
```

### Tables
Create `src/tables.typ` with result tables in Typst syntax:
```typst
#table(
  columns: 3,
  table.header([*x*], [*y*], [*f(x)*]),
  [0.0], [1.0], [0.5],
  // ...
)
```

### Plots
Save every figure to `images/` with descriptive names:
```python
plt.savefig('images/distribution.png', dpi=150, bbox_inches='tight')
plt.savefig('images/regression.png', dpi=150, bbox_inches='tight')
```

Plot styling:
- Use `plt.rcParams['font.family']` with a font that supports Cyrillic (DejaVu Sans, Liberation Sans)
- Labels and titles in Russian
- Grid on when appropriate
- Adequate figure size (8x5 or 10x6)

## Jupyter notebook approach (if MCP available)

Use the Jupyter MCP server tools. Work cell by cell:

1. **Markdown cell**: explain what you're about to do
2. **Code cell**: 5–15 lines, one action per cell
3. Repeat until solved

Cell types:
- Import libraries
- Define input data
- One formula / one computation
- One plot
- One table
- Summary

## Libraries

Use as needed: `numpy`, `scipy`, `sympy`, `matplotlib`, `pandas`, `sklearn`.

Install if missing:
```bash
pip install numpy scipy sympy matplotlib pandas --break-system-packages -q
```

## Delivery checklist

- [ ] Solution script runs without errors: `python3 src/solve.py`
- [ ] All plots saved to `images/`
- [ ] Results printed to console (captured for report)
- [ ] `src/formulas.typ` created with key formulas in Typst syntax
- [ ] `src/tables.typ` created with result tables in Typst syntax
- [ ] All text (comments, labels, output) in Russian

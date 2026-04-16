---
name: solve
description: Run full lab assignment pipeline autonomously. Parses guide PDF, solves tasks, writes Typst report, compiles to PDF. Use as /solve <guide.pdf> or /solve (if guide already exists). No human approval needed.
argument-hint: "[guide.pdf]"
---

# Solve — Full Lab Pipeline Orchestrator

You are the main orchestrator. Your job is to take a lab guide PDF and produce a complete, compiled PDF report with zero human intervention. Work autonomously — do NOT ask for confirmation between steps. If you encounter an issue, try to resolve it yourself. Only ask the user if critical information is truly impossible to infer.

## Prerequisites

Before starting, verify:
1. `forge.yaml` exists — if not, tell the user to run `/init` first.
2. The guide PDF is available — either passed as `$ARGUMENTS` or find any `.pdf` file in the project root.
3. `typst` is installed — if not, install it:
   ```bash
   wget -qO /tmp/typst.tar.xz https://github.com/typst/typst/releases/latest/download/typst-x86_64-unknown-linux-musl.tar.xz
   mkdir -p ~/.local/bin && tar xf /tmp/typst.tar.xz --strip-components=1 -C ~/.local/bin
   export PATH="$HOME/.local/bin:$PATH"
   ```

## Checkpoints (Version Snapshots)

After EACH phase, create a git checkpoint:
```bash
git add -A && git commit -m "forge: phase N — <description> [<agent>]"
```

This gives a full history of the pipeline. The user can:
- See what changed at each step: `git log --oneline`
- Diff any phase: `git diff HEAD~1`
- Roll back to any phase: `git checkout HEAD~2`
- Re-run from a specific point

**Checkpoint naming convention:**
- `forge: phase 1 — task extracted [planner]`
- `forge: phase 2 — solution complete [solver]`
- `forge: phase 3 — report written [writer]`
- `forge: phase 4 — PDF compiled [reviewer]`

If git is not initialized, run `git init && git add -A && git commit -m "forge: initial state"` before starting.

## Pipeline

Execute these phases in order. Each phase produces artifacts consumed by the next.

---

### Phase 1: PLAN (Analyze Guide)

**Goal:** Extract all requirements from the guide PDF into a structured `TASK.md`.

**If Forge OpenCode agents are installed**, delegate to `@planner`.
**Otherwise**, do this yourself:

1. Read the guide PDF thoroughly (use available PDF reading tools, `pdftotext`, or `python3` with `pymupdf`/`pdfplumber`).
2. Extract:
   - Full lab title
   - Objective
   - Theoretical background needed
   - Task requirements (what to implement/compute/solve)
   - Variant-specific data (if variant is set in `forge.yaml`)
   - Required report structure (if specified in the guide)
   - Any formulas, algorithms, or methods to use
   - Requirements for screenshots/figures
3. Update `forge.yaml` → fill in `lab.title` if it was empty.
4. Write `TASK.md` with this structure:

```markdown
# <Lab Title>

## Objective
<objective>

## Theoretical Background
<theory summary — key concepts, formulas, methods>

## Task
<full task description>
<variant-specific data if applicable>

## Report Structure
1. <section 1>
2. <section 2>
...

## Implementation Requirements
- <language, tools, constraints>

## Report Requirements
- <what must be included: code listings, screenshots, formulas, tables>
```

**Checkpoint:**
```bash
git add -A && git commit -m "forge: phase 1 — task extracted [planner]"
```

---

### Phase 2: SOLVE (Implement Solution)

**Goal:** Produce a working solution — code, computations, or both.

Read `TASK.md` and `forge.yaml` to determine the lab type.

#### If `type: code` or `type: mixed`:

**If Forge OpenCode agents are installed**, delegate to `@solver`.
**Otherwise**, do this yourself following the coder skill rules:

1. Read `TASK.md` for implementation requirements.
2. Determine the language (from `forge.yaml` or `TASK.md`). Default: C++23.
3. Write clean, compilable code in `src/`.
   - C++: headers in `.hpp` with `#pragma once`, implementations in `.cpp`.
   - Python: modules in `.py`, entry point in `main.py`.
   - Other languages: follow standard conventions.
4. Comments in the report language, minimal.
5. Build and test:
   - C++: `g++ -std=c++23 -o build/main src/*.cpp && ./build/main`
   - Python: `python3 src/main.py`
6. Capture program output for the report.

#### If `type: math` or `type: mixed`:

1. Create a Jupyter notebook in `notebooks/` OR a Python script in `src/`.
2. For each computational step:
   - Explain what you're doing
   - Show the formula
   - Compute the result
   - Print/display results
3. Save all plots to `images/`:
   ```python
   import matplotlib
   matplotlib.use('Agg')
   import matplotlib.pyplot as plt
   plt.savefig('images/plot_name.png', dpi=150, bbox_inches='tight')
   ```
4. Prepare Typst-compatible tables and formulas for the writer.

#### Screenshots

After running the solution, create screenshots of program output:

**Strategy 1 — Terminal output capture (preferred for CLI programs):**
```bash
# Run the program and capture output
./build/main > /tmp/output.txt 2>&1
# Use Python to render text as an image
python3 -c "
import subprocess
# Try to use a text-to-image approach
text = open('/tmp/output.txt').read()
try:
    from PIL import Image, ImageDraw, ImageFont
    # Create image from text
    lines = text.split('\n')
    font_size = 14
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf', font_size)
    except:
        font = ImageFont.load_default()
    padding = 20
    line_height = font_size + 4
    width = max(len(line) for line in lines) * (font_size // 2 + 1) + 2 * padding
    width = max(width, 400)
    height = len(lines) * line_height + 2 * padding
    img = Image.new('RGB', (width, height), '#1e1e2e')
    draw = ImageDraw.Draw(img)
    y = padding
    for line in lines:
        draw.text((padding, y), line, fill='#cdd6f4', font=font)
        y += line_height
    img.save('images/output.png')
    print('Screenshot saved to images/output.png')
except ImportError:
    # Fallback: save as text file, note in TASK.md
    print('PIL not available, saving text output only')
    with open('images/output.txt', 'w') as f:
        f.write(text)
"
```

**Strategy 2 — For graphical programs (Qt, etc.):**
```bash
# Install virtual framebuffer if needed
which Xvfb || sudo apt-get install -y xvfb
# Run with virtual display and take screenshot
Xvfb :99 -screen 0 1024x768x24 &
export DISPLAY=:99
sleep 1
./build/main &
APP_PID=$!
sleep 3
# Use import (ImageMagick) or scrot
import -window root images/screenshot.png || scrot images/screenshot.png
kill $APP_PID
```

**Strategy 3 — For matplotlib/plots (already handled above):**
Plots are saved directly as images.

**Strategy 4 — Fallback:**
If no screenshot tool works, include program output as a code block in the report and note that screenshots could not be captured automatically.

Install dependencies as needed:
```bash
pip install pillow matplotlib numpy scipy sympy pandas --break-system-packages -q 2>/dev/null
```

**Checkpoint:**
```bash
git add -A && git commit -m "forge: phase 2 — solution complete [solver]"
```

---

### Phase 3: WRITE (Compose Typst Report)

**Goal:** Write the complete report in `docs/report.typ`.

**If Forge OpenCode agents are installed**, delegate to `@writer`.
**Otherwise**, do this yourself following the writer skill rules:

1. Read `TASK.md` for the required report structure.
2. Read `forge.yaml` for metadata.
3. Read the solution files (code, notebooks, outputs).
4. Write `docs/report.typ`:

**Rules:**
- Start with the `#import "template.typ": *` and `#show: init` block.
- Mirror the section structure from `TASK.md` exactly.
- Write in coherent paragraphs, no bullet lists in body text.
- No bold/italic in body text unless quoting variable names or terms.
- All text in the report language (usually Russian unless specified otherwise).

**Code inclusion:**
```typst
#figure(
  raw(read("../src/main.cpp"), lang: "cpp", block: true),
  caption: "Source code"
)
```

**Images/screenshots:**
```typst
#figure(
  image("../images/output.png", width: 80%),
  caption: "Program output"
)
```

**Math formulas:** use Typst math syntax `$ ... $`.

**Tables:**
```typst
#figure(
  table(
    columns: 3,
    [*x*], [*y*], [*f(x)*],
    [0.0], [1.0], [0.5],
  ),
  caption: "Computational results"
)
```

**Checkpoint:**
```bash
git add -A && git commit -m "forge: phase 3 — report written [writer]"
```

---

### Phase 4: REVIEW (Compile & Verify)

**Goal:** Compile the report to PDF and verify completeness.

**If Forge OpenCode agents are installed**, delegate to `@reviewer`.
**Otherwise**, do this yourself:

1. **Compile:**
   ```bash
   cd docs && typst compile report.typ report.pdf 2>&1
   ```

2. **If compilation fails:**
   - Read the error message carefully.
   - Fix the issue in `report.typ`.
   - Re-compile.
   - Repeat up to 5 times. If still failing, report the error to the user.

3. **Verify PDF exists and is non-empty:**
   ```bash
   ls -la docs/report.pdf
   file docs/report.pdf
   ```

4. **Verify completeness:**
   - Read `TASK.md` section list.
   - Check that each required section exists in `report.typ`.
   - Check that code listings are included (if type is code/mixed).
   - Check that images/figures exist (if screenshots were required).
   - Check that mathematical formulas are present (if type is math/mixed).

5. **If something is missing:**
   - Go back to the relevant phase (SOLVE or WRITE) and fix it.
   - Re-compile.

6. **Final output:**
   ```
   ✅ Lab report compiled successfully!

   📄 PDF: docs/report.pdf
   📊 Pages: <N>
   📁 Images: <N> figures included
   📝 Sections: <list>

   The report is ready for submission.
   ```

7. **Final checkpoint:**
   ```bash
   git add -A && git commit -m "forge: phase 4 — PDF compiled [reviewer]"
   ```

8. **Show version history:**
   ```bash
   echo ""
   echo "📜 Version history:"
   git log --oneline --graph
   echo ""
   echo "Rollback to any phase: git checkout <hash>"
   echo "See changes in a phase: git diff <hash>~ <hash>"
   ```

## Error Recovery

- If `pdftotext` is not available: `pip install pymupdf --break-system-packages -q && python3 -c "import fitz; doc=fitz.open('guide.pdf'); [print(p.get_text()) for p in doc]"`
- If `g++` is not available: `sudo apt-get install -y g++` or use the available compiler.
- If Python packages are missing: `pip install <package> --break-system-packages -q`
- If fonts are missing for Typst: the template should use built-in fonts or download them.
- If the guide PDF is scanned (no text): use OCR with `pip install pytesseract --break-system-packages -q` and `tesseract`.

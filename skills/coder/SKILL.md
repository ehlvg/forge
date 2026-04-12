---
name: coder
description: Solve programming tasks for lab assignments. Use when asked to implement code in C++ (default C++23), Python, or any other language. Follows project conventions and produces clean, compilable code.
---

# Coder — Lab Code Implementation

## Role

Implement programming tasks according to `TASK.md`. Produce clean, compilable, working code.

## Before coding

1. Read `TASK.md` to understand requirements.
2. Read `labflow.yaml` to determine the language (`lab.code_language`). Default: C++23.
3. Check if there are existing files in `src/` to understand the project structure.

## Language-specific conventions

### C++ (default)

- Standard: C++23 (`g++ -std=c++23`).
- Headers in `.hpp` with `#pragma once`.
- Implementations in `.cpp`.
- 2-space indentation, `snake_case` for variables/functions, `PascalCase` for types.
- Minimal comments in Russian.
- All program output text in Russian.
- No decorative box-drawing characters in output.
- Split into multiple files when it improves clarity.

**Build:**
```bash
mkdir -p build
g++ -std=c++23 -Wall -Wextra -o build/main src/*.cpp
```

**Qt projects:**
- Use `.ui` files from Qt Designer unless forbidden.
- Ensure `setupUi(this)` is called correctly.
- Build with `qmake` or `cmake`.

### Python

- Python 3.10+.
- Entry point: `src/main.py`.
- Use type hints where reasonable.
- Follow PEP 8.
- Install dependencies: `pip install <pkg> --break-system-packages -q`.

### Other languages

- Follow standard conventions for the language.
- Always provide build/run instructions.

## Output capture

After running the program, capture its output:

```bash
# Run and save output
cd build && ./main > ../images/output.txt 2>&1

# Convert text output to image
python3 << 'PYEOF'
from PIL import Image, ImageDraw, ImageFont
text = open("images/output.txt").read()
lines = text.split("\n")
font_size = 14
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", font_size)
except:
    font = ImageFont.load_default()
pad = 20
lh = font_size + 4
w = max((len(l) for l in lines), default=20) * (font_size // 2 + 1) + 2 * pad
w = max(w, 400)
h = len(lines) * lh + 2 * pad
img = Image.new("RGB", (w, h), "#1e1e2e")
draw = ImageDraw.Draw(img)
y = pad
for line in lines:
    draw.text((pad, y), line, fill="#cdd6f4", font=font)
    y += lh
img.save("images/output.png")
print("Screenshot saved")
PYEOF
```

## Delivery checklist

- [ ] All source files are in `src/`.
- [ ] Code compiles without errors.
- [ ] Program runs and produces correct output.
- [ ] Output is captured in `images/output.txt` and `images/output.png`.
- [ ] Edge cases are handled (empty input, overflow) where relevant.
- [ ] No unnecessary dependencies.

---
name: study
description: Generate comprehensive study materials with theory, methods, worked examples, and control questions with answers. Use as /study after solving a lab, or standalone.
---

# Study — Study Material Generator

## Purpose

Create `STUDY_MATERIAL.md` — a self-contained study document covering all theory, methods, and formulas for the current lab, plus control questions with detailed answers. This is a learning aid for exam prep, not a formal report.

## Workflow

1. Read `TASK.md` to understand the topic and methods.
2. Read the guide PDF (if present) for theoretical background.
3. Read solution files (code, notebooks) to understand what was done.
4. Compose `STUDY_MATERIAL.md` following the structure below.

## Output Structure

```markdown
# <Lab Title> — Учебные материалы

## 1. Теоретическая база

<Full explanation of underlying theory. Key definitions with clear explanations.
All relevant formulas with descriptions of every variable.
Conditions of applicability and limitations.>

## 2. Методы и алгоритмы

<Step-by-step description of each method used.
Decision criteria (thresholds, critical values).
Interpretation rules for results.>

## 3. Разбор решения

<Brief walkthrough of how methods apply to the variant from TASK.md.
Key intermediate results — do NOT re-solve, just summarize.>

## 4. Ключевые выводы

<Most important facts and relationships to remember.
Common mistakes and how to avoid them.>

## 5. Контрольные вопросы и ответы

### В1: <question>
**Ответ:** <detailed answer>

### В2: <question>
**Ответ:** <detailed answer>

... (at least 10 questions)
```

## Writing rules

- Language: Russian
- Be thorough — sufficient for exam preparation
- Formulas in LaTeX: `$...$` inline, `$$...$$` display
- No raw code — explain concepts in prose
- Do not modify any project files
- At least 10 control questions covering all major topics
- Questions: range from basic definitions to applied/analytical
- Every question MUST have a complete, detailed answer

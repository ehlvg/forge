#!/usr/bin/env bash
# LabFlow Installer
# Installs LabFlow skills and agents globally for Claude Code / OpenCode.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
#   OR
#   git clone https://github.com/.../labflow && cd labflow && ./install.sh

set -euo pipefail

LABFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CLAUDE_AGENTS_DIR="$HOME/.claude/agents"

echo "🔧 Installing LabFlow..."

# --- Create directories ---
mkdir -p "$CLAUDE_SKILLS_DIR/labflow"
mkdir -p "$CLAUDE_SKILLS_DIR/init"
mkdir -p "$CLAUDE_SKILLS_DIR/solve"
mkdir -p "$CLAUDE_SKILLS_DIR/coder"
mkdir -p "$CLAUDE_SKILLS_DIR/math-solver"
mkdir -p "$CLAUDE_SKILLS_DIR/report-writer"
mkdir -p "$CLAUDE_SKILLS_DIR/report-reviewer"
mkdir -p "$CLAUDE_SKILLS_DIR/study-gen"
mkdir -p "$CLAUDE_AGENTS_DIR"

# --- Copy global skill ---
cp "$LABFLOW_DIR/SKILL.md" "$CLAUDE_SKILLS_DIR/labflow/SKILL.md"

# --- Copy skills ---
cp "$LABFLOW_DIR/skills/init/SKILL.md" "$CLAUDE_SKILLS_DIR/init/SKILL.md"
cp "$LABFLOW_DIR/skills/solve/SKILL.md" "$CLAUDE_SKILLS_DIR/solve/SKILL.md"
cp "$LABFLOW_DIR/skills/coder/SKILL.md" "$CLAUDE_SKILLS_DIR/coder/SKILL.md"
cp "$LABFLOW_DIR/skills/math/SKILL.md" "$CLAUDE_SKILLS_DIR/math-solver/SKILL.md"
cp "$LABFLOW_DIR/skills/writer/SKILL.md" "$CLAUDE_SKILLS_DIR/report-writer/SKILL.md"
cp "$LABFLOW_DIR/skills/reviewer/SKILL.md" "$CLAUDE_SKILLS_DIR/report-reviewer/SKILL.md"
cp "$LABFLOW_DIR/skills/study/SKILL.md" "$CLAUDE_SKILLS_DIR/study-gen/SKILL.md"

# --- Copy agents ---
cp "$LABFLOW_DIR/agents/planner.md" "$CLAUDE_AGENTS_DIR/planner.md"
cp "$LABFLOW_DIR/agents/solver.md" "$CLAUDE_AGENTS_DIR/solver.md"
cp "$LABFLOW_DIR/agents/writer.md" "$CLAUDE_AGENTS_DIR/writer.md"
cp "$LABFLOW_DIR/agents/reviewer.md" "$CLAUDE_AGENTS_DIR/reviewer.md"

# --- Copy template ---
mkdir -p "$CLAUDE_SKILLS_DIR/labflow/templates"
cp "$LABFLOW_DIR/templates/template.typ" "$CLAUDE_SKILLS_DIR/labflow/templates/template.typ"
cp "$LABFLOW_DIR/templates/titlepage.typ" "$CLAUDE_SKILLS_DIR/labflow/templates/titlepage.typ"

# --- Copy CLAUDE.md template ---
cp "$LABFLOW_DIR/CLAUDE.md.template" "$CLAUDE_SKILLS_DIR/labflow/CLAUDE.md.template"

# --- Copy config example ---
cp "$LABFLOW_DIR/config.example.yaml" "$CLAUDE_SKILLS_DIR/labflow/config.example.yaml"

# --- Install Typst if missing ---
if ! command -v typst &> /dev/null; then
  echo "📦 Installing Typst CLI..."
  wget -qO /tmp/typst.tar.xz https://github.com/typst/typst/releases/latest/download/typst-x86_64-unknown-linux-musl.tar.xz
  mkdir -p ~/.local/bin
  tar xf /tmp/typst.tar.xz --strip-components=1 -C ~/.local/bin
  # Add to PATH if not already there
  if ! grep -q '.local/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  fi
  export PATH="$HOME/.local/bin:$PATH"
  echo "  ✅ Typst $(typst --version) installed"
else
  echo "  ✅ Typst already installed: $(typst --version)"
fi

echo ""
echo "✅ LabFlow installed successfully!"
echo ""
echo "Available commands (in Claude Code / OpenCode):"
echo "  /init   — Initialize a new lab project"
echo "  /solve  — Run full pipeline (guide PDF → report PDF)"
echo "  /study  — Generate study materials"
echo ""
echo "Quick start:"
echo "  mkdir lab1 && cd lab1"
echo "  claude  # or opencode"
echo "  > /init"
echo "  > /solve guide.pdf"
echo ""

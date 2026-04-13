#!/usr/bin/env bash
# Forge Framework Installer
# Installs Forge Framework skills and agents globally for OpenCode.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
#   OR
#   git clone https://github.com/.../forge-framework && cd forge-framework && ./install.sh

set -euo pipefail

FORGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_SKILLS_DIR="${OPENCODE_SKILLS_DIR:-$HOME/.config/opencode/skills}"
OPENCODE_AGENTS_DIR="${OPENCODE_AGENTS_DIR:-$HOME/.config/opencode/agents}"

echo "Installing Forge Framework..."

# --- Create directories ---
mkdir -p "$OPENCODE_SKILLS_DIR/forge"
mkdir -p "$OPENCODE_SKILLS_DIR/init"
mkdir -p "$OPENCODE_SKILLS_DIR/solve"
mkdir -p "$OPENCODE_SKILLS_DIR/coder"
mkdir -p "$OPENCODE_SKILLS_DIR/math-solver"
mkdir -p "$OPENCODE_SKILLS_DIR/report-writer"
mkdir -p "$OPENCODE_SKILLS_DIR/report-reviewer"
mkdir -p "$OPENCODE_SKILLS_DIR/study-gen"
mkdir -p "$OPENCODE_AGENTS_DIR"

# --- Copy global skill ---
cp "$FORGE_DIR/SKILL.md" "$OPENCODE_SKILLS_DIR/forge/SKILL.md"

# --- Copy skills ---
cp "$FORGE_DIR/skills/init/SKILL.md" "$OPENCODE_SKILLS_DIR/init/SKILL.md"
cp "$FORGE_DIR/skills/solve/SKILL.md" "$OPENCODE_SKILLS_DIR/solve/SKILL.md"
cp "$FORGE_DIR/skills/coder/SKILL.md" "$OPENCODE_SKILLS_DIR/coder/SKILL.md"
cp "$FORGE_DIR/skills/math/SKILL.md" "$OPENCODE_SKILLS_DIR/math-solver/SKILL.md"
cp "$FORGE_DIR/skills/writer/SKILL.md" "$OPENCODE_SKILLS_DIR/report-writer/SKILL.md"
cp "$FORGE_DIR/skills/reviewer/SKILL.md" "$OPENCODE_SKILLS_DIR/report-reviewer/SKILL.md"
cp "$FORGE_DIR/skills/study/SKILL.md" "$OPENCODE_SKILLS_DIR/study-gen/SKILL.md"

# --- Copy agents ---
cp "$FORGE_DIR/agents/planner.md" "$OPENCODE_AGENTS_DIR/planner.md"
cp "$FORGE_DIR/agents/solver.md" "$OPENCODE_AGENTS_DIR/solver.md"
cp "$FORGE_DIR/agents/writer.md" "$OPENCODE_AGENTS_DIR/writer.md"
cp "$FORGE_DIR/agents/reviewer.md" "$OPENCODE_AGENTS_DIR/reviewer.md"

# --- Copy template ---
mkdir -p "$OPENCODE_SKILLS_DIR/forge/templates"
cp "$FORGE_DIR/templates/template.typ" "$OPENCODE_SKILLS_DIR/forge/templates/template.typ"
cp "$FORGE_DIR/templates/titlepage.typ" "$OPENCODE_SKILLS_DIR/forge/templates/titlepage.typ"

# --- Copy AGENTS.md template ---
cp "$FORGE_DIR/AGENTS.md.template" "$OPENCODE_SKILLS_DIR/forge/AGENTS.md.template"

# --- Copy config example ---
cp "$FORGE_DIR/config.example.yaml" "$OPENCODE_SKILLS_DIR/forge/config.example.yaml"

# --- Install Typst if missing ---
if ! command -v typst &> /dev/null; then
  echo "Installing Typst CLI..."

  # Detect OS and architecture
  OS="$(uname -s)"
  ARCH="$(uname -m)"

  # Map architecture names
  case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    *)
      echo "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac

  # Map OS names to Typst release targets
  case "$OS" in
    Linux) OS_NAME="unknown-linux-musl" ;;
    Darwin) OS_NAME="apple-darwin" ;;
    MINGW*|MSYS*|CYGWIN*) OS_NAME="pc-windows-msvc" ;;
    *)
      echo "Unsupported OS: $OS"
      exit 1
      ;;
  esac

  TYPST_URL="https://github.com/typst/typst/releases/latest/download/typst-${ARCH}-${OS_NAME}.tar.xz"
  TEMP_DIR="$(mktemp -d)"
  trap "rm -rf $TEMP_DIR" EXIT

  if command -v curl &> /dev/null; then
    curl -fsSL "$TYPST_URL" -o "$TEMP_DIR/typst.tar.xz"
  else
    wget -qO "$TEMP_DIR/typst.tar.xz" "$TYPST_URL"
  fi

  mkdir -p "$HOME/.local/bin"
  tar xf "$TEMP_DIR/typst.tar.xz" --strip-components=1 -C "$HOME/.local/bin"

  # Add to PATH if not already there
  case "$SHELL" in
    */bash)
      BASHRC="$HOME/.bashrc"
      ;;
    */zsh)
      BASHRC="$HOME/.zshrc"
      ;;
    *)
      BASHRC="$HOME/.profile"
      ;;
  esac

  if [ -n "$BASHRC" ] && [ ! -w "$BASHRC" ]; then
    BASHRC="$HOME/.bashrc"
  fi

  if [ -w "$BASHRC" ] && ! grep -q '.local/bin' "$BASHRC" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
  fi

  export PATH="$HOME/.local/bin:$PATH"
  echo "  Installed Typst $(typst --version)"
else
  echo "  Typst already installed: $(typst --version)"
fi

echo ""
echo "Forge Framework installed successfully!"
echo ""
echo "Available commands:"
echo "  /init   — Initialize a new lab project"
echo "  /solve  — Run full pipeline (guide PDF to report PDF)"
echo "  /study  — Generate study materials"
echo ""
echo "Quick start:"
echo "  mkdir lab1 && cd lab1"
echo "  opencode"
echo "  > /init"
echo "  > /solve guide.pdf"
echo ""
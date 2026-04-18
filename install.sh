#!/usr/bin/env bash
# Forge Framework Installer
# Installs Forge Framework skills, commands, and agents globally for OpenCode.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
#   OR
#   git clone https://github.com/.../forge-framework && cd forge-framework && ./install.sh

set -euo pipefail

FORGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_SKILLS_DIR="${OPENCODE_SKILLS_DIR:-$HOME/.config/opencode/skills}"
OPENCODE_AGENTS_DIR="${OPENCODE_AGENTS_DIR:-$HOME/.config/opencode/agents}"
OPENCODE_COMMANDS_DIR="${OPENCODE_COMMANDS_DIR:-$HOME/.config/opencode/commands}"
FORGE_BIN_DIR="${FORGE_BIN_DIR:-$HOME/.local/bin}"
FORGE_SHARE_DIR="${FORGE_SHARE_DIR:-$HOME/.local/share/forge}"

FORGE_MODEL_ALL="${FORGE_MODEL_ALL:-}"
FORGE_MODEL_PLANNER="${FORGE_MODEL_PLANNER:-}"
FORGE_MODEL_SOLVER="${FORGE_MODEL_SOLVER:-}"
FORGE_MODEL_WRITER="${FORGE_MODEL_WRITER:-}"
FORGE_MODEL_REVIEWER="${FORGE_MODEL_REVIEWER:-}"
AVAILABLE_MODELS=""

prompt_tty() {
  local prompt="$1"
  local reply=""

  if [ -r /dev/tty ]; then
    printf "%s" "$prompt" > /dev/tty
    IFS= read -r reply < /dev/tty || true
  fi

  printf "%s" "$reply"
}

print_tty() {
  if [ -w /dev/tty ]; then
    printf '%s\n' "$1" > /dev/tty
  else
    printf '%s\n' "$1" >&2
  fi
}

load_available_models() {
  if ! command -v opencode > /dev/null 2>&1; then
    return
  fi

  AVAILABLE_MODELS="$(opencode models 2> /dev/null || true)"
}

model_exists() {
  local model="$1"

  if [ -z "$AVAILABLE_MODELS" ] || [ -z "$model" ]; then
    return 1
  fi

  printf '%s\n' "$AVAILABLE_MODELS" | awk -v model="$model" '$0 == model { found = 1 } END { exit(found ? 0 : 1) }'
}

filter_models() {
  local query="$1"
  local query_lower

  if [ -z "$AVAILABLE_MODELS" ]; then
    return
  fi

  if [ -z "$query" ]; then
    printf '%s\n' "$AVAILABLE_MODELS"
    return
  fi

  query_lower="$(printf '%s' "$query" | tr '[:upper:]' '[:lower:]')"
  printf '%s\n' "$AVAILABLE_MODELS" | awk -v query="$query_lower" 'index(tolower($0), query) { print }'
}

show_model_matches() {
  local matches="$1"

  if [ -z "$matches" ]; then
    print_tty "  No matching models found."
    return
  fi

  if [ -w /dev/tty ]; then
    printf '%s\n' "$matches" | awk '
    NR <= 20 { printf "  %2d. %s\n", NR, $0 }
    END {
      if (NR > 20) {
        printf "  ... and %d more\n", NR - 20
      }
    }
    ' > /dev/tty
  else
    printf '%s\n' "$matches" | awk '
    NR <= 20 { printf "  %2d. %s\n", NR, $0 }
    END {
      if (NR > 20) {
        printf "  ... and %d more\n", NR - 20
      }
    }
    ' >&2
  fi
}

pick_model() {
  local role="$1"
  local prompt="$2"
  local choice=""
  local matches=""
  local selected=""

  if [ ! -r /dev/tty ]; then
    printf ""
    return
  fi

  if [ -z "$AVAILABLE_MODELS" ]; then
    printf '%s' "$(prompt_tty "$prompt")"
    return
  fi

  print_tty ""
  print_tty "Select model for $role"
  print_tty "- Press Enter to inherit the current OpenCode model"
  print_tty "- Type a search term to filter models from 'opencode models'"
  print_tty "- Type '?' to list all available models"
  print_tty "- Type a number to pick from the last search results"
  print_tty "- Paste an exact model id to select it immediately"

  while true; do
    choice="$(prompt_tty "$prompt")"

    case "$choice" in
      "")
        printf ""
        return
        ;;
      "?")
        matches="$AVAILABLE_MODELS"
        show_model_matches "$matches"
        ;;
      *)
        if model_exists "$choice"; then
          printf '%s' "$choice"
          return
        fi

        if printf '%s' "$choice" | awk '/^[0-9]+$/ { exit 0 } { exit 1 }'; then
          if [ -z "$matches" ]; then
            print_tty "  No active search results. Search first or type '?'."
            continue
          fi

          selected="$(printf '%s\n' "$matches" | awk -v index="$choice" 'NR == index { print; exit }')"
          if [ -z "$selected" ]; then
            print_tty "  Invalid selection number."
            continue
          fi

          printf '%s' "$selected"
          return
        fi

        matches="$(filter_models "$choice")"
        show_model_matches "$matches"
        ;;
    esac
  done
}

configure_agent_models() {
  local use_single

  if [ -n "$FORGE_MODEL_ALL$FORGE_MODEL_PLANNER$FORGE_MODEL_SOLVER$FORGE_MODEL_WRITER$FORGE_MODEL_REVIEWER" ]; then
    return
  fi

  if [ ! -r /dev/tty ]; then
    return
  fi

  echo ""
  echo "Forge agent model configuration"
  echo "Press Enter to keep model selection empty and inherit the current OpenCode model."

  use_single="$(prompt_tty "Use one model for all Forge agents? [Y/n]: ")"

  case "$use_single" in
    ""|"y"|"Y"|"yes"|"YES")
      FORGE_MODEL_ALL="$(pick_model "all Forge agents" "Model for all Forge agents: ")"
      ;;
    *)
      FORGE_MODEL_PLANNER="$(pick_model "planner" "Planner model: ")"
      FORGE_MODEL_SOLVER="$(pick_model "solver" "Solver model: ")"
      FORGE_MODEL_WRITER="$(pick_model "writer" "Writer model: ")"
      FORGE_MODEL_REVIEWER="$(pick_model "reviewer" "Reviewer model: ")"
      ;;
  esac
}

set_agent_model() {
  local file="$1"
  local model="$2"
  local tmp

  if [ -z "$model" ]; then
    return
  fi

  tmp="$(mktemp)"
  awk -v model="$model" '
    NR == 1 { print; next }
    !inserted && $0 == "---" {
      print "model: " model
      inserted = 1
    }
    { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

install_forge_cli() {
  local tmp_cli

  mkdir -p "$FORGE_BIN_DIR" "$FORGE_SHARE_DIR"
  mkdir -p "$FORGE_SHARE_DIR/commands" "$FORGE_SHARE_DIR/skills" "$FORGE_SHARE_DIR/agents" "$FORGE_SHARE_DIR/templates" "$FORGE_SHARE_DIR/styles"

  copy_file "$FORGE_DIR/commands/init.md" "$FORGE_SHARE_DIR/commands/init.md"
  copy_file "$FORGE_DIR/commands/solve.md" "$FORGE_SHARE_DIR/commands/solve.md"
  copy_file "$FORGE_DIR/commands/study.md" "$FORGE_SHARE_DIR/commands/study.md"

  copy_file "$FORGE_DIR/skills/init/SKILL.md" "$FORGE_SHARE_DIR/skills/init/SKILL.md"
  copy_file "$FORGE_DIR/skills/solve/SKILL.md" "$FORGE_SHARE_DIR/skills/solve/SKILL.md"
  copy_file "$FORGE_DIR/skills/coder/SKILL.md" "$FORGE_SHARE_DIR/skills/coder/SKILL.md"
  copy_file "$FORGE_DIR/skills/math/SKILL.md" "$FORGE_SHARE_DIR/skills/math/SKILL.md"
  copy_file "$FORGE_DIR/skills/writer/SKILL.md" "$FORGE_SHARE_DIR/skills/writer/SKILL.md"
  copy_file "$FORGE_DIR/skills/reviewer/SKILL.md" "$FORGE_SHARE_DIR/skills/reviewer/SKILL.md"
  copy_file "$FORGE_DIR/skills/study/SKILL.md" "$FORGE_SHARE_DIR/skills/study/SKILL.md"

  copy_file "$FORGE_DIR/agents/planner.md" "$FORGE_SHARE_DIR/agents/planner.md"
  copy_file "$FORGE_DIR/agents/solver.md" "$FORGE_SHARE_DIR/agents/solver.md"
  copy_file "$FORGE_DIR/agents/writer.md" "$FORGE_SHARE_DIR/agents/writer.md"
  copy_file "$FORGE_DIR/agents/reviewer.md" "$FORGE_SHARE_DIR/agents/reviewer.md"

  copy_file "$FORGE_DIR/templates/template.typ" "$FORGE_SHARE_DIR/templates/template.typ"
  copy_file "$FORGE_DIR/templates/titlepage.typ" "$FORGE_SHARE_DIR/templates/titlepage.typ"
  copy_file "$FORGE_DIR/templates/gost.typ.ru" "$FORGE_SHARE_DIR/templates/gost.typ.ru"
  copy_file "$FORGE_DIR/templates/titlepage.typ.ru" "$FORGE_SHARE_DIR/templates/titlepage.typ.ru"
  copy_file "$FORGE_DIR/styles/formal.md" "$FORGE_SHARE_DIR/styles/formal.md"
  copy_file "$FORGE_DIR/styles/simple.md" "$FORGE_SHARE_DIR/styles/simple.md"
  copy_file "$FORGE_DIR/styles/concise.md" "$FORGE_SHARE_DIR/styles/concise.md"
  copy_file "$FORGE_DIR/AGENTS.md.template" "$FORGE_SHARE_DIR/AGENTS.md.template"
  copy_file "$FORGE_DIR/config.example.yaml" "$FORGE_SHARE_DIR/config.example.yaml"

  tmp_cli="$(mktemp)"
  awk -v share_dir="$FORGE_SHARE_DIR" '{
    gsub("__FORGE_SHARE_DIR__", share_dir)
    print
  }' "$FORGE_DIR/bin/forge" > "$tmp_cli"
  mv "$tmp_cli" "$FORGE_BIN_DIR/forge"
  chmod +x "$FORGE_BIN_DIR/forge"
}

copy_file() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
}

echo "Installing Forge Framework..."

load_available_models
configure_agent_models
install_forge_cli

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
mkdir -p "$OPENCODE_COMMANDS_DIR"

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

set_agent_model "$OPENCODE_AGENTS_DIR/planner.md" "${FORGE_MODEL_PLANNER:-$FORGE_MODEL_ALL}"
set_agent_model "$OPENCODE_AGENTS_DIR/solver.md" "${FORGE_MODEL_SOLVER:-$FORGE_MODEL_ALL}"
set_agent_model "$OPENCODE_AGENTS_DIR/writer.md" "${FORGE_MODEL_WRITER:-$FORGE_MODEL_ALL}"
set_agent_model "$OPENCODE_AGENTS_DIR/reviewer.md" "${FORGE_MODEL_REVIEWER:-$FORGE_MODEL_ALL}"

# --- Copy commands ---
cp "$FORGE_DIR/commands/init.md" "$OPENCODE_COMMANDS_DIR/init.md"
cp "$FORGE_DIR/commands/solve.md" "$OPENCODE_COMMANDS_DIR/solve.md"
cp "$FORGE_DIR/commands/study.md" "$OPENCODE_COMMANDS_DIR/study.md"

# --- Copy templates ---
mkdir -p "$OPENCODE_SKILLS_DIR/forge/templates"
cp "$FORGE_DIR/templates/template.typ" "$OPENCODE_SKILLS_DIR/forge/templates/template.typ"
cp "$FORGE_DIR/templates/titlepage.typ" "$OPENCODE_SKILLS_DIR/forge/templates/titlepage.typ"
cp "$FORGE_DIR/templates/gost.typ.ru" "$OPENCODE_SKILLS_DIR/forge/templates/gost.typ.ru"
cp "$FORGE_DIR/templates/titlepage.typ.ru" "$OPENCODE_SKILLS_DIR/forge/templates/titlepage.typ.ru"

# --- Copy AGENTS.md template ---
cp "$FORGE_DIR/AGENTS.md.template" "$OPENCODE_SKILLS_DIR/forge/AGENTS.md.template"

# --- Copy styles ---
mkdir -p "$OPENCODE_SKILLS_DIR/forge/styles"
cp "$FORGE_DIR/styles/formal.md" "$OPENCODE_SKILLS_DIR/forge/styles/formal.md"
cp "$FORGE_DIR/styles/simple.md" "$OPENCODE_SKILLS_DIR/forge/styles/simple.md"
cp "$FORGE_DIR/styles/concise.md" "$OPENCODE_SKILLS_DIR/forge/styles/concise.md"

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
echo "Agent models:"
echo "  planner  — ${FORGE_MODEL_PLANNER:-${FORGE_MODEL_ALL:-inherit current OpenCode model}}"
echo "  solver   — ${FORGE_MODEL_SOLVER:-${FORGE_MODEL_ALL:-inherit current OpenCode model}}"
echo "  writer   — ${FORGE_MODEL_WRITER:-${FORGE_MODEL_ALL:-inherit current OpenCode model}}"
echo "  reviewer — ${FORGE_MODEL_REVIEWER:-${FORGE_MODEL_ALL:-inherit current OpenCode model}}"
echo ""
echo "Available commands:"
echo "  /init   — Initialize a new lab project"
echo "  /solve  — Run full pipeline (guide PDF to report PDF)"
echo "  /study  — Generate study materials"
echo "  Note: Forge overrides OpenCode's built-in /init command"
echo ""
echo "Forge CLI:"
echo "  forge init [path] — open OpenCode with Forge /init in any folder"
echo "  forge sync [path] — refresh Forge-managed files in a project"
echo ""
echo "Quick start:"
echo "  forge init lab1"
echo "  # complete Forge /init in OpenCode"
echo "  cd lab1"
echo "  > /solve guide.pdf"
echo ""

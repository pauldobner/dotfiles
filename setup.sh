#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"

SKIP_PACKAGES=false
SKIP_PLUGINS=false
SKIP_SHELL_CHANGE=false

info() { printf '[INFO] %s\n' "$*"; }
success() { printf '[ OK ] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die() { printf '[FAIL] %s\n' "$*" >&2; exit 1; }

on_error() {
  local exit_code=$?
  printf '[FAIL] Setup stopped at line %s while running: %s\n' "$1" "$2" >&2
  printf '       Fix the reported error, then run setup.sh again. Completed steps are safe to repeat.\n' >&2
  exit "$exit_code"
}
trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

usage() {
  cat <<'EOF'
Usage: ./setup.sh [options]

Install and link the Zsh and tmux configuration in this repository.

Options:
  --skip-packages       Do not install operating-system packages
  --skip-plugins        Do not install or update Oh My Zsh/tmux plugins
  --skip-shell-change   Do not change the default login shell to Zsh
  -h, --help            Show this help
EOF
}

while (($#)); do
  case "$1" in
    --skip-packages) SKIP_PACKAGES=true ;;
    --skip-plugins) SKIP_PLUGINS=true ;;
    --skip-shell-change) SKIP_SHELL_CHANGE=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "Unknown option: $1" ;;
  esac
  shift
done

[[ -f "$SCRIPT_DIR/.zshrc" && -f "$SCRIPT_DIR/.tmux.conf" ]] ||
  die "Run this script from a complete clone of the dotfiles repository."

sudo_command=()

prepare_sudo() {
  if ((EUID != 0)); then
    command -v sudo >/dev/null 2>&1 ||
      die "Package installation needs sudo. Install sudo or run with --skip-packages after installing dependencies manually."
    sudo_command=(sudo)
  fi
}

install_packages() {
  local missing=false command_name
  for command_name in zsh tmux git curl cc; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      missing=true
      break
    fi
  done
  if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
    missing=true
  fi

  if [[ "$missing" == false ]]; then
    success "Required system packages are already installed"
    return
  fi

  if command -v apt-get >/dev/null 2>&1; then
    prepare_sudo
    info "Installing packages with apt"
    "${sudo_command[@]}" apt-get update
    "${sudo_command[@]}" apt-get install -y zsh tmux git curl bat build-essential
  elif command -v dnf >/dev/null 2>&1; then
    prepare_sudo
    info "Installing packages with dnf"
    "${sudo_command[@]}" dnf install -y zsh tmux git curl bat gcc make
  elif command -v pacman >/dev/null 2>&1; then
    prepare_sudo
    info "Installing packages with pacman"
    "${sudo_command[@]}" pacman -S --needed --noconfirm zsh tmux git curl bat base-devel
  elif command -v apk >/dev/null 2>&1; then
    prepare_sudo
    info "Installing packages with apk"
    "${sudo_command[@]}" apk add zsh tmux git curl bat build-base
  elif command -v brew >/dev/null 2>&1; then
    info "Installing packages with Homebrew"
    brew install zsh tmux git curl bat gcc
  else
    die "No supported package manager found. Install zsh, tmux, git, curl, bat, make, and a C compiler, then use --skip-packages."
  fi
  success "System packages installed"
}

ensure_bat_command() {
  local bat_link="$HOME/.local/bin/bat" batcat_path

  command -v bat >/dev/null 2>&1 && return
  batcat_path="$(command -v batcat 2>/dev/null || true)"
  [[ -n "$batcat_path" ]] || return

  mkdir -p "$HOME/.local/bin"
  if [[ -x "$bat_link" ]]; then
    success "$bat_link already provides the bat command"
    return
  fi
  if [[ -e "$bat_link" || -L "$bat_link" ]]; then
    warn "$bat_link already exists, but 'bat' is not on the current PATH"
    warn "Make sure $HOME/.local/bin is included in PATH"
    return
  fi

  ln -s "$batcat_path" "$bat_link"
  success "Linked $bat_link -> $batcat_path for Debian/Ubuntu compatibility"
}

clone_or_update() {
  local repository=$1 destination=$2 label=$3

  if [[ -d "$destination/.git" ]]; then
    if ! git -C "$destination" diff --quiet || ! git -C "$destination" diff --cached --quiet; then
      warn "$label has local changes; leaving it unchanged"
      return
    fi
    info "Updating $label"
    git -C "$destination" pull --ff-only
  elif [[ -e "$destination" ]]; then
    die "$destination exists but is not a Git checkout. Move it aside and run setup.sh again."
  else
    info "Installing $label"
    mkdir -p "$(dirname -- "$destination")"
    git clone --depth=1 "$repository" "$destination"
  fi
}

next_backup_path() {
  local target=$1 candidate="${target}.backup-${BACKUP_SUFFIX}" counter=1
  while [[ -e "$candidate" || -L "$candidate" ]]; do
    candidate="${target}.backup-${BACKUP_SUFFIX}-${counter}"
    ((counter += 1))
  done
  printf '%s\n' "$candidate"
}

link_dotfile() {
  local source=$1 target=$2 current backup

  if [[ -L "$target" ]]; then
    current="$(readlink "$target")"
    if [[ "$current" == "$source" ]]; then
      success "$target is already linked correctly"
      return
    fi
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup="$(next_backup_path "$target")"
    mv -- "$target" "$backup"
    warn "Moved existing $target to $backup"
  fi

  ln -s "$source" "$target"
  success "Linked $target -> $source"
}

install_plugins() {
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" "Oh My Zsh"
  clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git "$zsh_custom/plugins/zsh-autosuggestions" "zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
  clone_or_update https://github.com/MichaelAquilina/zsh-you-should-use.git "$zsh_custom/plugins/you-should-use" "you-should-use"
  clone_or_update https://github.com/fdellwing/zsh-bat.git "$zsh_custom/plugins/zsh-bat" "zsh-bat"
  clone_or_update https://github.com/tmux-plugins/tpm.git "$HOME/.tmux/plugins/tpm" "TPM"

  info "Installing any missing tmux plugins"
  "$HOME/.tmux/plugins/tpm/bin/install_plugins"
  success "Shell and tmux plugins are installed"
}

change_default_shell() {
  local zsh_path current_shell
  zsh_path="$(command -v zsh)" || die "Zsh is not installed. Install it or rerun without --skip-packages."
  current_shell="$(getent passwd "${USER:-$(id -un)}" 2>/dev/null | cut -d: -f7 || true)"
  [[ -n "$current_shell" ]] || current_shell="${SHELL:-}"

  if [[ "$current_shell" == "$zsh_path" ]]; then
    success "Zsh is already the default shell"
  elif ! grep -Fxq "$zsh_path" /etc/shells 2>/dev/null; then
    warn "$zsh_path is not listed in /etc/shells; cannot change the login shell automatically"
    warn "Add it to /etc/shells, then run: chsh -s '$zsh_path'"
  elif chsh -s "$zsh_path"; then
    success "Default shell changed to Zsh (log out and back in to apply it)"
  else
    warn "Could not change the default shell. Try manually: chsh -s '$zsh_path'"
  fi
}

validate_configuration() {
  if command -v zsh >/dev/null 2>&1; then
    zsh -n "$SCRIPT_DIR/.zshrc"
    success "Zsh configuration syntax is valid"
  else
    warn "Skipping Zsh syntax check because zsh is unavailable"
  fi

  if command -v tmux >/dev/null 2>&1; then
    local socket="dotfiles-setup-$$"
    tmux -L "$socket" -f "$SCRIPT_DIR/.tmux.conf" new-session -d "sleep 5"
    tmux -L "$socket" kill-server
    success "tmux configuration loaded successfully"
  else
    warn "Skipping tmux configuration check because tmux is unavailable"
  fi
}

info "Setting up dotfiles from $SCRIPT_DIR"
[[ "$SKIP_PACKAGES" == true ]] || install_packages
ensure_bat_command
link_dotfile "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
link_dotfile "$SCRIPT_DIR/.tmux.conf" "$HOME/.tmux.conf"
[[ "$SKIP_PLUGINS" == true ]] || install_plugins
[[ "$SKIP_SHELL_CHANGE" == true ]] || change_default_shell
validate_configuration

printf '\n'
success "Setup complete"
info "Open a new terminal (or run 'exec zsh') to start using Zsh."
info "Existing tmux sessions can reload the config with: tmux source-file ~/.tmux.conf"

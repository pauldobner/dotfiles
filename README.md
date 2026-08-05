# dotfiles

<details>

<summary>ZSH setup</summary>

## Zsh setup

### 1. Install Zsh and dependencies

Ubuntu/Debian:

```sh
sudo apt update
sudo apt install zsh git curl bat
```

Set Zsh as the default shell:

```sh
chsh -s "$(command -v zsh)"
```

Log out and back in for the shell change to take effect.

### 2. Install Oh My Zsh

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

The installer may replace an existing `~/.zshrc`, so install Oh My Zsh before linking the `.zshrc` from this repository.

### 3. Install external plugins

```sh
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

git clone https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

git clone https://github.com/MichaelAquilina/zsh-you-should-use \
  "$ZSH_CUSTOM/plugins/you-should-use"

git clone https://github.com/fdellwing/zsh-bat \
  "$ZSH_CUSTOM/plugins/zsh-bat"
```

The following plugins are already included with Oh My Zsh and do not need to be cloned:

```text
git
conda
uv
```

The corresponding programs, such as `conda`, `uv`, and `bat`, must still be installed separately.

### 4. Enable the plugins

Add the following to `.zshrc` before sourcing Oh My Zsh or use the `.zshrc` file from the repo:

```sh
plugins=(
  git
  zsh-autosuggestions
  you-should-use
  zsh-bat
  conda
  uv
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"
```

Keep `zsh-syntax-highlighting` as the final plugin.

### 5. Install the dotfiles

From the dotfiles repository, link the Zsh configuration:

```sh
ln -sf "$PWD/.zshrc" "$HOME/.zshrc"
```

Reload the configuration:

```sh
exec zsh
```

</details>


<details>
  
<summary>Tmux setup</summary>

## tmux setup

### 1. Install tmux and dependencies

Ubuntu/Debian:

```sh
sudo apt update
sudo apt install tmux git bash build-essential
```

`build-essential` provides the C compiler used by `tmux-mighty-scroll` for better performance on Linux.

Check the installed tmux version:

```sh
tmux -V
```

A recent tmux 3.x version is recommended.

### 2. Install TPM

TPM is the Tmux Plugin Manager. Clone it into the location expected by `.tmux.conf`:

```sh
git clone https://github.com/tmux-plugins/tpm \
  "$HOME/.tmux/plugins/tpm"
```

TPM manages the following plugins configured in this repository:

```text
tmux-plugins/tmux-sensible
noscript/tmux-mighty-scroll
alexwforsythe/tmux-which-key
jaclu/tmux-menus
```

### 3. Install the tmux configuration

From the dotfiles repository, link the configuration:

```sh
ln -sf "$PWD/.tmux.conf" "$HOME/.tmux.conf"
```

Check the configuration for syntax errors:

```sh
tmux -f "$HOME/.tmux.conf" new-session -d -s tmux-config-test
tmux kill-session -t tmux-config-test
```

### 4. Start tmux and install plugins

Start tmux:

```sh
tmux
```

Inside tmux, press:

```text
Ctrl+B, then Shift+I
```

This installs all plugins declared in `.tmux.conf`.

The commands are sequential:

1. Hold `Ctrl` and press `B`.
2. Release both keys.
3. Press uppercase `I`.

After installation, TPM displays the status of each plugin.

### 5. Reload the configuration

After changing `.tmux.conf`, reload it from inside tmux with:

```text
Ctrl+B, then r
```

Alternatively:

```sh
tmux source-file "$HOME/.tmux.conf"
```

### 6. Useful key bindings

The default tmux prefix is `Ctrl+B`.

```text
Ctrl+B, r             Reload the configuration
Ctrl+B, C             Create a new window
Ctrl+B, |             Split pane horizontally
Ctrl+B, -             Split pane vertically
Ctrl+B, H/J/K/L       Resize the current pane
Ctrl+B, Space         Open tmux-which-key
Ctrl+Space            Open tmux-menus
```

For commands that use the prefix, press `Ctrl+B`, release it, and then press the second key.

### Updating plugins

Inside tmux:

```text
Ctrl+B, then U
```

### Removing plugins

Remove the corresponding `@plugin` line from `.tmux.conf`, then press:

```text
Ctrl+B, then Alt+U
```

### Troubleshooting

Verify that TPM exists:

```sh
test -x "$HOME/.tmux/plugins/tpm/tpm" && echo "TPM installed"
```

Reload the configuration:

```sh
tmux source-file "$HOME/.tmux.conf"
```

Install plugins without using the keyboard shortcut:

```sh
"$HOME/.tmux/plugins/tpm/bin/install_plugins"
```

Check whether the C compiler required by `tmux-mighty-scroll` is available:

```sh
cc --version
```

To restart tmux completely after configuration changes:

```sh
tmux kill-server
tmux
```

This closes all currently running tmux sessions.


</details>




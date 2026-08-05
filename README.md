# dotfiles

My Zsh and tmux config. I use `setup.sh` to get a new machine into the same state without working through the setup by hand each time.

## Setup

Clone the repo and run the script:

```sh
git clone https://github.com/pauldobner/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The script supports Debian/Ubuntu, Fedora, Arch Linux, Alpine Linux, and macOS with Homebrew. It may ask for a `sudo` password while installing packages. If it changes your login shell, log out and back in once setup has finished.

Run `./setup.sh` again whenever you want to check the setup or apply changes. The config files in your home directory are symlinks, so edits in this repo are already picked up by new Zsh and tmux sessions. Rerunning the script also repairs missing links, installs missing plugins, and runs the config checks again.

To pull changes first:

```sh
cd ~/dotfiles
git pull
./setup.sh
```

Existing config files are not thrown away. Before creating a link, the script moves an existing file to a timestamped backup such as `~/.zshrc.backup-20260805-120000`.

### What the script does

In order, [`setup.sh`](./setup.sh) does the following:

1. Checks for Zsh, tmux, Git, curl, bat, and a C compiler. If something is missing, it installs the package set for the detected package manager.
2. Links this repo's `.zshrc` and `.tmux.conf` into your home directory. Existing files and incorrect links are backed up first.
3. Installs Oh My Zsh, the external Zsh plugins, and TPM. Existing Git checkouts are updated with a fast-forward pull as long as they have no local changes.
4. Asks TPM to install any tmux plugins that are still missing.
5. Changes the login shell to Zsh when possible.
6. Checks the Zsh syntax and starts a temporary tmux server to make sure `.tmux.conf` loads.

If a command fails, setup stops and prints the command and line number. Fix the problem and run it again; completed steps are safe to repeat.

### Options

```text
--skip-packages       Skip operating system package installation
--skip-plugins        Skip Oh My Zsh and tmux plugin installation or updates
--skip-shell-change   Leave the default login shell unchanged
-h, --help            Show help
```

For example, this only refreshes the links and checks both config files:

```sh
./setup.sh --skip-packages --skip-plugins --skip-shell-change
```

## Manual setup

The script is the normal install path. The sections below show the same setup by hand, which is useful when something fails or when you want to see where a particular piece comes from. Package commands use Debian/Ubuntu names; use the equivalent packages from your distribution when needed.

<details>

<summary>Manual Zsh setup</summary>

### 1. Install Zsh and its dependencies

```sh
sudo apt update
sudo apt install zsh git bat
```

Some older Ubuntu and Debian releases install the executable as `batcat`. The setup script creates a `~/.local/bin/bat` link for those systems because the Zsh plugin looks for `bat`. For a manual install, create the same link if `bat --version` fails but `batcat --version` works:

```sh
mkdir -p "$HOME/.local/bin"
ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
```

Set Zsh as the login shell:

```sh
chsh -s "$(command -v zsh)"
```

The shell change takes effect after you log out and back in.

### 2. Install Oh My Zsh

The setup script uses a Git clone instead of the interactive Oh My Zsh installer. This keeps the installer from replacing `.zshrc` while the dotfile link is being set up.

```sh
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git \
  "$HOME/.oh-my-zsh"
```

If `~/.oh-my-zsh` already exists, update it instead:

```sh
git -C "$HOME/.oh-my-zsh" pull --ff-only
```

### 3. Install the external plugins

```sh
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

git clone --depth=1 https://github.com/MichaelAquilina/zsh-you-should-use.git \
  "$ZSH_CUSTOM/plugins/you-should-use"

git clone --depth=1 https://github.com/fdellwing/zsh-bat.git \
  "$ZSH_CUSTOM/plugins/zsh-bat"
```

The `git`, `conda`, and `uv` plugins come with Oh My Zsh, so they do not need separate clones. The `conda` and `uv` programs themselves are optional and are not installed by this repo.

The plugin order is defined in `.zshrc`:

```sh
plugins=(git zsh-autosuggestions you-should-use zsh-bat conda uv zsh-syntax-highlighting)
```

Keep `zsh-syntax-highlighting` last. It needs to see widgets added by the other plugins before it loads.

### 4. Link `.zshrc`

Run this from the root of the cloned repo:

```sh
if [ -e "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.backup-$(date +%Y%m%d-%H%M%S)"
fi

ln -s "$PWD/.zshrc" "$HOME/.zshrc"
```

Check the syntax and start a fresh Zsh process:

```sh
zsh -n "$HOME/.zshrc"
exec zsh
```

</details>

<details>

<summary>Manual tmux setup</summary>

### 1. Install tmux and build tools

```sh
sudo apt update
sudo apt install tmux git build-essential
```

`build-essential` supplies the compiler used by `tmux-mighty-scroll` on Linux. A recent tmux 3.x release is recommended. Check yours with:

```sh
tmux -V
cc --version
```

### 2. Install TPM

[TPM](https://github.com/tmux-plugins/tpm) is the plugin manager used by `.tmux.conf`.

```sh
git clone --depth=1 https://github.com/tmux-plugins/tpm.git \
  "$HOME/.tmux/plugins/tpm"
```

If TPM is already installed, update it with:

```sh
git -C "$HOME/.tmux/plugins/tpm" pull --ff-only
```

TPM reads these plugin entries from `.tmux.conf`:

```text
tmux-plugins/tmux-sensible
noscript/tmux-mighty-scroll
alexwforsythe/tmux-which-key
jaclu/tmux-menus
```

### 3. Link `.tmux.conf`

Run this from the root of the cloned repo:

```sh
if [ -e "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
  mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup-$(date +%Y%m%d-%H%M%S)"
fi

ln -s "$PWD/.tmux.conf" "$HOME/.tmux.conf"
```

### 4. Install the tmux plugins

The setup script runs TPM's installer directly, so you do not need to start tmux first:

```sh
"$HOME/.tmux/plugins/tpm/bin/install_plugins"
```

You can do the same from inside tmux with `Ctrl+B`, followed by uppercase `I`.

### 5. Check the config

Load the config in a separate tmux server so the check does not touch any sessions that are already running:

```sh
tmux -L dotfiles-check -f "$HOME/.tmux.conf" new-session -d "sleep 5"
tmux -L dotfiles-check kill-server
```

Start tmux normally after the check:

```sh
tmux
```

</details>

## tmux keys

The default prefix is `Ctrl+B`.

```text
Ctrl+B, r             Reload the config
Ctrl+B, c             Create a new window
Ctrl+B, |             Split the pane horizontally
Ctrl+B, -             Split the pane vertically
Ctrl+B, H/J/K/L       Resize the current pane
Ctrl+B, Space         Open tmux-which-key
Ctrl+Space            Open tmux-menus
Ctrl+B, I             Install missing plugins
Ctrl+B, U             Update plugins
Ctrl+B, Alt+U         Remove plugins that are no longer configured
```

For commands that use the prefix, press `Ctrl+B`, release it, then press the second key.

## Troubleshooting

Check where the dotfiles point:

```sh
readlink ~/.zshrc
readlink ~/.tmux.conf
```

If a plugin checkout contains changes, `setup.sh` leaves it alone instead of overwriting your work. Either commit or remove those changes before running the script again:

```sh
git -C ~/.oh-my-zsh status
git -C ~/.tmux/plugins/tpm status
```

Reload the current tmux server after editing `.tmux.conf`:

```sh
tmux source-file ~/.tmux.conf
```

If the login shell could not be changed, make sure the Zsh path appears in `/etc/shells`, then run:

```sh
chsh -s "$(command -v zsh)"
```

To restart tmux completely, run `tmux kill-server` and then `tmux`. This closes every tmux session, so save your work first.

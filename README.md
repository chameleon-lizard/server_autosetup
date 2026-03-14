# Server autosetup

Every self-respecting IT guy has a fleet of servers, which are accessed via SSH. Most of people in this group use VSCode and don't care about anything else, but for us, terminal dwellers, having a consistent, repeatable and easily distributed setup is paramount.

When I did not have this script, I used slightly modified [NVChad config from DreamsOfCode](https://github.com/dreamsofcode-io/neovim-python), [his tmux config, again, with my modifications](https://github.com/dreamsofcode-io/tmux) and oh-my-zsh with a custom theme. However, not all of my servers have nvim (and sudo rights to install them!) and I'm too lazy to install plugin managers, oh-my-zsh, manually modifying these configs, manually fixing incompatibilities with updated NVChad/tmux/oh-my-zsh/plugins/plugin managers/AAAAGH I CANNOT TAKE IT ANYMORE!!!

I've had enough. It was a high time for a change anyway. Thus, with generous help from my good friend C. Opus, I've made a portable and highly compatible bash, tmux and vim configs, providing comfy environment for me to work with. They are not minimal by any means (my `.vimrc` is 600+ lines long!) but it is compatible with all of my machines and is easy to distribute. You win some, you lose some.

It's not perfect, it has some weird quirks (for instance, you have to develop your config on a non-local machine, since I have a mac and mac does not use bash by default), but it's hackable -- especially via our dear mutual friend.

## Features

- Sensible defaults for tmux, beautiful theme without any plugins 
- Vim config with autocompletion, nvchad-like tabs, netrw, fuzzy file search and, again, sensible defaults
- Bashrc with nice autocompletion, beautiful prompt string and nicer Ctrl+W behaviour
- Orchestration script, which gets the configs from the SSH server and distributes it to all other servers in the fleet 

More information and a changelog is available in the [Terminal tools readme](https://github.com/chameleon-lizard/server_autosetup/blob/main/configs/terminal_tools_changelog.md).

## Setup

- Change your source and target servers in `server-list.env`
- Copy `.tmux.conf`, `.vimrc` and `.bashrc` to a separate machine 
- (Optional) Add current directory to PATH
- Run `distrubute_configs.sh`


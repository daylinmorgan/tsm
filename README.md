# Tmux session manager (tsm)

## Install

There are pre-built binaries available in [Releases](https://github.com/daylinmorgan/tsm/releases/) including a [nightly](https://github.com/daylinmorgan/tsm/releases/tag/nightly) release.

w/`eget`:
```sh
eget daylinmorgan/tsm
eget daylinmorgan/tsm --pre-release # for nightly build
```

w/`nimble`:
```sh
nimble install https://github.com/daylinmorgan/tsm
```

## Usage

To configure `tsm` export the environment variable `TSM_DIRS`, with a colon-delimited set of parent directories to find projects.

For example in your rc file:

```sh
export TSM_DIRS="$HOME/projects/personal:$HOME/projects/work"
```

To make full use of `tsm` you should also add a new key binding to your `tmux.conf`.
For example you can bind the s key to show a popup with `tsm`:

```sh
bind s display-popup \
  -h 60% -w 60% \
  -B -e FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --height=100%" \
  -E "tsm"
```

## Prior Art

- [ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer)

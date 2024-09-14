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

To configure `tsm` export the below environment variables:
> `TSM_PATHS`: a colon-delimited set of parent directories to find projects. \
> `TSM_HEIGHT`: integer specifying number of rows in terminal (default: 15)

For example in your rc file:

```sh
export TSM_PATHS="$HOME/projects/personal:$HOME/projects/work"
```

To make full use of `tsm` you should also add a new key binding to your `tmux.conf`.
For example, you can bind the f key to show a popup with `tsm`:

```sh
bind f display-popup \
  -h 60% -w 60% \
  -E "tsm"
```

## Prior Art

- [ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer)

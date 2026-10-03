# Vim Tutor

A clean tutorial in your terminal. Twenty-four small lessons, an editable practice
buffer, optional hints, and a place to try things freely. Every exercise runs in
**real Vim**, so the commands and muscle memory carry over to your own files.

## Start

Requires **Vim 8.2+** with JSON support and **Python 3.10+**. No Python dependencies,
Vim plugins, or installation required.

```sh
./vimlab
```

Or run `python3 -m vim_lab` from this folder. For a command available anywhere,
you can optionally install it with `pip install .` and then run `vimlab`.

## Find your way

| Key | Action |
| --- | --- |
| `j` / `k` or arrows | Select a lesson in the course |
| `Enter` | Open the selected lesson |
| `r` | Open the first unfinished lesson from the course |
| `s` | Open free practice from the course |
| `q` | Quit from the course or guide panel |
| `Esc` | Return to Normal mode while practicing |
| `F1` | Show or hide the current hint |
| `F2` | Return to the course |
| `F5` | Reset the current practice buffer |
| `F8` | Continue after completing a lesson |
| `Ctrl-w`, then `h/j/k/l` | Move between the guide and practice panes |

If your terminal intercepts function keys, use `:Hint`, `:Lessons`, `:Reset`,
`:Continue`, or `:Sandbox`, then press Enter. You can quit the entire app at any time
with `:qa!`. Native Vim commands remain available in the practice buffer.

Goals advance when you reach the right cursor position or produce the requested
text and return to Normal mode. The active destination is highlighted in movement
lessons. Editing goals compare the whole buffer, including spaces and punctuation.
You can finish with any valid Vim commands. Completed lessons stay open so you can
experiment; `F8` moves on when you're ready.

## The course

1. **Get moving** — home row, words, line edges, file jumps, character finds, search.
2. **Add & edit** — insert, append, line openings, character repairs, line deletion.
3. **Undo & reuse** — delete with motions, undo and redo, copy and paste.
4. **Select & change** — character and line selections, words, quoted text.
5. **Work smarter** — counts, repeat an edit, substitution.
6. **Bring it together** — save a file, then edit a small note.

The full course is about 47 minutes. There is no timer, score, or penalty for
trying again. Free practice includes a command reference in the guide panel.

```sh
./vimlab --resume               # Open your last unfinished lesson
./vimlab --lesson 7             # Jump to a lesson by number
./vimlab --lesson inside-quotes # Or use its ID
./vimlab --sandbox              # Start with a sample note for free practice
./vimlab --list                 # Print the course
```

## Files and progress

Vim Lab starts Vim with its own minimal configuration and theme. Your usual Vim
configuration is not loaded or changed. Each practice buffer is a real file in a
temporary folder, so `:w` works. Practice files are removed when you exit;
completion progress is saved after each finished lesson.

Progress lives in `$XDG_STATE_HOME/vim-lab/progress.json`, or
`~/.local/state/vim-lab/progress.json` when that variable isn't set. Use a different
folder if you prefer:

```sh
./vimlab --state-dir ./.vim-lab
```

The menu remembers completed lessons and the last lesson you opened. If a progress
file is unreadable, a dated backup is kept beside it before starting fresh. To
start a separate course, choose a new state folder.

The layout uses side-by-side panes in wide terminals and a compact guide above the
buffer in narrower terminals. A terminal of at least **70 columns × 22 rows** is
recommended; the course list scrolls with your selection. Standard 256-color
terminals are supported, with true color when your terminal advertises it.

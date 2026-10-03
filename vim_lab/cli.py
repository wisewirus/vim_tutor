"""Lightweight launcher. Vim itself provides the terminal UI and editing engine."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone

from . import __version__
from .curriculum import CHAPTERS, LESSONS, SANDBOX


def state_directory():
    base = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state")
    return base / "vim-lab"


def read_progress(path):
    if not path.exists():
        return {"version": 1, "completed": [], "last_lesson": ""}, ""
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if (
            not isinstance(data, dict)
            or data.get("version") != 1
            or not isinstance(data.get("completed"), list)
            or not all(isinstance(item, str) for item in data["completed"])
            or not isinstance(data.get("last_lesson", ""), str)
        ):
            raise ValueError("unrecognized progress format")
        known = {item["id"] for item in LESSONS}
        data["completed"] = list(dict.fromkeys(item for item in data["completed"] if item in known))
        return data, ""
    except (ValueError, UnicodeError):
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%f")
        backup = path.with_name(f"progress.invalid-{stamp}.json")
        path.rename(backup)
        return {"version": 1, "completed": [], "last_lesson": ""}, "Unreadable progress was backed up; starting fresh."


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="vimlab", description="Small guided exercises in real Vim. No plugins or Python packages required.",
        epilog="Inside the app: F1 hint · F2 course · F5 reset · F8 next. Esc returns to Normal mode.",
    )
    start = parser.add_mutually_exclusive_group()
    start.add_argument("--lesson", metavar="NUMBER_OR_ID", help="open a specific lesson (1–24 or its ID)")
    start.add_argument("--resume", action="store_true", help="open your last unfinished lesson")
    start.add_argument("--sandbox", action="store_true", help="open free practice")
    parser.add_argument("--list", action="store_true", help="list the course without opening Vim")
    parser.add_argument("--state-dir", type=Path, default=state_directory(), metavar="PATH", help="folder for saved progress")
    parser.add_argument("--version", action="version", version=f"Vim Lab {__version__}")
    args = parser.parse_args(argv)

    if args.list:
        chapter = None
        for index, item in enumerate(LESSONS, 1):
            if item["chapter"] != chapter:
                chapter = item["chapter"]
                print(f"\n  {CHAPTERS[chapter].upper()}")
            print(f"  {index:02}  {item['title']:<24} {item['id']}")
        print(f"\n  {len(LESSONS)} lessons · about {sum(item['minutes'] for item in LESSONS)} minutes · go at your pace\n")
        return 0

    index = None
    if args.lesson:
        if args.lesson.isdecimal() and 1 <= int(args.lesson) <= len(LESSONS):
            index = int(args.lesson) - 1
        else:
            index = next((i for i, item in enumerate(LESSONS) if item["id"] == args.lesson), None)
        if index is None:
            parser.error("unknown lesson; use --list to see the course")

    vim = shutil.which("vim")
    if not vim:
        print("Vim Lab needs Vim 8.2+ and Python 3.10+. Install Vim, then run this command again.", file=sys.stderr)
        return 1
    if not sys.stdin.isatty() or not sys.stdout.isatty():
        print("Open Vim Lab in an interactive terminal: python3 -m vim_lab", file=sys.stderr)
        return 1
    if not os.environ.get("TERM") or os.environ["TERM"] == "dumb":
        print("Vim Lab needs a terminal with cursor control (for example, xterm-256color).", file=sys.stderr)
        return 1

    try:
        state_dir = args.state_dir.expanduser().resolve()
        state_dir.mkdir(parents=True, exist_ok=True)
        progress_path = state_dir / "progress.json"
        progress, warning = read_progress(progress_path)
        completed = set(progress["completed"])
        first_unfinished = next((i for i, item in enumerate(LESSONS) if item["id"] not in completed), 0)
        last_unfinished = next((i for i, item in enumerate(LESSONS) if item["id"] == progress.get("last_lesson") and item["id"] not in completed), first_unfinished)
        config = {
            "lessons": LESSONS, "chapters": CHAPTERS, "sandbox": SANDBOX,
            "progress": progress, "progress_path": str(progress_path), "warning": warning,
            "initial": index if index is not None else last_unfinished,
            "start": "sandbox" if args.sandbox else "lesson" if index is not None or args.resume else "menu",
        }
        with tempfile.TemporaryDirectory(prefix="vim-lab-") as scratch:
            config["scratch"] = scratch
            config_path = Path(scratch) / "session.json"
            config_path.write_text(json.dumps(config, ensure_ascii=False), encoding="utf-8")
            env = dict(os.environ, VIM_LAB_CONFIG=str(config_path))
            app = Path(__file__).with_name("app.vim")
            # Start with an isolated config; edits only touch temporary practice files.
            return subprocess.call([vim, "-Nu", "NONE", "-U", "NONE", "-i", "NONE", "-n", "-N", "-S", str(app)], env=env)
    except OSError as error:
        print(f"Vim Lab couldn't open: {error}. You can choose a writable folder with --state-dir PATH.", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    raise SystemExit(main())

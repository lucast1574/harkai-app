"""Reject credential material in tracked source without printing values."""
from pathlib import Path
import re
import subprocess

pattern = re.compile(rb"AIza[0-9A-Za-z_-]{35}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{30,}")
files = subprocess.check_output(["git", "ls-files", "-z"]).decode().split("\0")
leaks = [name for name in files if name and Path(name).is_file() and pattern.search(Path(name).read_bytes())]
if leaks:
    raise SystemExit("Credential material must be removed from tracked files: " + ", ".join(leaks))
print("Tracked source contains no supported credential patterns.")

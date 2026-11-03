#!/usr/bin/env python3
"""Report pairs of skill descriptions that share enough vocabulary that a
realistic request could route to either. Heuristic for an author to read,
never a verdict. Usage: desc-overlap.py <skills-dir> [threshold] [other-root ...]
Other roots (installed plugins, other tools' skill dirs) are searched recursively
and labeled <plugin>:<skill>, so collisions outside this repo show up too."""
import itertools
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
threshold = float(sys.argv[2]) if len(sys.argv) > 2 else 0.18
others = [pathlib.Path(a) for a in sys.argv[3:]]
STOP = set((
    "a an the and or of to in for on at by with from as is are be not no nor "
    "when use used using where what who which that this these those it its "
    "into out one two three four five before after than then them they you "
    "your their skill skills method produces each every any some all both "
    "either neither own also only just more most less over under about "
    "between within without does do did done have has had can could should "
    "would will may might must asked ask someone anyone else"
).split())


def words(text):
    return {w for w in re.findall(r"[a-z][a-z-]+", text.lower())
            if w not in STOP and len(w) > 3}


def description(path):
    inside = False
    collecting = False
    lines = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip() == "---":
            if inside:
                break
            inside = True
            continue
        if not inside:
            continue
        if collecting:
            if line.startswith((" ", "\t")):
                lines.append(line.strip())
                continue
            break
        if line.startswith("description:"):
            rest = line[len("description:"):].strip()
            if rest and rest not in (">", ">-", "|", "|-"):
                lines.append(rest)
            collecting = True
    return " ".join(lines)


def label(path, other):
    # <plugin>:<skill>, skipping version and hash folders; a skill directly in the root keeps its name
    if path.parent.parent == other:
        return path.parent.name
    owner = next((a.name for a in path.parents[1:] if a.name != "skills"
                  and not re.fullmatch(r"[\d.]+|[0-9a-f]{8,}|[0-9a-f_-]{30,}", a.name)), "?")
    return f"{owner.split('~')[0]}:{path.parent.name}"


descs = {p.parent.name: words(description(p)) for p in sorted(root.glob("*/SKILL.md"))}
for other in others:
    for p in sorted(other.rglob("SKILL.md")):
        descs.setdefault(label(p, other), words(description(p)))
for a, b in itertools.combinations(sorted(descs), 2):
    wa, wb = descs[a], descs[b]
    if not wa or not wb:
        continue
    shared = wa & wb
    score = len(shared) / len(wa | wb)
    if score >= threshold:
        print(f"{a} / {b}: {score:.2f} shared ({', '.join(sorted(shared)[:6])})")

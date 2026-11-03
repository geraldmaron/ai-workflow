#!/usr/bin/env python3
"""Behavior eval: what a skill makes a model do, against a baseline without it.

Each scenario in evals/behavior/<id>/ has a prompt, an optional seeded
workspace, and checks for planted traps. Optional [variants] add the same task
under pressure, run as <id>+<name>. Two arms run the same prompt:
  bare     no user settings, plugins, global instructions, or skills from this
           repo; the harness's own built-in skills are still present
  library  bare plus every skill in this checkout, where the harness finds them

Offline (default): score the recorded fixtures in each scenario's fixtures/
and fail if any check disagrees with the fixture's expect file. No model calls.
Live (--live): run every cell (scenario x target x arm x run), score it, and
write pass rates to local/evals/behavior/last-run.tsv. Costs tokens.
Rescore (--rescore DIR): score a kept live run again after a check changes.
"""
import argparse
import concurrent.futures as cf
import datetime
import json
import os
import pathlib
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import tomllib

REPO = pathlib.Path(os.environ.get("REPO_ROOT") or pathlib.Path(__file__).resolve().parent.parent)
SCENARIOS = REPO / "evals" / "behavior"
OUT = REPO / "local" / "evals" / "behavior"
ARMS = ("bare", "library")
TIMEOUT = 900
SKILL_READ = re.compile(r"skills/([a-z0-9-]+)/SKILL\.md")


def load(only=None):
    found = []
    for path in sorted(SCENARIOS.glob("*/scenario.toml")):
        sc = tomllib.loads(path.read_text())
        sc["id"], sc["dir"] = path.parent.name, path.parent
        # A variant reruns the same workspace and checks under pressure (a deadline, sunk cost, "just merge it").
        variants = sc.pop("variants", {})
        found += [sc] + [{**sc, "id": f"{sc['id']}+{name}", "prompt": text, "variant": True}
                         for name, text in variants.items()]
    if only:
        found = [sc for sc in found if sc["id"] in only]
    if only and len(found) != len(only):
        sys.exit(f"unknown scenario in {sorted(only)}")
    return found


def git(cwd, *args):
    return subprocess.run(["git", "-c", "user.name=eval", "-c", "user.email=eval@localhost", *args],
                          cwd=cwd, capture_output=True, text=True, check=True)


def seed(sc, dest, extra=None):
    """A git workspace holding the scenario's files (and extra trees), committed as the base."""
    if (sc["dir"] / "workspace").is_dir():
        shutil.copytree(sc["dir"] / "workspace", dest, dirs_exist_ok=True)
    for src, rel in extra or ():
        shutil.copytree(src, dest / rel, dirs_exist_ok=True)
    git(dest, "init", "-q")
    git(dest, "add", "-A")
    git(dest, "commit", "-q", "--allow-empty", "-m", "base", "--no-verify")


def matches(check, text):
    flags = re.IGNORECASE
    pats = check["all"]
    if "per" in check:  # at least one match of the pattern per match of `per`, and never fewer than two
        return len(re.findall(pats[0], text, flags)) >= max(2, len(re.findall(check["per"], text, flags)))
    near = check.get("near")
    if near is None:
        return all(re.search(p, text, flags) for p in pats)
    rest = [[m.start() for m in re.finditer(p, text, flags)] for p in pats[1:]]
    return any(all(any(abs(s - m.start()) <= near for s in starts) for starts in rest)
               for m in re.finditer(pats[0], text, flags))


def score(sc, answer, commands, workdir):
    """{check id: True/False/None}; None means the check could not run here."""
    result = {}
    for check in sc["check"]:
        where = check["where"]
        if where == "shell":
            if workdir is None:
                result[check["id"]] = None
                continue
            env = dict(os.environ, SCENARIO_DIR=str(sc["dir"]))
            ok = subprocess.run(["sh", "-c", check["run"]], cwd=workdir, env=env,
                                capture_output=True).returncode == 0
        else:
            ok = matches(check, answer if where == "answer" else "\n".join(commands))
            if check.get("negate"):
                ok = not ok
        result[check["id"]] = ok
    return result


# --- offline: recorded fixtures must score exactly as their expect file says ---

def selftest(scenarios):
    bad = 0
    for sc in scenarios:
        if sc.get("variant"):  # same checks as its base, already proven on the base's fixtures
            continue
        fixtures = sorted(p for p in (sc["dir"] / "fixtures").glob("*") if p.is_dir())
        if not fixtures:
            print(f"FAIL {sc['id']}: no fixtures")
            bad += 1
            continue
        seen = {c["id"]: set() for c in sc["check"]}
        for fx in fixtures:
            expect = set((fx / "expect").read_text().split())
            unknown = expect - seen.keys()
            answer = (fx / "answer.md").read_text() if (fx / "answer.md").exists() else ""
            commands = (fx / "commands.txt").read_text().splitlines() if (fx / "commands.txt").exists() else []
            with tempfile.TemporaryDirectory() as tmp:
                work = None
                if any(c["where"] == "shell" for c in sc["check"]) and shutil.which("node"):
                    work = pathlib.Path(tmp)
                    seed(sc, work)
                    if (fx / "changes.patch").exists():
                        git(work, "apply", str(fx / "changes.patch"))
                got = score(sc, answer, commands, work)
            wrong = [cid for cid, ok in got.items() if ok is not None and ok != (cid in expect)]
            skipped = [cid for cid, ok in got.items() if ok is None]
            for cid, ok in got.items():
                if ok is not None:
                    seen[cid].add(ok)
            if wrong or unknown:
                bad += 1
                print(f"FAIL {sc['id']}/{fx.name}: scored wrong on {', '.join(wrong + sorted(unknown))}")
            else:
                note = f" (skipped, node not installed: {', '.join(skipped)})" if skipped else ""
                print(f"PASS {sc['id']}/{fx.name}{note}")
        # A check no fixture both passes and fails has never been shown to discriminate.
        for cid, outcomes in seen.items():
            if outcomes and outcomes != {True, False}:
                bad += 1
                print(f"FAIL {sc['id']}: check {cid} is never {'failed' if True in outcomes else 'passed'} by a fixture")
    return bad


# --- live ---

def claude_cmd(model, prompt):
    return [shutil.which("claude"), "-p", prompt, "--model", model,
            "--setting-sources", "project,local", "--strict-mcp-config",
            # Edits in the scratch workspace, plus the commands a fix needs to test itself.
            # This arm keeps the real HOME (auth lives there), so nothing that fetches and runs
            # a package (npx, npm install) is allowed.
            "--permission-mode", "acceptEdits",
            "--allowedTools", "Bash(node *)", "Bash(npm test*)", "Bash(git diff*)",
            "Bash(git status*)", "Bash(ls*)", "WebSearch", "WebFetch",
            "--output-format", "stream-json", "--verbose"]


def codex_cmd(model, prompt, work):
    cmd = [shutil.which("codex"), "exec", "--json", "--skip-git-repo-check", "--ephemeral",
           "-s", "workspace-write", "-C", str(work)]
    return cmd + (["-m", model] if model != "default" else []) + [prompt]


def hermes_cmd(model, prompt):
    # chat -q with stream-json, not -z: -z prints only the final text, and checks need the commands.
    cmd = [shutil.which("hermes"), "chat", "-q", prompt, "--format", "stream-json", "--yolo"]
    return cmd + (["-m", model] if model != "default" else [])


def hermes_config(env, *args):
    return subprocess.run([shutil.which("hermes"), "config", *args], env=env, capture_output=True,
                          text=True, timeout=300).stdout.strip().splitlines()[-1:]


def parse_claude(lines):
    answer, commands, fired, model, cost = "", [], [], "", None
    for line in lines:
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "system" and ev.get("subtype") == "init":
            model = ev.get("model", "")
        elif ev.get("type") == "assistant":
            for item in ev.get("message", {}).get("content", []):
                if item.get("type") != "tool_use":
                    continue
                args = item.get("input", {})
                if item.get("name") == "Skill":
                    fired.append(str(args.get("skill") or args.get("command") or "?").split(":")[-1])
                elif item.get("name") == "Bash":
                    commands.append(args.get("command", ""))
                fired += SKILL_READ.findall(json.dumps(args))
        elif ev.get("type") == "result":
            answer, cost = ev.get("result", "") or "", ev.get("total_cost_usd")
    return answer, commands, fired, model, cost


def parse_codex(lines):
    answer, commands, fired = "", [], []
    for line in lines:
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        item = ev.get("item", {})
        if ev.get("type") != "item.completed":
            continue
        if item.get("type") == "agent_message":
            answer = item.get("text", "")
        elif item.get("type") == "command_execution":
            commands.append(item.get("command", ""))
            fired += SKILL_READ.findall(item.get("command", ""))
    return answer, commands, fired, None, None


def parse_hermes(lines):
    answer, commands, fired = "", [], []
    for line in lines:
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "tool_use":
            args = ev.get("input") or {}
            if ev.get("name") == "terminal":
                commands.append(args.get("command", ""))
            elif ev.get("name") == "execute_code":  # Hermes also runs tests from a code cell
                commands.append(args.get("code", ""))
            elif ev.get("name") == "skill_view":
                fired.append(str(args.get("name", "?")).split(":")[-1])
            fired += SKILL_READ.findall(json.dumps(args))
        elif ev.get("type") == "result":
            answer = ev.get("text", "") or ""
    return answer, commands, fired, None, None


PARSE = {"claude": parse_claude, "codex": parse_codex, "hermes": parse_hermes}


def run_cell(cell, stamp_dir):
    sc, harness, model, arm, n = cell
    name = f"{sc['id']}.{harness}-{model}.{arm}.{n}"
    keep = stamp_dir / name
    keep.mkdir(parents=True)
    with tempfile.TemporaryDirectory(prefix="aiwf-behavior-") as tmp:
        tmp = pathlib.Path(tmp)
        work, home = tmp / "work", tmp / "home"
        work.mkdir()
        env = dict(os.environ)
        library = [(d, f"skills/{d.name}") for d in sorted((REPO / "skills").iterdir())
                   if (d / "SKILL.md").exists()]
        prompt = sc["prompt"].strip()
        if harness == "claude":
            # Project skills: the only skill root left once user settings are off.
            seed(sc, work, [(d, f".claude/{rel}") for d, rel in library] if arm == "library" else None)
            cmd = claude_cmd(model, prompt)
        elif harness == "hermes":
            # A scratch HERMES_HOME keeps the model and provider config but drops memory, SOUL.md,
            # plugins (ponytail), and skills.external_dirs; auth and .env are links, never copies.
            seed(sc, work)
            real = pathlib.Path(os.environ.get("HERMES_HOME") or pathlib.Path.home() / ".hermes")
            home.mkdir()
            # The copied config's ~/ and $HOME/ paths (a key_cmd, say) mean the real home, not the scratch one.
            (home / "config.yaml").write_text(re.sub(r"(?<=[\s\"'])(~|\$HOME|\$\{HOME\})/", f"{pathlib.Path.home()}/",
                                                     (real / "config.yaml").read_text()))
            for f in ("auth.json", ".env"):
                if (real / f).exists():
                    (home / f).symlink_to(real / f)
            for d, rel in library if arm == "library" else ():
                shutil.copytree(d, home / "library" / rel)
            # --yolo approves every command, so HOME is scratch too: the real home is out of reach.
            env.update(HERMES_HOME=str(home), HOME=str(home))
            hermes_config(env, "unset", "plugins.enabled")
            hermes_config(env, "set", "skills.external_dirs",
                          json.dumps([str(home / "library" / "skills")] if arm == "library" else []))
            hermes_model = model if model != "default" else "".join(hermes_config(env, "get", "model.default"))
            cmd = hermes_cmd(model, prompt)
        else:
            # A scratch HOME and CODEX_HOME drop user config, AGENTS.md, plugins, and
            # ~/.agents/skills; auth is a link to the real file, never a copy.
            seed(sc, work)
            (home / ".codex").mkdir(parents=True)
            (home / ".codex" / "auth.json").symlink_to(pathlib.Path.home() / ".codex" / "auth.json")
            for d, rel in library if arm == "library" else ():
                shutil.copytree(d, home / ".agents" / rel)
            env.update(HOME=str(home), CODEX_HOME=str(home / ".codex"))
            cmd = codex_cmd(model, prompt, work)
        started = datetime.datetime.now()
        proc = subprocess.Popen(cmd, cwd=work, env=env, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, text=True, start_new_session=True)
        try:
            out, err = proc.communicate(timeout=TIMEOUT)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)  # the whole group, never this session
            out, err = proc.communicate()
        seconds = (datetime.datetime.now() - started).seconds
        if harness == "hermes":  # chat -q starts a gateway for the scratch home; it must not outlive it
            subprocess.run([shutil.which("hermes"), "gateway", "stop"], env=env, capture_output=True, timeout=120)
        lines = out.splitlines()
        answer, commands, fired, resolved, cost = PARSE[harness](lines)
        if harness == "hermes":
            resolved = hermes_model
        got = score(sc, answer, commands, work)
        diff = subprocess.run(["git", "diff", "HEAD"], cwd=work, capture_output=True, text=True).stdout
        git(work, "add", "-A")
        (keep / "changes.patch").write_text(git(work, "diff", "--cached", "HEAD").stdout)
    (keep / "events.jsonl").write_text(out)
    (keep / "stderr.txt").write_text(err[-20000:])
    (keep / "answer.md").write_text(answer)
    (keep / "commands.txt").write_text("\n".join(commands))
    record = {"scenario": sc["id"], "harness": harness, "model": model, "resolved": resolved or model,
              "arm": arm, "run": n, "checks": got, "fired": sorted(set(fired)), "seconds": seconds,
              "cost_usd": cost, "exit": proc.returncode, "empty": not answer and not diff}
    (keep / "record.json").write_text(json.dumps(record, indent=2))
    return record


def default_targets():
    targets = ["claude:haiku", "claude:sonnet"] if shutil.which("claude") else []
    if shutil.which("codex"):
        model = "default"
        cfg = pathlib.Path.home() / ".codex" / "config.toml"
        if cfg.exists():
            model = tomllib.loads(cfg.read_text()).get("model", "default")
        targets.append(f"codex:{model}")
    return targets


def version(tool):
    try:
        out = subprocess.run([tool, "--version"], capture_output=True, text=True).stdout.strip()
        return out.splitlines()[0] if out else out  # hermes prints install details after the version
    except OSError:
        return "not installed"


def live(scenarios, targets, arms, runs, workers):
    for t in targets:
        harness = t.split(":")[0]
        if harness not in PARSE:
            sys.exit(f"unsupported harness '{harness}'; use claude, codex, or hermes")
        if not shutil.which(harness):
            sys.exit(f"{harness} is not installed")
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    stamp_dir = OUT / stamp
    stamp_dir.mkdir(parents=True)
    cells = [(sc, *t.split(":", 1), arm, n) for sc in scenarios for t in targets
             for arm in arms for n in range(1, runs + 1)]
    print(f"behavior eval: {len(cells)} sessions -> local/evals/behavior/{stamp}/", file=sys.stderr)
    records = []
    with cf.ThreadPoolExecutor(max_workers=workers) as pool:
        for fut in cf.as_completed([pool.submit(run_cell, c, stamp_dir) for c in cells]):
            r = fut.result()
            records.append(r)
            print(f"  {r['scenario']} {r['harness']}:{r['model']} {r['arm']} #{r['run']}: "
                  f"{sum(bool(v) for v in r['checks'].values())}/{len(r['checks'])} "
                  f"fired={','.join(r['fired']) or '-'}", file=sys.stderr)
    versions = {h: version(h) for h in {t.split(':')[0] for t in targets}}
    write_results(scenarios, records, stamp_dir, " | ".join(f"{h}: {v}" for h, v in sorted(versions.items())))


def rescore(scenarios, stamp_dir):
    """Score a kept run again with the current checks; no model calls."""
    by_id = {sc["id"]: sc for sc in scenarios}
    records = []
    for path in sorted(stamp_dir.glob("*/record.json")):
        r = json.loads(path.read_text())
        sc = by_id.get(r["scenario"])
        if sc is None:
            continue
        keep = path.parent
        with tempfile.TemporaryDirectory() as tmp:
            work = pathlib.Path(tmp)
            seed(sc, work)
            patch = keep / "changes.patch"
            if patch.exists() and patch.stat().st_size:
                git(work, "apply", str(patch))
            r["checks"] = score(sc, (keep / "answer.md").read_text(),
                                (keep / "commands.txt").read_text().splitlines(), work)
        path.write_text(json.dumps(r, indent=2))
        records.append(r)
    if not records:
        sys.exit(f"no recorded sessions in {stamp_dir}")
    old = (stamp_dir / "results.tsv").read_text().splitlines()[0] if (stamp_dir / "results.tsv").exists() else ""
    tools = " | ".join(old.split(" | ")[2:-1]) or "versions not recorded"
    write_results(scenarios, records, stamp_dir, f"{tools} | rescored {datetime.date.today()}")


def write_results(scenarios, records, stamp_dir, tools):
    head = (f"# behavior eval | {datetime.date.today()} | {tools}"
            + " | bare = no user settings, plugins, global instructions or repo skills; harness built-ins remain")
    rows = ["scenario\tharness\tmodel\tarm\truns\tcheck\tkind\tpassed\trate"]
    groups = {}
    for r in records:
        groups.setdefault((r["scenario"], r["harness"], r["resolved"], r["arm"]), []).append(r)
    kinds = {sc["id"]: {c["id"]: c["kind"] for c in sc["check"]} for sc in scenarios}
    for (sid, harness, model, arm), rs in sorted(groups.items()):
        n = len(rs)
        for cid, kind in kinds[sid].items():
            passed = sum(bool(r["checks"].get(cid)) for r in rs)
            rows.append(f"{sid}\t{harness}\t{model}\t{arm}\t{n}\t{cid}\t{kind}\t{passed}\t{passed / n:.2f}")
        for skill in sorted({s for r in rs for s in r["fired"]}):
            fired = sum(skill in r["fired"] for r in rs)
            rows.append(f"{sid}\t{harness}\t{model}\t{arm}\t{n}\tfired:{skill}\tskill\t{fired}\t{fired / n:.2f}")
        empty = sum(r["empty"] for r in rs)
        if empty:
            rows.append(f"{sid}\t{harness}\t{model}\t{arm}\t{n}\tno-output\terror\t{empty}\t{empty / n:.2f}")
    text = head + "\n" + "\n".join(rows) + "\n"
    (stamp_dir / "results.tsv").write_text(text)
    (OUT / "last-run.tsv").write_text(text)
    print(text)


def main():
    ap = argparse.ArgumentParser(description="Behavior eval: skill vs no-skill baseline on planted traps.")
    ap.add_argument("--live", action="store_true", help="call real models (costs tokens)")
    ap.add_argument("--scenario", help="comma list of scenario ids (default: all)")
    ap.add_argument("--targets", help="comma list of harness:model (default: claude:haiku,claude:sonnet,codex:<configured>; "
                    "hermes:<model> or hermes:default only when named)")
    ap.add_argument("--arms", default=",".join(ARMS))
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--rescore", metavar="DIR", help="score a kept live run again with the current checks (no model calls)")
    a = ap.parse_args()
    scenarios = load(set(a.scenario.split(",")) if a.scenario else None)
    if a.rescore:
        rescore(scenarios, pathlib.Path(a.rescore).resolve())
        return
    if not a.live:
        bad = selftest(scenarios)
        print(f"behavior eval (offline): {'all fixtures scored as expected' if not bad else f'{bad} problem(s)'}")
        sys.exit(1 if bad else 0)
    arms = a.arms.split(",")
    if set(arms) - set(ARMS):
        sys.exit(f"arms must be among {ARMS}")
    targets = a.targets.split(",") if a.targets else default_targets()
    if not targets:
        sys.exit("no harness installed: install claude or codex")
    live(scenarios, targets, arms, a.runs, a.workers)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""release_preflight.py -- read-only checks before (and after) a release of the nwcommands core.

    python3 tools/release_preflight.py                    before a release (run on `develop`)
    python3 tools/release_preflight.py --require-pushed   the same, and develop must equal origin/develop
    python3 tools/release_preflight.py --post             after the release: tag exists and is in origin/main, tree clean
    python3 tools/release_preflight.py --models-parent DIR [--model-pattern 'rd_{name}']
                                                           where the clones of nwsaom nwergm nwdynam nwrem are
                                                           (default: the parent of the core checkout, folder = the package name)
    python3 tools/release_preflight.py --no-network       skip the checks that ask GitHub (git ls-remote)

Prints PASS / FAIL / SKIP per item and exits 1 when any item FAILs. It never writes anything, never fetches, never runs Stata.
The master procedure is RELEASING.md. A FAIL means: stop and read the message, do not release.

Items: 1 VERSION file; 2 CHANGELOG top entry = VERSION; 3 version displays (tools/check_version.py); 4 help index
(tools/check_help_index.py); 5 Mata library hash = lib/lnwcommands.mlib.release.sha256; 6 tag vX.Y.Z (not yet there before the
release, there and inside origin/main after it), locally and on GitHub; 7 working tree clean; 8 branch (develop before, main
after) and up to date with origin; 9 plugin generation: NWCOMB_VERSION in native/nwcomb.h is not lower than any generation the
code asks for, and the Linux and Windows binaries were committed (by CI) after the last change in native/; 10 website shows the
version (packages table, core page, news, citation); 11 models: lib/core_mlib.sha256 of every model clone found equals the core
library's hash, and the website shows each model's VERSION.
"""
import argparse, datetime, glob, hashlib, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
MODELS = ["nwsaom", "nwergm", "nwdynam", "nwrem"]
results = []


def rec(status, name, detail=""):
    results.append(status)
    print(f"{status:<5} {name}" + (f": {detail}" if detail else ""))


def git(*args, cwd=ROOT):
    p = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True)
    return p.returncode, p.stdout.strip(), p.stderr.strip()


def read(path, default=None):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return default


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1], add_help=True)
    ap.add_argument("--post", action="store_true", help="check the state after the release")
    ap.add_argument("--require-pushed", action="store_true", help="the branch must equal its remote (default: ahead is allowed)")
    ap.add_argument("--no-network", action="store_true")
    ap.add_argument("--models-parent", default=os.path.dirname(ROOT))
    ap.add_argument("--model-pattern", default="{name}", help="folder name of a model clone, {name} = nwsaom etc.")
    ap.add_argument("--skip-website", action="store_true")
    a = ap.parse_args()

    # 1 VERSION
    v = read("VERSION", "").split()
    ver = date = None
    if len(v) >= 2 and re.fullmatch(r"\d+\.\d+\.\d+", v[0]):
        try:
            d = datetime.datetime.strptime(v[1], "%d%b%Y")
            ver, date, iso, longdate = v[0], v[1], d.strftime("%Y-%m-%d"), d.strftime("%-d %B %Y")
            rec("PASS", "VERSION", f"{ver} {date}")
        except ValueError:
            rec("FAIL", "VERSION", f"date '{v[1]}' is not in Stata format, e.g. 25oct2026")
    else:
        rec("FAIL", "VERSION", "line 1 must be MAJOR.MINOR.PATCH and line 2 the date (25oct2026)")
    if ver is None:
        return finish()

    # 2 CHANGELOG
    cl = read("CHANGELOG.md", "")
    m = re.search(r"(?m)^## \[(\d+\.\d+\.\d+)\] - (\d{4}-\d{2}-\d{2})\s*$", cl)
    if not m:
        rec("FAIL", "CHANGELOG top entry", "no '## [X.Y.Z] - YYYY-MM-DD' heading found")
    elif m.group(1) != ver:
        rec("FAIL", "CHANGELOG top entry", f"first entry is {m.group(1)}, VERSION is {ver}")
    elif m.group(2) != iso:
        rec("FAIL", "CHANGELOG top entry", f"{m.group(1)} is dated {m.group(2)}, VERSION says {iso}")
    else:
        body = cl[m.end():].split("\n## [", 1)[0]
        n = len([x for x in body.splitlines() if x.startswith("- ")])
        rec("PASS" if n else "FAIL", "CHANGELOG top entry", f"{ver} dated {iso}, {n} items" if n else "the entry is empty")

    # 3 version displays, 4 help index
    for name, script in (("version displays (tools/check_version.py)", "check_version.py"), ("help index (tools/check_help_index.py)", "check_help_index.py")):
        p = subprocess.run([sys.executable, os.path.join("tools", script)], capture_output=True, text=True)
        out = (p.stdout + p.stderr).strip().splitlines()
        if p.returncode == 0:
            rec("PASS", name, out[-1] if out else "")
        else:
            rec("FAIL", name, " | ".join(l for l in out if l.strip() and not l.startswith("*"))[:400])

    # 5 Mata library hash
    lib, hf = os.path.join("lib", "lnwcommands.mlib"), os.path.join("lib", "lnwcommands.mlib.release.sha256")
    libhash = None
    if not os.path.exists(lib):
        rec("FAIL", "Mata library hash", "lib/lnwcommands.mlib is missing")
    else:
        libhash = hashlib.sha256(open(lib, "rb").read()).hexdigest()
        rh = (read(hf, "") or "").split()
        if not rh:
            rec("FAIL", "Mata library hash", "lib/lnwcommands.mlib.release.sha256 is missing: python3 tools/record_release_hash.py")
        elif rh[0] != libhash:
            rec("FAIL", "Mata library hash", "the library differs from the recorded release hash. Either you meant to change it (lockstep "
                "release: rebuild the models against it, then python3 tools/record_release_hash.py) or it was rebuilt by accident (git checkout the library)")
        else:
            rec("PASS", "Mata library hash", libhash[:12] + "... equals the recorded release hash")

    # 6 tag
    tag = "v" + ver
    rc, loc, _ = git("tag", "-l", tag)
    have_local = loc == tag
    have_remote = None
    if not a.no_network:
        rc, out, err = git("ls-remote", "--tags", "origin", f"refs/tags/{tag}")
        have_remote = bool(out) if rc == 0 else None
        if rc != 0:
            rec("SKIP", f"remote tag {tag}", "GitHub not reachable: " + err[:100])
    if not a.post:
        rec("FAIL" if have_local else "PASS", f"local tag {tag} absent",
            "it exists (a legacy or earlier tag: never move a published tag; delete a purely local one, or raise the version)" if have_local else "free")
        if have_remote is not None:
            rec("FAIL" if have_remote else "PASS", f"remote tag {tag} absent", "already published: raise the version" if have_remote else "free")
    else:
        if not have_local:
            rec("FAIL", f"local tag {tag}", "missing")
        else:
            rc, _, _ = git("merge-base", "--is-ancestor", tag + "^{commit}", "origin/main")
            rec("PASS" if rc == 0 else "FAIL", f"tag {tag} is inside origin/main", "" if rc == 0 else "the tagged commit is not in origin/main (fetch first?)")
        if have_remote is not None:
            rec("PASS" if have_remote else "FAIL", f"remote tag {tag}", "" if have_remote else "not on GitHub")

    # 7 working tree
    rc, out, _ = git("status", "--porcelain")
    tracked = [l for l in out.splitlines() if not l.startswith("??")]
    untracked = [l for l in out.splitlines() if l.startswith("??")]
    if tracked:
        rec("FAIL", "working tree clean", f"{len(tracked)} changed tracked file(s), first: {tracked[0][3:]}")
    else:
        rec("PASS", "working tree clean", f"{len(untracked)} untracked file(s) (ignored)" if untracked else "")

    # 8 branch and origin
    rc, br, _ = git("branch", "--show-current")
    want = "main" if a.post else "develop"
    if br != want:
        rec("FAIL", "branch", f"on '{br or 'detached HEAD'}', expected {want} (core work is on develop, releases go to main; use a worktree)")
    else:
        rec("PASS", "branch", br)
    if br and not a.no_network:
        rc, out, err = git("ls-remote", "origin", f"refs/heads/{br}")
        if rc != 0 or not out:
            rec("SKIP", f"{br} versus origin/{br}", "GitHub not reachable or branch not on origin")
        else:
            rsha = out.split()[0]
            rc, head, _ = git("rev-parse", "HEAD")
            if rsha == head:
                rec("PASS", f"{br} equals origin/{br}", head[:10])
            else:
                rc1, _, _ = git("cat-file", "-e", rsha + "^{commit}")
                if rc1 != 0:
                    rec("FAIL", f"{br} versus origin/{br}", "origin has commits you do not have (git fetch; then merge or rebase; the CI bot commits plugins)")
                else:
                    rc2, _, _ = git("merge-base", "--is-ancestor", rsha, "HEAD")
                    if rc2 == 0:
                        rec("FAIL" if a.require_pushed else "PASS", f"{br} versus origin/{br}",
                            "ahead of origin (not pushed yet)" + ("" if a.require_pushed else ": allowed before the push"))
                    else:
                        rec("FAIL", f"{br} versus origin/{br}", "diverged from origin: merge or rebase first")

    # 9 plugin generation
    h = read(os.path.join("native", "nwcomb.h"), "")
    m = re.search(r"(?m)^#define NWCOMB_VERSION (\d+)", h)
    if not m:
        rec("FAIL", "plugin generation", "no '#define NWCOMB_VERSION' in native/nwcomb.h")
    else:
        gen = int(m.group(1))
        need = 0
        for f in ["unw_core.do"] + glob.glob("*.ado"):
            for k in re.findall(r"nwg_comb_version\(\)\s*>=\s*(\d+)", read(f, "")) + re.findall(r"nwg_comb_version\(\)\s*<\s*(\d+)", read(f, "")):
                need = max(need, int(k))
        if need > gen:
            rec("FAIL", "plugin generation", f"the code asks for generation {need} but native/nwcomb.h says NWCOMB_VERSION {gen}")
        else:
            rec("PASS", "plugin generation", f"NWCOMB_VERSION {gen}, highest generation the code asks for: {need}")
        rc, nc, _ = git("log", "-1", "--format=%H", "--", "native")
        for plat, fn in (("unix", "nwgraph_unix.plugin"), ("windows", "nwgraph_windows.plugin"), ("macos", "nwgraph_macos.plugin")):
            path = f"lib/plugins/{plat}/{fn}"
            rc, pc, _ = git("log", "-1", "--format=%H", "--", path)
            if not nc or not pc:
                rec("FAIL", f"{plat} plugin committed", path + " or native/ has no history here")
                continue
            rc, _, _ = git("merge-base", "--is-ancestor", nc, pc)
            if rc == 0:
                rec("PASS", f"{plat} plugin is newer than native/", pc[:10])
            else:
                note = ("push develop and wait for the 'ci: rebuild native plugins' commit, then git pull" if plat != "macos"
                        else "rebuild it locally (make -C native macos) or take the CI one")
                rec("FAIL", f"{plat} plugin is newer than native/", f"native/ last changed in {nc[:10]}, binary in {pc[:10]}: {note}")

    # 10 website
    if not a.skip_website:
        checks = [("website/index.md", r"\|\s*" + re.escape(ver) + r"\s*\|", "packages table row of the core"),
                  ("website/nwcommands/index.md", r"version " + re.escape(ver), "core page"),
                  ("website/news.md", r"\*\*nwcommands " + re.escape(ver) + r"[.*]", "news entry"),
                  ("website/citing.md", r"\(version " + re.escape(ver) + r"\)", "citation")]
        bad = [f"{p} ({w})" for p, pat, w in checks if not re.search(pat, read(p, ""))]
        placeholder = [p for p in ("website/nwcommands/index.md", "website/index.md") if re.search(r"\bDD [A-Z][a-z]+ 20\d\d", read(p, ""))]
        if bad:
            rec("FAIL", "website shows the core version", "missing in " + "; ".join(bad))
        else:
            rec("PASS", "website shows the core version", ver)
        rec("FAIL" if placeholder else "PASS", "website has no 'DD Month' date placeholder", ", ".join(placeholder))

    # 11 model clones
    for name in MODELS:
        d = os.path.join(a.models_parent, a.model_pattern.format(name=name))
        if not os.path.isdir(d):
            rec("SKIP", f"{name} clone", f"{d} not found")
            continue
        h = (read(os.path.join(d, "lib", "core_mlib.sha256"), "") or "").split()
        if not h or libhash is None:
            rec("FAIL", f"{name} lib/core_mlib.sha256", "missing")
        elif h[0] == libhash:
            rec("PASS", f"{name} built against this core library", h[0][:12] + "...")
        else:
            rec("FAIL", f"{name} built against this core library",
                "hash differs: lockstep (lib/build.do against this core, then tools/record_core_lib.py and release); for nwdynam/nwrem see RELEASING.md section B.4")
        mv = (read(os.path.join(d, "VERSION"), "") or "").split()
        if mv and not a.skip_website:
            mver = mv[0]
            s = read(f"website/{name}/index.md", "") + "\n" + read(f"website/{name}/install.md", "")
            ok = re.search(r"\|\s*Version\s*\|\s*" + re.escape(mver) + r"\b", s) and re.search(re.escape(name) + r" version " + re.escape(mver) + r"\b", s)
            rec("PASS" if ok else "FAIL", f"website shows {name} {mver}", "" if ok else f"website/{name}/index.md 'Version' row or install.md transcript differs from {name}/VERSION")
    return finish()


def finish():
    f, p, s = results.count("FAIL"), results.count("PASS"), results.count("SKIP")
    print(f"\n{p} passed, {f} failed, {s} skipped")
    sys.exit(1 if f else 0)


if __name__ == "__main__":
    main()

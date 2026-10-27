"""Re-parse the `sample` reports in logs/prof_*.txt: samples at the top of the stack by binary image, with the idle
thread-pool waits removed (a sampled process has many parked threads).  Writes summary/profiles_active.csv."""
import re, glob, os, csv, collections
B = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IDLE = ("__semwait_signal", "__workq_kernreturn", "mach_msg2_trap", "mach_msg_trap", "__psynch_cvwait", "__ulock_wait", "__ulock_wait2",
        "__select", "kevent", "__sigwait", "read", "poll", "__wait4", "__semwait_signal_nocancel", "semaphore_wait_trap", "semaphore_timedwait_trap", "__open")
rows = []
for f in sorted(glob.glob(B + "/logs/prof_*.txt")):
    impl_model = os.path.basename(f)[5:-4]
    txt = open(f, errors="replace").read()
    sec = txt.split("Sort by top of stack, same collapsed")[-1]
    img = collections.Counter(); fn = collections.Counter(); idle = 0
    for l in sec.splitlines():
        m = re.match(r"^\s+(.+?)\s+\(in (.+?)\)\s+(?:\+\s*\d+\s+)?\[?.*?\]?\s*(\d+)\s*$", l)
        if not m: continue
        name, im, n = m.group(1), m.group(2), int(m.group(3))
        if name.split()[0] in IDLE or name in IDLE: idle += n; continue
        img[im] += n; fn[(im, name)] += n
    tot = sum(img.values())
    rows.append([impl_model, tot, idle] + ["%s=%.1f%%" % (k, 100 * v / tot) for k, v in img.most_common(6)])
    print(impl_model, "active samples", tot, "idle", idle)
    for k, v in img.most_common(5): print("   %-30s %5.1f%%" % (k, 100 * v / tot))
    for (im, nm), v in fn.most_common(5): print("      %-28s %-45s %5.1f%%" % (im, nm[:45], 100 * v / tot))
with open(B + "/summary/profiles_active.csv", "w", newline="") as fh:
    csv.writer(fh).writerows([["profile", "active_samples", "idle_samples", "top images (share of active samples)"]] + rows)

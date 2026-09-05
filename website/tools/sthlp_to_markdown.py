#!/usr/bin/env python3
"""Convert nwcommands .sthlp (SMCL) help files into Markdown reference pages
for the Just the Docs Jekyll site, grouped using nw_topical.sthlp's own
category structure."""
import re
import sys
from pathlib import Path

REPO = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
OUT = Path(sys.argv[2] if len(sys.argv) > 2 else "./out")
REF_OUT = OUT / "reference"
REF_OUT.mkdir(parents=True, exist_ok=True)

STHLP_FILES = sorted(REPO.glob("*.sthlp"))
KNOWN = {f.stem for f in STHLP_FILES}

DROP_TAGS = re.compile(
    r"\{(?:txt|res|com|synoptline|synopthdr|p2colreset|smcl)\}"
    r"|\{synoptset[^{}]*\}"
    r"|\{p2colset[^{}]*\}"
    r"|\{p2line[^{}]*\}"
    r"|\{marker\s+[^{}]*\}"
    r"|\{hline\d*\}"
    r"|\{col\s+\d+\}"
    r"|\{\.\.\.\}"
    r"|\{ul (?:on|off)\}"
    r"|\{p\s+[0-9 ]+\}"
    r"|\{p(?:std|more2?|hang2?)\}"
)


def read_balanced(s, open_idx):
    """Given s[open_idx] == '{', return (inner_content, index_after_close)."""
    depth = 0
    i = open_idx
    n = len(s)
    while i < n:
        if s[i] == "{":
            depth += 1
        elif s[i] == "}":
            depth -= 1
            if depth == 0:
                return s[open_idx + 1 : i], i + 1
        i += 1
    return s[open_idx + 1 :], n


def link_or_code(target, label):
    target = target.strip()
    stem = target.split("##")[0]
    if stem in KNOWN:
        return f"[{label}]({stem}.md)"
    return f"`{label}`"


def _specific_inline(s: str) -> str:
    s = DROP_TAGS.sub("", s)
    s = re.sub(r"\{space\s+\d+\}", " ", s)
    s = re.sub(r"\{c -\(\}", "{", s)
    s = re.sub(r"\{c \)-\}", "}", s)
    s = re.sub(r"\{c (?:TLC|TRC|BLC|BRC|RT|LT)\}", "", s)
    s = re.sub(r'\{net\s+"([^"]+)":([^{}]*)\}', r"[\2](\1)", s)
    s = re.sub(r'\{browse\s+"([^"]+)":([^{}]*)\}', r"[\2](\1)", s)
    s = re.sub(r'\{stata\s+"[^"]*":([^{}]*)\}', r"`\1`", s)
    s = re.sub(r"\{dlgtab\s+\d+:([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{helpb?\s+([^:{}]+?)##[^:{}]*:([^{}]*)\}",
                lambda m: link_or_code(m.group(1), m.group(2)), s)
    s = re.sub(r"\{helpb?\s+([^:{}]+?)##[^{}]*\}",
                lambda m: link_or_code(m.group(1), m.group(1)), s)
    s = re.sub(r"\{helpb?\s+([^:{}]+?):([^{}]*)\}",
                lambda m: link_or_code(m.group(1), m.group(2)), s)
    s = re.sub(r"\{helpb?\s+([^{}]+?)\}",
                lambda m: link_or_code(m.group(1), m.group(1).strip()), s)
    s = re.sub(r"\{cmdab:\s*([^{}]*)\}", r"`\1`", s)
    s = re.sub(r"\{cmd:([^{}]*)\}", r"`\1`", s)
    s = re.sub(r"\{err:([^{}]*)\}", r"**\1**", s)
    s = re.sub(r"\{bf:([^{}]*)\}", r"**\1**", s)
    s = re.sub(r"\{it:([^{}]*)\}", r"*\1*", s)
    s = re.sub(r"\{center:([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{ralign\s+\d+:([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{opth?\s+([^{}]*)\}", r"`\1`", s)
    s = re.sub(r"\{p_end\}", "", s)
    return s


def _specific_plain(s: str) -> str:
    s = DROP_TAGS.sub("", s)
    s = re.sub(r"\{space\s+\d+\}", " ", s)
    s = re.sub(r"\{c -\(\}", "{", s)
    s = re.sub(r"\{c \)-\}", "}", s)
    s = re.sub(r"\{c (?:TLC|TRC|BLC|BRC|RT|LT)\}", "", s)
    s = re.sub(r'\{net\s+"([^"]+)":([^{}]*)\}', r"\2", s)
    s = re.sub(r'\{browse\s+"([^"]+)":([^{}]*)\}', r"\2", s)
    s = re.sub(r'\{stata\s+"[^"]*":([^{}]*)\}', r"\1", s)
    s = re.sub(r"\{dlgtab\s+\d+:([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{helpb?\s+([^:{}]+?)##[^:{}]*:([^{}]*)\}", r"\2", s)
    s = re.sub(r"\{helpb?\s+([^:{}]+?)##[^{}]*\}", r"\1", s)
    s = re.sub(r"\{helpb?\s+([^:{}]+?):([^{}]*)\}", r"\2", s)
    s = re.sub(r"\{helpb?\s+([^{}]+?)\}", lambda m: m.group(1).strip(), s)
    s = re.sub(r"\{cmdab:\s*([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{cmd:([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{err:([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{bf:([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{it:([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{center:([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{ralign\s+\d+:([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{opth?\s+([^{}]*)\}", r"\1", s)
    s = re.sub(r"\{p_end\}", "", s)
    return s


_FALLBACK = re.compile(r"\{([^{}]*)\}")


def _converge(s: str, specific_fn, rounds=8) -> str:
    """Resolve all recognized tags to a fixed point BEFORE ever applying the
    generic brace-unwrap fallback, so a freshly-exposed known tag (e.g. an
    {it:...} nested inside a {help ...:...}) always gets its own proper
    substitution instead of being swallowed verbatim by the fallback on the
    same pass."""
    prev = None
    for _ in range(rounds):
        if s == prev:
            break
        prev = s
        s = specific_fn(s)
    prev = None
    for _ in range(rounds):
        if s == prev:
            break
        prev = s
        s = specific_fn(s)
        s = _FALLBACK.sub(r"\1", s)
    return s.strip()


def inline(s: str) -> str:
    return _converge(s, _specific_inline)


def plain(s: str) -> str:
    """Like inline() but for the Syntax box: no markdown emphasis, no links."""
    return _converge(s, _specific_plain)


def get_section(text, name):
    """Return the raw content of {title:name} ... up to the next {title:...}."""
    pattern = re.compile(
        r"\{title:" + re.escape(name) + r"\}(.*?)(?=\{title:|\Z)", re.S | re.I
    )
    m = pattern.search(text)
    return m.group(1).strip("\n") if m else None


def paragraphs_to_md(raw: str) -> str:
    """Convert a section's raw SMCL body into markdown paragraphs, pulling
    out {cmd:. ...}-style example lines into fenced code blocks.

    SMCL only reflows text into one wrapped paragraph following an explicit
    {pstd}/{p ...} marker - Stata's own renderer otherwise shows each source
    line as its own line. Two very common raw (non-{pstd}) idioms need their
    own handling rather than being blindly joined into one run-on paragraph:
    (1) the standard "Stored results" convention - a bare header word
    (Scalars/Macros/Matrices/Functions) followed by indented {bf:e(...)}<tab>
    description lines, no {p_end} per line; (2) {p2col:label}desc{p_end}
    bullet/definition blocks (used for both plain bullets, {p2col: o}..., and
    labeled lists), bracketed by {p2colset ...}/{p2colreset}."""
    lines = raw.split("\n")
    out = []
    code_buf = []
    para_buf = []
    verbatim_buf = []
    list_buf = []
    mode = None  # "prose" after {pstd}/{p ...}; None = verbatim-eligible

    def flush_code():
        if code_buf:
            out.append("```stata")
            out.extend(code_buf)
            out.append("```")
            code_buf.clear()

    def flush_para():
        if para_buf:
            txt = inline(" ".join(x.strip() for x in para_buf if x.strip()))
            if txt:
                out.append(txt)
                out.append("")
            para_buf.clear()

    def flush_verbatim():
        if verbatim_buf:
            rendered = []
            for ln in verbatim_buf:
                t = inline(ln.strip())
                if not t:
                    continue
                t = re.sub(r"[ \t]+", " ", t)
                # a bare single-word header (Scalars/Macros/Matrices/...):
                # its own bolded line, not a bullet.
                if re.fullmatch(r"[A-Z][A-Za-z]*", t):
                    if rendered:
                        rendered.append("")
                    rendered.append(f"**{t}**")
                    rendered.append("")
                else:
                    rendered.append(f"- {t}")
            if rendered:
                out.extend(rendered)
                out.append("")
            verbatim_buf.clear()

    def flush_list():
        if list_buf:
            out.extend(list_buf)
            out.append("")
            list_buf.clear()

    def flush_all():
        flush_code()
        flush_para()
        flush_verbatim()
        flush_list()

    p2col_open = None  # (label_i, [desc_line, ...]) while an item's {p_end} hasn't been seen yet

    def finalize_p2col(label_i, desc_parts):
        desc_i = inline(" ".join(x.strip() for x in desc_parts if x.strip())).strip()
        if label_i in ("", "o"):
            if desc_i:
                list_buf.append(f"- {desc_i}")
        elif desc_i:
            list_buf.append(f"- **{label_i}** --- {desc_i}")
        else:
            list_buf.append(f"- **{label_i}**")

    for line in lines:
        stripped = line.strip()
        # continuation of a {p2col:...} item whose {p_end} wasn't on its
        # opening line (a handful of older files wrap a long description
        # across physical source lines, or drop {p_end} entirely and rely on
        # the next blank line/{p2col to close the item - a real, if sloppy,
        # pre-existing source pattern, not something worth "fixing" here).
        if p2col_open is not None:
            label_i, desc_parts = p2col_open
            pend_idx = line.find("{p_end}")
            if pend_idx != -1:
                desc_parts.append(line[:pend_idx])
                finalize_p2col(label_i, desc_parts)
                p2col_open = None
                continue
            if stripped == "" or re.match(r"\{p2col(?:\s+[\d ]+)?:", stripped):
                finalize_p2col(label_i, desc_parts)
                p2col_open = None
                # fall through: let this same line be handled normally below
            else:
                desc_parts.append(line)
                continue
        # paragraph-indent directive lines, alone on a line: start a
        # reflowable prose paragraph.
        if re.fullmatch(r"\{p(?:std|more2?|hang2?)\}(?:\{\.\.\.\})?", stripped):
            flush_all()
            mode = "prose"
            continue
        if re.fullmatch(r"\{p \d+ \d+ \d+\}(?:\{\.\.\.\})?", stripped):
            flush_all()
            mode = "prose"
            continue
        # {p2colset ...}/{p2colreset}: pure column-width setup, no content of
        # their own - {p2colreset} also closes out the current bullet group.
        if re.fullmatch(r"\{p2colset[^{}]*\}(?:\{\.\.\.\})?", stripped):
            flush_para()
            flush_verbatim()
            continue
        if re.fullmatch(r"\{p2colreset\}(?:\{\.\.\.\})?", stripped):
            flush_list()
            continue
        # {p2col:label}desc{p_end} or {p2col # # # #:label}desc{p_end}: one
        # bullet/definition-list item. Uses balanced-brace matching for the
        # label (often itself a nested tag, e.g. {bf:e(N)}) and a plain
        # search for the closing {p_end}, mirroring the {cmd:} handling below.
        p2col_m = re.match(r"\{p2col(?:\s+[\d ]+)?:", stripped)
        if p2col_m:
            flush_para()
            flush_verbatim()
            label_content, after = read_balanced(stripped, 0)
            label = label_content[len(p2col_m.group(0)) - 1 :]
            rest = stripped[after:]
            label_i = inline(label).strip()
            pend_idx = rest.find("{p_end}")
            if pend_idx != -1:
                finalize_p2col(label_i, [rest[:pend_idx]])
            else:
                p2col_open = (label_i, [rest])
            continue
        # example command lines: a whole line consisting of {cmd:. text},
        # optionally followed by a trailing {p_end}. Uses real balanced-brace
        # matching (not a greedy regex) since the command text itself often
        # contains further {cmd:}/{it:} fragments with their own braces.
        if stripped.startswith("{cmd:"):
            content, after = read_balanced(stripped, 0)
            inner = content[len("cmd:") :]
            remainder = stripped[after:].strip()
            if remainder in ("", "{p_end}"):
                flush_para()
                flush_verbatim()
                flush_list()
                code_buf.append(plain(inner))
                continue
            # a handful of source files have a stray literal brace outside
            # the {cmd:...} tag (a typo for {c -(}/{c )-}) - keep it verbatim
            if re.fullmatch(r"[{}]*", remainder):
                flush_para()
                flush_verbatim()
                flush_list()
                code_buf.append(plain(inner) + remainder)
                continue
        if stripped == "":
            flush_all()
            mode = None
            continue
        if mode == "prose":
            flush_code()
            flush_verbatim()
            flush_list()
            para_buf.append(line)
        else:
            flush_code()
            flush_para()
            flush_list()
            verbatim_buf.append(line)
    flush_all()
    # collapse extra blank lines
    md = "\n".join(out)
    md = re.sub(r"\n{3,}", "\n\n", md)
    return md.strip()


def parse_syntax_and_options(raw: str):
    """Split the Syntax section into (usage_text, [(group, [(opt, desc)])])."""
    # usage block: from start up to first {synoptset...} or {syntab:...} or {synopt:
    idx = re.search(r"\{synoptset|\{syntab:|\{synopt:", raw)
    usage_raw = raw[: idx.start()] if idx else raw
    usage = plain(usage_raw)
    usage = re.sub(r"\n{2,}", "\n", usage).strip()

    groups = []
    current_group = None
    current_rows = []
    tag_re = re.compile(r"\{(syntab|synopt):")
    pos = 0
    n = len(raw)
    while True:
        m = tag_re.search(raw, pos)
        if not m:
            break
        kind = m.group(1)
        content, after = read_balanced(raw, m.start())
        inner = content[len(kind) + 1 :]
        if kind == "syntab":
            if current_group is not None or current_rows:
                groups.append((current_group, current_rows))
            current_group = inline(inner)
            current_rows = []
            pos = after
        else:
            opt = inline(inner)
            pend = raw.find("{p_end}", after)
            if pend == -1:
                desc_raw = raw[after:]
                pos = n
            else:
                desc_raw = raw[after:pend]
                pos = pend + len("{p_end}")
            desc = inline(desc_raw)
            current_rows.append((opt, desc))
    if current_group is not None or current_rows:
        groups.append((current_group, current_rows))
    return usage, groups


def options_table_md(groups):
    if not groups:
        return ""
    out = []
    for group, rows in groups:
        if not rows:
            continue
        if group:
            out.append(f"**{group}**")
            out.append("")
        out.append("| | |")
        out.append("|---|---|")
        for opt, desc in rows:
            opt_cell = opt.replace("|", "\\|")
            desc_cell = desc.replace("|", "\\|")
            out.append(f"| {opt_cell} | {desc_cell} |")
        out.append("")
    return "\n".join(out).strip()


SECTION_ORDER = [
    "Description",
    "Options",
    "Remarks",
    "Examples",
    "Performance",
    "Supported network types",
    "Stored results",
    "References",
    "See also",
]


def convert_file(path: Path):
    text = path.read_text(errors="replace")
    stem = path.stem

    title_m = re.search(r"\{p2col\s*:\s*(\S+)\s*\{hline\s*\d*\}\}(.*?)\{p_end\}", text)
    if title_m:
        cmd_name = plain(title_m.group(1))
        short_desc = inline(title_m.group(2))
    else:
        cmd_name, short_desc = stem, ""

    fm_desc = short_desc.replace('"', "'")
    front_matter = [
        "---",
        f'title: "{cmd_name}"',
        'parent: "Command reference"',
        "nav_exclude: true",
        "search_exclude: false",
    ]
    if fm_desc:
        front_matter.append(f'description: "{fm_desc}"')
    front_matter.append("---")
    md = front_matter + ["", f"# `{cmd_name}`", ""]
    if short_desc:
        md.append(short_desc)
        md.append("")

    syntax_raw = get_section(text, "Syntax")
    if syntax_raw:
        usage, groups = parse_syntax_and_options(syntax_raw)
        md.append("## Syntax")
        md.append("")
        md.append("```stata")
        md.append(usage)
        md.append("```")
        md.append("")
        opt_md = options_table_md(groups)
        if opt_md:
            md.append(opt_md)
            md.append("")

    for section in SECTION_ORDER:
        raw = get_section(text, section)
        if raw is None:
            continue
        body = paragraphs_to_md(raw)
        if not body:
            continue
        md.append(f"## {section}")
        md.append("")
        md.append(body)
        md.append("")

    return cmd_name, short_desc, "\n".join(md).strip() + "\n"


def parse_topical(path: Path):
    text = path.read_text(errors="replace")
    title_map = {
        "concept": "Concepts",
        "import": "Import / Export",
        "generator": "Generators",
        "information": "Information",
        "manipulation": "Manipulation",
        "utilities": "Utilities",
        "visualization": "Visualization",
        "programming": "Programming",
        "uncategorized": "Uncategorized",
    }
    order = ["concept", "import", "generator", "information", "manipulation",
             "analysis", "utilities", "visualization", "programming", "uncategorized"]

    blocks = re.split(r"\{marker\s+([a-zA-Z_]+)\}\{\.\.\.\}", text)
    # blocks[0] is preamble; then alternating id, content
    sections = {}
    for i in range(1, len(blocks), 2):
        mid = blocks[i]
        content = blocks[i + 1] if i + 1 < len(blocks) else ""
        title_match = re.search(r"\{it:([^{}]*)\}", content)
        section_title = inline(title_match.group(1)) if title_match else title_map.get(mid, mid)
        rows = re.findall(
            r"\{p2col:\s*\{bf:\{help\s+(\S+?)\s*\}\}\}(.*?)\{p_end\}", content, re.S
        )
        cmds = [(c.strip(), inline(d)) for c, d in rows]
        sections[mid] = (section_title, cmds)

    top = {"analysis": ("Analysis", [])}
    tree = []
    for key in order:
        if key not in sections and key != "analysis":
            continue
        if key == "analysis":
            subs = [(k, v) for k, v in sections.items() if k.startswith("analysis_")]
            tree.append(("Analysis", None, subs))
        else:
            title, cmds = sections[key]
            tree.append((title, cmds, None))
    return tree


def main():
    tree = parse_topical(REPO / "nw_topical.sthlp")

    all_cmds_seen = set()
    for title, cmds, subs in tree:
        if subs:
            for _, (subtitle, subcmds) in subs:
                for c, _ in subcmds:
                    all_cmds_seen.add(c)
        else:
            for c, _ in (cmds or []):
                all_cmds_seen.add(c)

    index_lines = [
        "---",
        'title: "Command reference"',
        "nav_order: 3",
        "has_children: false",
        "---",
        "",
        "# Command reference",
        "",
        "All nwcommands commands, grouped as in `help nw_topical`.",
        "",
    ]

    for title, cmds, subs in tree:
        index_lines.append(f"## {title}")
        index_lines.append("")
        if subs:
            for sub_id, (subtitle, subcmds) in subs:
                index_lines.append(f"### {subtitle}")
                index_lines.append("")
                for c, desc in subcmds:
                    index_lines.append(f"- [`{c}`]({c}.md) --- {desc}" if desc else f"- [`{c}`]({c}.md)")
                index_lines.append("")
        else:
            for c, desc in (cmds or []):
                index_lines.append(f"- [`{c}`]({c}.md) --- {desc}" if desc else f"- [`{c}`]({c}.md)")
            index_lines.append("")

    uncategorized = sorted(KNOWN - all_cmds_seen)
    if uncategorized:
        index_lines.append("## Uncategorized")
        index_lines.append("")
        for c in uncategorized:
            index_lines.append(f"- [`{c}`]({c}.md)")
        index_lines.append("")

    (REF_OUT / "index.md").write_text("\n".join(index_lines).strip() + "\n")

    n_ok, n_err = 0, 0
    for f in STHLP_FILES:
        try:
            cmd_name, short_desc, md = convert_file(f)
            (REF_OUT / f"{f.stem}.md").write_text(md)
            n_ok += 1
        except Exception as e:
            print(f"FAILED {f.name}: {e}", file=sys.stderr)
            n_err += 1
    print(f"Converted {n_ok} files, {n_err} failures.")


if __name__ == "__main__":
    main()

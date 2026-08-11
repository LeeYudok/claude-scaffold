#!/usr/bin/env python3
"""PostToolUse(Bash) hook — 커밋된 .ts/.go/.py 파일의 Cognitive Complexity 추정 경고.
함수당 CC > THRESHOLD 이면 hookSpecificOutput.additionalContext 로 경고 주입."""
import re, subprocess, sys, json, os

THRESHOLD = 15

def get_staged_files():
    try:
        r = subprocess.run(
            ["git", "diff", "--cached", "--name-only"],
            capture_output=True, text=True,
            cwd=os.environ.get("CLAUDE_PROJECT_DIR", "."),
        )
        return [
            f for f in r.stdout.strip().split("\n") if f
            and any(f.endswith(e) for e in (".ts", ".tsx", ".go", ".py"))
            and "node_modules" not in f and "__pycache__" not in f
        ]
    except Exception:
        return []

CC_BRANCH = re.compile(r'\b(?:if|else\s+if|for|while|switch|case|catch|select)\b|\?\?|&&|\|\||\?(?=[^?])')
FUNC_TS   = re.compile(r'(?:export\s+)?(?:async\s+)?function\s+(\w+)|(?:const|let)\s+(\w+)\s*=\s*(?:async\s*)?\(')
FUNC_GO   = re.compile(r'^func\s+(?:\([^)]+\)\s+)?(\w+)', re.MULTILINE)
FUNC_PY   = re.compile(r'^(?:async\s+)?def\s+(\w+)', re.MULTILINE)

def strip_strings(code):
    code = re.sub(r'`[^`]*`|"[^"]*"|\'[^\']*\'', '""', code)
    return code

def calc_cc(funcs, lines, start_map=None):
    warnings = []
    for idx, (name, start) in enumerate(funcs):
        end = funcs[idx + 1][1] if idx + 1 < len(funcs) else len(lines)
        body = strip_strings("\n".join(lines[start:end]))
        cc = len(CC_BRANCH.findall(body))
        if cc > THRESHOLD:
            warnings.append(f"  {name}() CC~{cc} (L{start + 1})")
    return warnings

def check_file(path):
    try:
        with open(os.path.join(os.environ.get("CLAUDE_PROJECT_DIR", "."), path)) as fh:
            content = fh.read()
    except FileNotFoundError:
        return []
    lines = content.split("\n")
    if path.endswith((".ts", ".tsx")):
        funcs = [(m.group(1) or m.group(2), i) for i, l in enumerate(lines) for m in [FUNC_TS.search(l)] if m]
    elif path.endswith(".go"):
        funcs = [(m.group(1), i) for i, l in enumerate(lines) for m in [FUNC_GO.match(l)] if m]
    elif path.endswith(".py"):
        funcs = [(m.group(1), i) for i, l in enumerate(lines) for m in [FUNC_PY.match(l)] if m]
    else:
        return []
    return calc_cc(funcs, lines)

def main():
    # stdin guard: only fire on git commit
    raw = sys.stdin.read()
    if "git commit" not in raw:
        return
    files = get_staged_files()
    if not files:
        return
    all_warnings = []
    for f in files:
        w = check_file(f)
        if w:
            all_warnings.append(f"  [{f}]")
            all_warnings.extend(w)
    if all_warnings:
        msg = "[CC Check] High-complexity functions — refactoring recommended:\n" + "\n".join(all_warnings)
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": msg,
            }
        }))

if __name__ == "__main__":
    main()

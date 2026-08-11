#!/usr/bin/env bash
# PostToolUse hook — 세션 관찰 로그 (instinct-lite).
# 툴 호출을 .claude/memory/observations/<session>.jsonl 에 압축 기록한다.
# Stop 훅(stop-memory-remind.sh)이 이 로그를 근거로 습관(instinct) 추출을 유도한다.
# ECC continuous-learning-v2 의 경량판 — 백그라운드 관찰자 없음, 순수 stdlib.
set -uo pipefail

input="$(cat)"
[ -z "$input" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-.}"
dir="$root/.claude/memory/observations"
mkdir -p "$dir" 2>/dev/null || exit 0

# 7일 지난 로그 정리 (하루 1회)
marker="$dir/.last-prune"
if [ ! -f "$marker" ] || [ -n "$(find "$marker" -mtime +1 2>/dev/null)" ]; then
  find "$dir" -name "*.jsonl" -mtime +7 -delete 2>/dev/null || true
  touch "$marker" 2>/dev/null || true
fi

printf '%s' "$input" | python3 -c '
import json, sys, os, re, datetime

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

sid = (d.get("session_id") or "nosession")[:32]
tool = d.get("tool_name") or "unknown"
ti = d.get("tool_input") or {}

# 요약: Bash 는 command 앞부분, 파일 툴은 경로만 — 원문 전체 저장 금지
if tool == "Bash":
    summary = str(ti.get("command", ""))[:200]
else:
    summary = str(ti.get("file_path", ti.get("pattern", "")))[:200]

# 시크릿 마스킹 (bounded, 재앙적 백트래킹 방지)
summary = re.sub(
    r"(?i)(api[_-]?key|token|secret|password|authorization|auth)"
    r"([\"\x27\s:=]{1,8})((?:bearer|basic|token|bot)\s+)?[A-Za-z0-9_\-/.+=]{8,256}",
    r"\1\2\3[REDACTED]", summary)

resp = d.get("tool_response")
err = bool(isinstance(resp, dict) and (resp.get("is_error") or resp.get("error")))

path = os.path.join(sys.argv[1], f"{sid}.jsonl")
# 세션당 2MB 상한 — 초과 시 조용히 중단(관찰은 best-effort)
if os.path.exists(path) and os.path.getsize(path) > 2 * 1024 * 1024:
    sys.exit(0)

line = json.dumps({
    "ts": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    "tool": tool, "summary": summary, "err": err,
}, ensure_ascii=False)
with open(path, "a") as f:
    f.write(line + "\n")
' "$dir" 2>/dev/null || true

exit 0

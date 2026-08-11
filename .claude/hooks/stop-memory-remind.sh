#!/usr/bin/env bash
# Stop hook — 세션당 1회, 비자명한 학습을 .claude/memory/ 에 저장했는지 리마인드.
set -uo pipefail

input="$(cat)"
sid="$(printf '%s' "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null || true)"
[ -z "$sid" ] && sid="nosession"

f="/tmp/claude_memsync_${sid}"
[ -f "$f" ] && exit 0
touch "$f"

reason="세션 종료 전 점검(세션당 1회): 이번 세션에서 새로 알게 된 비자명한 학습 — 인프라 함정·반복될 디버깅 근본원인·사용자 선호·외부 리소스 포인터 — 을 .claude/memory/ 에 파일로 저장하고 MEMORY.md 인덱스에 1줄 추가했는지 확인하라. 코드·git 이력·AGENTS.md 가 이미 기록하는 것은 제외. 이미 저장했거나 저장할 새 학습이 없으면 그대로 종료해도 된다."

# instinct-lite: 이 세션의 관찰 로그가 충분하면 습관(instinct) 추출도 유도
# (observe-lite.sh 가 session_id 를 32자로 잘라 기록하므로 동일하게 잘라 조회)
obs="${CLAUDE_PROJECT_DIR:-.}/.claude/memory/observations/${sid:0:32}.jsonl"
if [ -f "$obs" ] && [ "$(wc -l < "$obs" 2>/dev/null || echo 0)" -ge 20 ]; then
  reason="$reason

추가(instinct-lite): 관찰 로그 ${obs} 를 훑어 반복 패턴 — 같은 에러의 반복 해결, 사용자 교정 후 정착된 방식, 반복 워크플로 — 이 있으면 instinct_<slug>.md 로 저장하라(frontmatter 에 trigger/confidence 0.3~0.9/evidence, 본문에 행동 1개). 이미 있는 instinct 와 겹치면 confidence 만 갱신. 반복 패턴이 없으면 생략."
fi

python3 -c "
import json, sys
reason = sys.argv[1]
print(json.dumps({'decision': 'block', 'reason': reason}))
" "$reason" 2>/dev/null || printf '{"decision":"block","reason":"세션 종료 전: 새로 알게 된 학습을 .claude/memory/ 에 저장했는지 확인. 없으면 그냥 종료."}\n'

# /knowledge-graph — .claude 지식 그래프 재생성·열람

AGENTS.md 생태계(rules·memory·agents·skills·commands·workflows)의 연결 구조를
1장의 대시보드로 뽑는다. 온보딩·문서 정합성 점검용.

## 절차

1. **생성**:
   ```bash
   python3 .claude/scripts/knowledge_graph.py
   ```
   `docs/knowledge-graph.html` 갱신 (노드·간선·깨진 링크 수를 stdout 으로 보고).

2. **열람** — 로컬 정적 서빙:
   ```bash
   python3 -m http.server -d docs 8899
   ```
   → http://localhost:8899/knowledge-graph.html (팬/줌/드래그, 노드 클릭 = 참조/피참조 상세)

3. **링크 정합성만 빠르게** (깨진 링크 있으면 exit 1 — CI 게이트로 사용 가능):
   ```bash
   python3 .claude/scripts/knowledge_graph.py --check
   ```

## 주의

- HTML 은 생성 시점 스냅샷 — 문서 구조를 바꿨으면 재생성 후 함께 커밋.
- 갱신 커밋은 이슈 없이도 가능하나 main 직접 커밋 금지(브랜치+PR/MR).

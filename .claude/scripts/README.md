# scripts/ — 레포 로컬 헬퍼 스크립트

템플릿에 동봉되어 커맨드/스킬이 호출하는 헬퍼 스크립트 (**훅 아님** — 훅은 `../hooks/`
에 있고 `settings.json` 으로 연결된다).

동봉:
- `knowledge_graph.py` — `.claude` 생태계에서 `docs/knowledge-graph.html` 생성;
  `--check` 모드는 깨진 링크 게이트 (`/knowledge-graph` 커맨드 참고).

컨벤션: stdlib 전용 Python(외부 라이브러리·xml/pyexpat 금지) 또는 POSIX shell;
레포 루트에서 실행 가능하게 유지; 신규 스크립트는 서술적 이름 사용.

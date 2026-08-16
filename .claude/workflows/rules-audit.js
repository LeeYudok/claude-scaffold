// 규칙 감사 워크플로 — 템플릿 예제. 특정 룰셋에 특화할 때는 `{{PROJECT_NAME}}-` prefix 로
// 개명해서 사용 (workflows/README.md 참고).
// 대상 파일을 .claude/rules/*.md 룰 파일 기준으로 병렬 감사 → 반박 검증(오탐 제거) → 이슈 초안,
// repair 옵션 시 확정 위반을 스스로 수정·빌드검증·PR/MR 제출까지 수행한다(머지는 하지 않음).
// 호출: Workflow {name: "rules-audit", args: ["src/pages", ...]}              — 감사만
//       Workflow {name: "rules-audit", args: {repair: true}}                  — 전체 감사 + 자가 수정
//       Workflow {name: "rules-audit", args: {targets: [...], rule: ".claude/rules/security.md", repair: true}}
// args/targets 생략 시 감사 대상을 첫 에이전트가 직접 발굴한다.
export const meta = {
  name: 'rules-audit',
  description: '.claude/rules/ 룰 파일 기준으로 대상 파일을 감사·반박검증하고, repair 옵션 시 확정 위반을 자가 수정해 PR/MR 까지 제출 — 머지는 사람 게이트',
  whenToUse: '규칙 위반 전수 점검이 필요할 때 (신규 룰 도입 직후, 릴리즈 전 감사). 수정까지 맡기려면 args {repair: true}',
  phases: [
    { title: 'Discover', detail: '감사 대상과 룰 파일 수집' },
    { title: 'Scan', detail: '대상별 병렬 감사' },
    { title: 'Verify', detail: '위반 의심건 반박 검증' },
    { title: 'Synthesize', detail: '확정건을 이슈 초안으로 병합' },
    { title: 'Repair', detail: '(repair 옵션) 이슈·worktree 준비 후 위반 수정' },
    { title: 'Verify-Build', detail: '(repair 옵션) 프로젝트 빌드/테스트 게이트 실행' },
    { title: 'Submit', detail: '(repair 옵션) 커밋·푸시·PR/MR 제출 — 머지 안 함' },
  ],
}

const FINDINGS = {
  type: 'object',
  required: ['violations'],
  properties: {
    violations: {
      type: 'array',
      items: {
        type: 'object',
        required: ['file', 'rule', 'detail'],
        properties: {
          file: { type: 'string' },
          line: { type: 'number' },
          rule: { type: 'string' },
          detail: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT = {
  type: 'object',
  required: ['real', 'reason'],
  properties: { real: { type: 'boolean' }, reason: { type: 'string' } },
}

// args 계약: 배열(targets) | {targets?, rule?, repair?} | 생략
const opts = Array.isArray(args) ? { targets: args } : (args || {})
const repair = !!opts.repair
const ruleFile = opts.rule || null

phase('Discover')
let targets = Array.isArray(opts.targets) && opts.targets.length ? opts.targets : null
const discovered = await agent(
  '이 레포에서 규칙 감사를 준비하라. ' +
    (ruleFile
      ? `룰 파일은 ${ruleFile} — frontmatter "paths:" glob 을 읽어라. `
      : '가장 적합한 .claude/rules/*.md 룰 파일("paths:" frontmatter 가 있는 것)을 고르고 glob 을 읽어라. ') +
    (targets
      ? `감사 대상은 이미 정해졌다: ${JSON.stringify(targets)} — 룰 파일만 확정하라. `
      : '그 glob 에 매칭되는 디렉터리/파일을 감사 대상 단위로 나열하라(엔트리당 라우트/모듈 1개, 테스트 파일 제외). ') +
    '룰 파일 경로와 대상 목록을 반환하라.',
  {
    label: 'discover:targets',
    phase: 'Discover',
    effort: 'low',
    schema: {
      type: 'object',
      required: ['rule', 'targets'],
      properties: {
        rule: { type: 'string' },
        targets: { type: 'array', items: { type: 'string' } },
      },
    },
  },
)
const rule = ruleFile || discovered.rule
targets = targets || discovered.targets
log(`감사 대상 ${targets.length}개, 기준 ${rule}${repair ? ' (자가 수정 모드)' : ''}`)

const results = await pipeline(
  targets,
  target =>
    agent(
      `${target} 를 룰 파일 ${rule} 기준으로 감사하라. ` +
        '룰 파일을 먼저 읽고 P0/P1 항목만 체크하라. ' +
        '위반만 보고하고, 룰 파일이 예외로 명시한 것은 넣지 마라.',
      { label: `scan:${target}`, phase: 'Scan', schema: FINDINGS, effort: 'low' },
    ),
  (found, target) =>
    parallel(
      found.violations.map(v => () =>
        agent(
          `다음 규칙 위반 주장을 반박하라: ${v.file}${v.line ? ':' + v.line : ''} — ${v.rule}: ${v.detail}. ` +
            `파일을 직접 읽고 ${rule} 의 원문과 예외 조항을 확인해, ` +
            '예외에 해당하거나 사실과 다르면 real=false. 불확실하면 real=false.',
          { label: `verify:${v.file}`, phase: 'Verify', schema: VERDICT },
        ).then(verdict => ({ ...v, target, verdict })),
      ),
    ),
)

const confirmed = results
  .flat()
  .filter(Boolean)
  .filter(f => f.verdict && f.verdict.real)
log(`위반 확정 ${confirmed.length}건`)

if (!confirmed.length) return { confirmed: [], draft: null }

phase('Synthesize')
const draft = await agent(
  '다음 규칙 위반 확정 목록을 이슈 초안(표준 톤)으로 정리하라. ' +
    '같은 파일·같은 규칙은 묶고, 제목·본문(위반 표 포함)·예상 수정 방향을 작성. ' +
    '이슈를 실제로 등록하지는 마라: ' +
    JSON.stringify(confirmed),
  { phase: 'Synthesize' },
)

if (!repair) return { confirmed, draft }

// ---------- Self-Repair — 수정·검증·PR/MR 까지. 머지는 절대 하지 않는다(사람 게이트). ----------

phase('Repair')
// 1) 이슈 등록 + 전용 worktree — 이후 단계가 같은 작업 공간을 순차 사용한다.
const setup = await agent(
  '이 레포에서 자가 수정 준비를 하라. ' +
    '① .claude/rules/forge.md 기준 forge CLI 로 다음 초안으로 이슈 생성 ' +
    '(gh issue create / glab issue create; 큰 본문은 파일 경유). 초안: ' +
    JSON.stringify(typeof draft === 'string' ? draft.slice(0, 4000) : draft) +
    ' ② 발번된 이슈 번호 N 으로 git worktree add ../{{PROJECT_NAME}}-rules-repair-N -b fix/issue-N-rules-audit ' +
    '(정식 클론에서 checkout 금지). 이슈 번호·worktree 절대경로·브랜치명을 반환하라.',
  {
    label: 'repair:setup',
    phase: 'Repair',
    schema: {
      type: 'object',
      required: ['issue', 'worktree', 'branch'],
      properties: {
        issue: { type: 'number' },
        worktree: { type: 'string' },
        branch: { type: 'string' },
      },
    },
  },
)
log(`수정 이슈 #${setup.issue}, worktree ${setup.worktree}`)

// 2) 위반 수정 — 단일 sdlc-developer 가 순차 수정(같은 worktree 병렬 편집 레이스 방지).
const fixed = await agent(
  `worktree ${setup.worktree} 안에서(그 밖 절대 수정 금지) 다음 규칙 위반들을 수정하라. ` +
    `기준은 ${rule} — 최소 diff 로, 위반과 무관한 리팩토링 금지. ` +
    '수정한 파일 목록과 각 위반의 처리 결과(fixed/skip+사유)를 반환하라. 위반 목록: ' +
    JSON.stringify(confirmed),
  {
    label: 'repair:fix',
    phase: 'Repair',
    agentType: 'sdlc-developer',
    schema: {
      type: 'object',
      required: ['files', 'outcomes'],
      properties: {
        files: { type: 'array', items: { type: 'string' } },
        outcomes: { type: 'array', items: { type: 'string' } },
      },
    },
  },
)
log(`수정 파일 ${fixed.files.length}개`)

phase('Verify-Build')
const build = await agent(
  `worktree ${setup.worktree} 에서 프로젝트의 타입체크/테스트 게이트를 실행하고 ` +
    '(.claude/hooks/pre-commit.sh 의 스택 게이트가 기준; 의존성 없으면 먼저 설치) ' +
    '통과 여부와 실패 시 에러 요약을 보고하라. 코드는 수정하지 마라.',
  {
    label: 'repair:verify',
    phase: 'Verify-Build',
    agentType: 'sdlc-verifier',
    schema: {
      type: 'object',
      required: ['passed', 'summary'],
      properties: { passed: { type: 'boolean' }, summary: { type: 'string' } },
    },
  },
)

if (!build.passed) {
  log('빌드/테스트 실패 — PR/MR 생략, worktree 보존')
  return {
    confirmed,
    issue: setup.issue,
    repaired: false,
    worktree: setup.worktree,
    buildFailure: build.summary,
  }
}

phase('Submit')
const mr = await agent(
  `worktree ${setup.worktree} 에서 다음을 수행하라: ` +
    `① 수정 파일만 명시 나열해 git add (git add -A / 디렉터리 금지): ${JSON.stringify(fixed.files)} ` +
    `② 커밋 메시지 "style(#${setup.issue}): 규칙 위반 자가 수정 (rules-audit self-repair)" ` +
    '+ 본문에 처리 결과 요약, 끝에 "Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" ' +
    `③ git push -u origin ${setup.branch} ` +
    `④ .claude/rules/forge.md 기준 forge CLI 로 PR/MR 생성 — 제목 "style(#${setup.issue}): 규칙 위반 자가 수정", ` +
    `본문 "Closes #${setup.issue}" + 자동 수정이므로 머지 전 사람 리뷰 필수라는 주석 ` +
    '⑤ **절대 머지하지 마라.** PR/MR URL 을 반환하라.',
  {
    label: 'repair:mr',
    phase: 'Submit',
    schema: {
      type: 'object',
      required: ['mrUrl'],
      properties: { mrUrl: { type: 'string' } },
    },
  },
)
log(`PR/MR 제출 완료(머지 대기): ${mr.mrUrl}`)

return {
  confirmed,
  issue: setup.issue,
  repaired: true,
  files: fixed.files,
  outcomes: fixed.outcomes,
  mrUrl: mr.mrUrl,
  note: '머지는 수행하지 않음 — PR/MR 리뷰(CI + 코드리뷰 + 육안) 후 사람이 머지',
}

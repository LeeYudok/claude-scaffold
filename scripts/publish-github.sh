#!/usr/bin/env bash
# GitHub 공개용 fresh-history 브랜치 생성 스크립트 (#8)
#
# 목적: 개인 이메일이 섞인 기존 커밋 히스토리를 공개 저장소에 노출하지 않기 위해,
#       현재 main 의 트리 스냅샷만으로 부모 없는 단일 커밋을 만들어
#       publish/github 브랜치를 (재)생성한다. LICENSE/내부참조 정리가 계속 진행 중이라
#       main 이 바뀔 때마다 재실행 가능해야 하므로 워킹트리를 건드리지 않는
#       commit-tree 방식을 쓴다 (orphan checkout 은 워킹트리를 오염시켜 재실행에 부적합).
#
# 사용법:
#   scripts/publish-github.sh                              # publish/github 로컬 (재)생성만
#   scripts/publish-github.sh --push git@github.com:org/repo.git   # 생성 후 해당 리모트로 push
#
# 환경변수:
#   PUBLISH_EMAIL  커밋 author/committer 이메일 오버라이드 (기본: leeyudok@users.noreply.github.com)
#   PUBLISH_NAME   커밋 author/committer 이름 오버라이드 (기본: leeyudok — 공개 핸들)

set -euo pipefail

SOURCE_BRANCH="main"
TARGET_BRANCH="publish/github"
PUBLISH_EMAIL="${PUBLISH_EMAIL:-leeyudok@users.noreply.github.com}"
PUBLISH_NAME="${PUBLISH_NAME:-leeyudok}"
PUSH_REMOTE_URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --push)
      PUSH_REMOTE_URL="${2:?--push 옵션에는 리모트 URL 이 필요함}"
      shift 2
      ;;
    *)
      echo "알 수 없는 옵션: $1" >&2
      exit 1
      ;;
  esac
done

# 개인 이메일 유출 방지 가드 — noreply 도메인이 아니면 중단
if [[ "$PUBLISH_EMAIL" != *"@users.noreply.github.com" ]]; then
  echo "PUBLISH_EMAIL 은 반드시 @users.noreply.github.com 도메인이어야 함: $PUBLISH_EMAIL" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

echo "== source 브랜치 확인: ${SOURCE_BRANCH} =="
if ! git rev-parse --verify "${SOURCE_BRANCH}" >/dev/null 2>&1; then
  echo "브랜치 ${SOURCE_BRANCH} 가 없음" >&2
  exit 1
fi

tree_sha="$(git rev-parse "${SOURCE_BRANCH}^{tree}")"
echo "== ${SOURCE_BRANCH} 트리: ${tree_sha} =="

# 내부 전용 파일 제외 (#26): .gitlab-ci.yml 은 self-hosted 러너 태그가 박힌 내부 CI 설정.
# 공개 트리에서는 GitHub Actions(.github/workflows/test.yml)가 CI 를 담당하므로 제거한다.
# 워킹트리를 건드리지 않기 위해 임시 인덱스에서 read-tree → rm --cached → write-tree.
# publish-github.sh 자신도 제외(#39): 내부 참조 가드 패턴(내부 호스트/IP 평문)을 담은
# 운영 스크립트라 공개 트리에 실릴 이유가 없고, 실리면 그 패턴 자체가 유출된다.
INTERNAL_ONLY_FILES=(".gitlab-ci.yml" "scripts/publish-github.sh")

echo "== 내부 전용 파일 제외한 publish 트리 생성 =="
tmp_index="$(mktemp)"
trap 'rm -f "$tmp_index"' EXIT
GIT_INDEX_FILE="$tmp_index" git read-tree "${tree_sha}"
GIT_INDEX_FILE="$tmp_index" git rm --cached -q --ignore-unmatch -- "${INTERNAL_ONLY_FILES[@]}"
publish_tree="$(GIT_INDEX_FILE="$tmp_index" git write-tree)"
echo "== publish 트리: ${publish_tree} =="

# 내부 참조 가드 (#26): publish 트리에 내부 호스트/그룹/IP 문자열이 남아 있으면 중단.
# 패턴을 늘릴 땐 공개해도 되는 일반 명사와 충돌하지 않는지 확인할 것.
# 이 스크립트 자신은 패턴 정의를 담고 있어 스캔에서 제외한다(self-match 방지).
INTERNAL_PATTERNS='doksam|gimje|busan/claude-scaffold|192\.168\.|220\.82\.|(^|[^0-9.])10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|(^|[^0-9.])172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}'

echo "== 내부 참조 가드 스캔 =="
if git grep -I -n -E "${INTERNAL_PATTERNS}" "${publish_tree}" -- .; then
  echo "내부 참조가 publish 트리에 남아 있음 — 중단" >&2
  exit 1
fi
echo "== 가드 통과: 내부 참조 없음 =="

commit_message="claude-scaffold: Claude Code .claude/ bootstrap template

Reusable Claude Code project bootstrap: agents, skills, hooks,
and rule presets for multi-stack repos."

echo "== 부모 없는 단일 커밋 생성 =="
new_sha="$(
  GIT_AUTHOR_NAME="${PUBLISH_NAME}" \
  GIT_AUTHOR_EMAIL="${PUBLISH_EMAIL}" \
  GIT_COMMITTER_NAME="${PUBLISH_NAME}" \
  GIT_COMMITTER_EMAIL="${PUBLISH_EMAIL}" \
  git commit-tree "${publish_tree}" -m "${commit_message}"
)"
echo "== 생성된 커밋: ${new_sha} =="

echo "== ${TARGET_BRANCH} 브랜치 (재)생성 =="
git branch -f "${TARGET_BRANCH}" "${new_sha}"

echo
echo "결과 브랜치: ${TARGET_BRANCH}"
echo "결과 SHA:    ${new_sha}"
echo
echo "검증 방법:"
echo "  git log ${TARGET_BRANCH} --format='%an %ae %s'"
echo "  git diff ${SOURCE_BRANCH} ${TARGET_BRANCH} --stat   # 내부 전용 파일(${INTERNAL_ONLY_FILES[*]}) 삭제만 보여야 함"

if [[ -n "${PUSH_REMOTE_URL}" ]]; then
  echo
  echo "== ${PUSH_REMOTE_URL} 로 push =="
  git push "${PUSH_REMOTE_URL}" "${TARGET_BRANCH}:main"
fi

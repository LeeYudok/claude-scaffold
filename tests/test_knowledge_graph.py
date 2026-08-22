#!/usr/bin/env python3
"""knowledge_graph.py 유닛테스트 (#37) — stdlib unittest 전용.

링크 체커는 머지 게이트(.gitlab-ci.yml → bats 17/18)라서 파서가 조용히 덜 잡으면
깨진 링크가 통과한다. bats 는 --check 의 exit code 만 간접 확인하므로, 여기서
파싱·해석 로직을 픽스처 트리 기반으로 직접 검증한다.

실행: python3 -m unittest discover -s tests -p 'test_*.py'
"""
import importlib.util
import os
import sys

# .claude 트리에 __pycache__(.pyc 바이너리)를 남기면 스캐폴드 sed 가 전멸한다(#37)
sys.dont_write_bytecode = True
import shutil
import subprocess
import tempfile
import unittest

REPO_ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SCRIPT = os.path.join(REPO_ROOT, ".claude", "scripts", "knowledge_graph.py")


def load_module(repo_dir):
    """스크립트를 독립 모듈로 로드하고 REPO 를 픽스처 디렉터리로 오버라이드."""
    spec = importlib.util.spec_from_file_location("kg_under_test", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.REPO = repo_dir
    return mod


def write(base, relpath, content):
    p = os.path.join(base, relpath)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write(content)


class FixtureCase(unittest.TestCase):
    def setUp(self):
        self.repo = tempfile.mkdtemp(prefix="kg-fixture-")
        self.addCleanup(shutil.rmtree, self.repo)

    def graph(self):
        return load_module(self.repo).build_graph()


class TestLinks(FixtureCase):
    def test_valid_relative_link_becomes_edge(self):
        write(self.repo, "AGENTS.md", "루트 문서. [공통 규칙](.claude/rules/common.md) 참조.")
        write(self.repo, ".claude/rules/common.md", "# 공통 규칙")
        nodes, edges, broken = self.graph()
        self.assertEqual(broken, [])
        self.assertIn(
            {"from": "AGENTS.md", "to": ".claude/rules/common.md", "kind": "link"}, edges
        )

    def test_missing_target_is_reported_broken(self):
        write(self.repo, ".claude/rules/common.md", "[없는 문서](../memory/nope.md)")
        nodes, edges, broken = self.graph()
        self.assertEqual(len(broken), 1)
        self.assertEqual(broken[0]["from"], ".claude/rules/common.md")
        self.assertEqual(broken[0]["target"], "../memory/nope.md")

    def test_existing_file_outside_graph_is_not_broken(self):
        # 그래프 스캔 대상 밖 실파일(코드 등)로의 링크는 broken 도 edge 도 아니다
        write(self.repo, ".claude/rules/common.md", "[체커](../scripts/knowledge_graph.py)")
        write(self.repo, ".claude/scripts/knowledge_graph.py", "# code")
        nodes, edges, broken = self.graph()
        self.assertEqual(broken, [])
        self.assertEqual([e for e in edges if e["kind"] == "link"], [])

    def test_gitignored_personal_memory_is_not_broken(self):
        # user_*.md 는 .claude/.gitignore 로 제외되는 개인 메모리다. MEMORY.md 가 링크하는 것이
        # 정상이고 파일 부재도 설계상 정상이므로 broken 으로 잡히면 안 된다.
        write(self.repo, ".claude/memory/MEMORY.md", "[내 머신](user_this-machine.md)")
        nodes, edges, broken = self.graph()
        self.assertEqual(broken, [])
        self.assertEqual([e for e in edges if e["kind"] == "link"], [])

    def test_missing_non_personal_memory_is_still_broken(self):
        # 위 예외가 일반 메모리까지 삼키면 안 된다.
        write(self.repo, ".claude/memory/MEMORY.md", "[없는 것](project_nope.md)")
        nodes, edges, broken = self.graph()
        self.assertEqual(len(broken), 1)
        self.assertEqual(broken[0]["target"], "project_nope.md")

    def test_links_inside_code_fence_and_inline_code_are_ignored(self):
        write(
            self.repo, ".claude/rules/common.md",
            "```\n[펜스 안](fence-only.md)\n```\n그리고 `[인라인](inline-only.md)` 도 무시.\n",
        )
        nodes, edges, broken = self.graph()
        self.assertEqual(broken, [])

    def test_external_and_anchor_links_are_ignored(self):
        write(
            self.repo, "AGENTS.md",
            "[외부](https://example.com/x.md) [메일](mailto:a@b.c) [자기앵커](#section)",
        )
        nodes, edges, broken = self.graph()
        self.assertEqual(broken, [])


class TestWikiLinksAndIssues(FixtureCase):
    def test_wiki_link_resolves_via_frontmatter_name(self):
        write(
            self.repo, ".claude/memory/project_alpha.md",
            "---\nname: alpha-note\n---\n\n[[beta-note]] 참조.\n",
        )
        write(
            self.repo, ".claude/memory/project_beta.md",
            "---\nname: beta-note\n---\n\n본문.\n",
        )
        nodes, edges, broken = self.graph()
        self.assertIn(
            {"from": ".claude/memory/project_alpha.md",
             "to": ".claude/memory/project_beta.md", "kind": "wiki"}, edges
        )

    def test_unresolved_wiki_link_is_silent_not_broken(self):
        write(self.repo, ".claude/memory/project_alpha.md", "---\nname: a\n---\n[[no-such-name]]\n")
        nodes, edges, broken = self.graph()
        self.assertEqual(broken, [])
        self.assertEqual([e for e in edges if e["kind"] == "wiki"], [])

    def test_issue_node_requires_two_or_more_files(self):
        write(self.repo, ".claude/rules/common.md", "규칙 (#42)")
        write(self.repo, ".claude/rules/security.md", "보안 규칙 (#42)")
        write(self.repo, ".claude/rules/testing.md", "테스트 규칙 (#77)")  # 단독 언급
        nodes, edges, broken = self.graph()
        node_ids = {n["id"] for n in nodes}
        self.assertIn("issue:42", node_ids)
        self.assertNotIn("issue:77", node_ids)
        self.assertEqual(len([e for e in edges if e["to"] == "issue:42"]), 2)


class TestNodeMetadata(FixtureCase):
    def test_memory_subtype_from_prefix(self):
        mod = load_module(self.repo)
        self.assertEqual(mod.memory_subtype("x/project_a.md"), "project")
        self.assertEqual(mod.memory_subtype("x/feedback_b.md"), "feedback")
        self.assertEqual(mod.memory_subtype("x/README.md"), "memory")

    def test_skill_and_readme_labels_use_directory_name(self):
        write(self.repo, ".claude/skills/grill-me/SKILL.md", "---\nname: grill-me\ndescription: d\n---\n")
        write(self.repo, ".claude/rules/README.md", "# rules")
        nodes, _, _ = self.graph()
        labels = {n["id"]: n["label"] for n in nodes}
        self.assertEqual(labels[".claude/skills/grill-me/SKILL.md"], "grill-me")
        self.assertEqual(labels[".claude/rules/README.md"], "rules/README")

    def test_observations_and_archive_dirs_are_skipped(self):
        write(self.repo, ".claude/memory/observations/log.md", "[깨진](nope.md)")
        write(self.repo, ".claude/memory/archive/old.md", "[깨진](nope.md)")
        nodes, edges, broken = self.graph()
        self.assertEqual(broken, [])
        self.assertEqual(nodes, [])


class TestCheckCli(FixtureCase):
    """--check CLI 는 스크립트 위치 기준 REPO 를 쓰므로, 스캐폴드처럼
    픽스처 안에 스크립트를 복사해 서브프로세스로 exit code 를 검증한다."""

    def run_check(self):
        dst = os.path.join(self.repo, ".claude", "scripts", "knowledge_graph.py")
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy(SCRIPT, dst)
        return subprocess.run(
            [sys.executable, dst, "--check"], capture_output=True, text=True
        )

    def test_exit_1_and_report_on_broken_link(self):
        write(self.repo, "AGENTS.md", "[없음](.claude/rules/nope.md)")
        r = self.run_check()
        self.assertEqual(r.returncode, 1)
        self.assertIn("broken link: AGENTS.md -> .claude/rules/nope.md", r.stdout)

    def test_exit_0_on_clean_tree(self):
        write(self.repo, "AGENTS.md", "[규칙](.claude/rules/common.md)")
        write(self.repo, ".claude/rules/common.md", "# ok")
        r = self.run_check()
        self.assertEqual(r.returncode, 0)
        self.assertIn("0 broken links", r.stdout)


if __name__ == "__main__":
    unittest.main()

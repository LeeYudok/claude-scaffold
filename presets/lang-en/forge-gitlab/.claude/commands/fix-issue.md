---
name: fix-issue
argument-hint: [issue-number]
---

Handle GitLab issue #$ARGUMENTS (issue-first workflow):

1. `glab issue view $ARGUMENTS` — check the issue content
2. Locate the relevant source files
3. Create a branch: `git checkout -b fix/issue-$ARGUMENTS-<summary>`
4. Implement the minimal fix + write a regression test
5. Confirm the build/tests are green (`./gradlew test` or `npm test`)
6. Commit (referencing `#$ARGUMENTS`) → push → create an MR → squash merge
7. **GitLab 19 manual close**: `glab issue note $ARGUMENTS` + `glab issue close $ARGUMENTS`

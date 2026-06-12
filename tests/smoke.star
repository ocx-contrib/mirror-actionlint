# tests/smoke.star — stable across upstream actionlint releases.
# Asserts the contract (exit code, version shape, lint pass/fail behavior),
# never help/version prose. See ocx.mirror testing-practices.md.

ACTIONLINT = "actionlint.exe" if ocx.target_platform.os == ocx.os.Windows else "actionlint"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE. The digits are
# the contract — not the vendor banner, not the exact version.
r_version = ocx.run(ACTIONLINT, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 3a: a VALID workflow lints clean -> exit 0. The file is passed
# explicitly so the check is hermetic (no .github/workflows layout needed).
ocx.write_file("good.yml", """on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo ok
""")
r_good = ocx.run(ACTIONLINT, "good.yml")
expect.ok(r_good)

# Tier 3b: a workflow with a core semantic error (a job depends on a job that
# does not exist) is rejected -> non-zero exit. Asserting the exit code, not
# the message text, keeps this stable across releases.
ocx.write_file("bad.yml", """on: push
jobs:
  build:
    runs-on: ubuntu-latest
    needs: [ghost]
    steps:
      - run: echo bad
""")
r_bad = ocx.run(ACTIONLINT, "bad.yml")
expect.ne(r_bad.exit_code, 0)

# No Tier 4: metadata.json declares PATH only (proven by Tier 1 liveness).

# actionlint/tests/smoke.star — stable across upstream actionlint releases.
# Asserts the contract (exit code, version shape, which CHECK fires), never
# help/version prose. See the create-mirror skill's testing-practices.md.

ACTIONLINT = "actionlint.exe" if ocx.target_platform.os == ocx.os.Windows else "actionlint"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE. The digits are
# the contract — not the vendor banner, not the exact version. Anchored at the
# start so the trailing "built with go1.26.1 …" line cannot satisfy it.
r_version = ocx.run(ACTIONLINT, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"^\d+\.\d+\.\d+")

# Tier 3: a hermetic .github/workflows/ project written into scratch. Files are
# passed EXPLICITLY — actionlint's own auto-discovery walks up for a Git
# repository ("no project was found in any parent directories …") and scratch
# is not one.
ocx.mkdir(".github/workflows")

# 3a — a valid workflow lints clean → exit 0.
ocx.write_file(".github/workflows/good.yml", """on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo ok
""")
r_good = ocx.run(ACTIONLINT, ".github/workflows/good.yml")
expect.ok(r_good)

# 3b — one workflow carrying two independent defects: a job that `needs:` a job
# which does not exist, and a runner label that is not a real GitHub label.
# The assertion is the RULE NAME actionlint prints in brackets, not the message
# prose around it. `job-needs` and `runner-label` are documented check names
# and are the stable tokens; verified identical at 1.7.0 (the floor) and
# 1.7.12. Two distinct rules prove the check engine actually ran, where a bare
# non-zero exit would also be satisfied by a parse failure. Diagnostics go to
# STDOUT, and colour is off whenever the stream is not a TTY.
ocx.write_file(".github/workflows/bad.yml", """on: push
jobs:
  build:
    runs-on: linux-latest
    needs: [ghost]
    steps:
      - run: echo bad
""")
r_bad = ocx.run(ACTIONLINT, ".github/workflows/bad.yml")
expect.ne(r_bad.exit_code, 0)
expect.contains(r_bad.stdout, "[job-needs]")
expect.contains(r_bad.stdout, "[runner-label]")

# No Tier 4: metadata.json declares PATH only (proven by Tier 1 liveness).

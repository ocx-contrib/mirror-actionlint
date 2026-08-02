# mirror-actionlint

OCX mirrors for [actionlint](https://github.com/rhysd/actionlint). One
repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [actionlint](https://github.com/rhysd/actionlint) | [`actionlint/mirror.yml`](actionlint/mirror.yml) | `ghcr.io/ocx-contrib/actionlint/actionlint` | `ocx.sh/actionlint/actionlint` | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

> This repository previously published the same upstream to the flat coordinate
> `ocx.sh/actionlint`. `actionlint/actionlint` is the grouped successor —
> upstream lives under the personal handle `rhysd`, which names a person rather
> than a vendor, so under the two-segment namespace rule the tool names itself.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
actionlint/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all.

## Platforms

`actionlint` publishes six platform entries: both Linux arches, both macOS
arches and both Windows arches. Upstream builds actionlint as a pure-Go binary
without cgo, so there is one Linux build per arch and it is **fully static** —
no `PT_INTERP`, no `DT_NEEDED`. `os.features` states what an artifact requires
*of the host*, so both Linux keys are **bare**: tagging them `+libc.musl` would
be a false requirement that hid them from every glibc host. The `alpine:3.20`
container leg in `mirror-base.yml` is what turns that claim into evidence; the
measurement itself is recorded above the `assets:` block in
`actionlint/mirror.yml`.

Upstream also ships `linux_386`, `linux_armv6`, `windows_386` (no GitHub
Actions runner) and `freebsd_{386,amd64}` (not an OCX platform); the anchored
asset regexes keep them out.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `actionlint/mirror.yml` | hand | yes — see below |
| `actionlint/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `actionlint/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec actionlint/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

Upstream ships actionlint **flat at the archive root** — the executable sits
beside `LICENSE.txt`, `README.md`, `docs/` and `man/`, with no `bin/` — so the
only honest PATH entry is a bare `${installPath}`. `bin_scan` only looks
*below* `${installPath}`, so any mode other than `off` is rejected at spec load
with exit 65. `mirror-base.yml` therefore sets `bin_scan: off` and
`actionlint/metadata.json` declares `binaries: ["actionlint"]` by hand; the
smoke test is what proves the name is really on the composed PATH.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).

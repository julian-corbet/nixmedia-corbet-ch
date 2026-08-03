# timg: AUR-only on Arch, an ordinary attribute on nixpkgs — the drift runs backward

**Finding:** `timg` (terminal image/video viewer, sixel- and kitty-graphics-protocol aware) is
**not** in Arch's official repos at all — `pacman -Si timg` returns nothing on `extra`,
`core`, or the CachyOS repos this fleet also has enabled. It exists only in the AUR. On nixpkgs,
by contrast, `timg` is a completely ordinary `pkgs.timg` attribute — official, no `aur`-style
caveat needed, force-evaluates cleanly.

**Why this is worth a study rather than just a catalogue line:** every other AUR-flagged entry
this family of catalogues (nixfont, nixoffice, and this one) has needed so far runs the OTHER
direction — a package is easy to get on Arch (AUR is low-friction, huge, and pacman-adjacent
tooling makes installing from it routine) and the gap is on the nixpkgs side (no maintainer has
packaged it, or it is intentionally excluded). `timg` inverts that: nixpkgs packaged it, Arch's
official maintainers have not (yet). Assuming the direction of drift without checking — "AUR
means nixpkgs is more likely to have the gap" — would have been exactly the kind of unverified
guess this catalogue's own header warns against.

**Evidence:**

```
$ pacman -Si timg
error: package 'timg' was not found

$ curl -s "https://aur.archlinux.org/rpc/v5/info?arg[]=timg"
{"resultcount":1,"results":[{"Name":"timg","Version":"1.6.3-2","PackageBase":"timg", ...}]}

$ nix eval --impure --json --expr '(import (fetchTarball ".../1d4e0f865...tar.gz") {}).timg.pname'
"timg"
```

**Decision this drove:** `lib/media.nix`'s `terminal.timg` entry carries `aur = true` (so
`nixmedia.aurPackages` — not `archPackages` — is what a host's reconciler feeds to its AUR
helper, keeping the "`pacman -S` dies on an AUR name and takes the whole transaction with it"
failure mode this split exists to avoid) alongside a plain, unqualified `nixpkgs = "timg"` — no
`null`, no override, no caveat needed on that side at all. The entry's own inline comment in
`lib/media.nix` calls out that the direction is inverted from the usual case, specifically so a
future reader auditing "why does this one have `aur = true`" does not assume it also means
"nixpkgs probably lacks it too" and skip actually checking.

**Method:** `pacman -Si` against a live CachyOS host for the
negative result; the AUR RPC v5 `info` endpoint for the positive AUR confirmation; a
force-evaluating `nix eval --impure` against the nixpkgs revision infra's own `flake.lock` had
pinned at the time for the positive nixpkgs confirmation. All three are reproducible via
`../experiments/verify-package-names.sh`.

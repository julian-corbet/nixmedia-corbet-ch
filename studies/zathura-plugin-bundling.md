# zathura: nixpkgs bundles the PDF backend, Arch does not

**Finding:** `pkgs.zathura` on nixpkgs is not the bare zathura core — it is a `symlinkJoin`
wrapper that already includes the djvu, ps, cb (comic book) and pdf-poppler plugins by default.
Arch's `zathura` package ships the core viewer only, with zero rendering backends; a PDF will not
open at all until a plugin package is installed separately.

**Why this matters for the catalogue:** `lib/media.nix`'s `viewers.zathura-pdf-poppler` entry has
`nixpkgs = null`. That is not a gap in coverage — there genuinely is no separate nixpkgs attribute
to point at, because the thing it would point at is already inside `zathura` itself. Mapping it to
some approximation (`zathura_pdf_poppler`, the plugin's own internal derivation name) would have
been actively wrong: selecting it on a NixOS host would either double-install the same plugin or,
worse, silently succeed while contributing nothing, masking the fact that this catalogue key has
no independent meaning on that platform.

**Evidence.** `pkgs.zathura` evaluates with `pname = "zathura-with-plugins"` (not `"zathura"`),
which was the first signal something was different from a plain 1:1 name mapping. The actual
wrapper derivation, `pkgs/applications/misc/zathura/wrapper.nix` (fetched from nixpkgs at the rev
this catalogue verified against, `1d4e0f865d68258aada31e68e6d79c8c463f3b34`):

```nix
{
  # ...
  plugins ? [
    zathura_djvu
    zathura_ps
    zathura_cb
    (if useMupdf then zathura_pdf_mupdf else zathura_pdf_poppler)
  ],
  # ...
}:
symlinkJoin {
  inherit (zathura_core) version;
  pname = "zathura-with-plugins";
  paths = with zathura_core; [ man dev out ] ++ plugins;
  # ...
}
```

`useMupdf` defaults to `false`, so the plain `pkgs.zathura` attribute is exactly "zathura core +
djvu + ps + cb + **poppler**" — the same backend this catalogue's Arch-side
`zathura-pdf-poppler` entry names explicitly. The two platforms end up equivalent in practice
(poppler-backed PDF rendering, plus djvu/ps/cb on nixpkgs specifically); they just get there
through a different shape — one package on nixpkgs, two on Arch.

**Decision this drove:** `viewers.zathura`'s own note in `lib/media.nix` states the asymmetry
directly rather than leaving a future reader to rediscover it by noticing a `null` and wondering
whether it was an oversight. `useMupdf = true` (the nixpkgs override) was considered as a second
catalogue entry and rejected for v1 — Arch's `zathura-pdf-mupdf` exists as an official-repo
alternative for anyone who wants it, but a `pkgs.zathura.override { useMupdf = true; }` value
cannot be expressed as a plain dotted attribute string the way every other entry in this table is,
and this catalogue's shape (`{ arch, nixpkgs, aur, note }`, one flat attribute path per side) is
worth keeping uniform rather than special-casing one entry for a backend nothing has asked for yet.

**Method:** confirmed with `nix eval --impure` against the pinned nixpkgs rev
(`pkgs.zathura.pname`, `pkgs.zathura.name`), then the wrapper source fetched directly from
`raw.githubusercontent.com` at that same rev to see the actual default. See
`../experiments/verify-package-names.sh` for the reproducible half of this (the plain
resolves-or-not check); the plugin-bundling behavior itself needed reading the source, which is
why it is written up here rather than being something the automated validator could have caught.

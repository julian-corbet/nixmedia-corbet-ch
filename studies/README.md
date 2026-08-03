# studies

Written-up findings: things that were tried in [`../experiments/`](../experiments/README.md),
worked (or failed instructively), and are worth recording properly — with the reasoning, not just
the result.

A study earns its place here once it changed a decision in the main project. See the main
[README](../README.md) for the project itself.

| File | Finding |
|---|---|
| `zathura-plugin-bundling.md` | nixpkgs's `zathura` attribute already bundles the pdf-poppler (and djvu/ps/cb) plugin by default; Arch's `zathura` ships with no backend at all. Decided `lib/media.nix`'s `zathura-pdf-poppler` entry to carry `nixpkgs = null` rather than an invented mapping. |
| `timg-arch-aur-only.md` | `timg` is AUR-only on Arch but an ordinary official attribute on nixpkgs — the drift runs the opposite direction from every other AUR-flagged entry in this catalogue family so far. Decided `lib/media.nix`'s `timg` entry to carry `aur = true` with a plain, unqualified `nixpkgs = "timg"`, and to say so inline. |

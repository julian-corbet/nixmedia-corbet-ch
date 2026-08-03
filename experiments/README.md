# experiments

Throwaway trials: spikes, one-off scripts, things tried and abandoned or not yet worth writing up.
Nothing here is guaranteed to work, be maintained, or survive the next cleanup pass — except the
two files below, which are load-bearing verification tools kept here deliberately (see each
file's own header) rather than promoted into `checks/`, which is `nix flake check`-wired and
therefore pinned to one nixpkgs revision — the opposite of what these two want, since a
CONSUMER's own pin is what actually decides whether a catalogue name resolves.

- `validate-nixpkgs-names.nix` — force-evaluates every nixpkgs attribute in `../lib/media.nix`
  against a real package set (not just `hasAttrByPath`, which nixfont's own history shows misses
  a nixpkgs rename-to-throw). Run by hand, against whatever nixpkgs revision you actually care
  about.
- `verify-package-names.sh` — the full verification (Arch official repos, the AUR, and the
  nixpkgs side above) in one script, reproducing exactly how `../lib/media.nix` was checked
  before being committed.

If something in here turns out to matter in a different way, distill the actual finding into
[`../studies/`](../studies/README.md) and let the experiment stay disposable (or delete it).

See the main [README](../README.md) for the project itself.

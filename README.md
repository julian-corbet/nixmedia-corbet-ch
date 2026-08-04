# nixmedia

Graphical media consumption declared: what a person plays in a window, resolved to the right
package name on each platform. Today that is one entry — vlc — because almost everything this
catalogue used to carry turned out to belong somewhere else.

## The placement rule

Whether a media-shaped tool belongs in this repo, in a sibling display-substrate repo, or in
[nixsh](https://github.com/julian-corbet/nixsh-corbet-ch) (the terminal-tool catalogue) is a test,
not a judgment call made fresh each time:

> Does the tool have a display mode at all, and is that mode its **default**?
>
> - **yes** → a display-substrate repo — this one, [nixdesktop][nixdesktop] (desktop policy and
>   shared components), or [nixrecord][nixrecord] (screen/window/region recording)
> - **no** → nixsh

"Can it be coaxed into a terminal" is deliberately **not** the test. mpv ships `--vo=sixel` and
OBS cannot run headless at all; a test built on capability rather than default would misfile both
anyway. Worked examples, so the rule is provable rather than merely asserted:

| Tool | Display mode? | Default? | Filed |
|---|---|---|---|
| cmus | none | — | nixsh |
| zathura | yes (gtk4) | yes, and it's the *only* mode | dropped — see below |
| OBS | yes, cannot run headless | yes | nixrecord (production, not consumption) |
| asciinema / vhs | records a terminal, no display server needed | — | nixsh |
| **mpv** | yes (graphical window) | yes | **nixsh anyway** — see below |
| vlc | yes (graphical window) | yes | here |

**zathura** was in this catalogue by mistake and was dropped outright, not filed in nixsh either:
it is a gtk4 GUI document viewer, never a TUI to begin with, so there was no terminal-tool case
for it. Nothing here or in nixsh replaces it.

**mpv is the deliberate exception**, called out explicitly so a reader does not conclude the rule
was applied loosely: it defaults to a graphical window, which by the rule above would put it in
this repo — but the operator uses it as the *terminal* video/audio player and vlc as the graphical
one. It is filed in nixsh by stated use, not by its default, and that override happened once, for
a named reason, not as a precedent.

## What moved out

`ffmpeg`, `mpv`, `cmus`, `yazi`, `chafa`, `timg`, and `yt-dlp` — every entry this catalogue
previously carried except vlc and the dropped zathura pair — have no display mode by default (or
mpv's stated exception above) and now live in nixsh. A consumer that previously selected any of
those from `nixmedia` selects them from nixsh instead; see that repo's own catalogue for the
current group/name shape.

## Why this repo isn't retired to one package

The operator has confirmed nixmedia grows: a graphical image viewer (imv or swayimg) and a comics
reader are both coming, both belonging here by the same display-and-default test. This repo stays
in place, thin on purpose, rather than folding vlc into a neighbor — the same reason nixfont and
nixoffice each stay their own repo instead of merging into one "workstation stuff" catalogue.

## What nixmedia is

A platform-neutral NixOS module that:

- **Selects graphical media tools by group.** `players` (vlc today) is the whole catalogue; a
  second group opens only once a second *kind* of graphical entry (an image viewer, a comics
  reader) is actually added — not pre-declared empty ahead of that.
- **Resolves to platform-specific package names.** Via `lib/media.nix`, each tool maps to a
  pacman package (official repo or AUR) and a nixpkgs attribute, or `null` where no equivalent
  exists — and says so, on the line, whenever the two platforms genuinely diverge. No entry
  diverges today; the mapping shape (including the `aur` field) stays ready for one that will.

It exists in three forms, the same shape as
[nixfont](https://github.com/julian-corbet/nixfont-corbet-ch) and
[nixoffice](https://github.com/julian-corbet/nixoffice-corbet-ch):

- `modules/nixmedia.nix`: the declarative policy — selection groups, and the resolved
  `archPackages`/`aurPackages`/`nixosPackages`/`unavailableOnNixos` lists a backend consumes.
- `modules/nixos.nix`: the NixOS backend, installing via `environment.systemPackages`. Force-
  evaluates every nixpkgs attribute before trusting it (`tryEval`, not `hasAttrByPath` — see that
  file's own header for the nixpkgs rename-to-throw class of bug this specifically guards
  against).
- `modules/arch.nix`: the Arch / system-manager backend, publishing `nixmedia.archPackages` and
  `nixmedia.aurPackages` for the host's own reconciler to consume.

Every tool is selected explicitly by the operator, never defaulted. An empty selection is a
legitimate answer — for a machine with no interactive session at all.

## What it explicitly does not own

- **Terminal-shaped tools**, even media-adjacent ones. See the placement rule above — that is
  nixsh's.
- **Recording/production.** A display-only tool that cannot run headless (OBS) is nixrecord's, not
  a media *consumption* concern.
- **Streaming/remote-desktop transport.** Sunshine and moonlight stay in
  [nixremote](https://github.com/julian-corbet/nixremote-corbet-ch). Do not re-declare either here
  even if a future entry looks adjacent; the boundary exists specifically so a headless box never
  has a reason to pull in a streaming client.

## Repository layout

| Path | Purpose |
|---|---|
| `flake.nix` | Flake entry point: `nixosModules.default` (NixOS install), `systemManagerModules.default` (Arch publish), `lib.catalogue`, and `checks`. |
| `lib/media.nix` | The media catalogue: one entry per selectable tool, with platform-specific package names, a note on what it is for, and the placement rule's full text with worked examples. |
| `modules/` | `nixmedia.nix` (policy + selection), `nixos.nix` and `arch.nix` (the two backends). |
| `checks/` | `nix flake check`-wired proof that the selection/resolution logic itself is wired correctly (module evaluation, not a real package build) — including that a name which left the catalogue (moved to nixsh, or dropped outright) is rejected, not silently accepted. |
| `experiments/` | `validate-nixpkgs-names.nix` (force-eval every catalogued nixpkgs name against a real package set) and `verify-package-names.sh` (the full Arch + AUR + nixpkgs verification, reproducible). |
| `studies/` | Findings from the experiments above that changed how the catalogue was shaped. Empty today — see that directory's own README for why. |

## Platform support

**NixOS:** Full. Selections resolve to nixpkgs attributes; the NixOS backend installs via
`environment.systemPackages`, skipping (with a warning) any mapping that has gone stale rather
than failing the whole system evaluation.

**Arch / CachyOS (via system-manager):** Publishes `nixmedia.archPackages` and
`nixmedia.aurPackages` for the host's reconciler to consume. Cannot install packages itself.

## Usage

```nix
{
  imports = [ inputs.nixmedia.nixosModules.default ]; # or .systemManagerModules.default on Arch

  nixmedia = {
    players = [ "vlc" ];
  };
}
```

On Arch, wire the resolved lists into your reconciler (the module above does not install
anything itself):

```nix
{
  imports = [ inputs.nixmedia.systemManagerModules.default ];
  nixarch.packages.pacman = config.nixmedia.archPackages;
  nixarch.packages.aur = config.nixmedia.aurPackages;
}
```

## Related projects

Part of the same independently-usable NixOS module family:
[nixfont](https://github.com/julian-corbet/nixfont-corbet-ch) (fonts as a shared concern),
[nixoffice](https://github.com/julian-corbet/nixoffice-corbet-ch) (documents half of a
workstation), [nixrecord][nixrecord] (declarative screen recording via OBS), and
[nixremote](https://github.com/julian-corbet/nixremote-corbet-ch) (remote-desktop streaming) — the
two this repo's own scope note draws its boundary against. [nixdesktop][nixdesktop] is the third
display-substrate repo the placement rule points at. [nixsh](https://github.com/julian-corbet/nixsh-corbet-ch)
is where everything without a default display mode lives instead.

[nixdesktop]: https://github.com/julian-corbet/nixdesktop-corbet-ch
[nixrecord]: https://github.com/julian-corbet/nixrecord-corbet-ch

## License

[MIT License](LICENSE) © 2026 Julian Corbet

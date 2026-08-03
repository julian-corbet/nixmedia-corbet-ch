# nixmedia

Media consumption declared: players, terminal browsing/preview, document viewers, and a
downloader, resolved to the right package name on each platform — plus the ffmpeg/mpv pair almost
every machine wants regardless of whether "media" is its job.

The scope is stated as a test, not a list: this module owns what a person **plays, browses,
reads, or fetches**. Two domains that look media-shaped on the surface are deliberately not
here:

- **Production** — recording your own screen, window, or a region of one — belongs to
  [nixrecord](https://github.com/julian-corbet/nixrecord-corbet-ch) (elitebook-only today), which
  declares OBS as a home-manager config that renders profile/scene files, not a package list.
- **Streaming transport** — sharing a live desktop session to another box over the network —
  belongs to [nixremote](https://github.com/julian-corbet/nixremote-corbet-ch), which already
  owns both `sunshine` (host) and `moonlight` (client). A media catalogue that also carried
  transport would give a headless box a reason to pull in a streaming client it will never run.

## What nixmedia is

A platform-neutral NixOS module that:

- **Selects media tools by group.** `base` (ffmpeg, mpv — wanted everywhere), `players` (VLC,
  cmus), `terminal` (yazi, chafa, timg — browsing and previewing media from a shell), `viewers`
  (zathura + its Arch-side PDF backend), and `acquire` (yt-dlp).
- **Resolves to platform-specific package names.** Via `lib/media.nix`, each tool maps to a
  pacman package (official repo or AUR) and a nixpkgs attribute, or `null` where no equivalent
  exists — and says so, on the line, whenever the two platforms genuinely diverge rather than
  merely spelling the same package differently. Two such divergences turned up while building
  this catalogue and are written up properly in `studies/`, not just left as a terse comment:
  nixpkgs's `zathura` already bundles the PDF backend Arch ships as a separate package
  (`studies/zathura-plugin-bundling.md`), and `timg` is AUR-only on Arch but an ordinary nixpkgs
  attribute — the opposite direction from the usual gap (`studies/timg-arch-aur-only.md`).

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

- **Recording/production.** See the scope note above — that is nixrecord's.
- **Streaming/remote-desktop transport.** Sunshine and moonlight stay in nixremote. Do not
  re-declare either here even if a future entry looks adjacent; the boundary exists specifically
  so a headless box never has a reason to pull in a streaming client.
- **The `base` pair is not "media policy."** ffmpeg and mpv are catalogued here because this is
  where a shared name→package table for exactly this kind of tool already lives, not because a
  headless server "does media." A host reaching for `base` alone, with every other group empty,
  is a completely ordinary, expected selection.

## Repository layout

| Path | Purpose |
|---|---|
| `flake.nix` | Flake entry point: `nixosModules.default` (NixOS install), `systemManagerModules.default` (Arch publish), `lib.catalogue`, and `checks`. |
| `lib/media.nix` | The media catalogue: one entry per selectable tool, with platform-specific package names and a note on what it is for. |
| `modules/` | `nixmedia.nix` (policy + selection), `nixos.nix` and `arch.nix` (the two backends). |
| `checks/` | `nix flake check`-wired proof that the selection/resolution logic itself is wired correctly (module evaluation, not a real package build). |
| `experiments/` | `validate-nixpkgs-names.nix` (force-eval every catalogued nixpkgs name against a real package set) and `verify-package-names.sh` (the full Arch + AUR + nixpkgs verification, reproducible). |
| `studies/` | Findings from the experiments above that changed how the catalogue was shaped. |

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
    base = [ "ffmpeg" "mpv" ];
    players = [ "vlc" "cmus" ];
    terminal = [ "yazi" "chafa" ];
    viewers = [ "zathura" "zathura-pdf-poppler" ]; # the second entry is a no-op on NixOS — see lib/media.nix
    acquire = [ "yt-dlp" ];
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
workstation), [nixrecord](https://github.com/julian-corbet/nixrecord-corbet-ch) (declarative
screen recording via OBS), and [nixremote](https://github.com/julian-corbet/nixremote-corbet-ch)
(remote-desktop streaming) — the two this repo's own scope note draws its boundary against.

## License

[MIT License](LICENSE) © 2026 Julian Corbet

#
# nixmedia — media consumption, declared: what a person plays, browses, reads, or fetches, plus
# the ffmpeg/mpv pair every machine wants regardless of whether "media" is its job.
#
# SCOPE test, same shape as nixoffice's own: this module owns what a person CONSUMES. Recording
# your own screen is nixrecord's (production, an OBS config rather than a package
# list); streaming that desktop session to another box over the network is nixremote's (it already
# owns sunshine and moonlight). Neither is duplicated here — see lib/media.nix's own header for
# why that boundary is drawn where it is, not just stated.
#
# THE INCIDENT `base` EXISTS TO PREVENT: mpv reached a real host once purely as a transitive
# dependency of something else, worked for months, then vanished the moment that something else
# was reconfigured — discovered only the next time someone actually tried to watch a file. `base`
# (ffmpeg, mpv) is the fix: declared explicitly, on every consumer, never left to arrive as a side
# effect of wanting something unrelated.
{ config, lib, ... }:
let
  cfg = config.nixmedia;
  cat = import ../lib/media.nix { };

  mkGroup = what: table: lib.mkOption {
    type = lib.types.listOf (lib.types.enum (lib.attrNames table));
    default = [ ];
    description = "Which ${what}. Available: ${lib.concatStringsSep ", " (lib.attrNames table)}.";
  };

  selected = lib.flatten [
    (map (k: cat.base.${k}) cfg.base)
    (map (k: cat.players.${k}) cfg.players)
    (map (k: cat.terminal.${k}) cfg.terminal)
    (map (k: cat.viewers.${k}) cfg.viewers)
    (map (k: cat.acquire.${k}) cfg.acquire)
  ];
in
{
  options.nixmedia = {
    base = mkGroup "base tools (wanted on every machine, media-specific or not)" cat.base;
    players = mkGroup "audio/video players" cat.players;
    terminal = mkGroup "terminal browsing and preview tools" cat.terminal;
    viewers = mkGroup "document/reading viewers" cat.viewers;
    acquire = mkGroup "acquisition tools" cat.acquire;

    selected = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      readOnly = true;
      internal = true;
      description = ''
        The resolved catalogue entries for every name in `base`/`players`/`terminal`/`viewers`/
        `acquire`, in one flat list — the canonical "what did this host actually ask for" a
        platform backend consumes. Both backends derive their package lists from THIS, not by
        re-categorizing selections through Arch's own AUR/pacman split the way nixfont's own
        `selected` option's docstring warns against — a package that is AUR-only on Arch is not
        AUR-only (or missing) on NixOS, and filtering by an Arch-only distinction would silently
        drop it there.
      '';
    };

    archPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      description = "Selections as pacman names, for the host's own reconciler: nixarch.packages.pacman = config.nixmedia.archPackages;";
    };

    aurPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      description = ''
        Selections that live in the AUR rather than an official repo, kept SEPARATE because
        `pacman -S` cannot resolve them — it fails the whole transaction with "target not found",
        which takes the rest of the converge down with it. Wire them to the AUR side:

          nixarch.packages.aur = config.nixmedia.aurPackages;

        With no `aurUser` configured the reconciler skips them with a warning, which is the right
        failure mode: the packages stay as they are and nothing else breaks.
      '';
    };

    nixosPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      description = ''
        Selections' nixpkgs attribute names (dotted paths), for introspection. The NixOS backend
        (modules/nixos.nix) does NOT install straight off this list — it force-evaluates each
        name against the real `pkgs` first, because a name appearing here can still be a STALE
        mapping (nixpkgs converts a renamed attribute to `throw "... renamed to ..."`, which keeps
        the key present and only breaks when the value is actually forced — see that module's own
        header). A name in `nixosPackages` is therefore a declared intent, not an install
        guarantee; `nix flake check`-time confidence about the mapping itself is
        experiments/validate-nixpkgs-names.nix's job, run against a real nixpkgs.
      '';
    };

    unavailableOnNixos = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      description = "Selections with no nixpkgs equivalent, surfaced rather than silently dropped.";
    };
  };

  config = {
    nixmedia.selected = selected;
    nixmedia.archPackages =
      lib.unique (map (t: t.arch) (lib.filter (t: !(t.aur or false)) selected));
    nixmedia.aurPackages =
      lib.unique (map (t: t.arch) (lib.filter (t: t.aur or false) selected));
    nixmedia.nixosPackages =
      lib.unique (map (t: t.nixpkgs) (lib.filter (t: t.nixpkgs != null) selected));
    nixmedia.unavailableOnNixos =
      lib.unique (map (t: t.arch) (lib.filter (t: t.nixpkgs == null) selected));
  };
}

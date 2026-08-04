#
# nixmedia — graphical media consumption, declared: what a person plays in a window (`players`),
# plus the GStreamer plugin/codec libraries (`plugins`) those players -- and any other GStreamer
# app a host happens to run -- load to gain format support. Every TOOL that has no display mode,
# or a display mode that is not its default, has moved to nixsh; a plugin is not a tool at all and
# is tested a different way. See lib/media.nix's own header for both placement rules, the worked
# examples that shaped `players`, and the one deliberate exception (mpv, filed in nixsh by stated
# use rather than by its default).
#
# SCOPE test against the two neighboring repos, same shape as nixoffice's own for documents: this
# module owns what a person CONSUMES on a screen. Recording your own screen is nixrecord's
# (production, an OBS config that renders profile/scene files, not a package list); streaming that
# desktop session to another box over the network is nixremote's (it already owns sunshine and
# moonlight). Neither is duplicated here.
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
    (map (k: cat.players.${k}) cfg.players)
    (map (k: cat.plugins.${k}) cfg.plugins)
  ];
in
{
  options.nixmedia = {
    players = mkGroup "graphical media players" cat.players;
    plugins = mkGroup "GStreamer plugin/codec libraries" cat.plugins;

    selected = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      readOnly = true;
      internal = true;
      description = ''
        The resolved catalogue entries for every name in `players` and `plugins` combined, in one
        flat list -- the canonical "what did this host actually ask for" a platform backend
        consumes. Two groups, tested two different ways -- see lib/media.nix's own header for why
        a GStreamer plugin does not fit the `players` test at all. A third group is opened only
        once a third KIND of entry (an image viewer, a comics reader -- still `players`, by that
        test) genuinely does not fit either shape, not pre-declared empty ahead of that.
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
        `pacman -S` cannot resolve them -- it fails the whole transaction with "target not found",
        which takes the rest of the converge down with it. Empty today (every catalogued entry --
        vlc and the six-entry `plugins` group alike -- is an official-repo package on Arch) --
        kept as its own list rather than folded into `archPackages` because the next addition is
        not guaranteed to be. Wire it regardless:

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
        (modules/nixos.nix) does NOT install straight off this list -- it force-evaluates each
        name against the real `pkgs` first, because a name appearing here can still be a STALE
        mapping (nixpkgs converts a renamed attribute to `throw "... renamed to ..."`, which keeps
        the key present and only breaks when the value is actually forced -- see that module's own
        header). A name in `nixosPackages` is therefore a declared intent, not an install
        guarantee.
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

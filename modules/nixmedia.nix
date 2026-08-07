#
# nixmedia — media consumption and format-shifting, declared: what a person plays in a window
# (`players`), the GStreamer plugin/codec libraries (`plugins`) those players -- and any other
# GStreamer app a host happens to run -- load to gain format support, the tool that re-encodes an
# artifact you already have (`transcode`), and the one hardware-keyed VA-API driver group
# (`accel`). Every TOOL that has no display mode, or a display mode that is not its default, has
# moved to nixsh; a plugin is not a tool at all and is tested a different way; `accel` is not
# selected by name at all. See lib/media.nix's own header for all four placement rules, the worked
# examples that shaped `players`, and the one deliberate exception (mpv, filed in nixsh by stated
# use rather than by its default).
#
# SCOPE test against the two neighboring repos, same shape as nixoffice's own for documents: this
# module owns what a person CONSUMES on a screen, plus what they re-encode from what they already
# have. Recording your own screen is nixrecord's (production, an OBS config that renders
# profile/scene files, not a package list); streaming that desktop session to another box over the
# network is nixremote's (it already owns sunshine and moonlight). Neither is duplicated here.
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
    (map (k: cat.transcode.${k}) cfg.transcode)
  ];

  # `accel` resolves through a DIFFERENT shape than the three groups above -- a single
  # host-declared vendor, not a list of catalogue keys, because at most one vendor's driver can
  # ever be correct on one host. `null` (the default) contributes nothing, BY CONSTRUCTION: no
  # filter to forget, no lookup even attempted -- the same construction nixgpu's own `vendor =
  # null` uses. Kept OUT of `selected` on purpose (see that option's own description below) so a
  # platform backend cannot install it the same way as everything else without an explicit choice
  # to do so.
  accelSelected = if cfg.accel == null then [ ] else cat.accel.${cfg.accel}.packages;
in
{
  options.nixmedia = {
    players = mkGroup "graphical media players" cat.players;
    plugins = mkGroup "GStreamer plugin/codec libraries" cat.plugins;
    transcode = mkGroup "format-shifting / transcoding tools" cat.transcode;

    accel = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "amd" "intel" "nvidia" ]);
      default = null;
      description = ''
        Which GPU vendor this host has, for the one VA-API driver whose correct answer genuinely
        varies by silicon -- null (the default) installs nothing extra and the host decodes in
        software, a correct and merely slower outcome. Deliberately NOT auto-detected: see
        lib/media.nix's own "THE FOURTH GROUP" section for why a host states its vendor rather
        than the module reading hardware at evaluation time. `amd` and `nvidia` both resolve to no
        packages at all -- a correct answer, not an unfilled one, see each cell's own note in the
        catalogue.

        Every OTHER group above is decode-side and safe on any silicon in the class; this is the
        one group gated on what the host actually has.
      '';
    };

    selected = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      readOnly = true;
      internal = true;
      description = ''
        The resolved catalogue entries for every name in `players`, `plugins` and `transcode`
        combined, in one flat list -- the canonical "what did this host actually ask for" a
        platform backend's normal package list (environment.systemPackages, home.packages)
        consumes. Deliberately does NOT include `accelSelected`: an `accel` vendor's driver is
        installed a different way on every platform backend (NixOS: hardware.graphics.extraPackages,
        never environment.systemPackages; home-manager: refused, with a warning -- neither backend
        change needed to keep excluding it, since it was never mixed in here to begin with). See
        lib/media.nix's own header for why a GStreamer plugin does not fit the `players` test, and
        why `transcode` and `accel` each needed their own group rather than stretching one of the
        first two.
      '';
    };

    accelSelected = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      readOnly = true;
      internal = true;
      description = ''
        The resolved catalogue entries for the selected `accel` vendor alone -- empty whenever
        `accel` is null, or resolves to a vendor cell with no packages (`amd`, `nvidia` -- see
        lib/media.nix's own accel section for why those cells are legitimately, not incompletely,
        empty). Combined into `archPackages`/`aurPackages` below (Arch treats an `accel` entry the
        same as everything else); kept OUT of `selected` and surfaced separately as
        `graphicsPackages` for the NixOS backend, which must route it to
        `hardware.graphics.extraPackages` instead.
      '';
    };

    archPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      description = ''
        Selections as pacman names, for the host's own reconciler:
        nixarch.packages.pacman = config.nixmedia.archPackages;

        Includes the selected `accel` vendor's package, if any -- on Arch, `/usr/lib/dri` is
        already on libva's default driverdir, so a VA-API driver needs no special routing the way
        the NixOS backend does.
      '';
    };

    aurPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      description = ''
        Selections that live in the AUR rather than an official repo, kept SEPARATE because
        `pacman -S` cannot resolve them -- it fails the whole transaction with "target not found",
        which takes the rest of the converge down with it. Empty today (every catalogued entry,
        across all four groups, is an official-repo package on Arch) -- kept as its own list
        rather than folded into `archPackages` because the next addition is not guaranteed to be.
        Wire it regardless:

          nixarch.packages.aur = config.nixmedia.aurPackages;

        With no `aurUser` configured the reconciler skips them with a warning, which is the right
        failure mode: the packages stay as they are and nothing else breaks.
      '';
    };

    nixosPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      description = ''
        `selected`'s nixpkgs attribute names (dotted paths), for introspection -- deliberately
        EXCLUDES the `accel` vendor's package; see `graphicsPackages` below for that one. The
        NixOS backend (modules/nixos.nix) does NOT install straight off this list -- it
        force-evaluates each name against the real `pkgs` first, because a name appearing here can
        still be a STALE mapping (nixpkgs converts a renamed attribute to `throw "... renamed to
        ..."`, which keeps the key present and only breaks when the value is actually forced --
        see that module's own header). A name in `nixosPackages` is therefore a declared intent,
        not an install guarantee.
      '';
    };

    unavailableOnNixos = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      description = "`selected` entries with no nixpkgs equivalent, surfaced rather than silently dropped. `accel` is not represented here -- see `graphicsPackages`.";
    };

    graphicsPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      description = ''
        The selected `accel` vendor's nixpkgs attribute name(s) (dotted paths), kept SEPARATE from
        `nixosPackages` because a VA-API driver placed in `environment.systemPackages` is never
        found by `libva` -- nixpkgs builds `libva` to look under `mesa.driverLink`
        (`/run/opengl-driver`), which the NixOS graphics module populates from
        `hardware.graphics.package` plus `hardware.graphics.extraPackages` ONLY. The NixOS backend
        (modules/nixos.nix) wires this list there instead, force-evaluating it the same way as
        everything else. Empty whenever `accel` is null or resolves to a vendor cell with no
        packages. See the README's "The NixOS plane is an option, not a package list" for the full
        argument.
      '';
    };
  };

  config = {
    nixmedia.selected = selected;
    nixmedia.accelSelected = accelSelected;
    nixmedia.archPackages =
      lib.unique (map (t: t.arch) (lib.filter (t: !(t.aur or false)) (selected ++ accelSelected)));
    nixmedia.aurPackages =
      lib.unique (map (t: t.arch) (lib.filter (t: t.aur or false) (selected ++ accelSelected)));
    nixmedia.nixosPackages =
      lib.unique (map (t: t.nixpkgs) (lib.filter (t: t.nixpkgs != null) selected));
    nixmedia.unavailableOnNixos =
      lib.unique (map (t: t.arch) (lib.filter (t: t.nixpkgs == null) selected));
    nixmedia.graphicsPackages =
      lib.unique (map (t: t.nixpkgs) (lib.filter (t: t.nixpkgs != null) accelSelected));
  };
}

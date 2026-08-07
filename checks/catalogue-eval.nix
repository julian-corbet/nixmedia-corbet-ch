# Evaluates modules/nixmedia.nix for real against `lib.evalModules` and asserts what it resolves
# — the same "Nix inspecting Nix" tier nixrecord's own checks/config-rendering.nix is (see that
# file's header for why `nix flake check` needs this at all: it does not evaluate
# `nixosModules`/`systemManagerModules` on its own, so a green check without a file like this one
# would prove nothing but flake syntax).
#
# Deliberately pkgs-FREE beyond `pkgs.emptyFile` for the derivation shell: this only proves the
# SELECTION/resolution logic (which category a key belongs to, the arch/AUR split, which nixpkgs
# names got named) is wired correctly. It does NOT prove those nixpkgs names still resolve on a
# real package set — that is experiments/validate-nixpkgs-names.nix's job, force-evaluating
# against one. The two are kept separate on purpose: folding the force-eval pass in here would pin
# `nix flake check`'s pass/fail to one nixpkgs revision, when the whole point of shipping nixpkgs
# ATTRIBUTE NAMES rather than derivations is that a consumer's own pin decides what they resolve
# to (see modules/nixos.nix's own tryEval pass, which runs at the consumer's actual evaluation).
{ pkgs, lib ? pkgs.lib }:
let
  evalWith = selection: (lib.evalModules {
    modules = [ ../modules/nixmedia.nix { nixmedia = selection; } ];
  }).config.nixmedia;

  full = evalWith { players = [ "vlc" ]; };

  allPlugins = [ "gst-plugins-base" "gst-plugins-good" "gst-plugins-bad" "gst-plugins-ugly" "gst-libav" "gst-plugin-pipewire" ];
  fullPlugins = evalWith { plugins = allPlugins; };
  everything = evalWith { players = [ "vlc" ]; plugins = allPlugins; };

  newPlugins = evalWith { plugins = [ "vlc-plugins-all" "libdvdcss" ]; };
  transcodeOnly = evalWith { transcode = [ "handbrake" ]; };

  has = list: item: lib.elem item list;

  results = {
    "empty selection resolves to nothing selected" =
      (evalWith { }).selected == [ ];

    "players alone resolves the one entry, no AUR" =
      full.archPackages == [ "vlc" ] && full.aurPackages == [ ];

    "the players selection alone is one entry (1 players = 1 selected)" =
      lib.length full.selected == 1;

    "vlc has a nixpkgs equivalent -- nothing surfaces as unavailable on NixOS" =
      full.unavailableOnNixos == [ ];

    "nixosPackages carries vlc's dotted nixpkgs name, and only that" =
      full.nixosPackages == [ "vlc" ];

    "archPackages and aurPackages never share a name -- the pacman transaction footgun this split exists to avoid" =
      lib.intersectLists full.archPackages full.aurPackages == [ ];

    "a name that left the catalogue (cmus -- moved to nixsh) is rejected at eval time, not silently ignored" =
      # `evalModules` is lazy -- `tryEval` alone only forces WHNF (the attrset exists), not the
      # type-checked VALUE inside it. `deepSeq` forces all the way through, which is what actually
      # runs the listOf-enum merge/check that rejects "cmus" now that `players` holds only vlc.
      (builtins.tryEval (builtins.deepSeq (evalWith { players = [ "cmus" ]; }).players true)).success == false;

    "a name that was dropped outright (zathura -- never moved, never re-added) is rejected the same way" =
      (builtins.tryEval (builtins.deepSeq (evalWith { players = [ "zathura" ]; }).players true)).success == false;

    # ── plugins: the GStreamer surface ────────────────────────────────────────────────────
    "all six plugins resolve, no AUR" =
      lib.length fullPlugins.archPackages == 6 && fullPlugins.aurPackages == [ ];

    "the plugins selection alone is six entries (6 plugins = 6 selected)" =
      lib.length fullPlugins.selected == 6;

    "gst-plugin-pipewire has no nixpkgs equivalent -- it surfaces as unavailable on NixOS, not silently dropped" =
      fullPlugins.unavailableOnNixos == [ "gst-plugin-pipewire" ];

    "the other five plugins DO have nixpkgs equivalents -- only pipewire's sink is null" =
      lib.length fullPlugins.nixosPackages == 5
      && !(has fullPlugins.nixosPackages "gst-plugin-pipewire");

    "nixosPackages carries the real gst_all_1 dotted attribute paths" =
      has fullPlugins.nixosPackages "gst_all_1.gst-plugins-base"
      && has fullPlugins.nixosPackages "gst_all_1.gst-libav";

    "players and plugins compose together in one selection (1 + 6 = 7)" =
      lib.length everything.selected == 7
      && has everything.archPackages "vlc"
      && has everything.archPackages "gst-libav";

    "a name never in the plugins catalogue is rejected at eval time, not silently ignored" =
      (builtins.tryEval (builtins.deepSeq (evalWith { plugins = [ "gst-plugins-ninja" ]; }).plugins true)).success == false;

    # ── plugins: the two proposed-and-now-declared entries ────────────────────────────────
    "vlc-plugins-all and libdvdcss both resolve, no AUR" =
      newPlugins.archPackages == [ "vlc-plugins-all" "libdvdcss" ] && newPlugins.aurPackages == [ ];

    "vlc-plugins-all has no nixpkgs equivalent -- surfaces as unavailable, not silently dropped" =
      newPlugins.unavailableOnNixos == [ "vlc-plugins-all" ];

    "libdvdcss DOES have a nixpkgs equivalent -- only vlc-plugins-all is unavailable" =
      newPlugins.nixosPackages == [ "libdvdcss" ];

    # ── transcode: the new group ──────────────────────────────────────────────────────────
    "handbrake resolves as its own group, one entry, no AUR" =
      transcodeOnly.archPackages == [ "handbrake" ] && transcodeOnly.aurPackages == [ ];

    "handbrake has a nixpkgs equivalent" =
      transcodeOnly.nixosPackages == [ "handbrake" ] && transcodeOnly.unavailableOnNixos == [ ];

    "a name never in the transcode catalogue is rejected at eval time, not silently ignored" =
      (builtins.tryEval (builtins.deepSeq (evalWith { transcode = [ "ffmpeg" ]; }).transcode true)).success == false;
  };

  failed = lib.attrNames (lib.filterAttrs (_: passed: !passed) results);
in
if failed == [ ]
then pkgs.emptyFile
else
  throw ''
    nixmedia: catalogue-eval check failed. Failing assertions:
    ${lib.concatMapStringsSep "\n" (f: "  - ${f}") failed}
  ''

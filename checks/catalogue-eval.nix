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

  has = list: item: lib.elem item list;

  results = {
    "empty selection resolves to nothing selected" =
      (evalWith { }).selected == [ ];

    "players alone resolves the one entry, no AUR" =
      full.archPackages == [ "vlc" ] && full.aurPackages == [ ];

    "the whole catalogue is one entry (1 players = 1 selected)" =
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
  };

  failed = lib.attrNames (lib.filterAttrs (_: passed: !passed) results);
in
if failed == [ ]
then pkgs.emptyFile
else throw ''
  nixmedia: catalogue-eval check failed. Failing assertions:
  ${lib.concatMapStringsSep "\n" (f: "  - ${f}") failed}
''

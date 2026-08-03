# Evaluates modules/nixmedia.nix for real against `lib.evalModules` and asserts what it resolves
# — the same "Nix inspecting Nix" tier nixrecord's own checks/config-rendering.nix is (see that
# file's header for why `nix flake check` needs this at all: it does not evaluate
# `nixosModules`/`systemManagerModules` on its own, so a green check without a file like this one
# would prove nothing but flake syntax). Neither nixfont nor nixoffice — the two repos this one is
# modelled on — carries a `checks` output; this is the gap being closed here.
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

  full = evalWith {
    base = [ "ffmpeg" "mpv" ];
    players = [ "vlc" "cmus" ];
    terminal = [ "yazi" "chafa" "timg" ];
    viewers = [ "zathura" "zathura-pdf-poppler" ];
    acquire = [ "yt-dlp" ];
  };

  baseOnly = evalWith { base = [ "ffmpeg" "mpv" ]; };

  has = list: item: lib.elem item list;

  results = {
    "empty selection resolves to nothing selected" =
      (evalWith { }).selected == [ ];

    "base tier alone resolves both arch names, no AUR" =
      baseOnly.archPackages == [ "ffmpeg" "mpv" ] && baseOnly.aurPackages == [ ];

    "every category contributes to `selected` (2 base + 2 players + 3 terminal + 2 viewers + 1 acquire = 10)" =
      lib.length full.selected == 10;

    "timg is the AUR entry in `terminal`, not chafa or yazi" =
      has full.aurPackages "timg" && !(has full.aurPackages "chafa") && !(has full.aurPackages "yazi");

    "zathura-pdf-poppler has no nixpkgs equivalent -- surfaced, not silently dropped" =
      has full.unavailableOnNixos "zathura-pdf-poppler";

    "zathura ITSELF does have a nixpkgs equivalent -- only its Arch-side backend package does not" =
      !(has full.unavailableOnNixos "zathura");

    "nixosPackages carries the mapped selections' dotted nixpkgs names, and only those" =
      has full.nixosPackages "ffmpeg"
      && has full.nixosPackages "yt-dlp"
      && !(has full.nixosPackages "zathura-pdf-poppler");

    "archPackages and aurPackages never share a name -- the pacman transaction footgun this split exists to avoid" =
      lib.intersectLists full.archPackages full.aurPackages == [ ];

    "selecting the same key from two different categories cannot happen -- the enum type is per-category, catching a typo'd cross-category reference at eval time" =
      # `evalModules` is lazy -- `tryEval` alone only forces WHNF (the attrset exists), not the
      # type-checked VALUE inside it. `deepSeq` forces all the way through, which is what actually
      # runs the listOf-enum merge/check that rejects "vlc" from the `base` category.
      (builtins.tryEval (builtins.deepSeq (evalWith { base = [ "vlc" ]; }).base true)).success == false;
  };

  failed = lib.attrNames (lib.filterAttrs (_: passed: !passed) results);
in
if failed == [ ]
then pkgs.emptyFile
else throw ''
  nixmedia: catalogue-eval check failed. Failing assertions:
  ${lib.concatMapStringsSep "\n" (f: "  - ${f}") failed}
''

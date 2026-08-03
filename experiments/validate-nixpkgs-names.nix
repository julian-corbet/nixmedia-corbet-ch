# Package names drift between distros, and existence alone does not prove a name still WORKS.
# This checks every non-null nixpkgs attribute in lib/media.nix actually resolves.
#
#   nix-instantiate --eval --strict experiments/validate-nixpkgs-names.nix -A missing   # => [ ]
#
# `resolves` FORCES the attribute, not just checks it exists — `hasAttrByPath` alone would miss a
# real rename. nixfont's own lib/fonts.nix hit exactly this: nixpkgs converted
# `noto-fonts-emoji`/`noto-fonts-extra` to `throw "... renamed to ..."` on 2025-10-27, and the OLD
# name stayed present as an attribute (the throw IS the value) — so an existence-only check said
# "resolves" right up until the NixOS backend actually built `fonts.packages` and hit the throw for
# real (caught 2026-08-03 against a post-rename pin). A `mkOption`/attrset key can exist and still
# not be a package; only forcing the value tells you. This file exists in nixmedia for the same
# reason it exists in nixfont — the mistake it catches is generic to any name→package table, not
# specific to fonts.
{ nixpkgs ? <nixpkgs> }:
let
  pkgs = import nixpkgs { config.allowUnfree = true; };
  lib = pkgs.lib;
  cat = import ../lib/media.nix { };
  all = lib.flatten (map lib.attrValues (lib.attrValues cat));
  named = lib.filter (t: t.nixpkgs != null) all;
  resolves = t:
    let path = lib.splitString "." t.nixpkgs; in
    lib.hasAttrByPath path pkgs
    && (builtins.tryEval (builtins.seq (lib.getAttrFromPath path pkgs) true)).success;
in
{
  checked = builtins.length named;
  missing = map (t: t.nixpkgs) (lib.filter (t: !(resolves t)) named);
}

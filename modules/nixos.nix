# NixOS backend — installs via environment.systemPackages.
#
# Force-evaluates every nixpkgs attribute rather than trusting `hasAttrByPath` alone — the exact
# fix nixfont's own modules/nixos.nix carries, forced by the same class of bug:
# `hasAttrByPath` only proves the ATTRIBUTE exists, not that it is a usable package. nixpkgs
# converts a renamed package to `<oldName> = throw "renamed to ...";`, which keeps the key present
# and only breaks when the value is actually forced — exactly what building
# `environment.systemPackages` does. `tryEval` turns that from a hard failure of the WHOLE system
# evaluation into a skip + a warning: lib/media.nix is a data table, edited far less carefully
# than code, and a single stale mapping in it should not be able to take a host down. See
# experiments/validate-nixpkgs-names.nix's own header for the concrete rename this exists to
# catch (nixfont's own noto-fonts-emoji/noto-fonts-extra incident, 2026-08-03).
{ config, lib, pkgs, ... }:
let
  cfg = config.nixmedia;

  # Filter `nixmedia.selected` directly — NOT `nixosPackages` or `archPackages` — for the same
  # reason nixfont's own nixos.nix backend does: neither of those two lists is the platform-
  # neutral "what did this host actually ask for" (archPackages is deliberately Arch's own
  # pacman/AUR split — an AUR-only entry is withheld from it because it needs an AUR helper on
  # Arch; that distinction means nothing on NixOS, which has no AUR at all).
  named = lib.filter (t: t.nixpkgs != null) cfg.selected;

  evaluated = map
    (t: {
      inherit t;
      try = builtins.tryEval (builtins.seq (lib.getAttrFromPath (lib.splitString "." t.nixpkgs) pkgs) true);
    })
    named;
  installable = map (r: r.t) (lib.filter (r: r.try.success) evaluated);
  staleMappings = map
    (r: "nixmedia: nixpkgs attribute \"${r.t.nixpkgs}\" (catalogue arch name \"${r.t.arch}\") no longer resolves -- lib/media.nix's mapping is stale, most likely a nixpkgs rename")
    (lib.filter (r: !r.try.success) evaluated);
in
{
  imports = [ ./nixmedia.nix ];
  config = {
    environment.systemPackages =
      lib.unique (map (t: lib.getAttrFromPath (lib.splitString "." t.nixpkgs) pkgs) installable);

    warnings =
      lib.optional (cfg.unavailableOnNixos != [ ])
        "nixmedia: no nixpkgs equivalent for: ${lib.concatStringsSep ", " cfg.unavailableOnNixos}"
      ++ staleMappings;
  };
}

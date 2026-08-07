# Home-manager backend — installs resolved media viewers to `home.packages` while surfacing stale
# mappings as warnings rather than hard failures.
{ config, lib, pkgs, ... }:
let
  cfg = config.nixmedia;

  # Filter directly from the platform-neutral selection, not from `nixosPackages`/arch package lists:
  # the catalogue is the authoritative intent; derived lists are backend-facing and can differ in
  # shape while intent stays stable.
  selected = lib.filter (t: t.nixpkgs != null) cfg.selected;
  evaluated = map
    (t: {
      inherit t;
      try = builtins.tryEval (builtins.seq (lib.getAttrFromPath (lib.splitString "." t.nixpkgs) pkgs) true);
    })
    selected;

  installable = map (r: r.t) (lib.filter (r: r.try.success) evaluated);
  staleMappings = map
    (r: "nixmedia: nixpkgs attribute \"${r.t.nixpkgs}\" (catalogue arch name \"${r.t.arch}\") no longer resolves -- lib/media.nix mapping is stale, most likely a nixpkgs rename")
    (lib.filter (r: !r.try.success) evaluated);
in
{
  imports = [ ../modules/nixmedia.nix ];

  config = {
    home.packages = lib.unique (map
      (t: lib.getAttrFromPath (lib.splitString "." t.nixpkgs) pkgs)
      installable);

    warnings =
      lib.optional (cfg.unavailableOnNixos != [ ])
        "nixmedia: no nixpkgs equivalent for: ${lib.concatStringsSep ", " cfg.unavailableOnNixos}"
      ++ staleMappings;
  };
}

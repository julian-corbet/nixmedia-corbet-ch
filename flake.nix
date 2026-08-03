{
  description = "nixmedia — media consumption declared: players, terminal browsing/preview, document viewers, and yt-dlp, plus the ffmpeg/mpv pair every machine wants. Not production (nixrecord) and not streaming transport (nixremote, which owns sunshine/moonlight)";

  # nixpkgs is used ONLY by this flake's own `checks` below (proving the module resolves
  # selections correctly, and separately — see experiments/validate-nixpkgs-names.nix — that
  # every catalogued nixpkgs name still force-evaluates on a real package set). The exported
  # modules (nixosModules/systemManagerModules) never see this input: they take `pkgs` from
  # whichever evaluation composes them, exactly like nixfont and nixoffice. Composing this flake
  # can never add a second nixpkgs to a consumer's closure.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
    in
    {
      # Platform-neutral policy: selections + the resolved package-name lists.
      nixosModules.nixmedia = ./modules/nixmedia.nix;

      # NixOS backend — installs via environment.systemPackages.
      nixosModules.default = ./modules/nixos.nix;
      nixosModules.install = ./modules/nixos.nix;

      # Arch / system-manager backend — publishes `nixmedia.archPackages`/`.aurPackages` for the
      # host's own reconciler.
      systemManagerModules.nixmedia = ./modules/arch.nix;
      systemManagerModules.default = ./modules/arch.nix;

      lib.catalogue = import ./lib/media.nix { };

      # `nix flake check` does not evaluate `nixosModules`/`systemManagerModules` on its own — see
      # nixrecord's own checks/config-rendering.nix header for the exact mechanism this repeats.
      # A green `nix flake check` on this repo without this file would cover nothing but flake
      # syntax; neither nixfont nor nixoffice carries a `checks` output at all today, which is
      # exactly the gap this closes.
      checks = forAllSystems (system: {
        catalogue-eval = import ./checks/catalogue-eval.nix {
          pkgs = nixpkgs.legacyPackages.${system};
        };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}

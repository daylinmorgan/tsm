{
  description = "tsm";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nim2nix.url = "github:daylinmorgan/nim2nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      nim2nix,
    }:
    let
      inherit (nixpkgs.lib) genAttrs;
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        genAttrs supportedSystems (
          system:
          f (import nixpkgs {
            inherit system;
            overlays = [nim2nix.overlays.default];
          }
        ));
      rev = toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nim
            nim-atlas # from overlay
          ];
        shellHook= ''
          echo -e "\n\nget started by running 'atlas rep' if needed"
        '';
        };
      });
      packages = forAllSystems (pkgs: {
        tsm = pkgs.buildAtlasPackage rec {
          pname = "tsm";
          version = "2025.1004-unstable-${rev}"  ;
          src = ../.;
          atlasDepsHash = "sha256-sifrhLuGPI2+ncE0ZGHZdrS9DUSC+d1VFP8Kpp5sZr8=";
          nimFlags = [
            "-d:TsmVersion=v${version}"
          ];
        };
        default = self.packages.${pkgs.system}.tsm;
      });
    };
}

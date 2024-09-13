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
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nim
            nimble
          ];
        };
      });
      packages = forAllSystems (pkgs: {
        tsm = pkgs.buildNimblePackage {
          pname = "tsm";
          version = "2024.1001";
          src = ../.;
          nimbleDepsHash = "sha256-ugu+bNCWukWSALzD0/i73d0O2kty85J824tHsmfWRDI=";
        };
        default = self.packages.${pkgs.system}.tsm;
      });
    };
}

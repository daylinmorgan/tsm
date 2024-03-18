{
  description = "tsm";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs.lib) genAttrs;
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = f: genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [ nim nimble ];
      };
    });
    packages = forAllSystems (
      pkgs: {
        tsm = pkgs.buildNimPackage {
          pname = "tsm";
          version = "2024.1001";
          src = ../.;
          lockFile = ./lock.json;
        };
        default = self.packages.${pkgs.system}.tsm;
      }
    );
  };
}

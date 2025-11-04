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
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forSystem =
        f: system:
        f system (
          import nixpkgs {
            inherit system;
            overlays = [ nim2nix.overlays.default ];
          }
        );
      forAllSystems = f: genAttrs systems (forSystem f);

      rev = toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
    in
    {
      devShells = forAllSystems (
        _: pkgs: {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nim
              nim-atlas # from overlay
            ];
            shellHook = ''
              echo -e "\n\nget started by running 'atlas rep' if needed"
            '';
          };
        }
      );
      packages = forAllSystems (
        system: pkgs: {
          tsm = pkgs.buildAtlasPackage rec {
            pname = "tsm";
            version = "2025.1004-unstable-${rev}";
            src = ../.;
            atlasDepsHash = "sha256-S2Z3kALdNcZmS09aC/kwKSaXsgBTnAM0WXSyjbzfSfs=";
            nimFlags = [
              "-d:TsmVersion=v${version}"
            ];
          };
          default = self.packages.${system}.tsm;
        }
      );
    };
}

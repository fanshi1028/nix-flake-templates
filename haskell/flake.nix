{
  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/fc00ff355ab4fea966098b2cb87104bd72163384";
    nix-github-actions = {
      url =
        "github:nix-community/nix-github-actions/5163432afc817cf8bd1f031418d1869e4c9d5547";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nix-github-actions }:
    let
      ghcVersion = "98";
      mkHsPackage = pkgs: pkgs.haskell.packages."ghc${ghcVersion}";
    in {

      packages = builtins.mapAttrs (system: pkgs: {
        default = ((mkHsPackage pkgs).developPackage {
          root = ./.;
          modifier = drv: pkgs.haskell.lib.appendConfigureFlag drv "-O2";
        });
      }) nixpkgs.legacyPackages;

      devShells = builtins.mapAttrs (system: pkgs:
        with pkgs;
        let hsPackage = mkHsPackage pkgs;
        in {
          default = (mkHsPackage pkgs).shellFor {
            packages = _: [ self.packages.${system}.default ];
            nativeBuildInputs = with pkgs; [
              (haskell-language-server.override {
                supportedGhcVersions = [ ghcVersion ];
              })
              cabal-install
              ghcid
            ];
            withHoogle = true;
          };
        }) nixpkgs.legacyPackages;

      checks = builtins.mapAttrs (system: pkgs:
        with pkgs; {
          default = self.packages.${system}.default;
          shell = self.devShells.${system}.default;
        }) nixpkgs.legacyPackages;

      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks =
          builtins.mapAttrs (_: checks: { inherit (checks) default shell; }) {
            inherit (self.checks) x86_64-linux x86_64-darwin;
          };
        platforms = {
          x86_64-linux = "ubuntu-22.04";
          x86_64-darwin = "macos-13";
        };
      };
    };
}

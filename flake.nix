{
  description = "A very basic flake.";

  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, haskellNix, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let
        projectName = "missing-package";
        compiler-nix-name = "ghc902";
        index-state = null;

        mkProject = haskell-nix:
          haskell-nix.cabalProject' {
            src = ./.;
            inherit index-state compiler-nix-name;

            # plan-sha256 = "";
            # materialized = ./materialized + "/${projectName}";
          };

        overlays = [
          haskellNix.overlay
          (self: super: { ${projectName} = mkProject self.haskell-nix; })
        ];

        pkgs = import nixpkgs {
          inherit system overlays;
          inherit (haskellNix) config;
        };
        project = pkgs.${projectName};
        flake = pkgs.${projectName}.flake {
          crossPlatforms = ps: with ps; [ mingwW64 ];
        };

        tools = {
          cabal = {
            inherit index-state;
            # plan-sha256 = "";
            # materialized = ./materialized/cabal;
          };

          haskell-language-server = {
            inherit index-state;
            # plan-sha256 = "";
            # materialized = ./materialized/haskell-language-server;
          };

          hoogle = {
            inherit index-state;
            # plan-sha256 = "";
            # materialized = ./materialized/hoogle;
          };
        };

        devShell = project.shellFor {
          packages = ps: [ ps.${projectName} ];
          inputsFrom = [{ buildInputs = with pkgs; [ nixpkgs-fmt ]; }];
          exactDeps = true;
          inherit tools;
        };

        materializers = {
          inherit overlays devShell;
          nixpkgs = pkgs;

          defaultPackage = flake.packages."${projectName}:exe:${projectName}";

          packages = flake.packages // {
            gcroot = pkgs.linkFarmFromDrvs "${projectName}-shell-gcroot" [
              devShell
              devShell.stdenv
              project.plan-nix
              project.roots

              (let
                compose = f: g: x: f (g x);
                flakePaths = compose pkgs.lib.attrValues (pkgs.lib.mapAttrs
                  (name: flake: {
                    name = name;
                    path = flake.outPath;
                  }));
              in pkgs.linkFarm "input-flakes" (flakePaths self.inputs))

              (let
                getMaterializers = (name: project:
                  pkgs.linkFarmFromDrvs "${name}" [
                    project.plan-nix.passthru.calculateMaterializedSha
                    project.plan-nix.passthru.generateMaterialized
                  ]);
              in pkgs.linkFarmFromDrvs "materializers"
              (pkgs.lib.mapAttrsToList getMaterializers ({
                ${projectName} = project;
              } // (pkgs.lib.mapAttrs (_: builtins.getAttr "project")
                (project.tools tools)))))
            ];
          };
        };

      in flake // materializers);
}

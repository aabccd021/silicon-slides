{
  nixConfig.allow-import-from-derivation = false;
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, ... }@inputs:
    let

      lib = inputs.nixpkgs.lib;

      collectInputs =
        is:
        pkgs.linkFarm "inputs" (
          builtins.mapAttrs
            (
              name: i:
              pkgs.linkFarm name {
                self = i.outPath;
                deps = collectInputs (lib.attrByPath [ "inputs" ] { } i);
              }
            )
            is
        );

      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

      silicon-slides = pkgs.writeShellApplication {
        name = "silicon-slides";
        runtimeInputs = [ pkgs.silicon pkgs.imagemagick ];
        text = builtins.readFile ./silicon-slides.sh;
      };

      silicon-slides-nix = pkgs.writeShellApplication {
        name = "silicon-slides-nix";
        runtimeInputs = [ silicon-slides ];
        text = builtins.readFile ./silicon-slides-nix.sh;
      };

      fontsConf = pkgs.makeFontsConf {
        fontDirectories = [
          pkgs.nerd-fonts.jetbrains-mono
        ];
      };

      siliconConfig = pkgs.writeText "silicon-config" ''
        --font "JetBrainsMono Nerd Font=200"
        --background "#000000"
        --no-window-controls
        --no-line-number
        --no-round-corner
        --pad-horiz 200
        --pad-vert 200
        --line-pad 12
        --theme 'DarkNeon'
      '';

      slides = pkgs.writeText "slides" ''
        ${./test/001.md}
        ${./test/002.md}
        ${./test/003.md}
        ${./test/004.md} --highlight-lines 5-6;7
      '';

      snapshot-test = pkgs.runCommandNoCCLocal "test" { } ''
        mkdir -p "$out/snapshot"
        export FONTCONFIG_FILE=${fontsConf}
        ${silicon-slides-nix}/bin/silicon-slides-nix \
          --outdir "$out/snapshot" \
          --silicon-config ${siliconConfig} \
          ${slides}
      '';

      devShells.default = pkgs.mkShellNoCC {
        buildInputs = [ pkgs.nixd ];
      };

      packages = devShells // {
        default = silicon-slides-nix;
        silicon-slides = silicon-slides;
        silicon-slides-nix = silicon-slides-nix;
        snapshot-test = snapshot-test;
        formatting = treefmtEval.config.build.check self;
        formatter = treefmtEval.config.build.wrapper;
        allInputs = collectInputs inputs;
      };

      gcroot = packages // {
        gcroot = pkgs.linkFarm "gcroot" packages;
      };

      formatter = treefmtEval.config.build.wrapper;

      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixpkgs-fmt.enable = true;
        programs.prettier.enable = true;
        programs.shfmt.enable = true;
        programs.shellcheck.enable = true;
        settings.formatter.shellcheck.options = [ "-s" "sh" ];
        settings.global.excludes = [ "LICENSE" "*.png" ];
      };

    in

    {

      packages.x86_64-linux = gcroot;

      checks.x86_64-linux = gcroot;

      formatter.x86_64-linux = treefmtEval.config.build.wrapper;

      devShells.x86_64-linux = devShells;

    };
}

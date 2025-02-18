{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { nixpkgs, treefmt-nix, self }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      silicon-slides = pkgs.writeShellApplication {
        name = "silicon-slides";
        runtimeInputs = [ pkgs.silicon pkgs.imagemagick ];
        text = builtins.readFile ./silicon-slides.sh;
      };

      fontsConf = pkgs.makeFontsConf {
        fontDirectories = [
          pkgs.nerd-fonts.jetbrains-mono
        ];
      };

      snapshot-test = pkgs.runCommandNoCCLocal "test"
        {
          buildInputs = [ silicon-slides ];
        } ''
        mkdir -p "$out/snapshot"
        export FONTCONFIG_FILE=${fontsConf}
        export XDG_CONFIG_HOME=$PWD/config
        export SILICON_CACHE_PATH=$PWD/silicone-cache
        silicon-slides \
          --outdir "$out/snapshot" \
          ${./test/001.md} ${./test/002.md} ${./test/003.md}
      '';

      packages = {
        default = silicon-slides;
        silicon-slides = silicon-slides;
        snapshot-test = snapshot-test;
        formatting = treefmtEval.config.build.check self;
      };

      gcroot = packages // {
        gcroot-all = pkgs.linkFarm "gcroot-all" packages;
      };

      treefmtEval = treefmt-nix.lib.evalModule pkgs {
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

    };
}

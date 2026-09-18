{
  description = "OJ Run-time Environments";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem =
        { pkgs, ... }:
        {
          packages = {
            runner = pkgs.writeShellApplication {
              name = "nix-judge-runner";
              runtimeInputs = with pkgs; [
                coreutils
                isolate
                nix
              ];
              text = builtins.readFile ./run.sh;
            };

            python3 = pkgs.buildEnv {
              name = "oj-python3";
              paths = [
                (pkgs.python3.withPackages (ps: with ps; [ ]))
              ];
            };

            rust = pkgs.buildEnv {
              name = "oj-rust";
              paths = with pkgs; [
                rustc
              ];
            };

            gcc = pkgs.buildEnv {
              name = "oj-gcc";
              paths = with pkgs; [
                gcc
              ];
            };

            clang = pkgs.buildEnv {
              name = "oj-clang";
              paths = with pkgs; [
                clang
              ];
            };
          };
        };
    };
}

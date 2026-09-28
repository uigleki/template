{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, systems, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.git-hooks.flakeModule ];
      systems = import systems;

      perSystem =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          devShells.default = pkgs.mkShell {
            inputsFrom = [ config.pre-commit.devShell ];
            packages = with pkgs; [
              nixd
            ];
          };

          pre-commit.settings = {
            package = pkgs.prek;
            hooks = {
              actionlint.enable = true;
              convco.enable = true;
              nixfmt.enable = true;
              typos.enable = true;

              betterleaks = {
                enable = true;
                package = pkgs.betterleaks;
                # Scans the files it is given; the official `git --staged` would ignore them.
                entry = "${lib.getExe pkgs.betterleaks} dir --redact --no-banner --verbose";
                types = [ "text" ];
              };

              nil = {
                enable = true;
                settings.denyWarnings = true;
              };

              rumdl = {
                enable = true;
                args = [ "--fix" ];
              };

              tombi = {
                enable = true;
                package = pkgs.tombi;
                entry = "${lib.getExe pkgs.tombi} format --offline";
                # Not `types = [ "toml" ]`: Cargo.lock is tagged toml too.
                files = "\\.toml$";
              };
            };
          };
        };
    };
}

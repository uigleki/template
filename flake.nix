{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs@{ flake-parts, systems, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.git-hooks.flakeModule ];

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

              betterleaks = {
                enable = true;
                package = pkgs.betterleaks;

                # Scans the files it is given; the official `git --staged` would ignore them.
                entry = "${lib.getExe pkgs.betterleaks} dir --redact --no-banner --verbose";

                types = [ "text" ];
              };

              convco.enable = true;
              deadnix.enable = true;

              nil = {
                enable = true;
                settings.denyWarnings = true;
              };

              nixfmt.enable = true;

              rumdl = {
                enable = true;
                args = [ "--fix" ];
              };

              statix.enable = true;

              tombi = {
                enable = true;
                package = pkgs.tombi;
                entry = "${lib.getExe pkgs.tombi} format --offline";

                # Not `types = [ "toml" ]`: Cargo.lock is tagged toml too.
                files = "\\.toml$";
              };

              typos.enable = true;

              yamlfmt = {
                enable = true;
                settings.lint-only = false;
              };
            };
          };
        };

      systems = import systems;
    };
}

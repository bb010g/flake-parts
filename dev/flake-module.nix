{ config, lib, inputs, withSystem, ... }:

{
  imports = [
    inputs.pre-commit-hooks-nix.flakeModule
    inputs.hercules-ci-effects.flakeModule # herculesCI attr
  ];
  config.systems = [ "x86_64-linux" "aarch64-darwin" ];

  config.hercules-ci.flake-update = {
    enable = true;
    autoMergeMethod = "merge";
    when.dayOfMonth = 1;
  };

  config.debug = true;

  config.perSystem = { config, pkgs, ... }: {

    devShells.default = pkgs.mkShell {
      nativeBuildInputs = [
        pkgs.nixpkgs-fmt
        pkgs.pre-commit
        pkgs.hci
      ];
      shellHook = ''
        ${config.pre-commit.installationScript}
      '';
    };

    pre-commit = {
      inherit pkgs; # should make this default to the one it can get via follows
      settings = {
        hooks.nixpkgs-fmt.enable = true;
      };
    };

    checks.eval-tests =
      let tests = import ./tests/eval-tests.nix;
      in tests.runTests pkgs.emptyFile // { internals = tests; };

  };
  config.flake = {
    config.effects = withSystem "x86_64-linux" ({ pkgs, hci-effects, ... }: {
      tests = {
        template = pkgs.callPackage ./tests/template.nix { inherit hci-effects; };
      };
    });
  };
}

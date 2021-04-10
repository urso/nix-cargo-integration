{ sources }:
let
  importCargoToml = root: builtins.fromTOML (builtins.readFile (root + "/Cargo.toml"));
  flakeUtils = import sources.flakeUtils;

  makeFlakeOutputs = root:
    let
      cargoToml = importCargoToml root;
    in
    with flakeUtils;
    eachSystem (cargoToml.package.metadata.nix.systems or defaultSystems) (makeOutputs root);

  makeOutputs = root: system:
    let
      common = import ./common.nix {
        cargoPkg = (importCargoToml root).package;
        inherit system root sources;
      };
      cargoPkg = common.cargoPkg;
      nixMetadata = common.nixMetadata;
      lib = common.pkgs.lib;

      packages = {
        # Compiles slower but has tests and faster executable
        "${cargoPkg.name}" = import ./build.nix {
          inherit common;
          doCheck = true;
          release = true;
        };
        # Compiles faster but no tests and slower executable
        "${cargoPkg.name}-debug" = import ./build.nix { inherit common; };
      };
      checks = {
        # Compiles faster but has tests and slower executable
        "${cargoPkg.name}-tests" = import ./build.nix { inherit common; doCheck = true; };
      };
      mkApp = n: v: flakeUtils.mkApp {
        name = n;
        drv = v;
        exePath = "/bin/${nixMetadata.executable or cargoPkg.name}";
      };
      apps = builtins.mapAttrs mkApp packages;
    in
    {
      devShell = import ./devShell.nix { inherit common; };
    } // (lib.optionalAttrs (nixMetadata.build or false) ({
      inherit packages checks;
      # Release build is the default package
      defaultPackage = packages."${cargoPkg.name}";
    } // (lib.optionalAttrs (nixMetadata.app or false) {
      inherit apps;
      # Release build is the default app
      defaultApp = apps."${cargoPkg.name}";
    })));
in
{
  inherit makeOutputs makeFlakeOutputs;
}
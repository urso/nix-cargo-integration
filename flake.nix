{
  inputs = {
    devshell.url = "github:numtide/devshell";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    naersk.url = "github:nmattia/naersk";
    flakeUtils.url = "github:numtide/flake-utils";
    rustOverlay.url = "github:oxalica/rust-overlay";
  };

  outputs = inputs: with inputs;
    {
      lib = import ./lib.nix {
        sources = { inherit flakeUtils rustOverlay devshell nixpkgs naersk; };
      };
    };
}
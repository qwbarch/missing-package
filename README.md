# cabal-template

Minimal template with nix flakes, with materialization and cross-compilation support.

## Preparing a project

1. Change the project name. This includes the cabal file's name, references inside the cabal file, and ``flake.nix``
2. Change the license inside the ``.cabal`` file (default is MIT)
3. Pick a ghc version, preferably one that is [cached](https://input-output-hk.github.io/haskell.nix/reference/supported-ghc-versions.html) by ``haskell.nix``
4. Change the description within the cabal file and ``flake.nix``.
5. Run ``nix develop``. Take note of the index state from the trace logs.
6. Set the index-state within ``flake.nix`` and ``cabal.project``.

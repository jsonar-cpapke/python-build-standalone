# Download release artifacts from GitHub Actions
release-download-distributions token commit:
  mkdir -p dist
  cargo run --release -- fetch-release-distributions --token {{token}} --commit {{commit}} --dest dist

# Perform local builds for macOS
release-build-macos tag:
  #!/bin/bash
  set -exo pipefail

  export PATH=~/.pyenv/shims:$PATH

  rm -rf build dist
  git checkout {{tag}}
  ./build-macos.py --python cpython-3.8 --optimizations pgo
  ./build-macos.py --python cpython-3.8 --optimizations pgo+lto
  ./build-macos.py --python cpython-3.9 --optimizations pgo
  ./build-macos.py --python cpython-3.9 --optimizations pgo+lto
  ./build-macos.py --python cpython-3.10 --optimizations pgo
  ./build-macos.py --python cpython-3.10 --optimizations pgo+lto

# Trigger builds of aarch64-apple-darwin release artifacts.
release-build-macos-remote tag:
  ssh macmini just --working-directory /Users/gps/src/python-build-standalone --justfile /Users/gps/src/python-build-standalone/Justfile release-build-macos tag={{tag}}
  mkdir -p dist
  scp 'macmini:~/src/python-build-standalone/dist/*.zst' dist/
  cargo run --release -- convert-install-only dist/cpython-*-aarch64-apple-darwin-pgo+lto*.zst

# Upload release artifacts to a GitHub release.
release-upload-distributions token datetime tag:
  cargo run --release -- upload-release-distributions --token {{token}} --datetime {{datetime}} --tag {{tag}} --dist dist

# Perform a release.
release token commit tag:
  #!/bin/bash
  set -eo pipefail

  rm -rf dist
  just release-download-distributions {{token}} {{commit}}
  just release-build-macos-remote {{tag}}
  datetime=$(ls dist/cpython-3.10.*-x86_64-unknown-linux-gnu-install_only-*.tar.gz  | awk -F- '{print $8}' | awk -F. '{print $1}')
  just release-upload-distributions {{token}} ${datetime} {{tag}}

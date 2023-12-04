#!/bin/bash -l

set -o errexit -o nounset -o xtrace

function install_dependencies() {
    KOPIA_VERSION="${KOPIA_VERSION:-0.15.0}"
    mkdir -p ${HOME}/.local/bin

    # Download and extract kopia
    wget https://github.com/kopia/kopia/releases/download/v${KOPIA_VERSION}/kopia-${KOPIA_VERSION}-linux-x64.tar.gz

    # Verify that file checksums are ok
    wget https://github.com/kopia/kopia/releases/download/v${KOPIA_VERSION}/checksums.txt
    sha256sum --check checksums.txt --ignore-missing

    # Import official signing key
    curl https://kopia.io/signing-key | gpg --import -
    # Verify signature file
    wget https://github.com/kopia/kopia/releases/download/v${KOPIA_VERSION}/checksums.txt.sig
    gpg --verify checksums.txt.sig

    # extract kopia and install it
    tar -xvf kopia-${KOPIA_VERSION}-linux-x64.tar.gz
    mv kopia-${KOPIA_VERSION}-linux-x64/kopia ${HOME}/.local/bin/kopia
    chmod +x ${HOME}/.local/bin/kopia
}
export -f install_dependencies

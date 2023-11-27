#!/bin/bash -l

set -o errexit -o nounset -o xtrace

function install_dependencies() {
    mkdir -p ${HOME}/.local/bin

    # Download and extract kopia
    wget https://github.com/kopia/kopia/releases/download/v0.15.0/kopia-0.15.0-linux-x64.tar.gz

    # Verify that file checksums are ok
    wget https://github.com/kopia/kopia/releases/download/v0.15.0/checksums.txt
    sha256sum --check checksums.txt --ignore-missing

    # Import official signing key
    curl https://kopia.io/signing-key | gpg --import -
    # Verify signature file
    wget https://github.com/kopia/kopia/releases/download/v0.15.0/checksums.txt.sig
    gpg --verify checksums.txt.sig

    # extract kopia and install it
    tar -xvf kopia-0.15.0-linux-x64.tar.gz
    mv kopia-0.15.0-linux-x64/kopia ${HOME}/.local/bin/kopia
    chmod +x ${HOME}/.local/bin/kopia
}
export -f install_dependencies

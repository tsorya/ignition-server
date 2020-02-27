#!/bin/bash -e

organization=kubevirt
commit="9d224d0c22e9ed2ca7588ccf3a258d82e160b195"

script_dir=$(dirname "$(readlink -f "$0")")
kubevirtci_dir=kubevirtci

rm -rf $kubevirtci_dir
git clone https://github.com/$organization/kubevirtci $kubevirtci_dir
pushd $kubevirtci_dir
git checkout $commit
popd

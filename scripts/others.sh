function _source_file {
  if [[ ! -z $1 ]]; then
    source "${CURRENT_DIR}/../${1}"
  fi
}

# install_go

VERSION="1.12.9"
OS="linux"
ARCH="amd64"
wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz
sudo tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz
rm -rf go$VERSION.$OS-$ARCH.tar.gz

function _source_file {
  if [[ ! -z $1 ]]; then
    source "${CURRENT_DIR}/../${1}"
  fi
}

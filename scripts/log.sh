function print_info {
  RED='\033[0;33m'
  NC='\033[0m' # No Color
  PROC_NAME="${RED}- [ $@ ] -${NC}"
  printf "$PROC_NAME\n"
}

function _info {
  echo "${LINE}"
  print_info "$@"
  echo "${LINE}"
}

function _log {
  RED='\033[0;35m'
  NC='\033[0m' # No Color
  printf "${RED}- $@${NC}\n"
}

function _error {
  RED='\033[0;31m'
  NC='\033[0m' # No Color
  printf "${RED}$@${NC}\n"
}

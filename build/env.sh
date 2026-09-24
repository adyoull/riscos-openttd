# Common settings for the build scripts. Override any of these in your
# environment before running them.
: "${GCCSDK_SRC:=$HOME/riscos/gccsdk}"          # clone of the GCCSDK sources
: "${GCCSDK_INSTALL_ENV:=$GCCSDK_SRC/env}"
: "${GCCSDK_INSTALL_CROSSBIN:=$GCCSDK_SRC/cross/bin}"
: "${OPENTTD_SRC:=$HOME/riscos/OpenTTD}"         # clone of OpenTTD at tag 14.1
: "${AB_DIR:=$HOME/riscos/abuild}"              # autobuilder work directory
REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export GCCSDK_SRC GCCSDK_INSTALL_ENV GCCSDK_INSTALL_CROSSBIN OPENTTD_SRC AB_DIR REPO_DIR

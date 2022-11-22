#!/bin/bash

set -e

source "$(dirname "$0")/libs/icons.sh"
source "$(dirname "$0")/libs/styles.sh"
source "$(dirname "$0")/libs/helpers.sh"

#Run
process-version

do-versionbump
do-branch
do-commit

echo -ne "\n${I_END}${S_QUESTION}Do not forget to push your changes to <${S_NORM}origin${S_QUESTION}> when you are ready to \"deploy\" this new release"

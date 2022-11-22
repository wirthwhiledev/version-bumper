RELEASE_PREFIX='release'
NEW_VERSION_INPUT=""
PREVIOUS_VERSION=$( sed -n 's/.*"version":.*"\(.*\)"\(,\)\{0,1\}/\1/p' "./package.json" )

GIT_MSG=""
NEW_VERSION=''

SKIP_CI=true
HAS_NEW_TAG=false

#version
process-version(){
  local V_PREV_LIST V_MAJOR V_MINOR V_PATCH

  V_PREV_LIST=( $( echo "$PREVIOUS_VERSION" | tr '.' ' ' ) )
  V_MAJOR=${V_PREV_LIST[0]}; 
  V_MINOR=${V_PREV_LIST[1]}; 
  
  V_MINOR=$((V_MINOR + 1)) # Increment
  V_SUGGEST="$V_MAJOR.$V_MINOR.0"

  #prompt
  echo -ne "\n${S_QUESTION}Enter a new version number or press <enter> to use [${S_NORM}$V_SUGGEST${S_QUESTION}]: "
  echo -ne "$S_WARN"
  read -r V_USR_INPUT

  if [ "$V_USR_INPUT" != "" ]; then 
      NEW_VERSION_INPUT=$V_USR_INPUT
  fi
}
do-versionbump(){
    echo -e "${S_NORM}\nIncreamenting package.json version"

    if [ -z "$NEW_VERSION_INPUT" ];  
    then
        NEW_VERSION=$(npm version minor --git-tag-version false)
    else
        NEW_VERSION=$(npm version $NEW_VERSION_INPUT --git-tag-version false)
    fi

    git add package.json
    #git add package-lock.json
    GIT_MSG+="updated package.json, updated package-lock.json, "

    echo -e "\n${I_OK} ${S_NOTICE} Updated package version: $NEW_VERSION"
}
do-patchbump(){
    echo -e "${S_NORM}\nPatching package.json version"

    NEW_VERSION=$(npm version patch --git-tag-version false)

    git add package.json
    git add package-lock.json
    GIT_MSG+="updated package.json, updated package-lock.json, "

    echo -e "\n${I_OK} ${S_NOTICE} Updated package version: $NEW_VERSION"
}

#git things
do-branch(){
    echo -e "${S_NORM}\nCreating new release branch..."
    SKIP_CI=false
    BRANCH_MSG=$(git branch "${RELEASE_PREFIX}/${NEW_VERSION}" 2>&1)
    if [ -z "$BRANCH_MSG" ]; then
        BRANCH_MSG=$(git checkout "${RELEASE_PREFIX}/${NEW_VERSION}" 2>&1)
        echo -e "\n${I_OK} ${S_NOTICE} ${BRANCH_MSG}"
    else
        echo -e "\n${I_STOP} ${S_ERROR} Error\n$BRANCH_MSG\n"
    fi 
}

#commit / push
get-commit-msg() {
  CMD=$([ ! "${PREVIOUS_VERSION}" = "${NEW_VERSION}" ] && echo "${PREVIOUS_VERSION} ->" || echo "to")
  echo bumped "$CMD" "$NEW_VERSION"
}

do-commit() {
    echo -e "\n${S_NORM} Committing..."

  GIT_MSG+="Automated: $(get-commit-msg)" 
  GIT_MSG_PREFIX="";

  if [ "$SKIP_CI" = true ]; then
    GIT_MSG_PREFIX="[skip ci] "
  fi

  COMMIT_MSG=$( git commit -m "${GIT_MSG_PREFIX}${GIT_MSG}" 2>&1 )
  if [ ! "$?" -eq 0 ]; then
    echo -e "\n${I_STOP} Error\n$COMMIT_MSG\n"
    exit 1
  else
    echo -e "\n${I_OK} ${S_NOTICE} $COMMIT_MSG"
  fi  
}

do-push() {
  PUSH_DEST='origin'
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  #push version tag
  if [ "$HAS_NEW_TAG" = true ] ; then
    echo -e "\n${S_NORM}Pushing tags to <${PUSH_DEST}>..."
    PUSH_MSG=$( git push "${PUSH_DEST}" "$NEW_VERSION" 2>&1 ) # Push new tag
    if [ ! "$?" -eq 0 ]; then
      echo -e "\n${I_STOP} ${S_WARN}Warning\n$PUSH_MSG"
      exit 1
    else
      echo -e "\n${S_NORM}$PUSH_MSG"
      echo -e "\n${I_OK} ${S_NOTICE} Push tag to <${S_NORM}${PUSH_DEST}${S_NOTICE}> was successful"
    fi
  fi

  #push files
  echo -e "\n${S_NORM}Pushing files to <${CURRENT_BRANCH}>..."
  PUSH_MSG=$( git push )
  if [ ! "$?" -eq 0 ]; then
    echo -e "\n${I_STOP} ${S_WARN}Warning\n$PUSH_MSG"
    exit 1
   else
    echo -e "\n${S_NORM}$PUSH_MSG"
    echo -e "\n${I_OK} ${S_NOTICE} Push files to <${S_NORM}${CURRENT_BRANCH}${S_NOTICE}> was successful"
   fi  
}
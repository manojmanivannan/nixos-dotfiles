# Ported from ~/MyArchDotFiles/zshrc/.zshrc_addon
# Sourced from home-manager programs.zsh.initContent (after oh-my-zsh loads),
# so functions/aliases here override oh-my-zsh plugin definitions.
#
# Adapted for NixOS:
#   - dropped `update_upgrade_clean='sudo pacman -Syu'` (Arch-only; use `nrs`)
#   - dropped `source <(fzf --zsh)` and `~/.fzf.zsh` (home-manager fzf integration)
#   - dropped `autoload -Uz compinit` (oh-my-zsh runs compinit)
#   - dropped the eza FPATH line (pointed at a non-existent custom-plugin path)
#   - guarded `. "$HOME/.local/bin/env"` so a missing file is a no-op
#   - split the glued `...export LIBVIRT_DEFAULT_URI=...` line

autoload -U bashcompinit
bashcompinit

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

function banner {
    lines=$(tput lines)
    cols=$(tput cols)

    # Calculate the length of the line
    line_length=$((cols - 1))

    printf '=%.0s' $(seq 1 $line_length)
    printf '\n'

    # Print the backup work files section
    # Convert the input string to uppercase
    message=$(echo "$1") # | tr '[:lower:]' [:upper:])

    # Print the converted message
    echo "$message"

    printf '=%.0s' $(seq 1 $line_length)
    printf '\n'
}

function confirmation() {
    # Description:
    #   The confirmation function is designed to prompt the user with a message and obtain confirmation through a yes/no response.
    #   It takes a message as input, displays it as a prompt, and expects the user to input either 'y' or 'n' (case-insensitive).
    #   If the user confirms by entering 'y' or 'Y', the function returns 0, indicating success.
    #   Otherwise, if the user declines by entering any other character or no input, the function returns 1, indicating failure.

    # Parameters:
    #   $1: The message to display as the confirmation prompt.

    # Return value:
    #   0: Success, indicating confirmation.
    #   1: Failure, indicating denial or invalid input.
    local message=$1
    read "response?${message} ?[y/N] "
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0 ;;
        *)
            return 1 ;;
    esac
}

function choice_selection() {
    # Description:
    #   The choice_selection function facilitates user selection from a list of options provided as arguments.
    #   It presents the options to the user using the select command, allowing them to choose one option by its corresponding number.
    #   Upon selection, the chosen option is returned and printed to the console.

    # Parameters:
    #   CHOICES: An array containing the list of options from which the user needs to choose.

    # Return value:
    #   The chosen option selected by the user.
    local CHOICES=("$@")
    select CHOICE in ${CHOICES[@]}; do break ; done
    echo $CHOICE
}


function fs() {
    local PATH_REGEX=${1?param missing - specify the path regex}
    local FILE_REGEX=${2?param missing - specify the file regex}
    local SEARCH_REGEX=${3?param missing - specify the string regex}
    find "$PATH_REGEX" -name "$FILE_REGEX" -print0 | xargs -0 grep -Hrin "$SEARCH_REGEX" | grep -i "$SEARCH_REGEX"
}

function s() {
    # s 'string1.*string2' path -> for AND
    # s 'string1\|string2' path -> for OR
    regex=${1?param missing - specify string to search}
    location=${2?param missing - specify directory to search (recursive)}
    location="$(realpath $location)"
    filename_ext="${3}"  #regex for file type, eg METRIC.xml
    if [ -z "$filename_ext" ]; then
        filename_ext="*";
    else
        filename_ext="$filename_ext"; fi

    grep -HErin "$regex" --include "$filename_ext" "$location";}

function sf() {
    # s 'string1.*string2' path -> for AND
    # s 'string1\|string2' path -> for OR
        regex=${1?param missing - specify string to search}
        location=${2?param missing - specify directory to search (recursive)}
        #location="$(realpath $location)"
        filename_ext="${3}"  #regex for file type, eg METRIC.xml
        if [ -z "$filename_ext" ]; then
                filename_ext="*";
        else
                filename_ext="$filename_ext"; fi

        grep -lrin "$regex" --include "$filename_ext" "$location";
    }

function sxtract(){
    local FILE=${1?param missing - specify file name}
    local REGEX=${2?param missing - specify the starting word}
    grep -oiP '(?<='"$REGEX"'")[a-zA-Z0-9_]+' $FILE


}


function f() {
    local regex=${1?param missing - specify string.}
    local location=${2?param missing - specify directory.}
    local full_location="$(realpath $location)"
    local extra_args=${3:-empty}
    if [[ $extra_args == *print* ]]; then
        find "$full_location" -type f -iname "*$regex*" -print0
        # ~/.scripts/.venv/bin/py_file_select -l $regex $full_location | tr '\n' ' '
    else
        find "$full_location" -type f -iname "*$regex*" | grep --color=auto --exclude-dir={.venv,.git} -i "$regex"
        # ~/.scripts/.venv/bin/py_file_select -l $regex $full_location
    fi
    }

function fo(){
    local regex=${1?param missing - specify string.}
    local location=${2?param missing - specify directory.}
    local RESULT=$(f $regex $location)
    local RESULT_LENGTH=$(echo $RESULT | tr ' ' '\n' | wc -l)

    if [[ ${RESULT_LENGTH} == "1" ]] && [[ ! -z ${RESULT} ]]; then
        echo "Opening $RESULT"
        sleep 0.5
        vim $RESULT
    elif [[ ${RESULT_LENGTH} -gt "1" ]] && [[ ! -z ${RESULT} ]]; then
        local array=()
        while IFS=  read -r -d $'\0'; do
            array+=("$REPLY")
        done < <(f $regex $location "print")
        py-file-opener "$location" "${array[@]}"
    else
        echo "No files found matching: \"$1\""
    fi
}

function s_in_quotes(){
    usage(){
        echo "Search any word [matching regex: a-zA-Z0-9_] betweem quotes, preceeded by another string"
        echo "s_in_quotes -word_before 'name' -file /path/to/file"

    }
    if [ $# -lt 1 ]
    then
        usage
        return
    fi

    local PRINT_SILENT=0
    while [[ $# > 0 ]]
    do
        key=$1
        case "$key" in
            -word_before) shift; local WORD_BEFORE_QUOTES=${1?Specifcy the string before quotes for -word_before} ;;
            -file) shift; local FILE_NAME=${1?Specify file path for -file} ;;
            -s) PRINT_SILENT=1 ;;
            *)  echo"Invalid option"; local INVALID=1; usage;;
        esac
        shift
    done

    if [[ ${INVALID} -ne 1 ]] && [[ ! -z ${WORD_BEFORE_QUOTES} ]] && [[ ! -z ${FILE_NAME} ]]; then


        if [[ ${PRINT_SILENT} -eq 0 ]]; then
            echo "Searching words within quotes matching regex .*${WORD_BEFORE_QUOTES}\"([a-zA-Z0-9_]{0,50})\".* in ${FILE_NAME}"
            echo
        fi
        sed -nr "s/.*${WORD_BEFORE_QUOTES}\"([a-zA-Z0-9_]{0,50})\".*/\1/p" $FILE_NAME
    else
        usage
    fi
}

# cd override: auto-activate ./.venv on enter, deactivate when leaving the venv tree.
function cd() {
  builtin cd "$@"

  if [[ -z "$VIRTUAL_ENV" ]] ; then
    ## If env folder is found then activate the vitualenv
      if [[ -d ./.venv ]] ; then
        source ./.venv/bin/activate
      fi
  else
    ## check the current folder belong to earlier VIRTUAL_ENV folder
    # if yes then do nothing
    # else deactivate
      parentdir="$(dirname "$VIRTUAL_ENV")"
      if [[ "$PWD"/ != "$parentdir"/* ]] ; then
        deactivate
      fi
  fi
}

# cp override: prompt to create the target directory if it doesn't exist.
function cp() {
    local src="${@: -2:1}"
    local dest="${@: -1}"
    local target_dir
    local reply

    if [[ "$dest" == */ ]]; then
        target_dir="$dest"
    else
        target_dir="$(dirname "$dest")"
    fi

    if [[ ! -d "$target_dir" ]]; then
        printf "Target directory '%s' does not exist. Create it? [y/N] " "$target_dir"
        read reply

        if [[ "$reply" =~ ^[Yy]$ ]]; then
            mkdir -p "$target_dir" || return 1
        else
            echo "Copy cancelled."
            return 1
        fi
    fi

    command cp "$@"
}

function mkdirr() {
    mkdir -p "$@"
    builtin cd "$@"
}

function transpose() {
    # TODO verify if ruby is installed
    local filename=${1?param missing - specify full file path}
    ruby -rcsv -e 'puts CSV.parse(STDIN).transpose.map &:to_csv' < "$filename" | while IFS=\, read -r a b ; do echo "$a=$b" ; done
}

function csv() {
    # TODO verify if ruby is installed
    local filename=${1?param missing - specify full file path}
    tabview $filename
    #    column -t -s, < "$filename" | less -#2 -N -S
}

function size_of() {
    local PATH=${1?param missing - specify path}
    /usr/bin/du -h --max-depth=0 $PATH
}

# https://github.com/junegunn/fzf/wiki/Examples

# fd - cd to selected directory
function fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# cf - fuzzy cd from anywhere
# ex: cf word1 word2 ... (even part of a file name)
# zsh autoload function
function cf() {
  local file

  file="$(locate -Ai -0 $@ | grep -z -vE '~$' | fzf --read0 -0 -1)"

  if [[ -n $file ]]
  then
    if [[ -d $file ]]
    then
      cd -- $file
    else
      cd -- ${file:h}
    fi
  fi
}


function count_records(){
    dir=${1?param missing - specify directory}
    location="$(realpath $dir)"
    header=${2?param missing - specify number of lines to consider as header rows}
    variable=$(find $dir -type f | xargs wc -l | awk '$1 > 1' | grep -v total | awk '{s+=$1-'$header'} END {printf "%.0f\n", s}')
    echo "Directory:  $location"
    echo "No lines :  $variable (ignoring $header lines as header):"
}

function wait_for()
{

    local SEC="$1"
    echo -n "Waiting for $SEC seconds ["
    for i in `seq 1 $SEC`; do
        echo -n "."
        sleep 1
    done
    echo "done]"
}

# Auto completion for kubectl
# source <(kubectl completion zsh)
#TMOUT=300
#TRAPALRM() { if command -v cmatrix &> /dev/null; then cmatrix -sb; fi }
#


# GIT Functions
function gpush(){
    if [[ $1 == "--force" ]]
    then
        local force="--force"
    else
        local force=""
    fi
    local cur_branch=$(git branch --show-current)
    echo git push $force origin $cur_branch
    git push $force origin $cur_branch
    if [ $? -eq "128" ]; then
        read "REPLY?Push to origin $cur_branch ?[y/N] "
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo git push --set-upstream origin $cur_branch
            git push --set-upstream origin "$cur_branch"
        fi
    fi
}



function gcommit(){
    local MSG="$@"
    #echo "Message $MSG"

    local JIRA_ID=$(git branch --show-current | grep -oh -E '([nla|ap|in|NLA|AP|IN]+-[0-9]+)')
    local commit_message="$JIRA_ID $MSG"
    echo git commit -m "\"$commit_message\""
    git commit -m "$commit_message"
    echo "Commit SHA: $(git rev-parse --verify HEAD)"
}

function gcorecent(){
    local branch=$(git recentb | cut -d ' ' -f1,3 | fzf | cut -d ' ' -f2)
    echo "Switching to $branch"
    gco $branch
}

function glsupport(){
    for each in $(git branch --list support/2.1\*);
    do
        #echo "Fetching $each"
        echo "gfo $each:$each"
        gfo $each:$each
    done
}

function gcbi(){
    local TYPE=${1?Type of branch missing - b:bugfix or f:feature}
    local JIRA=${2?JIRA ticket no without IN}
    if [[ "$TYPE" == "b" ]]; then
        gcb "bugfix/IN-$JIRA"
    elif [[ "$TYPE" == "f" ]]; then
        gcb "feature/IN-$JIRA"
    else
        echo "Invalid type"
    fi
}

function glast-tags-in-branch(){
    local BRANCH_NAME=${1?param missing - specify branch name}
    local CUR_BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
    local DISPLAY=${2:-1}
    git rev-parse --verify $BRANCH_NAME &> /dev/null  # verify that $BRANCH_NAME exists
    if [ $? -ne "0" ];then
        echo "Branch $BRANCH_NAME does not exist"
    fi
    if [[ "$BRANCH_NAME" == "$CUR_BRANCH_NAME" ]]; then
        git pull -q
    else
        git fetch -q origin $BRANCH_NAME:$BRANCH_NAME
    fi
    if [ $? -eq "0" ];then
        git tag --merged $BRANCH_NAME | grep -vE '[a-zA-Z]+' | sort -t "." -k1,1n -k2,2n -k3,3n | tail -n$DISPLAY
    else
        echo "Unable to get the last tag from branch $BRANCH_NAME"
    fi
}

function gcommit-since-last-tag(){
    local BRANCH_NAME=${1?param missing - specify branch name}
    git rev-parse --verify $BRANCH_NAME &> /dev/null  # verify that $BRANCH_NAME exists
    if [ $? -ne "0" ];then
        echo "Branch $BRANCH_NAME does not exist"
        return
    fi
    git log $(glast-tags-in-branch $BRANCH_NAME)..$BRANCH_NAME --oneline
}

function gcommit-deleted(){
    local STRING=${1?param missing - specify string to search}
    local FILE=${2?param missing - specify file to search}
    git log -c -S $STRING $FILE
}

function gmerge(){
    local BRANCH=${1?parameter missing - specify the branch to merge from}
    echo "git fetch origin $BRANCH:$BRANCH && git merge $BRANCH"
    git fetch origin $BRANCH:$BRANCH && git merge $BRANCH
}
# source "/home/mmanivannan/.kubectl/completion"

drmi(){
  local STRING=("${@?param missing - specify string that you want to match docker images}")
  for each in "${STRING[@]}"
  do
    banner "Images matching '$each'"
    docker images --format "{{.ID}} {{.Repository}}" | grep --color=auto -i $each
    if confirmation "Remove these images?"
    then
      docker images --format "{{.ID}} {{.Repository}}" | grep -i $each | awk '{print $1}' | xargs -r docker rmi --force
    fi
  done
}


uwu() {
  local cmd
  cmd="$(uwu-cli "$@")" || return
  vared -p "" -c cmd
  print -s -- "$cmd"   # add to history
  eval "$cmd"
}

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
alias gitzip="git archive HEAD -o ${PWD##*/}.zip"
alias sz='source ~/.zshrc'
alias gdiff='ydiff -s -w0'
alias grecent=gcorecent
alias gclean='git clean -fd && git checkout -- .'
alias glast-tag='git describe --tags --abbrev=0'
alias gtree='git log --graph --online --decorate --all'
alias gst='git status'
alias matrix='uvx git+https://github.com/will8211/unimatrix.git -s 96'

# ---------------------------------------------------------------------------
# Exports / environment
# ---------------------------------------------------------------------------
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export PATH=${PATH}:~/.local/bin
[ -d ~/.scripts ] && export PATH=$PATH:~/.scripts

autoload -Uz compinit
zstyle ':completion:*' menu select
[[ -d ~/.zfunc ]] && fpath+=(~/.zfunc)

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -s "$HOME/.api_key/keys.sh" ] && source "$HOME/.api_key/keys.sh"

[ -s "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"

export LIBVIRT_DEFAULT_URI=qemu:///system
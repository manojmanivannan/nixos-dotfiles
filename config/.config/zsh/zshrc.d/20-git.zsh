# Git helper functions.
# Split out of the original zshrc_addon.zsh.
# Relies on oh-my-zsh's `git` plugin aliases (gcb, gco, gfo) — kept enabled in
# home-manager/modules/zsh.nix.
# Sourced in load-order by ~/.config/zsh/zshrc_addon.zsh.

# source "/home/mmanivannan/.kubectl/completion"

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
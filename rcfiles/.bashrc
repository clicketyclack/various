# --- Start https://gist.github.com/sundeepgupta/b099c31ee2cc1eb31b6d ---

# Basic color set with .

    BLACK="\[\033[0;30m\]"
      RED="\[\033[0;31m\]"
    GREEN="\[\033[0;32m\]"
   YELLOW="\[\033[0;33m\]"
     BLUE="\[\033[0;34m\]"
  MAGENTA="\[\033[0;35m\]"
     CYAN="\[\033[0;36m\]"
    WHITE="\[\033[0;37m\]"

  L_BLACK="\[\033[1;30m\]"
    L_RED="\[\033[1;31m\]"
  L_GREEN="\[\033[1;32m\]"
 L_YELLOW="\[\033[1;33m\]"
   L_BLUE="\[\033[1;34m\]"
L_MAGENTA="\[\033[1;35m\]"
   L_CYAN="\[\033[1;36m\]"
  L_WHITE="\[\033[1;37m\]"

# Some re-naming / aliases / specials.

      GRASS="\[\033[1;32m\]"
      
       SAND="\[\033[0;33m\]"
     YELLOW="\[\033[1;33m\]"
      
     PURPLE="\[\033[0;35m\]" 
    MAGENTA="\[\033[1;35m\]"

 COLOR_NONE="\[\e[0m\]"
 
 
# Detect whether the current directory is a git repository.
function is_git_repository {
  git branch > /dev/null 2>&1
} 
 
 
# Determine the branch/state information for this git repository.
function set_git_branch {
  # Capture the output of the "git status" command.
  git_status="$(git status 2> /dev/null)"

  # Set color based on clean/staged/dirty.
  if [[ ${git_status} =~ "working tree clean" ]]; then
    state="${L_GREEN}"
  elif [[ ${git_status} =~ "Changes to be committed" ]]; then
    state="${YELLOW}"
  else
    state="${L_RED}"
  fi

  # Set arrow icon based on status against remote.
  remote_pattern="Your branch is (.*) of"
  if [[ ${git_status} =~ ${remote_pattern} ]]; then
    if [[ ${BASH_REMATCH[1]} == "ahead" ]]; then
      remote="?"
    else
      remote="?"
    fi
  else
    remote=""
  fi
  diverge_pattern="Your branch and (.*) have diverged"
  if [[ ${git_status} =~ ${diverge_pattern} ]]; then
    remote="?"
  fi

  # Repo location
  repo_location=$(git rev-parse --show-toplevel)
  repo_name=$(basename $repo_location)
  relative_path=$(python -c "import os.path; print(os.path.relpath('$PWD', '$repo_location'))" | sed -r -e 's/^\.$//')
  #echo "$repo_location -> $repo_name:$relative_path"

  # Get the name of the branch.
  branch_pattern="^(# )?On branch ([^${IFS}]*)"
  if [[ ${git_status} =~ ${branch_pattern} ]]; then
    branch=${BASH_REMATCH[2]}
  fi
  
  # If a repo has the keyword "sandbox" give it a 'sb:' prefix and a special color. This should override the hosting-coloring below.
  sandbox_pattern=".*sandbox.*"
  if [[ ${repo_location} =~ ${sandbox_pattern} ]]; then
    repo_name="${SAND}sb$COLOR_NONE:$SAND${repo_name}"
  fi
  
  # Otherwise color by hosting (assumes you checkout in host-named subdirs).
  bits_pattern="$HOME/bits/.*"
  if [[ ${repo_location} =~ ${bits_pattern} ]]; then
    # ${GRASS}bh$COLOR_NONE:
    repo_name="${L_BLUE}${repo_name}"
  fi

  ghub_pattern="$HOME/github/.*"
  if [[ ${repo_location} =~ ${ghub_pattern} ]]; then
    repo_name="${GRASS}gh$COLOR_NONE:${GRASS}${repo_name}"
  fi

  glab_pattern="$HOME/gitlab/.*"
  if [[ ${repo_location} =~ ${glab_pattern} ]]; then
    # ${CYAN}gl$COLOR_NONE:
    repo_name="${PURPLE}${repo_name}"
  fi

  go_pattern="$HOME/go-workspace/src/github.com/.*"
  if [[ ${repo_location} =~ ${go_pattern} ]]; then
    repo_name="${CYAN}go$COLOR_NONE:${CYAN}${repo_name}"
  fi


  # Set the final branch string.
  BRANCH="${state}(${repo_name}$COLOR_NONE:${state}${branch})${remote}${L_BLUE}/${relative_path}${COLOR_NONE}"
}

# Set user color depending on the user.
function set_user_color () {
  if [[ $USER =~ ^r.* ]]; then
    USER_COLOR="$L_RED"
  elif [[ $USER =~ ^s.* ]]; then
    USER_COLOR="$L_MAGENTA"
  elif [[ $USER =~ .*r$ ]]; then
    USER_COLOR="$L_YELLOW"
  else
    USER_COLOR="$SAND"
  fi
}

# Set user color depending on the user.
function set_host_color () {

  hostname="$(hostname -f)"

  if [[ $hostname =~ ^w.* ]]; then
    HOST_COLOR="$L_WHITE"
  elif [[ $hostname =~ .*e$ ]]; then
    HOST_COLOR="$L_CYAN"
  elif [[ $hostname =~ ^i.* ]]; then
    HOST_COLOR="$L_BLUE"
  else
    HOST_COLOR="$L_RED"
  fi
}


function set_venv_name () {
  if [ -n "$VIRTUAL_ENV" ]; then
    PROMPT_VENV=$(echo $VIRTUAL_ENV | sed -r -e 's!.*/!!')
    PROMPT_VENV=" $WHITE[$GREEN$PROMPT_VENV$WHITE]"
  fi
}



# Return the prompt symbol to use, colorized based on the return value of the
# previous command.
function set_prompt_symbol () {
  if test $1 -eq 0 ; then
      PROMPT_SYMBOL="${GREEN}\$${COLOR_NONE}"
  else
      PROMPT_SYMBOL="${RED}\$${COLOR_NONE}"
  fi
}

# Set the full bash prompt.
function set_bash_prompt () {
  # Set the PROMPT_SYMBOL variable. We do this first so we don't lose the
  # return value of the last command.
  set_prompt_symbol $?

  # Set the BRANCH variable.
  if is_git_repository ; then
    set_git_branch
  else
    BRANCH=''
  fi

  # Zero out branch variable if we aren't in github repo.
  if [[ $PWD/ = $HOME/github/* ]]; then
    BRANCH=$BRANCH
  elif [[ $PWD/ = $HOME/gitlab/* ]]; then
    BRANCH=$BRANCH
  elif [[ $PWD/ = $HOME/sandbox/* ]]; then
    BRANCH=$BRANCH
  elif [[ $PWD/ = $HOME/bits/* ]]; then
    BRANCH=$BRANCH
  elif [[ $PWD/ = $HOME/go-workspace/src/github.com/* ]]; then
    BRANCH=$BRANCH
  else
    BRANCH=''
  fi
  
  set_user_color
  set_host_color
  set_venv_name

  PS1="$USER_COLOR\u$COLOR_NONE@$HOST_COLOR\h"
  
  if [ -n "$PROMPT_VENV" ]; then
    PS1="$PS1$PROMPT_VENV"
  fi

  if [ -n "$BRANCH" ]; then
    # If in git branch
    PS1="$PS1 $BRANCH"
  else
    PS1="$PS1$COLOR_NONE:$L_BLUE\w"
  fi

  PS1="$PS1$PROMPT_SYMBOL$COLOR_NONE "

}


PROMPT_COMMAND=set_bash_prompt


# --- end https://gist.github.com/sundeepgupta/b099c31ee2cc1eb31b6d --- 
 
alias ls="ls --color -AFv"
alias hub="cd ~/github/"
alias lab="cd ~/gitlab/"

export PS1="$GREEN\u$COLOR_NONE@$WHITE\h $L_BLUE\W \$ $COLOR_NONE"
export PATH=$PATH:$HOME/local/bin/:$HOME/.local/bin/:$HOME/funbox/ioke/dist/ioke/bin:$HOME/funbox/clojure/dist:$HOME/bin:/opt/scala/bin:$HOME/rust-inst/bin:$HOME/.cargo/bin
export SCALA_HOME=/opt/scala
export GEM_HOME=$HOME/.gemhome
export RUBYOPT=rubygems
export DOTNET_CLI_TELEMETRY_OPTOUT=1


export CPPFLAGS="$CPPFLAGS -I$HOME/local/include"
export LDFLAGS="$LDFLAGS -L$HOME/local/lib"
export PKG_CONFIG_PATH="$HOME/local/lib/pkgconfig"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/local/lib"

# Node user-global.
export PATH="$HOME/.node-inst/node_modules/.bin:$PATH"

# Go. Symlink your versioned install to 'go-root'.
export GOROOT="$HOME/go-root/"
export PATH="$HOME/go-root/bin:$PATH"
export GOPATH="$HOME/go-workspace/"


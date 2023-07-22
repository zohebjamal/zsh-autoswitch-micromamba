export AUTOSWITCH_MENV_VERSION='0.3.4'

if ! type micromamba > /dev/null; then
    export DISABLE_AUTOSWITCH_MENV="1"
    printf "\e[1m\e[31m"
    printf "zsh-autoswitch-micromamba requires micromamba to be installed!\n\n"
    printf "\e[0m\e[39m"
    printf "If this is already installed but you are still seeing this message, \nadd the "
    printf "following to your ~/.zshenv:\n\n"
    printf "\e[1m"
    printf ". YOUR_CONDA_PATH/etc/profile.d/conda.sh\n"
    printf "\n"
    printf "\e[0m"
    printf "https://github.com/bckim92/zsh-autoswitch-conda#Setup"
    printf "\e[0m"
    printf "\n"
fi

function _maybeactivate() {
  if [[ -z "$MICROMAMBA_DEFAULT_ENV" || "$1" != "$(basename $MICROMAMBA_DEFAULT_ENV)" ]]; then
     if [ -z "$AUTOSWITCH_SILENT" ]; then
        printf "Switching micromamba environment: %s  " $1
     fi

     micromamba activate "$1"

     if [ -z "$AUTOSWITCH_SILENT" ]; then
       # For some reason python --version writes to st derr
       printf "[%s]\n" "$(python --version 2>&1)"
     fi
  fi
}


# Gives the path to the nearest parent .menv file or nothing if it gets to root
function _check_menv_path()
{
    local check_dir=$1

    if [[ -f "${check_dir}/.menv" ]]; then
        printf "${check_dir}/.menv"
        return
    else
        if [ "$check_dir" = "/" ]; then
            return
        fi
        _check_menv_path "$(dirname "$check_dir")"
    fi
}


# Automatically switch micromamba environment when .menv file detected
function check_menv()
{
    if [ "AS_MENV:$PWD" != "$MYOLDPWD" ]; then
        # Prefix PWD with "AS_MENV:" to signify this belongs to this plugin
        # this prevents the AUTONAMEDIRS in prezto from doing strange things
        # (Since zsh-autoswitch-virtualenv use "AS:" prefix, we instead use "AS_MENV:"
        # See https://github.com/MichaelAquilina/zsh-autoswitch-virtualenv/issues/19
        MYOLDPWD="AS_MENV:$PWD"

        SWITCH_TO=""

        # Get the .menv file, scanning parent directories
        menv_path=$(_check_menv_path "$PWD")
        if [[ -n "$menv_path" ]]; then

          stat --version &> /dev/null
          if [[ $? -eq 0 ]]; then   # Linux, or GNU stat
            file_owner="$(stat -c %u "$menv_path")"
            file_permissions="$(stat -c %a "$menv_path")"
          else                      # macOS, or FreeBSD stat
            file_owner="$(stat -f %u "$menv_path")"
            file_permissions="$(stat -f %OLp "$menv_path")"
          fi

          if [[ "$file_owner" != "$(id -u)" ]]; then
            printf "AUTOSWITCH WARNING: Micromamba environment will not be activated\n\n"
            printf "Reason: Found a .menv file but it is not owned by the current user\n"
            printf "Change ownership of $menv_path to '$USER' to fix this\n"
          elif [[ "$file_permissions" != "600" ]]; then
            printf "AUTOSWITCH WARNING: Micromamba environment will not be activated\n\n"
            printf "Reason: Found a .menv file with weak permission settings ($file_permissions).\n"
            printf "Run the following command to fix this: \"chmod 600 $menv_path\"\n"
          else
            SWITCH_TO="$(<"$menv_path")"
          fi
        fi

        if [[ -n "$SWITCH_TO" ]]; then
          _maybeactivate "$SWITCH_TO"
        else
          _default_menv
        fi
    fi
}

# Switch to the default micromamba environment
function _default_menv()
{
  if [[ -n "$AUTOSWITCH_DEFAULT_MICROMAMBAENV" ]]; then
     _maybeactivate "$AUTOSWITCH_DEFAULT_MICROMAMBAENV"
  elif [[ -n "$MICROMAMBA_DEFAULT_ENV" ]]; then
      micromamba deactivate
  fi
}


# remove micromamba environment for current directory
function rmmenv()
{
  if [[ -f ".menv" ]]; then

    menv_name="$(<.menv)"

    # detect if we need to switch micromamba environment first
    if [[ -n "$MICROMAMBA_DEFAULT_ENV" ]]; then
        current_menv="$(basename $MICROMAMBA_DEFAULT_ENV)"
        if [[ "$current_menv" = "$menv_name" ]]; then
            _default_menv
        fi
    fi

    micromamba env remove --name "$menv_name"
    rm ".menv"
  else
    printf "No .menv file in the current directory!\n"
  fi
}


# helper function to create a micromamba environment for the current directory
function mkmenv()
{
  if [[ -f ".menv" ]]; then
    printf ".menv file already exists. If this is a mistake use the rmmenv command\n"
  else
    menv_name="$(basename $PWD)"
    micromamba create --name "$menv_name" $@
    micromamba activate "$menv_name"

    setopt nullglob
    for requirements in *requirements.txt
    do
      printf "Found a %s file. Install using pip? [y/N]: " "$requirements"
      read ans

      if [[ "$ans" = "y" || "$ans" = "Y" ]]; then
        pip install -r "$requirements"
      fi
    done

    # Sample yml file can be found at
    # https://github.com/vithursant/deep-learning-micromamba-envs/blob/master/tf-py3p6-env.yml
    for requirements in *requirements.yml
    do
      printf "Found a %s file. Install using micromamba? [y/N]: " "$requirements"
      read ans

      if [[ "$ans" = "y" || "$ans" = "Y" ]]; then
        micromamba env update -f "$requirements"
      fi
    done
    for requirements in *environment.yml
    do
      printf "Found a %s file. Install using micromamba? [y/N]: " "$requirements"
      read ans

      if [[ "$ans" = "y" || "$ans" = "Y" ]]; then
        micromamba env update -f "$requirements"
      fi
    done

    printf "$menv_name\n" > ".menv"
    chmod 600 .menv
    AUTOSWITCH_PROJECT="$PWD"
  fi
}

if [[ -z "$DISABLE_AUTOSWITCH_MENV" ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook -D chpwd check_menv
    add-zsh-hook chpwd check_menv

    check_menv
fi

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

prepend_path() {
    case ":$PATH:" in
    *:"$1":*) ;;
    *)
        PATH="$1${PATH:+:$PATH}"
        ;;
    esac
}

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
    prepend_path "$HOME/bin"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
    prepend_path "$HOME/.local/bin"
fi

yarn_dir="${XDG_CONFIG_HOME:-$HOME/.config}/yarn/global"
# Yarn global packages
if [ -d "$yarn_dir/node_modules/.bin/" ]; then
    prepend_path "$yarn_dir/node_modules/.bin"
fi
unset yarn_dir

# Rust packages from `cargo install`
if [ -d "$HOME/.cargo/bin/" ]; then
    prepend_path "$HOME/.cargo/bin"
fi

#allows for system-dependent additions
if [ -f "$HOME/.local/.profile" ]; then
    . "$HOME/.local/.profile"
fi

unset -f prepend_path

export PATH

if command -v dbus-update-activation-environment >/dev/null; then
    dbus-update-activation-environment --systemd --all
    # add system variables to dbus and systemd --user
fi

# timeout console sessions after 5 minutes (300 seconds)
readlink /proc/self/fd/0 | grep -c tty >/dev/null && TMOUT=300

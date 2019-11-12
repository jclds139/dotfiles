#!/bin/bash
if [ "$PWD" != "$HOME/dotfiles" ]; then
	echo "Must be run inside dotfiles directory"
else

	for file in $("ls"); do
		fn=$(basename "$file")
		if [ -e "$HOME/.$fn" ]; then
			mv -v "$HOME/.$fn" "$HOME/old.""$fn"
		fi

		if [ $fn != "install.sh" ]; then # don't link the installer script
			ln -sv "$(pwd)/$fn" "$HOME/.$fn"
		fi
	done

	if [ -d "$HOME/.ssh" ]; then #if we have an ssh setup, link the rc
		ln -sv "$(pwd)/.tmux-ssh/.ssh rc" "$HOME/.ssh/rc"
	fi

	if [ -e "$HOME/.vimrc" ]; then
		mv -v "$HOME/.vimrc" "$HOME/.old.vimrc"
	fi

	if [ -z "$XDG_CONFIG_HOME" ]; then
		ln -sv "$HOME/.vim" "$HOME/.config/nvim"
	else
		ln -sv "$HOME/.vim" "$XDG_CONFIG_HOME/nvim"
	fi
fi

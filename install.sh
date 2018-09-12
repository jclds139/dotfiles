#!/bin/bash
if [ "$(basename $(pwd))" != "dotfiles" ]; then
	echo "Must be run inside dotfiles directory"
else

	for file in $(find . -maxdepth 1 -type f | grep --color=no "\./[^.]"); do
		fn=$(basename "$file")
		if [ -e "$HOME/.$fn" ]; then
			mv -v "$HOME/.$fn" "$HOME/.local.""$fn"
		fi

		if [ $fn != "install.sh" ]; then # don't link the installer script
			ln -sv "$(pwd)/$fn" "$HOME/.$fn"
		fi
	done

	if [ -d "$HOME/.ssh" ]; then #if we have an ssh setup, link the rc
		ln -sv "$(pwd)/tmux-ssh/.ssh rc" "$HOME/.ssh/rc"
	fi

	if [ -d "$HOME/.vim" ]; then #remove 
		mv -v "$HOME/.vim" "$HOME/.local.vim"
	fi

	if [ -e "$HOME/.vimrc" ]; then
		mv -v "$HOME/.vimrc" "$HOME/.local.vimrc"
	fi

	ln -sv "$(pwd)/vim" "$HOME/.vim"
fi

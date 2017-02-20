alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
git clone --bare git@github.com:jared-hess/dotfiles.git $HOME/.dotfiles
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout 
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME submodule init 
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME submodule update 
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config --local status.ShowUntrackedFiles no 

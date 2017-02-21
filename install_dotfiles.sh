git clone --bare git@github.com:jared-hess/dotfiles.git $HOME/.dotfiles
function config {
   /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}
config checkout
if [ $? = 0 ]; then
  echo "Checked out config."
  else
    echo "Backing up pre-existing dot files."
    mkdir -p .dotfiles-backup
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .dotfiles-backup/{}
fi
config checkout
config config status.showUntrackedFiles no

config submodule init
config submodule update


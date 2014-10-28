#!/usr/bin/env bash
# http://qiita.com/osakanafish/items/731dc31168e3330dbcd0
brew update
brew uninstall ricty
brew tap sanemat/font
brew install --vim-powerline ricty
cp -f /usr/local/Cellar/ricty/*/share/fonts/Ricty*.ttf ~/Library/Fonts/
fc-cache -vf
exec $SHELL -l

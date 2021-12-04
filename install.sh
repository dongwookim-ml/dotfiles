#!/bin/bash

# copy zshfile
# cp -i zshrc ~/.zshrc

# copy vim config file
cp -i vimrc ~/.vimrc

# matpotlibrc
# mkdir -p ~/.matplotlib
# cp -i matplotlibrc ~/.matplotlib/matplotlibrc 

# install font
# clone
git clone https://github.com/powerline/fonts.git --depth=1
# install
cd fonts
./install.sh
# clean-up a bit
cd ..
rm -rf fonts


# install powerlevel9k theme for oh-my-zsh
# git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

git clone https://github.com/altercation/vim-colors-solarized ~/.vim/bundle/
mkdir -p ~/.vim/colors/
cp -i ~/.vim/bundle/colors/solarized.vim ~/.vim/colors/

# copy ssh config file
mkdir -p ~/.ssh
cp -i ssh_config ~/.ssh/config


# add ssh-keys
cp ./ssh/* ~/.ssh/
chmod 600 ~/.ssh/*


#!/bin/bash

# copy zshfile
cp -i ~/.zshrc zshrc

# copy vim config file
cp -i ~/.vimrc vimrc

# copy ssh config file
# mkdir -p ~/.ssh
cp -i ~/.ssh/config ssh_config

# matpotlibrc
# mkdir -p ~/.matplotlib
cp -i ~/.matplotlib/matplotlibrc matplotlibrc

# install font
# clone
# git clone https://github.com/powerline/fonts.git --depth=1

# add ssh-keys
cp ~/.ssh/* ./ssh/* 
# chmod 600 ~/.ssh/*

git add --all
git commit -a -m "auto-update dot files"
git push


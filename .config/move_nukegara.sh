#!/usr/bin/env bash
cd `dirname $0`

if [ `echo $PWD | grep nukegara` ]; then
    echo ~/.configで実行してください
    exit
fi

if [ ! "$1" ]; then
    echo usase: $0 [target]
    exit
fi

src=$PWD/$1
if [ ! -e $src ]; then
    echo $src not found
    exit
fi

dst=~/Documents/nukegara/`hostname`/.config/`basename $src`
mv $src $dst
ln -s $dst $src

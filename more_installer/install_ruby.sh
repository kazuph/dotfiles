#!/bin/bash
if [ -f ~/.rbenv ] ; then
    echo exists rbenv
else
    git clone git://github.com/sstephenson/rbenv.git ~/.rbenv
fi

if [ -f ~/.rbenv/plugins/ruby-build ] ; then
    echo exists ruby-build
else
    git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
fi
exec $SHELL -l

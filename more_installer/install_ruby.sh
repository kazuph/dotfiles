#!/bin/bash
which rbenv > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    echo exists rbenv
else
    git clone git://github.com/sstephenson/rbenv.git ~/.rbenv
fi

which rbenv install -l > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    echo exists ruby-build
else
    git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
fi
exec $SHELL -l

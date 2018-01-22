#!/bin/sh
set -e # exit on errors
set -x # echo each line

PROJECTS="neil hlint cmdargs hoogle shake extra"
for PROJECT in ${PROJECTS}; do
    git clone https://github.com/ndmitchell/$PROJECT
done

(cd neil && cabal install --flags=small)
(cd hlint && cabal install)

for PROJECT in ${PROJECTS}; do
    (cd $PROJECT && neil check && hlint .)
done

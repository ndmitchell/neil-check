#!/bin/sh
set -e # exit on errors
set -x # echo each line

cabal install happy
ghc --version
cabal --version
happy --version

# My list of projects I check on Travis and which might break due to me changing the rules after-the-fact
PROJECTS="cmdargs debug extra ghc-make ghcid hexml hlint hoogle js-flot js-jquery neil nsis profiterole safe shake tagsoup weeder"
for PROJECT in ${PROJECTS}; do
    git clone https://github.com/ndmitchell/$PROJECT
done

(cd neil && cabal install --flags=small)
(cd hlint && cabal install)

for PROJECT in ${PROJECTS}; do
    (cd $PROJECT && neil check && hlint .)
done

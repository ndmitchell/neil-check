#!/bin/sh
set -e # exit on errors
set -x # echo each line

export PATH=$HOME/.cabal/bin:$PATH
ghc --version
cabal --version

# Currently excluded but should be included
TODO="ghc-make derive uniplate"

# My list of projects I check on Travis and which might break due to me changing the rules after-the-fact
PROJECTS="cmdargs debug extra ghcid hexml hlint hoogle js-flot js-jquery neil nsis profiterole safe shake tagsoup weeder"
for PROJECT in ${PROJECTS}; do
    git clone https://github.com/ndmitchell/$PROJECT
done

(cd neil && cabal install --flags=small)
for PROJECT in ${PROJECTS}; do
    (cd $PROJECT && neil check)
done

cabal install happy
happy --version
(cd hlint && cabal install)
for PROJECT in ${PROJECTS}; do
    (cd $PROJECT && hlint .)
done

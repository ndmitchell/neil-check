
import System.IO.Extra
import System.Directory.Extra
import Data.List
import Control.Monad
import System.Process.Extra
import System.FilePath


projects = words "cmdargs debug derive extra ghc-make ghcid hexml hlint hoogle js-flot js-jquery neil nsis profiterole safe shake tagsoup uniplate weeder"
excluded = words "ghc-make derive uniplate"

main = withTempDir $ \tdir -> withCurrentDirectory tdir $ do
    system_ <- return $ \x -> do
        dir <- getCurrentDirectory
        putStrLn $ "$ cd " ++ takeFileName dir ++ " && " ++ x
        system_ x

    let ps = projects \\ excluded
    forM_ ps $ \p ->
        system_ $ "git clone --depth=1 https://github.com/ndmitchell/" ++ p

    withCurrentDirectory "neil" $ do
        system_ "cabal install --dependencies"
        system_ "cabal configure --flags=small"
        system_ "cabal build"
    forM_ ps $ \p ->
        withCurrentDirectory p $ system_ $ normalise "../neil/dist/build/neil/neil" ++ " check"

    withCurrentDirectory "hlint" $ do
        system_ "cabal install happy"
        system_ "cabal install --dependencies"
        system_ "cabal configure"
        system_ "cabal build"
        files <- listFilesRecursive "data"
        print files
        forM_ files $ \file -> do
            let out = "dist/build/hlint" </> file
            createDirectoryIfMissing True $ takeDirectory out
            copyFile file out
    forM_ ps $ \p ->
        withCurrentDirectory p $ do
            b <- doesDirectoryExist "src"
            system_ $ normalise "../hlint/dist/build/hlint/hlint" ++ " " ++ (if b then "src" else ".")

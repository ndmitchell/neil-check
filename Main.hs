
import System.IO.Extra
import System.Directory.Extra
import Data.List
import Data.Maybe
import Control.Exception.Extra
import Control.Monad
import System.Process.Extra
import System.FilePath


projects =
    -- deliberately exclude ghc-make, derive, uniplate
    map ("ndmitchell/" ++) (words "cmdargs debug extra ghcid hexml hlint hoogle js-flot js-jquery neil nsis profiterole safe shake tagsoup weeder record-dot-preprocessor") ++
    ["haskell/filepath"]

forEachProject :: (String -> IO ()) -> IO ()
forEachProject act = do
    failed <- fmap catMaybes $ forM projects $ \p -> do
        res <- try_ $ act p
        case res of
            Left e -> do putStrLn $ "FAILED: " ++ p ++ ", " ++ show e; return $ Just p
            Right _ -> return Nothing
    when (failed /= []) $
        fail $ "FAILED: " ++ unwords failed


main = withTempDir $ \tdir -> withCurrentDirectory tdir $ do
    system_ <- return $ \x -> do
        dir <- getCurrentDirectory
        putStrLn $ "$ cd " ++ takeFileName dir ++ " && " ++ x
        system_ x

    forM_ projects $ \p ->
        system_ $ "git clone --depth=1 https://github.com/" ++ p

    withCurrentDirectory "neil" $ do
        system_ "cabal install --flags=small --dependencies"
        system_ "cabal configure --flags=small"
        system_ "cabal build"
    forEachProject $ \p ->
        withCurrentDirectory (takeFileName p) $ system_ $ normalise "../neil/dist/build/neil/neil" ++ " check"

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
    forEachProject $ \p ->
        withCurrentDirectory (takeFileName p) $ do
            b <- doesDirectoryExist "src"
            system_ $ normalise "../hlint/dist/build/hlint/hlint" ++ " " ++ (if b then "src" else ".")


import System.IO.Extra
import System.Directory.Extra
import Data.List
import Data.Maybe
import Control.Exception.Extra
import Control.Monad
import System.Process.Extra
import System.FilePath
import Data.List.Extra


projects =
    -- deliberately exclude ghc-make, debug, derive
    map ("ndmitchell/" ++) (words "cmdargs extra filepattern ghcid hexml hlint hoogle js-flot js-jquery js-dgtable neil nsis profiterole safe shake tagsoup record-dot-preprocessor record-hasfield rattle uniplate")

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
    hSetBuffering stdout NoBuffering
    hSetBuffering stderr NoBuffering
    system_ <- return $ \x -> do
        dir <- getCurrentDirectory
        putStrLn $ "$ cd " ++ takeFileName dir ++ " && " ++ x
        system_ x

    forM_ projects $ \p ->
        system_ $ "git clone --depth=1 https://github.com/" ++ p

    withCurrentDirectory "neil" $ do
        system_ "cabal new-install --flags=small --installdir=."
    forEachProject $ \p ->
        withCurrentDirectory (takeFileName p) $ system_ $ normalise "../neil/neil" ++ " check"

    withCurrentDirectory "hlint" $ do
        system_ "cabal new-install --disable-optimisation --installdir=."
    forEachProject $ \p ->
        withCurrentDirectory (takeFileName p) $ do
            xs <- readFile' ".travis.yml"
            let unquote = dropPrefix "\"" . dropSuffix "\""
            let args = unquote $ fromMaybe "." $ firstJust (stripPrefix "- export HLINT_ARGUMENTS=") $ lines xs
            system_ $ normalise "../hlint/hlint" ++ " " ++ args ++ " --with-group=extra --with-group=future"

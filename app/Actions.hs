module Actions (act) where

import OptionsParser
import Types

import Language.Haskell.Format
import Language.Haskell.Format.Definitions

import Control.Monad
import Data.Algorithm.Diff
import Data.Algorithm.DiffContext
import Data.Algorithm.DiffOutput
import Text.PrettyPrint

act :: Options -> ReformatResult -> IO ()
act options (InvalidReformat input errorString) =
  putStrLn ("Error reformatting " ++ show input ++ ": " ++ errorString)
act options (Reformat input source result) = act' (optAction options)
  where
    act' PrintDiffs = when wasReformatted (printDiff input source result)
    act' PrintSources = undefined
    act' PrintFilePaths = when wasReformatted (print input)
    act' WriteSources = when wasReformatted (writeSource input (reformattedSource result))
    wasReformatted = sourceChangedOrHasSuggestions source result

sourceChangedOrHasSuggestions :: HaskellSource -> Reformatted -> Bool
sourceChangedOrHasSuggestions source reformatted =
  not (null (suggestions reformatted)) || source /= reformattedSource reformatted

printDiff :: InputFile -> HaskellSource -> Reformatted -> IO ()
printDiff (InputFilePath path) source reformatted = do
  putStrLn (path ++ ":")
  mapM_ (putStr . show) (suggestions reformatted)
  putStr (showDiff source (reformattedSource reformatted))
printDiff (InputFromStdIn) source reformatted = do
  mapM_ (putStr . show) (suggestions reformatted)
  putStr (showDiff source (reformattedSource reformatted))

showDiff :: HaskellSource -> HaskellSource -> String
showDiff (HaskellSource a) (HaskellSource b) = render (toDoc diff)
  where
    toDoc = prettyContextDiff (text "Original") (text "Reformatted") text
    diff = getContextDiff linesOfContext (lines a) (lines b)
    linesOfContext = 1

writeSource :: InputFile -> HaskellSource -> IO ()
writeSource (InputFilePath path) (HaskellSource source) = writeFile path source
writeSource InputFromStdIn (HaskellSource source) = putStr source

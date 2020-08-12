{-# LANGUAGE FlexibleContexts #-}

module Monomer.Main.Util where

import Control.Applicative ((<|>))
import Data.Default
import Data.Maybe

import qualified Data.Sequence as Seq

import Monomer.Common.Geometry
import Monomer.Common.Tree (Path, rootPath)
import Monomer.Main.Types
import Monomer.Widget.Types
import Monomer.Widget.Util

initMonomerContext :: s -> Size -> Bool -> Double -> MonomerContext s
initMonomerContext model winSize useHiDPI devicePixelRate = MonomerContext {
  _mcMainModel = model,
  _mcWindowSize = winSize,
  _mcHdpi = useHiDPI,
  _mcDpr = devicePixelRate,
  _mcInputStatus = def,
  _mcPathFocus = Seq.empty,
  _mcPathHover = Nothing,
  _mcPathPressed = Nothing,
  _mcPathOverlay = Nothing,
  _mcWidgetTasks = Seq.empty
}

findNextFocusable :: WidgetEnv s e -> Path -> WidgetInstance s e -> Path
findNextFocusable wenv currentFocus widgetRoot = fromJust nextFocus where
  widget = _wiWidget widgetRoot
  candidateFocus = widgetNextFocusable widget wenv currentFocus widgetRoot
  fromRootFocus = widgetNextFocusable widget wenv rootPath widgetRoot
  nextFocus = candidateFocus <|> fromRootFocus <|> Just currentFocus

resizeWidget
  :: WidgetEnv s e -> Size -> WidgetInstance s e -> WidgetInstance s e
resizeWidget wenv windowSize widgetRoot = newRoot where
  Size w h = windowSize
  assigned = Rect 0 0 w h
  instReqs = widgetPreferredSize (_wiWidget widgetRoot) wenv widgetRoot
  newRoot = widgetResize (_wiWidget instReqs) wenv assigned assigned instReqs

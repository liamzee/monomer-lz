{-# LANGUAGE RecordWildCards #-}

module Monomer.Widget.Widgets.Spacer (spacer) where

import Control.Monad

import Monomer.Common.Geometry
import Monomer.Common.Style
import Monomer.Common.Tree
import Monomer.Widget.BaseWidget
import Monomer.Widget.Types
import Monomer.Widget.Util

spacer :: (Monad m) => WidgetInstance s e m
spacer = defaultWidgetInstance "spacer" makeSpacer

defaultSpace :: Double
defaultSpace = 10

makeSpacer :: (Monad m) => Widget s e m
makeSpacer = createWidget {
    _widgetPreferredSize = preferredSize
  }
  where
    preferredSize renderer app widgetInstance = singleNode sizeReq where
      sizeReq = SizeReq (Size defaultSpace defaultSpace) RemainderSize RemainderSize

{-# LANGUAGE MultiWayIf #-}

module Monomer.Widget.Widgets.Stack (
  hstack,
  vstack
) where

import Control.Monad
import Data.List (foldl')
import Data.Sequence (Seq(..), (<|), (|>))

import qualified Data.Sequence as Seq

import Monomer.Common.Geometry
import Monomer.Common.Tree
import Monomer.Widget.Types
import Monomer.Widget.BaseContainer
import Monomer.Widget.Util

hstack :: (Traversable t) => t (WidgetInstance s e) -> WidgetInstance s e
hstack children = (defaultWidgetInstance "hstack" (makeStack True)) {
  _wiChildren = foldl' (|>) Empty children
}

vstack :: (Traversable t) => t (WidgetInstance s e) -> WidgetInstance s e
vstack children = (defaultWidgetInstance "vstack" (makeStack False)) {
  _wiChildren = foldl' (|>) Empty children
}

makeStack :: Bool -> Widget s e
makeStack isHorizontal = widget where
  widget = createContainer {
    widgetPreferredSize = containerPreferredSize preferredSize,
    widgetResize = containerResize resize
  }

  preferredSize wenv widgetInst children = sizeReq where
    vreqs = _wiSizeReq <$> Seq.filter _wiVisible children
    size = calcPreferredSize vreqs
    sizeReq = SizeReq size FlexibleSize FlexibleSize

  resize wenv viewport renderArea children widgetInst = resized where
    Rect l t w h = renderArea
    vchildren = Seq.filter _wiVisible children
    vreqs = _wiSizeReq <$> vchildren
    mainSize = if isHorizontal then w else h
    mainStart = if isHorizontal then l else t
    policyFilter policy req = policySelector req == policy
    sChildren = Seq.filter (policyFilter StrictSize) vreqs
    fChildren = Seq.filter (policyFilter FlexibleSize) vreqs
    rChildren = Seq.filter (policyFilter RemainderSize) vreqs
    fExists = not $ null fChildren
    rExists = not $ null rChildren
    sSize = sizeSelector $ calcPreferredSize sChildren
    fSize = sizeSelector $ calcPreferredSize fChildren
    rSize = max 0 (mainSize - sSize)
    fCount = fromIntegral $ length fChildren
    rCount = fromIntegral $ length rChildren
    fExtra
      | fExists && fSize > 0 = (rSize - fSize) / fSize
      | otherwise = 0
    rUnit
      | rExists && (not fExists || fSize <= 0) = rSize / rCount
      | otherwise = 0
    assignedArea = Seq.zip newViewports newViewports
    (newViewports, _) = foldl' foldHelper (Seq.empty, mainStart) children
    foldHelper (accum, offset) child = (newAccum, newOffset) where
      newSize = resizeChild renderArea fExtra rUnit offset child
      newAccum = accum |> newSize
      newOffset = offset + rectSelector newSize
    resized = (widgetInst, assignedArea)

  resizeChild renderArea fExtra rUnit offset child = result where
    Rect l t w h = renderArea
    req = _wiSizeReq child
    srSize = _srSize req
    emptyRect = Rect l t 0 0
    hRect = Rect offset t calcNewSize h
    vRect = Rect l offset w calcNewSize
    calcNewSize = case policySelector req of
      StrictSize -> sizeSelector srSize
      FlexibleSize -> (1 + fExtra) * sizeSelector srSize
      RemainderSize -> rUnit
    result
      | not $ _wiVisible child = emptyRect
      | isHorizontal = hRect
      | otherwise = vRect

  calcPreferredSize vreqs = Size width height where
    (maxWidth, sumWidth, maxHeight, sumHeight) = calcDimensions vreqs
    width = if isHorizontal then sumWidth else maxWidth
    height = if isHorizontal then maxHeight else sumHeight

  calcDimensions vreqs = (maxWidth, sumWidth, maxHeight, sumHeight) where
    sumWidth = (sum . fmap (_w . _srSize)) vreqs
    sumHeight = (sum . fmap (_h . _srSize)) vreqs
    maxWidth
      | Seq.null vreqs = 0
      | otherwise = (maximum . fmap (_w . _srSize)) vreqs
    maxHeight
      | Seq.null vreqs = 0
      | otherwise = (maximum . fmap (_h . _srSize)) vreqs

  sizeSelector = if isHorizontal then _w else _h
  rectSelector = if isHorizontal then _rw else _rh
  policySelector = if isHorizontal then _srPolicyWidth else _srPolicyHeight

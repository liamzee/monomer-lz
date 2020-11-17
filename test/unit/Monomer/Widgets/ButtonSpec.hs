module Monomer.Widgets.ButtonSpec (spec) where

import Data.Default
import Data.Text (Text)
import Test.Hspec

import qualified Data.Sequence as Seq

import Monomer.Core
import Monomer.Event
import Monomer.TestUtil
import Monomer.Widgets.Button

data BtnEvent
  = BtnClick
  | GotFocus
  | LostFocus
  deriving (Eq, Show)

spec :: Spec
spec = describe "Button" $ do
  handleEvent
  updateSizeReq

handleEvent :: Spec
handleEvent = describe "handleEvent" $ do
  it "should not generate an event if clicked outside" $
    clickEvts (Point 3000 3000) `shouldBe` Seq.empty

  it "should generate a user provided event when clicked" $
    clickEvts (Point 100 100) `shouldBe` Seq.singleton BtnClick

  it "should generate a user provided event when Enter/Space is pressed" $
    keyEvts keyReturn `shouldBe` Seq.singleton BtnClick

  it "should generate an event when focus is received" $
    events Focus `shouldBe` Seq.singleton GotFocus

  it "should generate an event when focus is lost" $
    events Blur `shouldBe` Seq.singleton LostFocus

  where
    wenv = mockWenv ()
    btnInst = button_ "Click" BtnClick [onFocus GotFocus, onBlur LostFocus]
    clickEvts p = instHandleEventEvts wenv [Click p LeftBtn] btnInst
    keyEvts key = instHandleEventEvts wenv [KeyAction def key KeyPressed] btnInst
    events evt = instHandleEventEvts wenv [evt] btnInst

updateSizeReq :: Spec
updateSizeReq = describe "updateSizeReq" $ do
  it "should return width = Flex 50 1" $
    sizeReqW `shouldBe` FlexSize 50 1

  it "should return height = Fixed 20" $
    sizeReqH `shouldBe` FixedSize 20

  where
    wenv = mockWenv ()
    btnInst = button "Click" BtnClick
    (sizeReqW, sizeReqH) = instUpdateSizeReq wenv btnInst

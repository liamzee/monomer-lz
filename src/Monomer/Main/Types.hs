{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TemplateHaskell #-}

module Monomer.Main.Types where

import Control.Concurrent.Async
import Control.Concurrent.STM.TChan
import Control.Monad.State
import Data.Typeable (Typeable)
import Data.Sequence (Seq, (|>), (<|), fromList)
import Lens.Micro.TH (makeLenses)

import Monomer.Common.Geometry
import Monomer.Common.Tree
import Monomer.Event.Types
import Monomer.Widget.Types

type MonomerM s m = (Eq s, MonadState (MonomerContext s) m, MonadIO m)
type UIBuilder s e = s -> WidgetInstance s e
type AppEventHandler s e = s -> e -> EventResponse s e

type TaskHandler e = IO (Maybe e)
type ProducerHandler e = (e -> IO ()) -> IO ()

data EventResponse s e = State s
                       | Event e
                       | Task (TaskHandler e)
                       | Producer (ProducerHandler e)
                       | Multiple (Seq (EventResponse s e))

instance Semigroup (EventResponse s e) where
  Multiple seq1 <> Multiple seq2 = Multiple (seq1 <> seq2)
  Multiple seq1 <> er2 = Multiple (seq1 |> er2)
  er1 <> Multiple seq2 = Multiple (er1 <| seq2)
  er1 <> er2 = Multiple (fromList [er1, er2])

data MonomerApp s e m = MonomerApp {
  _uiBuilder :: UIBuilder s e,
  _appEventHandler :: AppEventHandler s e
}

data MonomerContext s = MonomerContext {
  _appContext :: s,
  _windowSize :: Rect,
  _useHiDPI :: Bool,
  _devicePixelRate :: Double,
  _inputStatus :: InputStatus,
  _focused :: Path,
  _latestHover :: Maybe Path,
  _widgetTasks :: Seq WidgetTask
}

data WidgetTask =
    forall a . Typeable a => WidgetTask Path (Async a)
  | forall a . Typeable a => WidgetProducer Path (TChan a) (Async ())

makeLenses ''MonomerContext

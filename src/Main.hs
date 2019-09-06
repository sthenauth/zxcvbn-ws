{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveAnyClass      #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators       #-}

{-|

Copyright:
  This file is part of the package zxcvbn-ws. It is subject to the
  license terms in the LICENSE file found in the top-level directory
  of this distribution and at:

    https://code.devalot.com/sthenauth/zxcvbn-ws

  No part of this package, including this file, may be copied,
  modified, propagated, or distributed except according to the terms
  contained in the LICENSE file.

License: MIT

-}
module Main (main) where

--------------------------------------------------------------------------------
-- Library Imports:
import System.Environment (lookupEnv)
import Control.Monad (forever)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Aeson (FromJSON, ToJSON)
import qualified Data.Aeson as Aeson
import Data.Text (Text)
import qualified Data.Text as Text
import Data.Time.Calendar (Day)
import Data.Time.Clock (getCurrentTime, utctDay)
import GHC.Generics (Generic)
import qualified Network.Wai.Handler.Warp as Warp
import Network.WebSockets (Connection)
import qualified Network.WebSockets as WS
import Servant
import Servant.API.WebSocket (WebSocket)
import Servant.Server.StaticFiles (serveDirectoryFileServer)
import System.FilePath ((</>))
import qualified Text.Password.Strength as Zxcvbn

--------------------------------------------------------------------------------
-- | Access the static www files.
import Paths_zxcvbn_ws (getDataDir)

--------------------------------------------------------------------------------
-- | Web Socket request.
newtype Request = Request
  { password :: Text
    -- ^ The password that we're being asked to analyze.

  } deriving (Generic, FromJSON)

--------------------------------------------------------------------------------
-- | Web Socket response.
data Response = Response
  { description :: Text
    -- ^ English text describing the strength of a password.

  , strength :: Int
    -- ^ Numeric strength ranges from 0 to @possible@.

  , possible :: Int
    -- ^ Maximum possible strength.  Useful to gauge the @strength@
    -- value against.

  } deriving (Generic, ToJSON)

--------------------------------------------------------------------------------
-- | Configuration options.
newtype Options = Options
  { portNum :: Int
    -- ^ What port should we bind to?
  }

--------------------------------------------------------------------------------
-- | Configuration options.
options :: IO Options
options = do
  portNum <- maybe 12345 read <$> lookupEnv "ZXCVBN_PORT"
  pure Options{..}

--------------------------------------------------------------------------------
-- | Servant/HTTP routes.
type API = "connect" :> WebSocket :<|> Raw

--------------------------------------------------------------------------------
-- | Necessary Servant boilerplate.
api :: Proxy API
api = Proxy

--------------------------------------------------------------------------------
-- | HTTP handler.
server :: FilePath -> Server API
server www = handler :<|> serveDirectoryFileServer www

--------------------------------------------------------------------------------
-- | Handle a Web Socket connection by reading requests and writing
-- responses.  All messages are encoded as JSON.
handler :: forall m. (MonadIO m) => Connection -> m ()
handler connection = do
  liftIO (WS.forkPingThread connection 30)

  forever $ do
    msg <- liftIO (WS.receiveDataMessage connection)

    case Aeson.eitherDecode (WS.fromDataMessage msg) of
      Left _  -> pure () -- Ignore request
      Right m -> (`go` m) . utctDay <$> liftIO getCurrentTime >>= send

  where
    -- Score a password and generate a response.  Only score the first
    -- 100 characters of the password to keep this running fast.
    go :: Day -> Request -> Response
    go day Request{..} =
      let score' = Zxcvbn.score Zxcvbn.en_US day (Text.take 100 password)
          score  = Zxcvbn.strength score'
      in Response { description = Text.pack (show score)
                  , strength    = fromEnum score
                  , possible    = fromEnum (maxBound :: Zxcvbn.Strength)
                  }

    -- Send a response to the client.
    send :: Response -> m ()
    send = liftIO . WS.sendTextData connection . Aeson.encode

--------------------------------------------------------------------------------
-- | Hey, it's main!
main :: IO ()
main = do
  -- Where are our static files?
  root <- getDataDir

  -- Configuration options:
  Options{..} <- options

  -- Start your engines!
  Warp.run portNum $ serve api (server $ root </> "www")

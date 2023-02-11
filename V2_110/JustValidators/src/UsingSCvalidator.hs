{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE NoImplicitPrelude   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TypeApplications    #-}
{-# LANGUAGE TypeFamilies        #-}
{-# LANGUAGE TypeOperators       #-}
{-# LANGUAGE OverloadedStrings   #-}

module UsingSCvalidator where

--PlutusTx 
import           PlutusTx                       (Data (..))
import qualified PlutusTx
import qualified PlutusTx.Builtins              as Builtins
import           PlutusTx.Prelude               hiding (Semigroup(..), unless, (.))
           
--Ledger 
import           Ledger                         hiding (singleton)
import qualified Ledger.Address                 as V1Address
import           Ledger.Constraints             as Constraints              -- Same library name, different functions for V1 and V2 in some cases
--import qualified Ledger.Typed.Scripts         as Scripts
import           Ledger.Typed.Scripts           as UScripts
import           Ledger.Typed.Scripts.Validators
import qualified Plutus.Script.Utils.V2.Typed.Scripts as Scripts            -- New library name for Typed Validators and some new fuctions
import qualified Plutus.V2.Ledger.Api                 as PlutusV2            
import           Ledger.Ada                     as Ada
import           Ledger
--import for Serialization
import           Cardano.Api                          (PlutusScript, PlutusScriptV2, writeFileTextEnvelope)
import           Cardano.Api.Shelley                  (PlutusScript (..),
                                                       ScriptDataJsonSchema (ScriptDataJsonDetailedSchema),
                                                       fromPlutusData,
                                                       scriptDataToJson)
import          Codec.Serialise          
import           Data.Aeson                           as A
import qualified Data.ByteString.Lazy                 as LBS
import qualified Data.ByteString.Short                as SBS
import           Data.Functor                         (void)
import           Prelude                              (FilePath, IO, Semigroup (..), Show (..), print, (.))
import qualified Plutus.V1.Ledger.Api                 as PlutusV1



{-# OPTIONS_GHC -fno-warn-unused-imports #-}

--THE ON-CHAIN CODE

data Actions = RequestLoan | CancelLoan

data LoanBond = LB { borrower :: PubKeyHash
                   , request  :: Ledger.Value
                   , duration :: POSIXTime
                   , collateral :: Ledger.Value
                   }

{-# INLINABLE loanRequest #-} 
loanRequest :: LoanBond -> Actions -> PlutusV2.ScriptContext -> Bool   
loanRequest datum action sContext 
  | action == RequestLoan      = requestLoan
  | action == CancelLoan       = cancelLoan  
  | otherwise                  = False
  where

    info :: TxInfo
    info = scriptContextTxInfo sContext

    timeoutReached :: Bool
    timeoutReached = contains (from $ duration datum) (txInfoValidRange info)   
 
    requestLoan :: Bool
    requestLoan = True
    cancelLoan :: Bool
    cancelLoan = True

data Typed                                                          -- New type that encode the information about the Datum and the Redeemer
instance Scripts.ValidatorTypes Typed where
     type instance RedeemerType Typed = Actions
     type instance DatumType Typed = LoanBond
   
typedValidator :: Scripts.TypedValidator Typed
typedValidator = Scripts.mkTypedValidator @Typed
    $$(PlutusTx.compile [|| typedRedeemer ||]) 
    $$(PlutusTx.compile [|| wrap ||])                               
  where
    wrap = UScripts.mkUntypedValidator  --New wrapper function for typed validators             
    

validator :: Validator
validator = Scripts.validatorScript typedValidator                   -- Get the untyped validator script of the wrapped typeValidator PlutusCore

valHash :: Ledger.ValidatorHash
valHash = Scripts.validatorHash typedValidator                      

scrAddress :: Ledger.Address
scrAddress = Scripts.validatorAddress typedValidator                 -- New functino to derive the address, included in the Utils library
--scrAddress = scriptAddress validator 

{- As a Short Byte String -}

scriptSBS :: SBS.ShortByteString
scriptSBS = SBS.toShort . LBS.toStrict $ serialise validator

{- As a Serialised Script -}

serialisedScript :: PlutusScript PlutusScriptV2
serialisedScript = PlutusScriptSerialised scriptSBS

writeRL :: IO ()
writeRL = void $ writeFileTextEnvelope "./testnet/RequestLoan.plutus" Nothing serialisedScript

writeJSON :: PlutusTx.ToData a => FilePath -> a -> IO ()
writeJSON file = LBS.writeFile file . A.encode . scriptDataToJson ScriptDataJsonDetailedSchema . fromPlutusData . PlutusV1.toData

writeRedeemerRL :: IO ()
writeRedeemerRL = writeJSON "./testnet/requestLoan.json" (RequestLoan)

-- writeDatum :: IO ()
-- writeDatum = writeJSON "./testnet/mwd20.json" (MWDan 20)


writeUnit :: IO ()
writeUnit = writeJSON "./testnet/unit.json" ()

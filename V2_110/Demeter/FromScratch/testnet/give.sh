utxoin="23d14bb9fedcdb0720d955b8f626d326cf570902ddd720f99c61087835f2302c#0"
address=$(cat vesting.addr)
address_out=$(cat payment.addr) 
output="100000000"

cardano-cli query protocol-parameters --testnet-magic 2 --out-file protocol.params

cardano-cli transaction build \
  --babbage-era \
  --testnet-magic 2 \
  --tx-in $utxoin \
  --tx-out $address+$output \
  --tx-out-datum-hash-file unit.json \
  --change-address  $address_out\
  --protocol-params-file protocol.params \
  --out-file give.unsigned

cardano-cli transaction sign \
    --tx-body-file give.unsigned \
    --signing-key-file benef1.skey \
    --testnet-magic 2 \
    --out-file give.signed

 cardano-cli transaction submit \
    --testnet-magic 2 \
    --tx-file give.signed
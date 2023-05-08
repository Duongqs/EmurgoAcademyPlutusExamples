utxoin="68e34108ea8300d746479deed9d3f189d46842a6c402e379702f75c6319404c9#1"
address=$(cat vesting.addr) 
output="90000000"
collateral="7232b2242a6542b2336b52fe655f84007ad5e6fd45dd40a81b45ea5b9420acdc#1"
signerPKH="5153b2f1d11f5739c36776d1e89db5a4e9d6d450e9150a8a0c853c44"
nami="addr_test1qz50c8fgdlk9nafppmlzdu6nr8fzpzzgp4vl7l5dvt95lcl4qx6ehrzfcm7cu78gymeqxtzemw9txrgywk0m0qcxux4qm3fx2d"
payment=$(cat payment.addr)

cardano-cli transaction build \
  --babbage-era \
  --testnet-magic 2 \
  --tx-in $utxoin \
  --tx-in-script-file DvR.plutus \
  --tx-in-datum-file value19.json \
  --tx-in-redeemer-file value22.json \
  --required-signer-hash $signerPKH \
  --tx-in-collateral $collateral \
  --tx-out $payment+$output \
  --change-address $nami \
  --protocol-params-file protocol.params \
  --out-file grab.unsigned

cardano-cli transaction sign \
    --tx-body-file grab.unsigned \
    --signing-key-file benef1.skey \
    --testnet-magic 2 \
    --out-file grab.signed

 cardano-cli transaction submit \
    --testnet-magic 2 \
    --tx-file grab.signed
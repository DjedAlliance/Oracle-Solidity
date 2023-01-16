
#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | xargs) 
else
    echo "Please set your .env file"
    exit 1
fi


forge create --legacy --rpc-url ${RPC_URL} \
    --constructor-args  ${OWNER} ${DESCRIPTION} ${TERMS_OF_SERVICE} \
    --private-key ${PRIVATE_KEY} src/SimpleOracle.sol:SimpleOracle

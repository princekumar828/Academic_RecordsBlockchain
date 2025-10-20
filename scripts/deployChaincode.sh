#!/bin/bash
#
# Copyright NIT Warangal. All Rights Reserved.
#
# Script to deploy chaincode

CHANNEL_NAME=${1:-"academic-records-channel"}
CC_NAME=${2:-"academic-records"}
CC_SRC_PATH=${3:-"../chaincode-go/academic-records"}
CC_VERSION=${4:-"1.0"}
CC_SEQUENCE=${5:-"1"}
CC_INIT_FCN=${6:-"NA"}
CC_END_POLICY=${7:-"NA"}
CC_COLL_CONFIG=${8:-"NA"}
DELAY=${9:-"3"}
MAX_RETRY=${10:-"5"}
VERBOSE=${11:-"false"}

export PATH=${PWD}/../../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../config

echo "Deploying chaincode ${CC_NAME} on channel ${CHANNEL_NAME}"

# import environment variables
. scripts/envVar.sh

packageChaincode() {
  set -x
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang golang --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode packaging failed"
  echo "Chaincode is packaged"
}

# installChaincode PEER ORG
installChaincode() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode installation on peer0.org${ORG} failed"
  echo "Chaincode is installed on peer0.org${ORG}"
}

# queryInstalled PEER ORG
queryInstalled() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on peer0.org${ORG} failed"
  echo "Query installed successful on peer0.org${ORG} on channel"
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.nitw.edu --tls --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  echo "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME'"
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  ORG=$1
  shift 1
  setGlobals $ORG
  echo "Checking the commit readiness of the chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    echo "Attempting to check the commit readiness of the chaincode definition on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} --output json >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=0
    for var in "$@"; do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    echo "Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    echo "After $MAX_RETRY attempts, Check commit readiness result on peer0.org${ORG} is INVALID!"
    exit 1
  fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.nitw.edu --tls --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} "${PEER_CONN_PARMS[@]}" --version ${CC_VERSION} --sequence ${CC_SEQUENCE} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  echo "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

# queryCommitted ORG
queryCommitted() {
  ORG=$1
  setGlobals $ORG
  EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
  echo "Querying chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    echo "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    echo "Query chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    echo "After $MAX_RETRY attempts, Query chaincode definition result on peer0.org${ORG} is INVALID!"
    exit 1
  fi
}

chaincodeInvokeInit() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  set -x
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.nitw.edu --tls --cafile "$ORDERER_CA" -C $CHANNEL_NAME -n ${CC_NAME} "${PEER_CONN_PARMS[@]}" --isInit -c '{"function":"InitLedger","Args":[]}' >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"
}

chaincodeQuery() {
  ORG=$1
  setGlobals $ORG
  echo "Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    echo "Attempting to Query peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["GetAllStudents"]}' >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    echo "Query successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    echo "After $MAX_RETRY attempts, Query result on peer0.org${ORG} is INVALID!"
    exit 1
  fi
}

## Package the chaincode
packageChaincode

## Install chaincode on peer0.org1 and peer0.org2
echo "Installing chaincode on peer0.nitwarangal..."
installChaincode 1
echo "Install chaincode on peer0.departments..."
installChaincode 2
echo "Install chaincode on peer0.verifiers..."
installChaincode 3

## query whether the chaincode is installed
queryInstalled 1

## approve the definition for org1
approveForMyOrg 1

## check whether the chaincode definition is ready to be committed
checkCommitReadiness 1 "\"NITWarangalMSP\": true" "\"DepartmentsMSP\": false" "\"VerifiersMSP\": false"

## approve the definition for org2
approveForMyOrg 2

## check whether the chaincode definition is ready to be committed
checkCommitReadiness 1 "\"NITWarangalMSP\": true" "\"DepartmentsMSP\": true" "\"VerifiersMSP\": false"

## approve the definition for org3
approveForMyOrg 3

## check whether the chaincode definition is ready to be committed
checkCommitReadiness 1 "\"NITWarangalMSP\": true" "\"DepartmentsMSP\": true" "\"VerifiersMSP\": true"

## commit the chaincode definition
commitChaincodeDefinition 1 2 3

## query on both orgs to see that the definition committed successfully
queryCommitted 1

## Invoke the chaincode - Initialize
chaincodeInvokeInit 1 2 3

sleep 10

## Query chaincode
echo "Querying chaincode on peer0.nitwarangal..."
chaincodeQuery 1

exit 0

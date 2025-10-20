#!/bin/bash
#
# Copyright NIT Warangal. All Rights Reserved.
#
# Script to create channel

CHANNEL_NAME=${1:-"academic-records-channel"}
DELAY=${2:-"3"}
MAX_RETRY=${3:-"5"}
VERBOSE=${4:-"false"}

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}

echo "Channel name: ${CHANNEL_NAME}"

# import environment variables
. scripts/envVar.sh

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelGenesisBlock() {
	which configtxgen
	if [ "$?" -ne 0 ]; then
		echo "configtxgen tool not found."
		exit 1
	fi
	set -x
	configtxgen -profile AcademicRecordsChannel -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	setGlobals 1
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		osnadmin channel join --channelID $CHANNEL_NAME --config-block ./channel-artifacts/${CHANNEL_NAME}.block -o orderer.nitw.edu:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  ORG=$1
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

setAnchorPeer() {
  ORG=$1
  setGlobals $ORG
  
  docker exec cli peer channel fetch config channel-artifacts/config_block.pb -o orderer.nitw.edu:7050 --ordererTLSHostnameOverride orderer.nitw.edu -c $CHANNEL_NAME --tls --cafile "$ORDERER_CA"
  
  docker exec cli configtxlator proto_decode --input channel-artifacts/config_block.pb --type common.Block --output channel-artifacts/config_block.json
  
  docker exec cli jq .data.data[0].payload.data.config channel-artifacts/config_block.json > channel-artifacts/config.json
  
  # Modify config json
  if [ $ORG -eq 1 ]; then
    HOST="peer0.nitwarangal.nitw.edu"
    PORT=7051
  elif [ $ORG -eq 2 ]; then
    HOST="peer0.departments.nitw.edu"
    PORT=9051
  elif [ $ORG -eq 3 ]; then
    HOST="peer0.verifiers.nitw.edu"
    PORT=11051
  fi
  
  set -x
  # Create modified config
  peer channel update -f channel-artifacts/${CHANNEL_NAME}anchors.tx -c $CHANNEL_NAME -o orderer.nitw.edu:7050 --ordererTLSHostnameOverride orderer.nitw.edu --tls --cafile "$ORDERER_CA"
  res=$?
  { set +x; } 2>/dev/null
  verifyResult $res "Anchor peer update failed"
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo $2
    exit 1
  fi
}

FABRIC_CFG_PATH=${PWD}/../configtx

## Create channel genesis block
echo "Generating channel genesis block '${CHANNEL_NAME}.block'"
createChannelGenesisBlock

## Create channel
echo "Creating channel ${CHANNEL_NAME}"
createChannel

## Join all the peers to the channel
echo "Join NITWarangal peers to the channel..."
joinChannel 1
echo "Join Departments peers to the channel..."
joinChannel 2
echo "Join Verifiers peers to the channel..."
joinChannel 3

## Set the anchor peers for each org in the channel
echo "Setting anchor peer for NITWarangal..."
setAnchorPeer 1
echo "Setting anchor peer for Departments..."
setAnchorPeer 2
echo "Setting anchor peer for Verifiers..."
setAnchorPeer 3

echo
echo "========= Channel successfully joined =========== "
echo

exit 0

#!/bin/bash
# ============================================================
#  NIT WARANGAL - Academic Records Blockchain Network Script
#  Author: Prince Kumar
#  Purpose: Automate full Hyperledger Fabric workflow
# ============================================================

set -e  # Exit on first error
set -o pipefail

CHANNEL_NAME="academic-records-channel"
CHAINCODE_NAME="academic-records"
CHAINCODE_PATH="./chaincode-go/academic-records"
CHAINCODE_LANG="golang"
CHAINCODE_LABEL="academic_records_1.4"
CHAINCODE_VERSION="1.4"
ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/tls/ca.crt"
ORDERER_ADDR="orderer.nitw.edu:7050"

printHeader() {
  echo -e "\n=============================="
  echo -e "🔹 $1"
  echo -e "=============================="
}

# ------------------------------------------------------------
# 1. Clean previous setup
# ------------------------------------------------------------
cleanup() {
  printHeader "Cleaning network and artifacts..."
  docker-compose -f docker/docker-compose-net.yaml down --volumes 2>/dev/null || true
  rm -rf organizations/ channel-artifacts/*.block channel-artifacts/*.tx system-genesis-block/*.block *.tar.gz 2>/dev/null || true
  echo "✓ Clean complete"
}

# ------------------------------------------------------------
# 2. Generate crypto materials
# ------------------------------------------------------------
generateCrypto() {
  printHeader "Generating cryptographic materials..."
  ../bin/cryptogen generate --config=./crypto-config.yaml --output="organizations"
  echo "✓ Crypto materials generated"
}

# ------------------------------------------------------------
# 3. Create genesis block & bring up containers
# ------------------------------------------------------------
startNetwork() {
  printHeader "Starting Docker network..."
  export FABRIC_CFG_PATH=${PWD}/configtx
  ../bin/configtxgen -profile ThreeOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
  docker-compose -f docker/docker-compose-net.yaml up -d
  sleep 5
  docker ps --format "table {{.Names}}\t{{.Status}}"
  echo "✓ Containers running"
}

# ------------------------------------------------------------
# 4. Create channel & join orderer
# ------------------------------------------------------------
createChannel() {
  printHeader "Creating $CHANNEL_NAME..."
  export FABRIC_CFG_PATH=${PWD}/configtx
  ../bin/configtxgen -profile AcademicRecordsChannel -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID ${CHANNEL_NAME}
  echo "✓ Channel block created"

  ../bin/osnadmin channel join --channelID ${CHANNEL_NAME} \
    --config-block ./channel-artifacts/${CHANNEL_NAME}.block \
    -o orderer.nitw.edu:7053 \
    --ca-file ${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/tls/ca.crt \
    --client-cert ${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/tls/server.crt \
    --client-key ${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/tls/server.key

  echo "✓ Channel joined to orderer"
}

# ------------------------------------------------------------
# 5. Join peers (all orgs)
# ------------------------------------------------------------
joinPeers() {
  printHeader "Joining all peers to channel..."

  docker cp ./channel-artifacts/${CHANNEL_NAME}.block cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/

  docker exec cli sh -c '
  export FABRIC_CFG_PATH=/etc/hyperledger/fabric
  export CORE_PEER_TLS_ENABLED=true

  joinPeer () {
    echo "=== Joining $1 ==="
    export CORE_PEER_LOCALMSPID="$2"
    export CORE_PEER_ADDRESS="$3"
    export CORE_PEER_TLS_ROOTCERT_FILE="$4"
    export CORE_PEER_MSPCONFIGPATH="$5"
    peer channel join -b academic-records-channel.block
  }

  joinPeer peer0.nitwarangal NITWarangalMSP peer0.nitwarangal.nitw.edu:7051 \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp

  joinPeer peer1.nitwarangal NITWarangalMSP peer1.nitwarangal.nitw.edu:8051 \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer1.nitwarangal.nitw.edu/tls/ca.crt \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp

  joinPeer peer0.departments DepartmentsMSP peer0.departments.nitw.edu:9051 \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp

  joinPeer peer1.departments DepartmentsMSP peer1.departments.nitw.edu:10051 \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/departments.nitw.edu/peers/peer1.departments.nitw.edu/tls/ca.crt \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp

  joinPeer peer0.verifiers VerifiersMSP peer0.verifiers.nitw.edu:11051 \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp

  echo "✓ All peers joined successfully!"
  '
}

# ------------------------------------------------------------
# 6. Package & Install chaincode
# ------------------------------------------------------------
deployChaincode() {
  printHeader "Packaging and installing chaincode..."

  cd chaincode-go/academic-records
  GO111MODULE=on go mod vendor
  cd ../..
  export FABRIC_CFG_PATH=../config
  ../bin/peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz \
    --path ${CHAINCODE_PATH} --lang ${CHAINCODE_LANG} --label ${CHAINCODE_LABEL}
  echo "✓ Chaincode packaged"

  docker cp ${PWD}/${CHAINCODE_NAME}.tar.gz cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/${CHAINCODE_NAME}.tar.gz

  docker exec cli bash -c '
  export CORE_PEER_LOCALMSPID="NITWarangalMSP"
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_ADDRESS="peer0.nitwarangal.nitw.edu:7051"
  export CORE_PEER_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp"
  peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/academic-records.tar.gz

  export CORE_PEER_LOCALMSPID="DepartmentsMSP"
  export CORE_PEER_ADDRESS="peer0.departments.nitw.edu:9051"
  export CORE_PEER_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp"
  peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/academic-records.tar.gz

  export CORE_PEER_LOCALMSPID="VerifiersMSP"
  export CORE_PEER_ADDRESS="peer0.verifiers.nitw.edu:11051"
  export CORE_PEER_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp"
  peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/academic-records.tar.gz
  '
  echo "✓ Chaincode installed on all orgs"
}

# ------------------------------------------------------------
# 7. Approve & Commit
# ------------------------------------------------------------
approveAndCommit() {
  printHeader "Approving and committing chaincode..."
  PACKAGE_ID=$(docker exec cli bash -c '
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_ADDRESS="peer0.nitwarangal.nitw.edu:7051"
export CORE_PEER_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp"
peer lifecycle chaincode queryinstalled
' | grep "${CHAINCODE_LABEL}" | awk -F "Package ID: " '{print $2}' | awk -F "," '{print $1}')
  echo "Detected Package ID: $PACKAGE_ID"

  approveOrg() {
    ORG=$1
    PEER_ADDR=$2
    TLS_CA=$3
    MSP_PATH=$4
    docker exec -e CORE_PEER_LOCALMSPID=${ORG} -e CORE_PEER_TLS_ENABLED=true \
      -e CORE_PEER_TLS_ROOTCERT_FILE=${TLS_CA} -e CORE_PEER_MSPCONFIGPATH=${MSP_PATH} \
      -e CORE_PEER_ADDRESS=${PEER_ADDR} cli peer lifecycle chaincode approveformyorg \
      -o ${ORDERER_ADDR} --ordererTLSHostnameOverride orderer.nitw.edu --tls --cafile ${ORDERER_CA} \
      --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} \
      --package-id ${PACKAGE_ID} --sequence 1
  }

  approveOrg NITWarangalMSP peer0.nitwarangal.nitw.edu:7051 /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp
  approveOrg DepartmentsMSP peer0.departments.nitw.edu:9051 /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp
  approveOrg VerifiersMSP peer0.verifiers.nitw.edu:11051 /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp

  echo "✓ All orgs approved"

  docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 cli peer lifecycle chaincode commit \
    -o ${ORDERER_ADDR} --ordererTLSHostnameOverride orderer.nitw.edu --tls --cafile ${ORDERER_CA} \
    --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version ${CHAINCODE_VERSION} --sequence 1 \
    --peerAddresses peer0.nitwarangal.nitw.edu:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
    --peerAddresses peer0.departments.nitw.edu:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
    --peerAddresses peer0.verifiers.nitw.edu:11051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt

  echo "✓ Chaincode committed successfully"
}

# ------------------------------------------------------------
# 8. Test chaincode basic transactions
# ------------------------------------------------------------
testChaincode() {
  printHeader "Testing chaincode..."
  
  docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 cli peer chaincode invoke \
    -o ${ORDERER_ADDR} --ordererTLSHostnameOverride orderer.nitw.edu \
    --tls --cafile ${ORDERER_CA} -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} \
    --peerAddresses peer0.nitwarangal.nitw.edu:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
    --peerAddresses peer0.departments.nitw.edu:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
    -c '{"function":"CreateStudent","Args":["CS21B001","John Doe","CSE","2021","john.doe@student.nitw.ac.in","abc123hash","GENERAL"]}'
  
  echo "⏳ Waiting for transaction to be committed..."
  sleep 5
  
  echo "📋 Querying student record..."
  docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 cli peer chaincode query \
    -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} \
    -c '{"function":"GetStudent","Args":["CS21B001"]}'
  
  echo "✓ Chaincode test completed successfully!"
}

# ------------------------------------------------------------
# Run commands
# ------------------------------------------------------------
case "$1" in
  up)
    cleanup
    generateCrypto
    startNetwork
    createChannel
    joinPeers
    deployChaincode
    approveAndCommit
    testChaincode
    ;;
  clean)
    cleanup
    ;;
  *)
    echo "Usage: ./network.sh up | clean"
    ;;
esac
#!/bin/bash
#
# Complete chaincode deployment script
# This script will: create channel, join peers, install chaincode, approve, and commit

set -e

CHANNEL_NAME="academic-records-channel"
CC_NAME="academic-records"
CC_VERSION="1.0"
CC_PACKAGE_ID="academic_records_1.0:14bd8e0b0270176c88017c0369ffaae6519df081e349537ad48bd72edbf0e1b7"

echo "=========================================="
echo "Step 1: Creating Channel"
echo "=========================================="

# Create channel genesis block
export FABRIC_CFG_PATH=${PWD}
../bin/configtxgen -profile AcademicRecordsChannel -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME

# Join orderer to channel
../bin/osnadmin channel join --channelID $CHANNEL_NAME --config-block ./channel-artifacts/${CHANNEL_NAME}.block \
  -o orderer.nitw.edu:7053 \
  --ca-file ${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/msp/tlscacerts/tlsca.nitw.edu-cert.pem \
  --client-cert ${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/tls/server.crt \
  --client-key ${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/tls/server.key

echo "✅ Channel created and orderer joined"
sleep 3

echo ""
echo "=========================================="
echo "Step 2: Joining Peers to Channel"
echo "=========================================="

export FABRIC_CFG_PATH=../config
export CORE_PEER_TLS_ENABLED=true

# Join peer0.nitwarangal
echo "Joining peer0.nitwarangal..."
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
../bin/peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

# Join peer1.nitwarangal
echo "Joining peer1.nitwarangal..."
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer1.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_ADDRESS=peer1.nitwarangal.nitw.edu:8051
../bin/peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

# Join peer0.departments
echo "Joining peer0.departments..."
export CORE_PEER_LOCALMSPID="DepartmentsMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp
export CORE_PEER_ADDRESS=peer0.departments.nitw.edu:9051
../bin/peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

# Join peer1.departments
echo "Joining peer1.departments..."
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer1.departments.nitw.edu/tls/ca.crt
export CORE_PEER_ADDRESS=peer1.departments.nitw.edu:10051
../bin/peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

# Join peer0.verifiers
echo "Joining peer0.verifiers..."
export CORE_PEER_LOCALMSPID="VerifiersMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp
export CORE_PEER_ADDRESS=peer0.verifiers.nitw.edu:11051
../bin/peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

echo "✅ All peers joined channel"
sleep 2

echo ""
echo "=========================================="
echo "Step 3: Installing Chaincode on All Peers"
echo "=========================================="

# Install on peer0.nitwarangal
echo "Installing on peer0.nitwarangal..."
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
../bin/peer lifecycle chaincode install academic-records.tar.gz

# Install on peer0.departments
echo "Installing on peer0.departments..."
export CORE_PEER_LOCALMSPID="DepartmentsMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp
export CORE_PEER_ADDRESS=peer0.departments.nitw.edu:9051
../bin/peer lifecycle chaincode install academic-records.tar.gz

# Install on peer0.verifiers  
echo "Installing on peer0.verifiers..."
export CORE_PEER_LOCALMSPID="VerifiersMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp
export CORE_PEER_ADDRESS=peer0.verifiers.nitw.edu:11051
../bin/peer lifecycle chaincode install academic-records.tar.gz

echo "✅ Chaincode installed on all peers"
sleep 2

echo ""
echo "=========================================="
echo "Step 4: Approving Chaincode for All Orgs"
echo "=========================================="

export ORDERER_CA=${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/msp/tlscacerts/tlsca.nitw.edu-cert.pem

# Approve for NITWarangalMSP
echo "Approving for NITWarangalMSP..."
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051

../bin/peer lifecycle chaincode approveformyorg -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --channelID $CHANNEL_NAME \
  --name $CC_NAME \
  --version $CC_VERSION \
  --package-id $CC_PACKAGE_ID \
  --sequence 1 \
  --tls \
  --cafile $ORDERER_CA

# Approve for DepartmentsMSP
echo "Approving for DepartmentsMSP..."
export CORE_PEER_LOCALMSPID="DepartmentsMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.departments.nitw.edu:9051

../bin/peer lifecycle chaincode approveformyorg -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --channelID $CHANNEL_NAME \
  --name $CC_NAME \
  --version $CC_VERSION \
  --package-id $CC_PACKAGE_ID \
  --sequence 1 \
  --tls \
  --cafile $ORDERER_CA

# Approve for VerifiersMSP
echo "Approving for VerifiersMSP..."
export CORE_PEER_LOCALMSPID="VerifiersMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.verifiers.nitw.edu:11051

../bin/peer lifecycle chaincode approveformyorg -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --channelID $CHANNEL_NAME \
  --name $CC_NAME \
  --version $CC_VERSION \
  --package-id $CC_PACKAGE_ID \
  --sequence 1 \
  --tls \
  --cafile $ORDERER_CA

echo "✅ Chaincode approved by all organizations"
sleep 2

echo ""
echo "=========================================="
echo "Step 5: Checking Commit Readiness"
echo "=========================================="

../bin/peer lifecycle chaincode checkcommitreadiness \
  --channelID $CHANNEL_NAME \
  --name $CC_NAME \
  --version $CC_VERSION \
  --sequence 1 \
  --tls \
  --cafile $ORDERER_CA \
  --output json

echo ""
echo "=========================================="
echo "Step 6: Committing Chaincode Definition"
echo "=========================================="

../bin/peer lifecycle chaincode commit \
  -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --channelID $CHANNEL_NAME \
  --name $CC_NAME \
  --version $CC_VERSION \
  --sequence 1 \
  --tls \
  --cafile $ORDERER_CA \
  --peerAddresses peer0.nitwarangal.nitw.edu:7051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.departments.nitw.edu:9051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.verifiers.nitw.edu:11051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt

echo "✅ Chaincode committed to channel"
sleep 2

echo ""
echo "=========================================="
echo "Step 7: Querying Committed Chaincode"
echo "=========================================="

../bin/peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CC_NAME

echo ""
echo "=========================================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "Network Status:"
echo "  - Channel: $CHANNEL_NAME"
echo "  - Chaincode: $CC_NAME v$CC_VERSION"
echo "  - All peers joined and chaincode deployed"
echo ""
echo "Next steps:"
echo "  1. Test chaincode with invoke/query"
echo "  2. Set up REST API server"
echo "  3. Run end-to-end tests"
echo ""

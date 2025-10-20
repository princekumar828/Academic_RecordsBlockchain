#!/bin/bash
# Quick chaincode upgrade script for v1.2

set -e

VERSION="1.2"
PACKAGE_ID="academic_records_${VERSION}:$(../bin/peer lifecycle chaincode calculatepackageid academic_records_${VERSION}.tar.gz | tail -1)"

echo "Package ID: $PACKAGE_ID"

# Install on all peers
echo "Installing on peer0.nitwarangal..."
export FABRIC_CFG_PATH=/Users/apple/hyperledger/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp
/Users/apple/hyperledger/fabric-samples/bin/peer lifecycle chaincode install academic_records_${VERSION}.tar.gz

echo "Installing on peer0.departments..."
export CORE_PEER_LOCALMSPID="DepartmentsMSP"
export CORE_PEER_ADDRESS=peer0.departments.nitw.edu:9051
export CORE_PEER_TLS_ROOTCERT_FILE=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp
/Users/apple/hyperledger/fabric-samples/bin/peer lifecycle chaincode install academic_records_${VERSION}.tar.gz

echo "Installing on peer0.verifiers..."
export CORE_PEER_LOCALMSPID="VerifiersMSP"
export CORE_PEER_ADDRESS=peer0.verifiers.nitw.edu:11051
export CORE_PEER_TLS_ROOTCERT_FILE=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp
/Users/apple/hyperledger/fabric-samples/bin/peer lifecycle chaincode install academic_records_${VERSION}.tar.gz

# Get the actual package ID
PACKAGE_ID=$(/Users/apple/hyperledger/fabric-samples/bin/peer lifecycle chaincode queryinstalled | grep "academic_records_${VERSION}" | sed 's/^Package ID: //;s/, Label.*//')
echo "Actual Package ID: $PACKAGE_ID"

ORDERER_CA=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/msp/tlscacerts/tlsca.nitw.edu-cert.pem

# Approve for all orgs
echo "Approving for NITWarangalMSP..."
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp
/Users/apple/hyperledger/fabric-samples/bin/peer lifecycle chaincode approveformyorg -o orderer.nitw.edu:7050 --ordererTLSHostnameOverride orderer.nitw.edu --tls --cafile "$ORDERER_CA" --channelID academic-records-channel --name academic-records --version ${VERSION} --package-id "$PACKAGE_ID" --sequence 3

echo "Approving for DepartmentsMSP..."
export CORE_PEER_LOCALMSPID="DepartmentsMSP"
export CORE_PEER_ADDRESS=peer0.departments.nitw.edu:9051
export CORE_PEER_TLS_ROOTCERT_FILE=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp
/Users/apple/hyperledger/fabric-samples/bin/peer lifecycle chaincode approveformyorg -o orderer.nitw.edu:7050 --ordererTLSHostnameOverride orderer.nitw.edu --tls --cafile "$ORDERER_CA" --channelID academic-records-channel --name academic-records --version ${VERSION} --package-id "$PACKAGE_ID" --sequence 3

echo "Approving for VerifiersMSP..."
export CORE_PEER_LOCALMSPID="VerifiersMSP"
export CORE_PEER_ADDRESS=peer0.verifiers.nitw.edu:11051
export CORE_PEER_TLS_ROOTCERT_FILE=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp
/Users/apple/hyperledger/fabric-samples/bin/peer lifecycle chaincode approveformyorg -o orderer.nitw.edu:7050 --ordererTLSHostnameOverride orderer.nitw.edu --tls --cafile "$ORDERER_CA" --channelID academic-records-channel --name academic-records --version ${VERSION} --package-id "$PACKAGE_ID" --sequence 3

# Commit
echo "Committing chaincode..."
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp
/Users/apple/hyperledger/fabric-samples/bin/peer lifecycle chaincode commit -o orderer.nitw.edu:7050 --ordererTLSHostnameOverride orderer.nitw.edu --tls --cafile "$ORDERER_CA" --channelID academic-records-channel --name academic-records --version ${VERSION} --sequence 3 \
  --peerAddresses peer0.nitwarangal.nitw.edu:7051 --tlsRootCertFiles /Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.departments.nitw.edu:9051 --tlsRootCertFiles /Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.verifiers.nitw.edu:11051 --tlsRootCertFiles /Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt

echo "✅ Chaincode upgraded to version ${VERSION}"

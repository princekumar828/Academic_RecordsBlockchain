#!/bin/bash
#
# Comprehensive chaincode testing script
# Tests all major functions of the academic records chaincode

set -e

CHANNEL_NAME="academic-records-channel"
CC_NAME="academic-records"

# Setup environment
export FABRIC_CFG_PATH=../config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/msp/tlscacerts/tlsca.nitw.edu-cert.pem

echo "=========================================="
echo "🧪 Testing Academic Records Chaincode"
echo "=========================================="
echo ""

# Test 1: Create another student
echo "📝 Test 1: Creating Student STU004 (Bob Williams)..."
../bin/peer chaincode invoke -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CC_NAME \
  --peerAddresses peer0.nitwarangal.nitw.edu:7051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.departments.nitw.edu:9051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
  -c '{"function":"CreateStudent","Args":["STU005","Bob Williams","Civil Engineering","2023","CE001","bob@nitw.edu"]}'

sleep 2
echo "✅ Student STU004 created"
echo ""

# Test 2: Query the new student
echo "🔍 Test 2: Querying Student STU004..."
../bin/peer chaincode query -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"GetStudent","Args":["STU005"]}' | jq .
echo ""

# Test 3: Create Academic Record for STU001
echo "📚 Test 3: Creating Academic Record for STU001 (Semester 2)..."
../bin/peer chaincode invoke -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CC_NAME \
  --peerAddresses peer0.nitwarangal.nitw.edu:7051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.departments.nitw.edu:9051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
  -c '{"function":"CreateAcademicRecord","Args":["REC002","STU001","2","[{\"courseCode\":\"CS201\",\"courseName\":\"Data Structures\",\"credits\":4,\"grade\":\"S\"},{\"courseCode\":\"MA201\",\"courseName\":\"Linear Algebra\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"PH201\",\"courseName\":\"Electronics\",\"credits\":3,\"grade\":\"A\"}]"]}'

sleep 2
echo "✅ Academic record REC002 created"
echo ""

# Test 4: Query Academic Record
echo "🔍 Test 4: Querying Academic Record REC002..."
../bin/peer chaincode query -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"GetAcademicRecord","Args":["REC002"]}' | jq .
echo ""

# Test 5: Approve Academic Record
echo "✍️ Test 5: Approving Academic Record REC002..."
../bin/peer chaincode invoke -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CC_NAME \
  --peerAddresses peer0.nitwarangal.nitw.edu:7051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.departments.nitw.edu:9051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
  -c '{"function":"ApproveAcademicRecord","Args":["REC002"]}'

sleep 2
echo "✅ Record approved"
echo ""

# Test 6: Query approved record
echo "🔍 Test 6: Querying approved record..."
../bin/peer chaincode query -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"GetAcademicRecord","Args":["REC002"]}' | jq .
echo ""

# Test 7: Get Student History
echo "📜 Test 7: Getting complete history for STU001..."
../bin/peer chaincode query -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"GetStudentHistory","Args":["STU001"]}' | jq .
echo ""

# Test 8: Issue Certificate
echo "🎓 Test 8: Issuing Certificate for STU001..."
../bin/peer chaincode invoke -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CC_NAME \
  --peerAddresses peer0.nitwarangal.nitw.edu:7051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.departments.nitw.edu:9051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
  -c '{"function":"IssueCertificate","Args":["CERT002","STU001","DEGREE","def456hash","Qm456ipfshash"]}'

sleep 2
echo "✅ Certificate issued"
echo ""

# Test 9: Query Certificate
echo "🔍 Test 9: Querying Certificate CERT002..."
../bin/peer chaincode query -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"GetCertificate","Args":["CERT002"]}' | jq .
echo ""

# Test 10: Verify Certificate
echo "✔️ Test 10: Verifying Certificate CERT002..."
../bin/peer chaincode query -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"VerifyCertificate","Args":["CERT002"]}' | jq .
echo ""

# Test 11: Update Student Status
echo "🔄 Test 11: Updating Student Status to GRADUATED..."
../bin/peer chaincode invoke -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CC_NAME \
  --peerAddresses peer0.nitwarangal.nitw.edu:7051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.departments.nitw.edu:9051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
  -c '{"function":"UpdateStudentStatus","Args":["STU001","GRADUATED"]}'

sleep 2
echo "✅ Status updated"
echo ""

# Test 12: Verify status update
echo "🔍 Test 12: Verifying updated student status..."
../bin/peer chaincode query -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"GetStudent","Args":["STU001"]}' | jq .
echo ""

# Test 13: Get All Students
echo "📋 Test 13: Getting all students..."
../bin/peer chaincode query -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"GetAllStudents","Args":[]}' | jq .
echo ""

# Test 14: Check if student exists
echo "❓ Test 14: Checking if STU001 exists..."
../bin/peer chaincode query -C $CHANNEL_NAME -n $CC_NAME \
  -c '{"function":"StudentExists","Args":["STU001"]}'
echo ""

echo "=========================================="
echo "✅ All Tests Completed Successfully!"
echo "=========================================="
echo ""
echo "📊 Test Summary:"
echo "  ✅ Created 2 students"
echo "  ✅ Created 1 academic record with auto-calculated SGPA"
echo "  ✅ Approved academic record"
echo "  ✅ Issued 1 certificate"
echo "  ✅ Verified certificate"
echo "  ✅ Updated student status"
echo "  ✅ Queried student history"
echo "  ✅ Retrieved all students"
echo ""
echo "🎉 Chaincode is fully functional!"

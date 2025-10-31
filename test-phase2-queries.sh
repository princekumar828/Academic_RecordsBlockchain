#!/bin/bash
# ============================================================
#  Phase 2 Query Functions Test Script
#  Tests: 6 query functions with pagination
# ============================================================

set -e

ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/tls/ca.crt"
PEER_NITW_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt"
PEER_DEPT_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt"

printHeader() {
    echo -e "\n=============================="
    echo "🔹 $1"
    echo "=============================="
}

# Step 1: Create test data (students from multiple departments and years)
printHeader "Creating test data: 5 students across 3 departments"

echo "Creating CS21B002 (CSE, 2021)..."
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode invoke \
    -o orderer.nitw.edu:7050 \
    --tls --cafile $ORDERER_CA \
    -C academic-records-channel -n academic-records \
    --peerAddresses peer0.nitwarangal.nitw.edu:7051 --tlsRootCertFiles $PEER_NITW_CA \
    --peerAddresses peer0.departments.nitw.edu:9051 --tlsRootCertFiles $PEER_DEPT_CA \
    -c '{"function":"CreateStudent","Args":["CS21B002","Jane Smith","CSE","2021","jane.smith@student.nitw.ac.in","hash456","GENERAL"]}'

echo "Creating EC22B001 (ECE, 2022)..."
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode invoke \
    -o orderer.nitw.edu:7050 \
    --tls --cafile $ORDERER_CA \
    -C academic-records-channel -n academic-records \
    --peerAddresses peer0.nitwarangal.nitw.edu:7051 --tlsRootCertFiles $PEER_NITW_CA \
    --peerAddresses peer0.departments.nitw.edu:9051 --tlsRootCertFiles $PEER_DEPT_CA \
    -c '{"function":"CreateStudent","Args":["EC22B001","Bob Johnson","ECE","2022","bob.johnson@student.nitw.ac.in","hash789","OBC"]}'

echo "Creating MM23B001 (MME, 2023)..."
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode invoke \
    -o orderer.nitw.edu:7050 \
    --tls --cafile $ORDERER_CA \
    -C academic-records-channel -n academic-records \
    --peerAddresses peer0.nitwarangal.nitw.edu:7051 --tlsRootCertFiles $PEER_NITW_CA \
    --peerAddresses peer0.departments.nitw.edu:9051 --tlsRootCertFiles $PEER_DEPT_CA \
    -c '{"function":"CreateStudent","Args":["MM23B001","Alice Brown","MME","2023","alice.brown@student.nitw.ac.in","hash101","SC"]}'

echo "Creating CS22B001 (CSE, 2022)..."
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode invoke \
    -o orderer.nitw.edu:7050 \
    --tls --cafile $ORDERER_CA \
    -C academic-records-channel -n academic-records \
    --peerAddresses peer0.nitwarangal.nitw.edu:7051 --tlsRootCertFiles $PEER_NITW_CA \
    --peerAddresses peer0.departments.nitw.edu:9051 --tlsRootCertFiles $PEER_DEPT_CA \
    -c '{"function":"CreateStudent","Args":["CS22B001","Charlie Wilson","CSE","2022","charlie.wilson@student.nitw.ac.in","hash202","EWS"]}'

echo "✓ 5 students created"

# Step 2: Create academic records for different semesters
printHeader "Creating academic records for different semesters"

echo "Creating record for CS21B001 (Semester 1, DRAFT status)..."
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode invoke \
    -o orderer.nitw.edu:7050 \
    --tls --cafile $ORDERER_CA \
    -C academic-records-channel -n academic-records \
    --peerAddresses peer0.nitwarangal.nitw.edu:7051 --tlsRootCertFiles $PEER_NITW_CA \
    --peerAddresses peer0.departments.nitw.edu:9051 --tlsRootCertFiles $PEER_DEPT_CA \
    -c '{"function":"CreateAcademicRecord","Args":["REC002","CS21B001","1","2021-22","CSE","[{\"courseCode\":\"CS101\",\"courseName\":\"Programming\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"MA101\",\"courseName\":\"Calculus\",\"credits\":4,\"grade\":\"B\"},{\"courseCode\":\"PH101\",\"courseName\":\"Physics\",\"credits\":3,\"grade\":\"S\"},{\"courseCode\":\"CH101\",\"courseName\":\"Chemistry\",\"credits\":3,\"grade\":\"A\"},{\"courseCode\":\"EE101\",\"courseName\":\"Circuits\",\"credits\":3,\"grade\":\"B\"}]","17"]}'

echo "Creating record for CS21B002 (Semester 2, DRAFT status)..."
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode invoke \
    -o orderer.nitw.edu:7050 \
    --tls --cafile $ORDERER_CA \
    -C academic-records-channel -n academic-records \
    --peerAddresses peer0.nitwarangal.nitw.edu:7051 --tlsRootCertFiles $PEER_NITW_CA \
    --peerAddresses peer0.departments.nitw.edu:9051 --tlsRootCertFiles $PEER_DEPT_CA \
    -c '{"function":"CreateAcademicRecord","Args":["REC003","CS21B002","2","2021-22","CSE","[{\"courseCode\":\"CS201\",\"courseName\":\"DataStructures\",\"credits\":4,\"grade\":\"S\"},{\"courseCode\":\"MA201\",\"courseName\":\"Statistics\",\"credits\":3,\"grade\":\"A\"},{\"courseCode\":\"CS202\",\"courseName\":\"Algorithms\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"CS203\",\"courseName\":\"DBMS\",\"credits\":3,\"grade\":\"B\"},{\"courseCode\":\"CS204\",\"courseName\":\"OS\",\"credits\":3,\"grade\":\"A\"}]","17"]}'

echo "Creating record for EC22B001 (Semester 1, DRAFT status)..."
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode invoke \
    -o orderer.nitw.edu:7050 \
    --tls --cafile $ORDERER_CA \
    -C academic-records-channel -n academic-records \
    --peerAddresses peer0.nitwarangal.nitw.edu:7051 --tlsRootCertFiles $PEER_NITW_CA \
    --peerAddresses peer0.departments.nitw.edu:9051 --tlsRootCertFiles $PEER_DEPT_CA \
    -c '{"function":"CreateAcademicRecord","Args":["REC004","EC22B001","1","2022-23","ECE","[{\"courseCode\":\"EC101\",\"courseName\":\"Circuits\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"MA101\",\"courseName\":\"Calculus\",\"credits\":4,\"grade\":\"B\"},{\"courseCode\":\"PH101\",\"courseName\":\"Physics\",\"credits\":3,\"grade\":\"A\"},{\"courseCode\":\"CH101\",\"courseName\":\"Chemistry\",\"credits\":3,\"grade\":\"C\"},{\"courseCode\":\"EC102\",\"courseName\":\"Electronics\",\"credits\":3,\"grade\":\"B\"}]","17"]}'

echo "✓ 3 academic records created"

# Step 3: Update student status (create GRADUATED student for testing)
printHeader "Updating CS21B001 status to GRADUATED"

docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode invoke \
    -o orderer.nitw.edu:7050 \
    --tls --cafile $ORDERER_CA \
    -C academic-records-channel -n academic-records \
    --peerAddresses peer0.nitwarangal.nitw.edu:7051 --tlsRootCertFiles $PEER_NITW_CA \
    --peerAddresses peer0.departments.nitw.edu:9051 --tlsRootCertFiles $PEER_DEPT_CA \
    -c '{"function":"UpdateStudentStatus","Args":["CS21B001","GRADUATED","Completed all requirements"]}'

echo "✓ Student status updated"

sleep 5

# Step 4: Test Query Functions
printHeader "Testing Phase 2 Query Functions"

echo -e "\n📊 Test 1: QueryStudentsByDepartment (CSE)"
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"QueryStudentsByDepartment","Args":["CSE","",  "50"]}' | python3 -m json.tool

echo -e "\n📊 Test 2: QueryStudentsByYear (2022)"
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"QueryStudentsByYear","Args":["2022","","50"]}' | python3 -m json.tool

echo -e "\n📊 Test 3: QueryStudentsByStatus (ACTIVE)"
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"QueryStudentsByStatus","Args":["ACTIVE","","50"]}' | python3 -m json.tool

echo -e "\n📊 Test 4: QueryStudentsByStatus (GRADUATED)"
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"QueryStudentsByStatus","Args":["GRADUATED","","50"]}' | python3 -m json.tool

echo -e "\n📊 Test 5: QueryRecordsBySemester (Semester 1)"
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"QueryRecordsBySemester","Args":["1","","50"]}' | python3 -m json.tool

echo -e "\n📊 Test 6: QueryRecordsByStatus (DRAFT)"
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"QueryRecordsByStatus","Args":["DRAFT","","50"]}' | python3 -m json.tool

echo -e "\n📊 Test 7: QueryPendingRecords (DRAFT + SUBMITTED)"
docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"QueryPendingRecords","Args":["","50"]}' | python3 -m json.tool

printHeader "✅ All Phase 2 Query Functions Tested!"
echo "Summary:"
echo "- QueryStudentsByDepartment: ✅ Tested"
echo "- QueryStudentsByYear: ✅ Tested"
echo "- QueryStudentsByStatus (ACTIVE): ✅ Tested"
echo "- QueryStudentsByStatus (GRADUATED): ✅ Tested"
echo "- QueryRecordsBySemester: ✅ Tested"
echo "- QueryRecordsByStatus: ✅ Tested"
echo "- QueryPendingRecords: ✅ Tested"

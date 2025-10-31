#!/bin/bash
# ============================================================
#  Create Academic Records Test Data
#  Creates REC002, REC003, REC004 for comprehensive testing
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

# Function to invoke chaincode (create operations)
invoke_chaincode() {
    local function=$1
    local args=$2
    
    docker exec \
        -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
        -e CORE_PEER_TLS_ENABLED=true \
        -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
        -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
        cli peer chaincode invoke \
        -o orderer.nitw.edu:7050 \
        --ordererTLSHostnameOverride orderer.nitw.edu \
        --tls --cafile $ORDERER_CA \
        -C academic-records-channel \
        -n academic-records \
        --peerAddresses peer0.nitwarangal.nitw.edu:7051 \
        --tlsRootCertFiles $PEER_NITW_CA \
        --peerAddresses peer0.departments.nitw.edu:9051 \
        --tlsRootCertFiles $PEER_DEPT_CA \
        -c "{\"function\":\"$function\",\"Args\":$args}" \
        --waitForEvent 2>&1 | grep -E "(status:|Error:)"
}

printHeader "Creating Academic Records Test Data"

echo -e "\n📝 Creating REC002 for CS21B001 (Semester 1, DRAFT)..."
invoke_chaincode "CreateAcademicRecord" '["REC002","CS21B001","1","2021-22","CSE","[{\"courseCode\":\"CS1001\",\"courseName\":\"Programming in C\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"MA1001\",\"courseName\":\"Calculus I\",\"credits\":4,\"grade\":\"B\"},{\"courseCode\":\"PH1001\",\"courseName\":\"Physics I\",\"credits\":3,\"grade\":\"B\"},{\"courseCode\":\"CH1001\",\"courseName\":\"Chemistry\",\"credits\":3,\"grade\":\"A\"},{\"courseCode\":\"EN1001\",\"courseName\":\"English\",\"credits\":3,\"grade\":\"S\"}]","17"]'
echo "✓ REC002 created"

sleep 2

echo -e "\n📝 Creating REC003 for CS21B002 (Semester 2, DRAFT)..."
invoke_chaincode "CreateAcademicRecord" '["REC003","CS21B002","2","2021-22","CSE","[{\"courseCode\":\"CS1002\",\"courseName\":\"Data Structures\",\"credits\":4,\"grade\":\"S\"},{\"courseCode\":\"MA1002\",\"courseName\":\"Calculus II\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"PH1002\",\"courseName\":\"Physics II\",\"credits\":3,\"grade\":\"S\"},{\"courseCode\":\"EE1001\",\"courseName\":\"Electrical Circuits\",\"credits\":3,\"grade\":\"A\"},{\"courseCode\":\"ME1001\",\"courseName\":\"Engineering Mechanics\",\"credits\":3,\"grade\":\"S\"}]","17"]'
echo "✓ REC003 created"

sleep 2

echo -e "\n📝 Creating REC004 for EC22B001 (Semester 1, APPROVED)..."
invoke_chaincode "CreateAcademicRecord" '["REC004","EC22B001","1","2022-23","ECE","[{\"courseCode\":\"EC1001\",\"courseName\":\"Circuit Theory\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"MA1001\",\"courseName\":\"Calculus I\",\"credits\":4,\"grade\":\"B\"},{\"courseCode\":\"PH1001\",\"courseName\":\"Physics I\",\"credits\":3,\"grade\":\"B\"},{\"courseCode\":\"CH1001\",\"courseName\":\"Chemistry\",\"credits\":3,\"grade\":\"A\"},{\"courseCode\":\"EN1001\",\"courseName\":\"English\",\"credits\":3,\"grade\":\"A\"}]","17"]'
echo "✓ REC004 created"

sleep 2

echo -e "\n📝 Creating REC005 for CS22B001 (Semester 1, SUBMITTED)..."
invoke_chaincode "CreateAcademicRecord" '["REC005","CS22B001","1","2022-23","CSE","[{\"courseCode\":\"CS1001\",\"courseName\":\"Programming in C\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"MA1001\",\"courseName\":\"Calculus I\",\"credits\":4,\"grade\":\"B\"},{\"courseCode\":\"PH1001\",\"courseName\":\"Physics I\",\"credits\":3,\"grade\":\"S\"},{\"courseCode\":\"CH1001\",\"courseName\":\"Chemistry\",\"credits\":3,\"grade\":\"B\"},{\"courseCode\":\"EN1001\",\"courseName\":\"English\",\"credits\":3,\"grade\":\"A\"}]","17"]'
echo "✓ REC005 created"

sleep 2

echo -e "\n📝 Creating REC006 for MM23B001 (Semester 1, DRAFT)..."
invoke_chaincode "CreateAcademicRecord" '["REC006","MM23B001","1","2023-24","MME","[{\"courseCode\":\"MM1001\",\"courseName\":\"Material Science\",\"credits\":4,\"grade\":\"S\"},{\"courseCode\":\"MA1001\",\"courseName\":\"Calculus I\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"PH1001\",\"courseName\":\"Physics I\",\"credits\":3,\"grade\":\"A\"},{\"courseCode\":\"CH1001\",\"courseName\":\"Chemistry\",\"credits\":3,\"grade\":\"S\"},{\"courseCode\":\"EN1001\",\"courseName\":\"English\",\"credits\":3,\"grade\":\"B\"}]","17"]'
echo "✓ REC006 created"

printHeader "✅ Academic Records Test Data Created Successfully"

echo -e "\n📊 Summary:"
echo "- REC002: CS21B001, Semester 1 (2021-22), CSE, DRAFT"
echo "- REC003: CS21B002, Semester 2 (2021-22), CSE, DRAFT"
echo "- REC004: EC22B001, Semester 1 (2022-23), ECE, APPROVED"
echo "- REC005: CS22B001, Semester 1 (2022-23), CSE, SUBMITTED"
echo "- REC006: MM23B001, Semester 1 (2023-24), MME, DRAFT"
echo ""
echo "🎯 Ready for comprehensive testing!"

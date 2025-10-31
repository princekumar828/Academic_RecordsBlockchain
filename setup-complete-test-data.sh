#!/bin/bash
# ============================================================
#  Complete Test Data Setup
#  Creates all students and academic records for testing
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

printHeader "Creating Test Students (CS21B002, EC22B001, CS22B001, MM23B001)"

echo -e "\n📝 Creating CS21B002 (Jane Smith, CSE, 2021)..."
invoke_chaincode "CreateStudent" '["CS21B002","Jane Smith","CSE","2021","jane.smith@student.nitw.ac.in","","","hash456","GENERAL"]'
echo "✓ CS21B002 created"

sleep 1

echo -e "\n📝 Creating EC22B001 (Bob Johnson, ECE, 2022)..."
invoke_chaincode "CreateStudent" '["EC22B001","Bob Johnson","ECE","2022","bob.johnson@student.nitw.ac.in","","","hash789","OBC"]'
echo "✓ EC22B001 created"

sleep 1

echo -e "\n📝 Creating CS22B001 (Charlie Wilson, CSE, 2022)..."
invoke_chaincode "CreateStudent" '["CS22B001","Charlie Wilson","CSE","2022","charlie.wilson@student.nitw.ac.in","","","hash202","EWS"]'
echo "✓ CS22B001 created"

sleep 1

echo -e "\n📝 Creating MM23B001 (Alice Brown, MME, 2023)..."
invoke_chaincode "CreateStudent" '["MM23B001","Alice Brown","MME","2023","alice.brown@student.nitw.ac.in","","","hash101","SC"]'
echo "✓ MM23B001 created"

printHeader "Creating Academic Records"

sleep 2

echo -e "\n📝 Creating REC002 for CS21B001 (Semester 1, DRAFT)..."
invoke_chaincode "CreateAcademicRecord" '["REC002","CS21B001","1","2021-22","CSE","[{\"courseCode\":\"CS1001\",\"courseName\":\"Programming in C\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"MA1001\",\"courseName\":\"Calculus I\",\"credits\":4,\"grade\":\"B\"},{\"courseCode\":\"PH1001\",\"courseName\":\"Physics I\",\"credits\":3,\"grade\":\"B\"},{\"courseCode\":\"CH1001\",\"courseName\":\"Chemistry\",\"credits\":3,\"grade\":\"A\"},{\"courseCode\":\"EN1001\",\"courseName\":\"English\",\"credits\":3,\"grade\":\"S\"}]","17"]'
echo "✓ REC002 created"

sleep 2

echo -e "\n📝 Creating REC003 for CS21B002 (Semester 2, DRAFT)..."
invoke_chaincode "CreateAcademicRecord" '["REC003","CS21B002","2","2021-22","CSE","[{\"courseCode\":\"CS1002\",\"courseName\":\"Data Structures\",\"credits\":4,\"grade\":\"S\"},{\"courseCode\":\"MA1002\",\"courseName\":\"Calculus II\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"PH1002\",\"courseName\":\"Physics II\",\"credits\":3,\"grade\":\"S\"},{\"courseCode\":\"EE1001\",\"courseName\":\"Electrical Circuits\",\"credits\":3,\"grade\":\"A\"},{\"courseCode\":\"ME1001\",\"courseName\":\"Engineering Mechanics\",\"credits\":3,\"grade\":\"S\"}]","17"]'
echo "✓ REC003 created"

sleep 2

echo -e "\n📝 Creating REC004 for EC22B001 (Semester 1, will be APPROVED)..."
invoke_chaincode "CreateAcademicRecord" '["REC004","EC22B001","1","2022-23","ECE","[{\"courseCode\":\"EC1001\",\"courseName\":\"Circuit Theory\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"MA1001\",\"courseName\":\"Calculus I\",\"credits\":4,\"grade\":\"B\"},{\"courseCode\":\"PH1001\",\"courseName\":\"Physics I\",\"credits\":3,\"grade\":\"B\"},{\"courseCode\":\"CH1001\",\"courseName\":\"Chemistry\",\"credits\":3,\"grade\":\"A\"},{\"courseCode\":\"EN1001\",\"courseName\":\"English\",\"credits\":3,\"grade\":\"A\"}]","17"]'
echo "✓ REC004 created"

sleep 2

echo -e "\n📝 Creating REC005 for CS22B001 (Semester 1, will be SUBMITTED)..."
invoke_chaincode "CreateAcademicRecord" '["REC005","CS22B001","1","2022-23","CSE","[{\"courseCode\":\"CS1001\",\"courseName\":\"Programming in C\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"MA1001\",\"courseName\":\"Calculus I\",\"credits\":4,\"grade\":\"B\"},{\"courseCode\":\"PH1001\",\"courseName\":\"Physics I\",\"credits\":3,\"grade\":\"S\"},{\"courseCode\":\"CH1001\",\"courseName\":\"Chemistry\",\"credits\":3,\"grade\":\"B\"},{\"courseCode\":\"EN1001\",\"courseName\":\"English\",\"credits\":3,\"grade\":\"A\"}]","17"]'
echo "✓ REC005 created"

sleep 2

echo -e "\n📝 Creating REC006 for MM23B001 (Semester 1, DRAFT)..."
invoke_chaincode "CreateAcademicRecord" '["REC006","MM23B001","1","2023-24","MME","[{\"courseCode\":\"MM1001\",\"courseName\":\"Material Science\",\"credits\":4,\"grade\":\"S\"},{\"courseCode\":\"MA1001\",\"courseName\":\"Calculus I\",\"credits\":4,\"grade\":\"A\"},{\"courseCode\":\"PH1001\",\"courseName\":\"Physics I\",\"credits\":3,\"grade\":\"A\"},{\"courseCode\":\"CH1001\",\"courseName\":\"Chemistry\",\"credits\":3,\"grade\":\"S\"},{\"courseCode\":\"EN1001\",\"courseName\":\"English\",\"credits\":3,\"grade\":\"B\"}]","17"]'
echo "✓ REC006 created"

printHeader "Updating Record Statuses"

sleep 2

echo -e "\n📝 Submitting REC005 (CS22B001)..."
invoke_chaincode "SubmitAcademicRecord" '["REC005"]'
echo "✓ REC005 submitted"

sleep 2

echo -e "\n📝 Submitting REC004 (EC22B001)..."
invoke_chaincode "SubmitAcademicRecord" '["REC004"]'
echo "✓ REC004 submitted"

sleep 2

echo -e "\n📝 Approving REC004 (EC22B001)..."
invoke_chaincode "ApproveAcademicRecord" '["REC004"]'
echo "✓ REC004 approved"

printHeader "✅ Complete Test Data Setup Finished"

echo -e "\n📊 Summary:"
echo ""
echo "Students (5 total):"
echo "- CS21B001: John Doe (CSE, 2021, ACTIVE)"
echo "- CS21B002: Jane Smith (CSE, 2021, ACTIVE)"
echo "- EC22B001: Bob Johnson (ECE, 2022, ACTIVE)"
echo "- CS22B001: Charlie Wilson (CSE, 2022, ACTIVE)"
echo "- MM23B001: Alice Brown (MME, 2023, ACTIVE)"
echo ""
echo "Academic Records (5 total):"
echo "- REC002: CS21B001, Semester 1, DRAFT"
echo "- REC003: CS21B002, Semester 2, DRAFT"
echo "- REC004: EC22B001, Semester 1, APPROVED ✓"
echo "- REC005: CS22B001, Semester 1, SUBMITTED"
echo "- REC006: MM23B001, Semester 1, DRAFT"
echo ""
echo "🎯 Ready for comprehensive testing with all statuses!"

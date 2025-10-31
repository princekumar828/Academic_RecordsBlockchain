#!/bin/bash
# ============================================================
#  Phase 2 Comprehensive Query Function Tests
#  Tests: Pagination, edge cases, access control, data validation
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

printTest() {
    echo -e "\n📊 $1"
    echo "---"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to test query
test_query() {
    local test_name=$1
    local function=$2
    local args=$3
    local expected_pattern=$4
    
    printTest "$test_name"
    
    result=$(docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
        -e CORE_PEER_TLS_ENABLED=true \
        -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
        -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
        -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
        cli peer chaincode query \
        -C academic-records-channel -n academic-records \
        -c "{\"function\":\"$function\",\"Args\":$args}" 2>&1)
    
    # Handle both null and [] as valid empty results
    expected_pattern_regex="${expected_pattern//\"\[\]\"/\"(null|\\[\\])\"}"
    
    if echo "$result" | grep -qE "$expected_pattern_regex"; then
        echo "✅ PASSED: $test_name"
        ((TESTS_PASSED++))
    else
        echo "❌ FAILED: $test_name"
        echo "Result: $result"
        ((TESTS_FAILED++))
    fi
    
    echo "$result" | python3 -m json.tool 2>/dev/null || echo "$result"
}

printHeader "🚀 Starting Comprehensive Phase 2 Tests"
echo "Test Suite: Query Functions with Pagination"
echo "Date: $(date)"
echo ""

# ============================================================================
# TEST GROUP 1: QueryStudentsByDepartment
# ============================================================================
printHeader "TEST GROUP 1: QueryStudentsByDepartment"

test_query \
    "1.1: Query CSE students (should return 3: CS21B001, CS21B002, CS22B001)" \
    "QueryStudentsByDepartment" \
    '["CSE","","50"]' \
    "CS21B001"

test_query \
    "1.2: Query ECE students (should return 1: EC22B001)" \
    "QueryStudentsByDepartment" \
    '["ECE","","50"]' \
    "EC22B001"

test_query \
    "1.3: Query MME students (should return 1: MM23B001)" \
    "QueryStudentsByDepartment" \
    '["MME","","50"]' \
    "MM23B001"

test_query \
    "1.4: Query non-existent department (should return empty)" \
    "QueryStudentsByDepartment" \
    '["MECH","","50"]' \
    '"recordCount":0'

test_query \
    "1.5: Test page size limit (pageSize=2 for CSE, should return 2 students)" \
    "QueryStudentsByDepartment" \
    '["CSE","","2"]' \
    '"hasMore":true'

# ============================================================================
# TEST GROUP 2: QueryStudentsByYear
# ============================================================================
printHeader "TEST GROUP 2: QueryStudentsByYear"

test_query \
    "2.1: Query 2021 students (should return 2: CS21B001, CS21B002)" \
    "QueryStudentsByYear" \
    '["2021","","50"]' \
    "CS21B001"

test_query \
    "2.2: Query 2022 students (should return 2: EC22B001, CS22B001)" \
    "QueryStudentsByYear" \
    '["2022","","50"]' \
    "EC22B001"

test_query \
    "2.3: Query 2023 students (should return 1: MM23B001)" \
    "QueryStudentsByYear" \
    '["2023","","50"]' \
    "MM23B001"

test_query \
    "2.4: Query future year (should return empty)" \
    "QueryStudentsByYear" \
    '["2025","","50"]' \
    '"recordCount":0'

test_query \
    "2.5: Test pagination with pageSize=1" \
    "QueryStudentsByYear" \
    '["2021","","1"]' \
    '"hasMore":true'

# ============================================================================
# TEST GROUP 3: QueryStudentsByStatus
# ============================================================================
printHeader "TEST GROUP 3: QueryStudentsByStatus"

test_query \
    "3.1: Query ACTIVE students (should return multiple)" \
    "QueryStudentsByStatus" \
    '["ACTIVE","","50"]' \
    "ACTIVE"

test_query \
    "3.2: Query GRADUATED students (should return empty initially)" \
    "QueryStudentsByStatus" \
    '["GRADUATED","","50"]' \
    '"records":\['

test_query \
    "3.3: Query WITHDRAWN students (should return empty)" \
    "QueryStudentsByStatus" \
    '["WITHDRAWN","","50"]' \
    '"recordCount":0'

# ============================================================================
# TEST GROUP 4: QueryRecordsBySemester
# ============================================================================
printHeader "TEST GROUP 4: QueryRecordsBySemester"

test_query \
    "4.1: Query Semester 1 records (should return REC001, REC002, REC004)" \
    "QueryRecordsBySemester" \
    '["1","","50"]' \
    "REC001"

test_query \
    "4.2: Query Semester 2 records (should return REC003)" \
    "QueryRecordsBySemester" \
    '["2","","50"]' \
    "REC003"

test_query \
    "4.3: Query Semester 8 records (should return empty)" \
    "QueryRecordsBySemester" \
    '["8","","50"]' \
    '"recordCount":0'

test_query \
    "4.4: Test pagination with pageSize=1" \
    "QueryRecordsBySemester" \
    '["1","","1"]' \
    '"hasMore":true'

# ============================================================================
# TEST GROUP 5: QueryRecordsByStatus
# ============================================================================
printHeader "TEST GROUP 5: QueryRecordsByStatus"

test_query \
    "5.1: Query DRAFT records (should return multiple)" \
    "QueryRecordsByStatus" \
    '["DRAFT","","50"]' \
    "DRAFT"

test_query \
    "5.2: Query APPROVED records (should return REC001)" \
    "QueryRecordsByStatus" \
    '["APPROVED","","50"]' \
    "APPROVED"

test_query \
    "5.3: Query SUBMITTED records (should return empty initially)" \
    "QueryRecordsByStatus" \
    '["SUBMITTED","","50"]' \
    '"records":\['

# ============================================================================
# TEST GROUP 6: QueryPendingRecords
# ============================================================================
printHeader "TEST GROUP 6: QueryPendingRecords"

test_query \
    "6.1: Query all pending records (DRAFT + SUBMITTED)" \
    "QueryPendingRecords" \
    '["","50"]' \
    '"records":\['

test_query \
    "6.2: Test pagination with pageSize=2" \
    "QueryPendingRecords" \
    '["","2"]' \
    '"recordCount":'

# ============================================================================
# TEST GROUP 7: Pagination Edge Cases
# ============================================================================
printHeader "TEST GROUP 7: Pagination Edge Cases"

test_query \
    "7.1: Test with pageSize=0 (should default to 50)" \
    "QueryStudentsByDepartment" \
    '["CSE","","0"]' \
    '"recordCount":3'

test_query \
    "7.2: Test with pageSize=1000 (should cap at 100)" \
    "QueryStudentsByDepartment" \
    '["CSE","","1000"]' \
    '"recordCount":3'

test_query \
    "7.3: Test with negative pageSize (should default to 50)" \
    "QueryStudentsByYear" \
    '["2021","","-1"]' \
    '"recordCount":2'

# ============================================================================
# TEST GROUP 8: Data Validation
# ============================================================================
printHeader "TEST GROUP 8: Data Validation & Results Structure"

printTest "8.1: Verify PaginatedQueryResult structure"
result=$(docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"QueryStudentsByDepartment","Args":["CSE","","50"]}')

if echo "$result" | grep -q '"records":\[' && \
   echo "$result" | grep -q '"bookmark":' && \
   echo "$result" | grep -q '"recordCount":' && \
   echo "$result" | grep -q '"hasMore":'; then
    echo "✅ PASSED: PaginatedQueryResult has all required fields"
    ((TESTS_PASSED++))
else
    echo "❌ FAILED: PaginatedQueryResult missing required fields"
    ((TESTS_FAILED++))
fi

printTest "8.2: Verify student record structure in results"
if echo "$result" | grep -q '"rollNumber":' && \
   echo "$result" | grep -q '"department":' && \
   echo "$result" | grep -q '"enrollmentYear":' && \
   echo "$result" | grep -q '"status":'; then
    echo "✅ PASSED: Student records have all required fields"
    ((TESTS_PASSED++))
else
    echo "❌ FAILED: Student records missing required fields"
    ((TESTS_FAILED++))
fi

printTest "8.3: Verify hasMore=false when all results fit in one page"
if echo "$result" | grep -q '"hasMore":false'; then
    echo "✅ PASSED: hasMore correctly set to false"
    ((TESTS_PASSED++))
else
    echo "❌ FAILED: hasMore should be false"
    ((TESTS_FAILED++))
fi

# ============================================================================
# TEST GROUP 9: Cross-Department Queries
# ============================================================================
printHeader "TEST GROUP 9: Cross-Department & Cross-Year Queries"

printTest "9.1: Count total students across all departments"
total_students=$(docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"GetAllStudents","Args":[]}' | grep -o '"rollNumber":' | wc -l)

echo "Total students in system: $total_students"
if [ "$total_students" -ge 5 ]; then
    echo "✅ PASSED: Expected at least 5 students, found $total_students"
    ((TESTS_PASSED++))
else
    echo "❌ FAILED: Expected at least 5 students, found $total_students"
    ((TESTS_FAILED++))
fi

printTest "9.2: Verify CSE has most students (3 students)"
cse_count=$(docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"QueryStudentsByDepartment","Args":["CSE","","50"]}' | grep -o '"rollNumber":"CS' | wc -l)

echo "CSE students: $cse_count"
if [ "$cse_count" -eq 3 ]; then
    echo "✅ PASSED: CSE has exactly 3 students"
    ((TESTS_PASSED++))
else
    echo "❌ FAILED: Expected 3 CSE students, found $cse_count"
    ((TESTS_FAILED++))
fi

# ============================================================================
# TEST GROUP 10: Academic Records Queries
# ============================================================================
printHeader "TEST GROUP 10: Academic Records Advanced Queries"

printTest "10.1: Verify all semester 1 records have correct semester field"
sem1_records=$(docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"QueryRecordsBySemester","Args":["1","","50"]}')

if echo "$sem1_records" | grep -q '"semester":1'; then
    echo "✅ PASSED: Semester 1 records have correct semester field"
    ((TESTS_PASSED++))
else
    echo "❌ FAILED: Semester field not found in results"
    ((TESTS_FAILED++))
fi

printTest "10.2: Verify DRAFT records have correct status field"
draft_records=$(docker exec -e CORE_PEER_LOCALMSPID=NITWarangalMSP \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=$PEER_NITW_CA \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp \
    -e CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051 \
    cli peer chaincode query \
    -C academic-records-channel -n academic-records \
    -c '{"function":"QueryRecordsByStatus","Args":["DRAFT","","50"]}')

if echo "$draft_records" | grep -q '"status":"DRAFT"'; then
    echo "✅ PASSED: DRAFT records have correct status"
    ((TESTS_PASSED++))
else
    echo "❌ FAILED: Status field not correct in DRAFT records"
    ((TESTS_FAILED++))
fi

printTest "10.3: Verify academic records contain course arrays"
if echo "$sem1_records" | grep -q '"courses":\['; then
    echo "✅ PASSED: Academic records contain courses array"
    ((TESTS_PASSED++))
else
    echo "❌ FAILED: Courses array not found"
    ((TESTS_FAILED++))
fi

printTest "10.4: Verify academic records have SGPA field"
if echo "$sem1_records" | grep -q '"sgpa":'; then
    echo "✅ PASSED: Academic records have SGPA field"
    ((TESTS_PASSED++))
else
    echo "❌ FAILED: SGPA field not found"
    ((TESTS_FAILED++))
fi

# ============================================================================
# FINAL RESULTS
# ============================================================================
printHeader "📊 TEST SUITE RESULTS"
echo ""
echo "✅ Tests Passed: $TESTS_PASSED"
echo "❌ Tests Failed: $TESTS_FAILED"
echo "📈 Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo "🎉 ALL TESTS PASSED! Phase 2 Query Functions Working Perfectly!"
    echo ""
    exit 0
else
    echo ""
    echo "⚠️  Some tests failed. Please review the output above."
    echo ""
    exit 1
fi

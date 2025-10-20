#!/bin/bash
#
# Test script for NIT Warangal Academic Records Blockchain

API_URL="http://localhost:3000"

echo "=========================================="
echo "NIT Warangal Academic Records API Tests"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Health Check
echo -e "${YELLOW}Test 1: Health Check${NC}"
curl -s $API_URL/health | jq .
echo ""
sleep 1

# Test 2: Create Student
echo -e "${YELLOW}Test 2: Create Student${NC}"
curl -s -X POST $API_URL/api/students \
  -H "Content-Type: application/json" \
  -d '{
    "studentId": "NITW2021001",
    "name": "Rajesh Kumar",
    "department": "Computer Science and Engineering",
    "enrollmentYear": 2021,
    "rollNumber": "21CS001",
    "email": "rajesh.kumar@student.nitw.ac.in"
  }' | jq .
echo ""
sleep 2

# Test 3: Create Another Student
echo -e "${YELLOW}Test 3: Create Another Student${NC}"
curl -s -X POST $API_URL/api/students \
  -H "Content-Type: application/json" \
  -d '{
    "studentId": "NITW2021002",
    "name": "Priya Sharma",
    "department": "Electronics and Communication Engineering",
    "enrollmentYear": 2021,
    "rollNumber": "21EC001",
    "email": "priya.sharma@student.nitw.ac.in"
  }' | jq .
echo ""
sleep 2

# Test 4: Get Student
echo -e "${YELLOW}Test 4: Get Student by ID${NC}"
curl -s $API_URL/api/students/NITW2021001 | jq .
echo ""
sleep 1

# Test 5: Get All Students
echo -e "${YELLOW}Test 5: Get All Students${NC}"
curl -s $API_URL/api/students | jq .
echo ""
sleep 1

# Test 6: Create Academic Record
echo -e "${YELLOW}Test 6: Create Academic Record (Semester 1)${NC}"
curl -s -X POST $API_URL/api/records \
  -H "Content-Type: application/json" \
  -d '{
    "recordId": "REC-2021-1-001",
    "studentId": "NITW2021001",
    "semester": 1,
    "courses": [
      {
        "courseCode": "CS101",
        "courseName": "Programming for Problem Solving",
        "credits": 4,
        "grade": "A",
        "facultyId": "FAC001"
      },
      {
        "courseCode": "MA101",
        "courseName": "Mathematics-I",
        "credits": 4,
        "grade": "S",
        "facultyId": "FAC002"
      },
      {
        "courseCode": "PH101",
        "courseName": "Engineering Physics",
        "credits": 3,
        "grade": "A",
        "facultyId": "FAC003"
      },
      {
        "courseCode": "EE101",
        "courseName": "Basic Electrical Engineering",
        "credits": 3,
        "grade": "B",
        "facultyId": "FAC004"
      }
    ]
  }' | jq .
echo ""
sleep 2

# Test 7: Get Academic Record
echo -e "${YELLOW}Test 7: Get Academic Record${NC}"
curl -s $API_URL/api/records/REC-2021-1-001 | jq .
echo ""
sleep 1

# Test 8: Approve Academic Record
echo -e "${YELLOW}Test 8: Approve Academic Record${NC}"
curl -s -X PUT $API_URL/api/records/REC-2021-1-001/approve | jq .
echo ""
sleep 2

# Test 9: Create Semester 2 Record
echo -e "${YELLOW}Test 9: Create Academic Record (Semester 2)${NC}"
curl -s -X POST $API_URL/api/records \
  -H "Content-Type: application/json" \
  -d '{
    "recordId": "REC-2021-2-001",
    "studentId": "NITW2021001",
    "semester": 2,
    "courses": [
      {
        "courseCode": "CS201",
        "courseName": "Data Structures",
        "credits": 4,
        "grade": "S",
        "facultyId": "FAC005"
      },
      {
        "courseCode": "MA201",
        "courseName": "Mathematics-II",
        "credits": 4,
        "grade": "A",
        "facultyId": "FAC006"
      },
      {
        "courseCode": "EC201",
        "courseName": "Digital Logic Design",
        "credits": 3,
        "grade": "A",
        "facultyId": "FAC007"
      }
    ]
  }' | jq .
echo ""
sleep 2

# Test 10: Approve Semester 2 Record
echo -e "${YELLOW}Test 10: Approve Semester 2 Record${NC}"
curl -s -X PUT $API_URL/api/records/REC-2021-2-001/approve | jq .
echo ""
sleep 2

# Test 11: Get Student History
echo -e "${YELLOW}Test 11: Get Complete Student History${NC}"
curl -s $API_URL/api/students/NITW2021001/history | jq .
echo ""
sleep 1

# Test 12: Update Student Status
echo -e "${YELLOW}Test 12: Update Student Status to GRADUATED${NC}"
curl -s -X PUT $API_URL/api/students/NITW2021001/status \
  -H "Content-Type: application/json" \
  -d '{
    "status": "GRADUATED"
  }' | jq .
echo ""
sleep 1

# Test 13: Verify Updated Status
echo -e "${YELLOW}Test 13: Verify Updated Student Status${NC}"
curl -s $API_URL/api/students/NITW2021001 | jq .
echo ""

echo -e "${GREEN}=========================================="
echo "All Tests Completed!"
echo -e "==========================================${NC}"

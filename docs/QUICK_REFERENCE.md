# ⚡ Quick Reference Guide

## Essential Commands for Daily Operations

---

## 🚀 Starting the Network

```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network

# Start network
docker-compose -f docker/docker-compose-net.yaml up -d

# Start API server
cd application-typescript
nohup npm run dev > api-server.log 2>&1 &
```

---

## 🛑 Stopping the Network

```bash
# Stop API server
pkill -f "npm run dev"

# Stop containers
cd ~/hyperledger/fabric-samples/nit-warangal-network
docker-compose -f docker/docker-compose-net.yaml down
```

---

## 📊 Status Checks

### Network Status
```bash
docker ps
docker logs orderer.nitw.edu
docker logs peer0.nitwarangal.nitw.edu
```

### API Status
```bash
curl http://localhost:3000/health
tail -50 ~/hyperledger/fabric-samples/nit-warangal-network/application-typescript/api-server.log
```

### Channel Status
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network
export FABRIC_CFG_PATH=/Users/apple/hyperledger/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp

../bin/peer channel list
../bin/peer channel getinfo -c academic-records-channel
```

### Chaincode Status
```bash
../bin/peer lifecycle chaincode queryinstalled
../bin/peer lifecycle chaincode querycommitted -C academic-records-channel -n academic-records
```

---

## 🔄 Environment Setup (Copy-Paste)

### For NITWarangal Org
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network
export FABRIC_CFG_PATH=/Users/apple/hyperledger/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/msp/tlscacerts/tlsca.nitw.edu-cert.pem
```

### For Departments Org
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network
export FABRIC_CFG_PATH=/Users/apple/hyperledger/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="DepartmentsMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp
export CORE_PEER_ADDRESS=peer0.departments.nitw.edu:9051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/msp/tlscacerts/tlsca.nitw.edu-cert.pem
```

### For Verifiers Org
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network
export FABRIC_CFG_PATH=/Users/apple/hyperledger/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="VerifiersMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp
export CORE_PEER_ADDRESS=peer0.verifiers.nitw.edu:11051
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/msp/tlscacerts/tlsca.nitw.edu-cert.pem
```

---

## 🧪 Common API Tests

### Health Check
```bash
curl http://localhost:3000/health
```

### Get All Students
```bash
curl -s http://localhost:3000/api/students | python3 -m json.tool
```

### Get Specific Student
```bash
curl -s http://localhost:3000/api/students/STU001 | python3 -m json.tool
```

### Create Student
```bash
curl -X POST http://localhost:3000/api/students \
  -H "Content-Type: application/json" \
  -d '{
    "studentId": "STU003",
    "name": "Alice Johnson",
    "department": "Mechanical Engineering",
    "enrollmentYear": "2024",
    "rollNumber": "ME001",
    "email": "alice@nitw.edu"
  }' | python3 -m json.tool
```

### Create Academic Record
```bash
curl -X POST http://localhost:3000/api/records \
  -H "Content-Type: application/json" \
  -d '{
    "recordId": "REC003",
    "studentId": "STU003",
    "semester": "1",
    "courses": [
      {"courseCode":"ME101","courseName":"Engineering Drawing","credits":3,"grade":"A"},
      {"courseCode":"MA101","courseName":"Calculus","credits":4,"grade":"S"}
    ]
  }' | python3 -m json.tool
```

### Get Student Records
```bash
curl -s http://localhost:3000/api/records/student/STU003 | python3 -m json.tool
```

### Approve Record (Departments)
```bash
curl -X PUT http://localhost:3000/api/records/REC003/approve \
  -H "Content-Type: application/json" \
  -d '{"approver":"Prof. Kumar","comments":"Verified"}' | python3 -m json.tool
```

---

## 🔧 Chaincode CLI Commands

### Invoke CreateStudent
```bash
../bin/peer chaincode invoke \
  -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  -C academic-records-channel \
  -n academic-records \
  --peerAddresses peer0.nitwarangal.nitw.edu:7051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.departments.nitw.edu:9051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
  -c '{"function":"CreateStudent","Args":["STU999","Test User","CSE","2024","CS999","test@nitw.edu"]}'
```

### Query GetStudent
```bash
../bin/peer chaincode query \
  -C academic-records-channel \
  -n academic-records \
  -c '{"function":"GetStudent","Args":["STU999"]}'
```

### Query GetAllStudents
```bash
../bin/peer chaincode query \
  -C academic-records-channel \
  -n academic-records \
  -c '{"function":"GetAllStudents","Args":[]}'
```

---

## 📦 Chaincode Upgrade Process

### 1. Update Code
```bash
# Edit chaincode-go/academic-records/chaincode.go
nano chaincode-go/academic-records/chaincode.go
```

### 2. Package New Version
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network
../bin/peer lifecycle chaincode package academic_records_1.3.tar.gz \
  --path chaincode-go/academic-records \
  --lang golang \
  --label academic_records_1.3
```

### 3. Install on All Peers
```bash
# Set env for each org and run:
../bin/peer lifecycle chaincode install academic_records_1.3.tar.gz
```

### 4. Get Package ID
```bash
../bin/peer lifecycle chaincode queryinstalled
export CC_PACKAGE_ID="<copy-package-id-here>"
```

### 5. Approve for All Orgs
```bash
# For each org (NITWarangal, Departments, Verifiers):
../bin/peer lifecycle chaincode approveformyorg \
  -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  --channelID academic-records-channel \
  --name academic-records \
  --version 1.3 \
  --package-id $CC_PACKAGE_ID \
  --sequence 2
```

### 6. Commit
```bash
../bin/peer lifecycle chaincode commit \
  -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  --channelID academic-records-channel \
  --name academic-records \
  --version 1.3 \
  --sequence 2 \
  --peerAddresses peer0.nitwarangal.nitw.edu:7051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.departments.nitw.edu:9051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.verifiers.nitw.edu:11051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt
```

---

## 🧹 Cleanup Commands

### Remove Old Chaincode Packages
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network
rm -f academic_records_*.tar.gz
```

### Clean Docker
```bash
docker system prune -a
docker volume prune
```

### Clean API Wallet
```bash
rm -rf application-typescript/wallet/
cd application-typescript
npx ts-node src/enrollAdmin.ts
```

### Complete Reset
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network

# Stop everything
docker-compose -f docker/docker-compose-net.yaml down -v
pkill -f "npm run dev"

# Clean artifacts
rm -rf organizations/
rm -rf channel-artifacts/*
rm -rf application-typescript/wallet/
rm -f academic_records_*.tar.gz

# Then follow COMPLETE_SETUP_GUIDE.md from Step 2
```

---

## 🔍 Debugging

### Check Logs
```bash
# Orderer
docker logs orderer.nitw.edu

# Peer
docker logs peer0.nitwarangal.nitw.edu

# API Server
tail -100 ~/hyperledger/fabric-samples/nit-warangal-network/application-typescript/api-server.log

# All containers
docker-compose -f docker/docker-compose-net.yaml logs
```

### Network Connectivity
```bash
# Test DNS resolution
ping peer0.nitwarangal.nitw.edu

# Test port
telnet peer0.nitwarangal.nitw.edu 7051

# Check listening ports
netstat -an | grep LISTEN | grep -E '7051|9051|11051|7050'
```

### Test TLS Certificates
```bash
# Check cert validity
openssl x509 -in organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/server.crt -text -noout

# Check cert dates
openssl x509 -in organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/server.crt -dates -noout
```

---

## 📝 Port Reference

| Service | Port | URL |
|---------|------|-----|
| Orderer | 7050 | orderer.nitw.edu:7050 |
| Orderer Admin | 7053 | localhost:7053 |
| Peer0 NITWarangal | 7051 | peer0.nitwarangal.nitw.edu:7051 |
| Peer1 NITWarangal | 8051 | peer1.nitwarangal.nitw.edu:8051 |
| Peer0 Departments | 9051 | peer0.departments.nitw.edu:9051 |
| Peer1 Departments | 10051 | peer1.departments.nitw.edu:10051 |
| Peer0 Verifiers | 11051 | peer0.verifiers.nitw.edu:11051 |
| REST API | 3000 | http://localhost:3000 |

---

## 🎯 Key File Locations

```
nit-warangal-network/
├── organizations/                          # Generated crypto materials
│   ├── ordererOrganizations/
│   └── peerOrganizations/
├── channel-artifacts/                      # Channel config & blocks
│   ├── genesis.block
│   └── academic-records-channel.block
├── chaincode-go/academic-records/          # Smart contract code
│   └── chaincode.go
├── application-typescript/                 # REST API
│   ├── src/server.ts
│   ├── wallet/                            # User identities
│   └── .env                               # Configuration
├── docker/                                # Docker compose files
│   └── docker-compose-net.yaml
├── configtx/                              # Channel configuration
│   └── configtx.yaml
└── scripts/                               # Utility scripts
```

---

## 💡 Pro Tips

1. **Always set environment variables** before running peer commands
2. **Use absolute paths** to avoid confusion
3. **Check Docker logs first** when debugging
4. **Increment sequence number** for chaincode upgrades
5. **Keep track of Package ID** - it changes with each package
6. **Use python3 -m json.tool** to format JSON output
7. **Run health check** before testing API
8. **Restart API server** after wallet changes

---

## 🆘 Common Issues & Solutions

### "Error: chaincode not found"
```bash
# Check if chaincode is committed
../bin/peer lifecycle chaincode querycommitted -C academic-records-channel
```

### "Connection refused"
```bash
# Check if containers are running
docker ps

# Check /etc/hosts
cat /etc/hosts | grep nitw
```

### "Wallet not found"
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network/application-typescript
npx ts-node src/enrollAdmin.ts
```

### "MVCC read conflict"
```bash
# Transaction conflict - retry after a moment
sleep 2
# Then retry your transaction
```

---

**Quick Start After System Reboot:**
```bash
# 1. Start network
cd ~/hyperledger/fabric-samples/nit-warangal-network
docker-compose -f docker/docker-compose-net.yaml up -d

# 2. Wait 10 seconds
sleep 10

# 3. Start API
cd application-typescript
nohup npm run dev > api-server.log 2>&1 &

# 4. Test
curl http://localhost:3000/health
```

---

**Version:** 1.2.0  
**Last Updated:** October 21, 2025  

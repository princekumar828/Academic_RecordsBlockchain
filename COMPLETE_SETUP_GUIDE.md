# 🚀 Complete Setup Guide - NIT Warangal Academic Records Blockchain

## Version 1.2 - Final Working Commands

This guide contains all the tested, working commands to deploy the blockchain network from scratch.

---

## 📋 Prerequisites

### Required Software
```bash
# Check versions
docker --version          # Should be 20.10+
docker-compose --version  # Should be 1.29+
node --version           # Should be v16+
npm --version            # Should be 8+
go version               # Should be 1.21+

# Check if Hyperledger Fabric binaries exist
ls ~/hyperledger/fabric-samples/bin/
# Should show: peer, orderer, configtxgen, etc.
```

### System Requirements
- **OS:** macOS (Apple Silicon or Intel)
- **RAM:** 8GB minimum, 16GB recommended
- **Disk:** 20GB free space
- **Network:** Internet connection for downloads

---

## 📁 Step 1: Project Setup

### 1.1 Navigate to Fabric Samples Directory
```bash
cd ~/hyperledger/fabric-samples
```

### 1.2 Verify nit-warangal-network Directory Exists
```bash
ls -la nit-warangal-network/
```

**If directory doesn't exist, the project files should be in this repository.**

---

## 🔐 Step 2: Generate Crypto Materials

### 2.1 Navigate to Project Directory
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network
```

### 2.2 Generate Certificates and Keys
```bash
# Generate crypto materials using cryptogen
../bin/cryptogen generate --config=./crypto-config.yaml --output="organizations"

# Verify generation
ls -la organizations/
# Should show: ordererOrganizations/ and peerOrganizations/
```

**Expected Output:**
```
org1.example.com
org2.example.com
org3.example.com
nitwarangal.nitw.edu
departments.nitw.edu
verifiers.nitw.edu
ordererOrganizations
```

---

## 🏗️ Step 3: Generate Genesis Block and Channel Configuration

### 3.1 Set Fabric Config Path
```bash
export FABRIC_CFG_PATH=${PWD}/configtx
```

### 3.2 Generate Genesis Block
```bash
../bin/configtxgen -profile ThreeOrgsOrdererGenesis \
  -channelID system-channel \
  -outputBlock ./channel-artifacts/genesis.block \
  -configPath ./configtx
```

**Expected Output:**
```
Loading configuration
Generating genesis block
Writing genesis block
```

### 3.3 Generate Channel Configuration Transaction
```bash
../bin/configtxgen -profile ThreeOrgsChannel \
  -outputCreateChannelTx ./channel-artifacts/academic-records-channel.tx \
  -channelID academic-records-channel \
  -configPath ./configtx
```

### 3.4 Generate Anchor Peer Configurations
```bash
# For NITWarangalMSP
../bin/configtxgen -profile ThreeOrgsChannel \
  -outputAnchorPeersUpdate ./channel-artifacts/NITWarangalMSPanchors.tx \
  -channelID academic-records-channel \
  -asOrg NITWarangalMSP \
  -configPath ./configtx

# For DepartmentsMSP
../bin/configtxgen -profile ThreeOrgsChannel \
  -outputAnchorPeersUpdate ./channel-artifacts/DepartmentsMSPanchors.tx \
  -channelID academic-records-channel \
  -asOrg DepartmentsMSP \
  -configPath ./configtx

# For VerifiersMSP
../bin/configtxgen -profile ThreeOrgsChannel \
  -outputAnchorPeersUpdate ./channel-artifacts/VerifiersMSPanchors.tx \
  -channelID academic-records-channel \
  -asOrg VerifiersMSP \
  -configPath ./configtx
```

---

## 🐳 Step 4: Update /etc/hosts

### 4.1 Add Hostnames (Required for TLS)
```bash
sudo nano /etc/hosts
```

**Add these lines:**
```
127.0.0.1 orderer.nitw.edu
127.0.0.1 orderer2.nitw.edu
127.0.0.1 orderer3.nitw.edu
127.0.0.1 peer0.nitwarangal.nitw.edu
127.0.0.1 peer1.nitwarangal.nitw.edu
127.0.0.1 peer0.departments.nitw.edu
127.0.0.1 peer1.departments.nitw.edu
127.0.0.1 peer0.verifiers.nitw.edu
```

**Save and exit:** `Ctrl+O`, `Enter`, `Ctrl+X`

---

## 🚀 Step 5: Start the Network

### 5.1 Start Docker Containers
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network

docker-compose -f docker/docker-compose-net.yaml up -d
```

### 5.2 Verify All Containers Are Running
```bash
docker ps
```

**Expected Output:** 8 containers running
- orderer.nitw.edu
- orderer2.nitw.edu (may be inactive)
- orderer3.nitw.edu (may be inactive)
- peer0.nitwarangal.nitw.edu
- peer1.nitwarangal.nitw.edu
- peer0.departments.nitw.edu
- peer1.departments.nitw.edu
- peer0.verifiers.nitw.edu
- cli

### 5.3 Check Container Logs (Optional)
```bash
# Check orderer
docker logs orderer.nitw.edu

# Check peer
docker logs peer0.nitwarangal.nitw.edu
```

---

## 📡 Step 6: Create and Join Channel

### 6.1 Set Environment Variables
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

### 6.2 Create Channel
```bash
../bin/peer channel create \
  -o orderer.nitw.edu:7050 \
  -c academic-records-channel \
  -f ./channel-artifacts/academic-records-channel.tx \
  --outputBlock ./channel-artifacts/academic-records-channel.block \
  --tls --cafile $ORDERER_CA
```

**Expected Output:**
```
Channel 'academic-records-channel' created
```

### 6.3 Join Orderer to Channel
```bash
../bin/osnadmin channel join \
  --channelID academic-records-channel \
  --config-block ./channel-artifacts/academic-records-channel.block \
  -o localhost:7053 \
  --ca-file "$ORDERER_CA" \
  --client-cert "${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/tls/server.crt" \
  --client-key "${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/tls/server.key"
```

### 6.4 Join All Peers to Channel

**Peer0 NITWarangal:**
```bash
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp

../bin/peer channel join -b ./channel-artifacts/academic-records-channel.block
```

**Peer1 NITWarangal:**
```bash
export CORE_PEER_ADDRESS=peer1.nitwarangal.nitw.edu:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer1.nitwarangal.nitw.edu/tls/ca.crt

../bin/peer channel join -b ./channel-artifacts/academic-records-channel.block
```

**Peer0 Departments:**
```bash
export CORE_PEER_LOCALMSPID="DepartmentsMSP"
export CORE_PEER_ADDRESS=peer0.departments.nitw.edu:9051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp

../bin/peer channel join -b ./channel-artifacts/academic-records-channel.block
```

**Peer1 Departments:**
```bash
export CORE_PEER_ADDRESS=peer1.departments.nitw.edu:10051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer1.departments.nitw.edu/tls/ca.crt

../bin/peer channel join -b ./channel-artifacts/academic-records-channel.block
```

**Peer0 Verifiers:**
```bash
export CORE_PEER_LOCALMSPID="VerifiersMSP"
export CORE_PEER_ADDRESS=peer0.verifiers.nitw.edu:11051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp

../bin/peer channel join -b ./channel-artifacts/academic-records-channel.block
```

### 6.5 Verify Channel Membership
```bash
../bin/peer channel list
```

**Expected Output:**
```
Channels peers has joined: 
academic-records-channel
```

---

## 📦 Step 7: Deploy Chaincode (Smart Contract)

### 7.1 Package Chaincode
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network

../bin/peer lifecycle chaincode package academic_records_1.2.tar.gz \
  --path chaincode-go/academic-records \
  --lang golang \
  --label academic_records_1.2
```

### 7.2 Install Chaincode on All Endorsing Peers

**On Peer0 NITWarangal:**
```bash
export FABRIC_CFG_PATH=/Users/apple/hyperledger/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp

../bin/peer lifecycle chaincode install academic_records_1.2.tar.gz
```

**On Peer0 Departments:**
```bash
export CORE_PEER_LOCALMSPID="DepartmentsMSP"
export CORE_PEER_ADDRESS=peer0.departments.nitw.edu:9051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp

../bin/peer lifecycle chaincode install academic_records_1.2.tar.gz
```

**On Peer0 Verifiers:**
```bash
export CORE_PEER_LOCALMSPID="VerifiersMSP"
export CORE_PEER_ADDRESS=peer0.verifiers.nitw.edu:11051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp

../bin/peer lifecycle chaincode install academic_records_1.2.tar.gz
```

### 7.3 Query Installed Chaincode and Get Package ID
```bash
../bin/peer lifecycle chaincode queryinstalled
```

**Copy the Package ID** (format: `academic_records_1.2:xxxxx...`)

### 7.4 Approve Chaincode for Each Organization

**Set the Package ID:**
```bash
export CC_PACKAGE_ID="academic_records_1.2:a37c987afe6085a1ef031ec9affdc0c5ab4a17d3c1b5fa5801a89464275736da"
# Replace with YOUR actual package ID from previous step
```

**Approve for NITWarangalMSP:**
```bash
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp

../bin/peer lifecycle chaincode approveformyorg \
  -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  --channelID academic-records-channel \
  --name academic-records \
  --version 1.2 \
  --package-id $CC_PACKAGE_ID \
  --sequence 1
```

**Approve for DepartmentsMSP:**
```bash
export CORE_PEER_LOCALMSPID="DepartmentsMSP"
export CORE_PEER_ADDRESS=peer0.departments.nitw.edu:9051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/departments.nitw.edu/users/Admin@departments.nitw.edu/msp

../bin/peer lifecycle chaincode approveformyorg \
  -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  --channelID academic-records-channel \
  --name academic-records \
  --version 1.2 \
  --package-id $CC_PACKAGE_ID \
  --sequence 1
```

**Approve for VerifiersMSP:**
```bash
export CORE_PEER_LOCALMSPID="VerifiersMSP"
export CORE_PEER_ADDRESS=peer0.verifiers.nitw.edu:11051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/users/Admin@verifiers.nitw.edu/msp

../bin/peer lifecycle chaincode approveformyorg \
  -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  --channelID academic-records-channel \
  --name academic-records \
  --version 1.2 \
  --package-id $CC_PACKAGE_ID \
  --sequence 1
```

### 7.5 Check Commit Readiness
```bash
../bin/peer lifecycle chaincode checkcommitreadiness \
  --channelID academic-records-channel \
  --name academic-records \
  --version 1.2 \
  --sequence 1 \
  --tls --cafile $ORDERER_CA \
  --output json
```

**Expected:** All three orgs should show `"Approved": true`

### 7.6 Commit Chaincode
```bash
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp

../bin/peer lifecycle chaincode commit \
  -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  --channelID academic-records-channel \
  --name academic-records \
  --version 1.2 \
  --sequence 1 \
  --peerAddresses peer0.nitwarangal.nitw.edu:7051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.departments.nitw.edu:9051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/departments.nitw.edu/peers/peer0.departments.nitw.edu/tls/ca.crt \
  --peerAddresses peer0.verifiers.nitw.edu:11051 \
  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/verifiers.nitw.edu/peers/peer0.verifiers.nitw.edu/tls/ca.crt
```

### 7.7 Verify Chaincode is Committed
```bash
../bin/peer lifecycle chaincode querycommitted \
  --channelID academic-records-channel \
  --name academic-records
```

**Expected Output:**
```
Version: 1.2, Sequence: 1, Endorsement Plugin: escc, Validation Plugin: vscc, Approvals: [NITWarangalMSP: true, DepartmentsMSP: true, VerifiersMSP: true]
```

---

## 🧪 Step 8: Test Chaincode

### 8.1 Create a Student
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network

export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp

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
  -c '{"function":"CreateStudent","Args":["STU001","John Doe","Computer Science","2023","CS001","john@nitw.edu"]}'
```

**Expected:** `status:200`

### 8.2 Query the Student
```bash
../bin/peer chaincode query \
  -C academic-records-channel \
  -n academic-records \
  -c '{"function":"GetStudent","Args":["STU001"]}'
```

**Expected Output:**
```json
{"studentId":"STU001","name":"John Doe","department":"Computer Science","enrollmentYear":2023,"rollNumber":"CS001","email":"john@nitw.edu","status":"ACTIVE"}
```

### 8.3 Query All Students
```bash
../bin/peer chaincode query \
  -C academic-records-channel \
  -n academic-records \
  -c '{"function":"GetAllStudents","Args":[]}'
```

---

## 🌐 Step 9: Setup REST API

### 9.1 Install Dependencies
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network/application-typescript

npm install
```

### 9.2 Configure Environment
```bash
# Verify .env file exists
cat .env
```

**Should contain:**
```env
PORT=3000
NODE_ENV=development
CHANNEL_NAME=academic-records-channel
CHAINCODE_NAME=academic-records
ORG_NAME=NITWarangal
USER_ID=admin
CONNECTION_PROFILE_PATH=../organizations/peerOrganizations/nitwarangal.nitw.edu/connection-nitwarangal.json
WALLET_PATH=./wallet
MSP_ID=NITWarangalMSP
PEER_ENDPOINT=peer0.nitwarangal.nitw.edu:7051
```

### 9.3 Enroll Admin User
```bash
npx ts-node src/enrollAdmin.ts
```

**Expected Output:**
```
Successfully enrolled admin user and imported it into the wallet
```

### 9.4 Verify Wallet Created
```bash
ls -la wallet/
```

**Should show:** `admin.id`

### 9.5 Start API Server
```bash
# Start in background
nohup npm run dev > api-server.log 2>&1 &

# Check it started
tail -f api-server.log
```

**Expected Output:**
```
╔════════════════════════════════════════════════════════════╗
║  NIT Warangal Academic Records Blockchain API              ║
║  Server running on port 3000                              ║
║  Health check: http://localhost:3000/health              ║
╚════════════════════════════════════════════════════════════╝
```

Press `Ctrl+C` to stop tailing logs.

---

## ✅ Step 10: Test REST API

### 10.1 Health Check
```bash
curl http://localhost:3000/health
```

**Expected:**
```json
{"status":"ok","message":"NIT Warangal Academic Records API is running"}
```

### 10.2 Get All Students
```bash
curl -s http://localhost:3000/api/students | python3 -m json.tool
```

### 10.3 Get Specific Student
```bash
curl -s http://localhost:3000/api/students/STU001 | python3 -m json.tool
```

### 10.4 Create New Student via API
```bash
curl -s -X POST http://localhost:3000/api/students \
  -H "Content-Type: application/json" \
  -d '{
    "studentId": "STU002",
    "name": "Jane Smith",
    "department": "Electrical Engineering",
    "enrollmentYear": "2023",
    "rollNumber": "EE001",
    "email": "jane@nitw.edu"
  }' | python3 -m json.tool
```

### 10.5 Create Academic Record
```bash
curl -s -X POST http://localhost:3000/api/records \
  -H "Content-Type: application/json" \
  -d '{
    "recordId": "REC001",
    "studentId": "STU001",
    "semester": "1",
    "courses": [
      {"courseCode":"CS101","courseName":"Programming","credits":4,"grade":"A"},
      {"courseCode":"MA101","courseName":"Mathematics","credits":4,"grade":"S"},
      {"courseCode":"PH101","courseName":"Physics","credits":3,"grade":"A"}
    ]
  }' | python3 -m json.tool
```

---

## 🔧 Troubleshooting Commands

### Check Docker Status
```bash
docker ps -a
docker logs orderer.nitw.edu
docker logs peer0.nitwarangal.nitw.edu
```

### Check Network Connectivity
```bash
ping peer0.nitwarangal.nitw.edu
telnet peer0.nitwarangal.nitw.edu 7051
```

### Check API Server Status
```bash
# Check if running
ps aux | grep "npm run dev"

# Check logs
tail -100 ~/hyperledger/fabric-samples/nit-warangal-network/application-typescript/api-server.log

# Restart API
pkill -f "npm run dev"
cd ~/hyperledger/fabric-samples/nit-warangal-network/application-typescript
nohup npm run dev > api-server.log 2>&1 &
```

### Check Channel Status
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

### Check Chaincode Status
```bash
../bin/peer lifecycle chaincode queryinstalled
../bin/peer lifecycle chaincode querycommitted -C academic-records-channel -n academic-records
```

---

## 🛑 Stopping the Network

### Stop API Server
```bash
pkill -f "npm run dev"
```

### Stop Docker Containers
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network
docker-compose -f docker/docker-compose-net.yaml down
```

### Remove Volumes (Complete Clean)
```bash
docker-compose -f docker/docker-compose-net.yaml down -v
```

---

## 🔄 Complete Restart from Scratch

### Clean Everything
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network

# Stop containers
docker-compose -f docker/docker-compose-net.yaml down -v

# Remove generated artifacts
rm -rf organizations/
rm -rf channel-artifacts/*
rm -rf application-typescript/wallet/
rm -f academic_records_*.tar.gz

# Restart from Step 2
```

---

## 📊 Success Verification Checklist

- [ ] All 8 Docker containers running
- [ ] Channel created successfully
- [ ] All 5 peers joined channel
- [ ] Chaincode installed on 3 peers
- [ ] Chaincode approved by 3 orgs
- [ ] Chaincode committed (sequence 1)
- [ ] Test student created via CLI
- [ ] Test student queried successfully
- [ ] API server running on port 3000
- [ ] Health endpoint returns success
- [ ] GET /api/students returns data
- [ ] POST /api/students creates student

---

## 📝 Important Notes

1. **Absolute Paths:** Use full paths `/Users/apple/hyperledger/...` to avoid issues
2. **FABRIC_CFG_PATH:** Must be set for peer commands
3. **Environment Variables:** Must be set for each organization when switching contexts
4. **Package ID:** Will be different each time - copy from `queryinstalled` output
5. **Sequence Number:** Increment for chaincode upgrades (1, 2, 3...)
6. **/etc/hosts:** Required for TLS hostname validation
7. **Wallet Location:** Must be in `application-typescript/wallet/` directory
8. **Connection Profile:** TLS cert paths must be absolute

---

## 🎓 Key Concepts

- **Chaincode v1.2:** Uses deterministic timestamps and composite keys for LevelDB
- **3 Organizations:** NITWarangal, Departments, Verifiers
- **Endorsement Policy:** Majority (2 out of 3) required for transactions
- **TLS Enabled:** All communication encrypted
- **Channel:** academic-records-channel
- **State DB:** LevelDB with composite key optimization

---

## 🆘 Getting Help

If you encounter issues:

1. Check Docker logs
2. Verify environment variables
3. Check /etc/hosts entries
4. Ensure all paths are absolute
5. Review TROUBLESHOOTING.md (if exists)
6. Check API logs in `api-server.log`

---

**Version:** 1.2.0  
**Last Updated:** October 21, 2025  
**Status:** ✅ Production Ready

**🎉 You now have a complete, working blockchain network with REST API! 🎉**

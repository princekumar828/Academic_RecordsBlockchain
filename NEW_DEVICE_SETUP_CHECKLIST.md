# ✅ New Device Setup Checklist

## For Setting Up NIT Warangal Blockchain on Fresh macOS

---

## 📦 Phase 1: Prerequisites Installation

### 1.1 Install Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
- [ ] Homebrew installed
- [ ] Run `brew --version` to verify

### 1.2 Install Docker Desktop
- [ ] Download from https://www.docker.com/products/docker-desktop
- [ ] Install and start Docker Desktop
- [ ] Run `docker --version` (should be 20.10+)
- [ ] Run `docker-compose --version` (should be 1.29+)

### 1.3 Install Node.js and npm
```bash
brew install node@16
```
- [ ] Node.js installed
- [ ] Run `node --version` (should be v16+)
- [ ] Run `npm --version` (should be 8+)

### 1.4 Install Go
```bash
brew install go
```
- [ ] Go installed
- [ ] Run `go version` (should be 1.21+)

### 1.5 Install Git (if not installed)
```bash
brew install git
```
- [ ] Git installed
- [ ] Run `git --version`

---

## 🏗️ Phase 2: Hyperledger Fabric Setup

### 2.1 Create Directory Structure
```bash
mkdir -p ~/hyperledger
cd ~/hyperledger
```
- [ ] Directory created

### 2.2 Download Fabric Samples and Binaries
```bash
curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh

./install-fabric.sh docker binary samples
```
- [ ] Fabric binaries downloaded to `~/hyperledger/fabric-samples/bin/`
- [ ] Docker images pulled (may take 10-15 minutes)
- [ ] Run `ls ~/hyperledger/fabric-samples/bin/` to verify

**Expected binaries:**
- configtxgen
- configtxlator
- cryptogen
- discover
- fabric-ca-client
- fabric-ca-server
- ledgerutil
- orderer
- osnadmin
- peer

### 2.3 Add Binaries to PATH (Optional)
```bash
echo 'export PATH="$HOME/hyperledger/fabric-samples/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```
- [ ] PATH updated
- [ ] Run `peer version` to verify

---

## 📥 Phase 3: Project Files Setup

### 3.1 Copy/Clone Project Files
**Option A: If you have the project files:**
```bash
# Copy the nit-warangal-network directory to:
cp -r /path/to/nit-warangal-network ~/hyperledger/fabric-samples/
```

**Option B: From GitHub (if available):**
```bash
cd ~/hyperledger/fabric-samples
git clone <your-repo-url> nit-warangal-network
```

- [ ] `nit-warangal-network` directory exists in `~/hyperledger/fabric-samples/`

### 3.2 Verify Project Structure
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network
ls -la
```

**Should see:**
- [ ] `chaincode-go/`
- [ ] `application-typescript/`
- [ ] `configtx/`
- [ ] `crypto-config.yaml`
- [ ] `docker/`
- [ ] `scripts/`
- [ ] `COMPLETE_SETUP_GUIDE.md`
- [ ] `QUICK_REFERENCE.md`

---

## 🔐 Phase 4: Network Setup

### 4.1 Update /etc/hosts
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
- [ ] Hosts file updated
- [ ] Run `ping peer0.nitwarangal.nitw.edu` to verify (should resolve to 127.0.0.1)

### 4.2 Generate Crypto Materials
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network
../bin/cryptogen generate --config=./crypto-config.yaml --output="organizations"
```
- [ ] `organizations/` directory created
- [ ] Contains `ordererOrganizations/` and `peerOrganizations/`

### 4.3 Create Channel Artifacts Directory
```bash
mkdir -p channel-artifacts
```
- [ ] `channel-artifacts/` directory exists

### 4.4 Generate Genesis Block and Channel Config
```bash
export FABRIC_CFG_PATH=${PWD}/configtx

../bin/configtxgen -profile ThreeOrgsOrdererGenesis \
  -channelID system-channel \
  -outputBlock ./channel-artifacts/genesis.block \
  -configPath ./configtx

../bin/configtxgen -profile ThreeOrgsChannel \
  -outputCreateChannelTx ./channel-artifacts/academic-records-channel.tx \
  -channelID academic-records-channel \
  -configPath ./configtx

../bin/configtxgen -profile ThreeOrgsChannel \
  -outputAnchorPeersUpdate ./channel-artifacts/NITWarangalMSPanchors.tx \
  -channelID academic-records-channel \
  -asOrg NITWarangalMSP \
  -configPath ./configtx

../bin/configtxgen -profile ThreeOrgsChannel \
  -outputAnchorPeersUpdate ./channel-artifacts/DepartmentsMSPanchors.tx \
  -channelID academic-records-channel \
  -asOrg DepartmentsMSP \
  -configPath ./configtx

../bin/configtxgen -profile ThreeOrgsChannel \
  -outputAnchorPeersUpdate ./channel-artifacts/VerifiersMSPanchors.tx \
  -channelID academic-records-channel \
  -asOrg VerifiersMSP \
  -configPath ./configtx
```
- [ ] `genesis.block` created
- [ ] `academic-records-channel.tx` created
- [ ] All anchor peer update files created

---

## 🐳 Phase 5: Docker Network

### 5.1 Start Docker Containers
```bash
docker-compose -f docker/docker-compose-net.yaml up -d
```
- [ ] All containers started
- [ ] Run `docker ps` - should show 8 containers

### 5.2 Verify Container Health
```bash
docker logs orderer.nitw.edu 2>&1 | grep -i "Beginning to serve requests"
docker logs peer0.nitwarangal.nitw.edu 2>&1 | grep -i "Starting peer"
```
- [ ] Orderer is serving requests
- [ ] Peers are running

---

## 📡 Phase 6: Channel Creation

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
- [ ] Environment variables set

### 6.2 Create Channel
```bash
../bin/peer channel create \
  -o orderer.nitw.edu:7050 \
  -c academic-records-channel \
  -f ./channel-artifacts/academic-records-channel.tx \
  --outputBlock ./channel-artifacts/academic-records-channel.block \
  --tls --cafile $ORDERER_CA
```
- [ ] Channel `academic-records-channel` created
- [ ] `academic-records-channel.block` exists

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
- [ ] Orderer joined channel

### 6.4 Join All Peers (Run commands from COMPLETE_SETUP_GUIDE.md Step 6.4)
- [ ] Peer0 NITWarangal joined
- [ ] Peer1 NITWarangal joined
- [ ] Peer0 Departments joined
- [ ] Peer1 Departments joined
- [ ] Peer0 Verifiers joined

### 6.5 Verify Peers Joined
```bash
../bin/peer channel list
```
- [ ] Shows `academic-records-channel`

---

## 📦 Phase 7: Chaincode Deployment

### 7.1 Package Chaincode
```bash
../bin/peer lifecycle chaincode package academic_records_1.2.tar.gz \
  --path chaincode-go/academic-records \
  --lang golang \
  --label academic_records_1.2
```
- [ ] `academic_records_1.2.tar.gz` created

### 7.2 Install on All Endorsing Peers (Step 7.2 from guide)
- [ ] Installed on Peer0 NITWarangal
- [ ] Installed on Peer0 Departments
- [ ] Installed on Peer0 Verifiers

### 7.3 Get Package ID
```bash
../bin/peer lifecycle chaincode queryinstalled
```
- [ ] Package ID copied (format: `academic_records_1.2:xxxxx...`)
- [ ] Exported as `CC_PACKAGE_ID`

### 7.4 Approve for All Orgs (Step 7.4 from guide)
- [ ] Approved by NITWarangalMSP
- [ ] Approved by DepartmentsMSP
- [ ] Approved by VerifiersMSP

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
- [ ] All 3 orgs show `"Approved": true`

### 7.6 Commit Chaincode (Step 7.6 from guide)
```bash
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
- [ ] Chaincode committed

### 7.7 Verify Commitment
```bash
../bin/peer lifecycle chaincode querycommitted \
  --channelID academic-records-channel \
  --name academic-records
```
- [ ] Shows `Version: 1.2, Sequence: 1`

---

## 🧪 Phase 8: Test Chaincode

### 8.1 Create Test Student
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
  -c '{"function":"CreateStudent","Args":["STU001","John Doe","Computer Science","2023","CS001","john@nitw.edu"]}'
```
- [ ] Transaction successful (status: 200)

### 8.2 Query Student
```bash
../bin/peer chaincode query \
  -C academic-records-channel \
  -n academic-records \
  -c '{"function":"GetStudent","Args":["STU001"]}'
```
- [ ] Returns student JSON data

---

## 🌐 Phase 9: REST API Setup

### 9.1 Install API Dependencies
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network/application-typescript
npm install
```
- [ ] Dependencies installed
- [ ] No critical errors

### 9.2 Verify .env Configuration
```bash
cat .env
```
- [ ] PORT=3000
- [ ] All paths correct

### 9.3 Enroll Admin
```bash
npx ts-node src/enrollAdmin.ts
```
- [ ] Success message shown
- [ ] `wallet/` directory created
- [ ] `wallet/admin.id` exists

### 9.4 Start API Server
```bash
nohup npm run dev > api-server.log 2>&1 &
```
- [ ] Server started
- [ ] Run `tail -20 api-server.log` to verify

---

## ✅ Phase 10: Final Verification

### 10.1 Network Health
```bash
# All containers running
docker ps
```
- [ ] 8 containers running

### 10.2 API Health
```bash
curl http://localhost:3000/health
```
- [ ] Returns `{"status":"ok",...}`

### 10.3 Test API Endpoints
```bash
# Get all students
curl -s http://localhost:3000/api/students | python3 -m json.tool

# Get specific student
curl -s http://localhost:3000/api/students/STU001 | python3 -m json.tool
```
- [ ] Both return valid JSON with student data

### 10.4 Create Student via API
```bash
curl -X POST http://localhost:3000/api/students \
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
- [ ] Success response received
- [ ] New student created

---

## 🎉 Final Success Checklist

- [ ] All prerequisites installed
- [ ] Hyperledger Fabric binaries present
- [ ] Docker containers running (8 total)
- [ ] Channel created and peers joined
- [ ] Chaincode v1.2 deployed and committed
- [ ] CLI test successful (CreateStudent & GetStudent)
- [ ] REST API running on port 3000
- [ ] API health check passes
- [ ] API can read from blockchain
- [ ] API can write to blockchain
- [ ] Admin wallet enrolled

---

## 📚 Post-Setup Resources

After successful setup, refer to:

1. **COMPLETE_SETUP_GUIDE.md** - Full command reference
2. **QUICK_REFERENCE.md** - Daily operations guide
3. **NEXT_STEPS.md** - Future enhancements
4. **API_DOCUMENTATION.md** - API endpoint details
5. **IMPLEMENTATION_SUCCESS_SUMMARY.md** - Project overview

---

## 🆘 If Something Goes Wrong

### Stuck at Prerequisites?
- Ensure macOS is up to date
- Check internet connection
- Verify Homebrew is working: `brew doctor`

### Docker Issues?
- Restart Docker Desktop
- Check Docker has enough resources (8GB RAM minimum)
- Run `docker system prune` if disk space is low

### Network Won't Start?
- Check /etc/hosts entries
- Verify crypto materials exist
- Check Docker logs: `docker logs <container-name>`

### Chaincode Install Fails?
- Verify Go is installed: `go version`
- Check chaincode.go has no syntax errors
- Ensure all paths are correct

### API Won't Start?
- Check Node.js version: `node --version`
- Verify wallet exists: `ls wallet/`
- Check .env configuration
- Look at api-server.log for errors

### Still Stuck?
Review the specific error message and:
1. Check logs (Docker, API, terminal output)
2. Verify environment variables
3. Ensure all steps completed in order
4. Try the "Complete Reset" from QUICK_REFERENCE.md

---

## ⏱️ Estimated Time

| Phase | Time |
|-------|------|
| Prerequisites | 30-60 min |
| Fabric Setup | 15-30 min |
| Project Files | 5 min |
| Network Setup | 10 min |
| Docker Network | 5 min |
| Channel Creation | 10 min |
| Chaincode Deploy | 15 min |
| Test Chaincode | 5 min |
| API Setup | 10 min |
| Final Verification | 5 min |
| **TOTAL** | **2-3 hours** |

*Time may vary based on internet speed and system performance*

---

## 💾 Save This Checklist

Print or save this checklist. Check off items as you complete them. If interrupted, you'll know exactly where to resume.

---

**Version:** 1.2.0  
**Last Updated:** October 21, 2025  
**Status:** ✅ Ready for Production Deployment

**Good luck with your setup! 🚀**

# 🔧 Troubleshooting Guide

## Common Issues and Solutions

---

## Table of Contents

1. [Docker Issues](#docker-issues)
2. [Network Startup Issues](#network-startup-issues)
3. [Channel Creation Issues](#channel-creation-issues)
4. [Chaincode Issues](#chaincode-issues)
5. [API Issues](#api-issues)
6. [Certificate/TLS Issues](#certificatetls-issues)
7. [Performance Issues](#performance-issues)
8. [General Debugging](#general-debugging)

---

## Docker Issues

### ❌ Problem: "Cannot connect to the Docker daemon"

**Symptoms:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solutions:**
1. Start Docker Desktop application
2. Wait for Docker to fully start (whale icon in menu bar)
3. Verify: `docker ps`
4. If still failing, restart Docker Desktop

---

### ❌ Problem: "Port already in use"

**Symptoms:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:7051: bind: address already in use
```

**Solutions:**
```bash
# Find which process is using the port
lsof -i :7051

# Kill the process
kill -9 <PID>

# Or stop the old containers
docker ps -a
docker stop <container-id>
docker rm <container-id>

# Then restart
docker-compose -f docker/docker-compose-net.yaml up -d
```

---

### ❌ Problem: Containers keep restarting

**Symptoms:**
```bash
docker ps
# Shows containers with "Restarting" status
```

**Solutions:**
```bash
# Check logs for specific error
docker logs orderer.nitw.edu

# Common causes:
# 1. Wrong file permissions
sudo chown -R $USER:$USER organizations/

# 2. Missing genesis block
ls -la channel-artifacts/genesis.block

# 3. Configuration errors
cat configtx/configtx.yaml | grep -i error

# 4. Restart with fresh start
docker-compose -f docker/docker-compose-net.yaml down
docker-compose -f docker/docker-compose-net.yaml up -d
```

---

### ❌ Problem: "No space left on device"

**Symptoms:**
```
Error: No space left on device
```

**Solutions:**
```bash
# Clean Docker system
docker system prune -a --volumes

# Remove unused images
docker image prune -a

# Remove stopped containers
docker container prune

# Check disk space
df -h
```

---

## Network Startup Issues

### ❌ Problem: Orderer won't start

**Symptoms:**
```
orderer.nitw.edu exits immediately
```

**Solutions:**
```bash
# Check orderer logs
docker logs orderer.nitw.edu 2>&1 | tail -50

# Common issues:

# 1. Genesis block missing or wrong path
ls -la channel-artifacts/genesis.block
# Regenerate if needed:
export FABRIC_CFG_PATH=${PWD}/configtx
../bin/configtxgen -profile ThreeOrgsOrdererGenesis \
  -channelID system-channel \
  -outputBlock ./channel-artifacts/genesis.block

# 2. Certificate issues
ls -la organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/

# 3. Port conflicts (see Port already in use above)
```

---

### ❌ Problem: Peer won't connect to orderer

**Symptoms:**
```
Failed to dial orderer.nitw.edu:7050: connection refused
```

**Solutions:**
```bash
# 1. Check if orderer is running
docker ps | grep orderer

# 2. Check /etc/hosts
cat /etc/hosts | grep orderer.nitw.edu
# Should be: 127.0.0.1 orderer.nitw.edu

# 3. Test connectivity
ping orderer.nitw.edu
telnet orderer.nitw.edu 7050

# 4. Check orderer logs
docker logs orderer.nitw.edu | grep -i "error\|fail"

# 5. Verify TLS certificates
openssl x509 -in organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/tls/server.crt -text -noout
```

---

### ❌ Problem: "dial tcp: lookup peer0.nitwarangal.nitw.edu: no such host"

**Symptoms:**
```
Failed to dial peer0.nitwarangal.nitw.edu:7051
```

**Solutions:**
```bash
# 1. Update /etc/hosts
sudo nano /etc/hosts

# Add all hostnames:
127.0.0.1 orderer.nitw.edu
127.0.0.1 peer0.nitwarangal.nitw.edu
127.0.0.1 peer1.nitwarangal.nitw.edu
127.0.0.1 peer0.departments.nitw.edu
127.0.0.1 peer1.departments.nitw.edu
127.0.0.1 peer0.verifiers.nitw.edu

# 2. Verify resolution
ping peer0.nitwarangal.nitw.edu
# Should resolve to 127.0.0.1

# 3. Clear DNS cache (if needed)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

---

## Channel Creation Issues

### ❌ Problem: "Channel already exists"

**Symptoms:**
```
Error: got unexpected status: BAD_REQUEST -- error authorizing update: channel already exists
```

**Solutions:**
```bash
# This is usually OK if you're re-running commands
# To verify channel exists:
../bin/peer channel list

# To recreate from scratch:
docker-compose -f docker/docker-compose-net.yaml down -v
rm -rf channel-artifacts/academic-records-channel.block
# Then follow setup guide from Step 6
```

---

### ❌ Problem: "Access denied"

**Symptoms:**
```
Error: got unexpected status: FORBIDDEN -- Failed to reach implicit threshold
```

**Solutions:**
```bash
# Check environment variables are set correctly
echo $CORE_PEER_MSPCONFIGPATH
echo $CORE_PEER_LOCALMSPID

# Should point to Admin MSP, e.g.:
# /Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp
# NITWarangalMSP

# Reset environment (copy from QUICK_REFERENCE.md)
cd ~/hyperledger/fabric-samples/nit-warangal-network
export FABRIC_CFG_PATH=/Users/apple/hyperledger/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
# ... (rest of environment variables)
```

---

### ❌ Problem: Peer won't join channel

**Symptoms:**
```
Error: proposal failed with status: 500
```

**Solutions:**
```bash
# 1. Check if channel exists
ls -la channel-artifacts/academic-records-channel.block

# 2. Verify peer is running
docker ps | grep peer0.nitwarangal

# 3. Check peer logs
docker logs peer0.nitwarangal.nitw.edu

# 4. Verify environment variables
echo $CORE_PEER_ADDRESS
echo $CORE_PEER_TLS_ROOTCERT_FILE

# 5. Re-fetch channel block
../bin/peer channel fetch 0 academic-records-channel.block \
  -o orderer.nitw.edu:7050 \
  -c academic-records-channel \
  --tls --cafile $ORDERER_CA

# 6. Try join again
../bin/peer channel join -b ./channel-artifacts/academic-records-channel.block
```

---

## Chaincode Issues

### ❌ Problem: "Chaincode install failed"

**Symptoms:**
```
Error: chaincode install failed with status: 500
```

**Solutions:**
```bash
# 1. Check Go is installed
go version

# 2. Verify chaincode compiles
cd chaincode-go/academic-records
go mod tidy
go build
cd ../..

# 3. Check package exists
ls -la academic_records_1.2.tar.gz

# 4. Recreate package
rm academic_records_*.tar.gz
../bin/peer lifecycle chaincode package academic_records_1.2.tar.gz \
  --path chaincode-go/academic-records \
  --lang golang \
  --label academic_records_1.2

# 5. Check peer logs
docker logs peer0.nitwarangal.nitw.edu | grep -i chaincode

# 6. Try install again
../bin/peer lifecycle chaincode install academic_records_1.2.tar.gz
```

---

### ❌ Problem: "Package ID not found"

**Symptoms:**
```
Error: query failed with status: 404 - package ID not found
```

**Solutions:**
```bash
# 1. Query installed chaincode
../bin/peer lifecycle chaincode queryinstalled

# 2. Copy the EXACT package ID (including hash)
# Should look like: academic_records_1.2:a37c987afe6085a1ef031ec9affdc0c5ab4a17d3c1b5fa5801a89464275736da

# 3. Export it
export CC_PACKAGE_ID="academic_records_1.2:<YOUR-HASH-HERE>"

# 4. Verify
echo $CC_PACKAGE_ID

# 5. Use in approve command
```

---

### ❌ Problem: "Chaincode not approved by sufficient number of orgs"

**Symptoms:**
```
Error: proposal failed with status: 500 - failed to invoke backing implementation of 'CommitChaincodeDefinition'
```

**Solutions:**
```bash
# 1. Check approval status
../bin/peer lifecycle chaincode checkcommitreadiness \
  --channelID academic-records-channel \
  --name academic-records \
  --version 1.2 \
  --sequence 1 \
  --tls --cafile $ORDERER_CA \
  --output json

# Expected: All 3 orgs should show "Approved": true
# {
#   "approvals": {
#     "NITWarangalMSP": true,
#     "DepartmentsMSP": true,
#     "VerifiersMSP": true
#   }
# }

# 2. If any org shows false, approve for that org
# Set environment for that org (see QUICK_REFERENCE.md)
# Then run:
../bin/peer lifecycle chaincode approveformyorg \
  -o orderer.nitw.edu:7050 \
  --ordererTLSHostnameOverride orderer.nitw.edu \
  --tls --cafile $ORDERER_CA \
  --channelID academic-records-channel \
  --name academic-records \
  --version 1.2 \
  --package-id $CC_PACKAGE_ID \
  --sequence 1

# 3. Check again
../bin/peer lifecycle chaincode checkcommitreadiness ...
```

---

### ❌ Problem: "Chaincode invoke timeout"

**Symptoms:**
```
Error: timeout expired while executing transaction
```

**Solutions:**
```bash
# 1. Check if all endorsing peers are running
docker ps | grep -E "peer0.nitwarangal|peer0.departments"

# 2. Check peer logs for errors
docker logs peer0.nitwarangal.nitw.edu | tail -50

# 3. Verify chaincode container is running
docker ps | grep dev-peer0.nitwarangal

# 4. Increase timeout (add --waitForEvent flag)
../bin/peer chaincode invoke \
  --waitForEvent \
  --waitForEventTimeout 300s \
  # ... rest of command

# 5. Try with just 2 peers
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
  -c '{"function":"CreateStudent","Args":["STU001","John Doe","CSE","2023","CS001","john@nitw.edu"]}'
```

---

### ❌ Problem: "MVCC read conflict"

**Symptoms:**
```
Error: endorsement failure during invoke. response: status:500 message:"MVCC_READ_CONFLICT"
```

**Solutions:**
```bash
# This happens when two transactions try to modify the same key simultaneously

# Solution 1: Just retry after a moment
sleep 2
# Then retry your transaction

# Solution 2: Check for duplicate transactions
# Ensure you're not running the same command multiple times in parallel

# Solution 3: Query the current state first
../bin/peer chaincode query \
  -C academic-records-channel \
  -n academic-records \
  -c '{"function":"GetStudent","Args":["STU001"]}'

# Then retry the transaction
```

---

## API Issues

### ❌ Problem: "Cannot find module 'fabric-network'"

**Symptoms:**
```
Error: Cannot find module 'fabric-network'
```

**Solutions:**
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network/application-typescript

# 1. Clean install
rm -rf node_modules package-lock.json
npm install

# 2. Verify package.json has correct dependencies
cat package.json | grep fabric-network

# 3. Install specific version if needed
npm install fabric-network@2.2.20

# 4. Rebuild
npm run build
```

---

### ❌ Problem: "Wallet not found"

**Symptoms:**
```
Error: Identity not found in wallet: admin
```

**Solutions:**
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network/application-typescript

# 1. Check if wallet exists
ls -la wallet/

# 2. If missing, enroll admin
npx ts-node src/enrollAdmin.ts

# 3. Verify enrollment
ls -la wallet/admin.id

# 4. Check .env points to correct path
cat .env | grep WALLET_PATH
# Should be: WALLET_PATH=./wallet

# 5. Try with absolute path in .env
WALLET_PATH=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/application-typescript/wallet
```

---

### ❌ Problem: "Connection profile not found"

**Symptoms:**
```
Error: Failed to connect to gateway: ENOENT: no such file or directory
```

**Solutions:**
```bash
cd ~/hyperledger/fabric-samples/nit-warangal-network/application-typescript

# 1. Check connection profile exists
ls -la ../organizations/peerOrganizations/nitwarangal.nitw.edu/connection-nitwarangal.json

# 2. Verify .env has correct path
cat .env | grep CONNECTION_PROFILE_PATH

# 3. Use absolute path
CONNECTION_PROFILE_PATH=/Users/apple/hyperledger/fabric-samples/nit-warangal-network/organizations/peerOrganizations/nitwarangal.nitw.edu/connection-nitwarangal.json

# 4. Verify connection profile has absolute paths for certs
cat ../organizations/peerOrganizations/nitwarangal.nitw.edu/connection-nitwarangal.json | grep path
```

---

### ❌ Problem: API returns "Gateway connection failed"

**Symptoms:**
```
Error: Gateway connection failed: 14 UNAVAILABLE: failed to connect to all addresses
```

**Solutions:**
```bash
# 1. Check if peers are running
docker ps | grep peer0.nitwarangal

# 2. Check peer endpoint in .env
cat .env | grep PEER_ENDPOINT
# Should be: PEER_ENDPOINT=peer0.nitwarangal.nitw.edu:7051

# 3. Test connectivity
telnet peer0.nitwarangal.nitw.edu 7051

# 4. Check /etc/hosts
cat /etc/hosts | grep peer0.nitwarangal.nitw.edu

# 5. Verify TLS certificates in connection profile
cat ../organizations/peerOrganizations/nitwarangal.nitw.edu/connection-nitwarangal.json

# 6. Check peer logs
docker logs peer0.nitwarangal.nitw.edu

# 7. Restart API server
pkill -f "npm run dev"
nohup npm run dev > api-server.log 2>&1 &
```

---

### ❌ Problem: "IPFS module export error"

**Symptoms:**
```
Error: Named export 'create' not found
```

**Solutions:**
```bash
# This is a known issue with ipfs-http-client module

# Solution: IPFS functionality is already commented out in server.ts
# Verify:
cat src/server.ts | grep -A5 "IPFS"

# Should see:
# // IPFS temporarily disabled
# // const ipfs = create({...})

# If not commented:
nano src/server.ts
# Comment out IPFS-related code

# Restart API
pkill -f "npm run dev"
nohup npm run dev > api-server.log 2>&1 &
```

---

## Certificate/TLS Issues

### ❌ Problem: "TLS handshake failed"

**Symptoms:**
```
Error: failed to create new connection: context deadline exceeded
```

**Solutions:**
```bash
# 1. Verify certificates exist
ls -la organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/

# Should have:
# - ca.crt
# - server.crt
# - server.key

# 2. Check certificate validity
openssl x509 -in organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/server.crt -dates -noout

# 3. Regenerate crypto materials if expired
rm -rf organizations/
../bin/cryptogen generate --config=./crypto-config.yaml --output="organizations"

# 4. Restart network
docker-compose -f docker/docker-compose-net.yaml down
docker-compose -f docker/docker-compose-net.yaml up -d

# 5. Recreate channel and redeploy chaincode (see COMPLETE_SETUP_GUIDE.md)
```

---

### ❌ Problem: "Certificate signed by unknown authority"

**Symptoms:**
```
Error: x509: certificate signed by unknown authority
```

**Solutions:**
```bash
# 1. Check CA certificate
ls -la organizations/peerOrganizations/nitwarangal.nitw.edu/ca/

# 2. Verify environment variable
echo $CORE_PEER_TLS_ROOTCERT_FILE

# 3. Should point to correct CA cert
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt

# 4. For orderer CA
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/nitw.edu/orderers/orderer.nitw.edu/msp/tlscacerts/tlsca.nitw.edu-cert.pem

# 5. Verify file exists
ls -la $CORE_PEER_TLS_ROOTCERT_FILE
ls -la $ORDERER_CA
```

---

## Performance Issues

### ❌ Problem: Slow transaction processing

**Symptoms:**
- Transactions take >5 seconds
- API responses are slow

**Solutions:**
```bash
# 1. Check system resources
docker stats

# 2. Allocate more resources to Docker
# Docker Desktop → Preferences → Resources
# Increase CPUs to 4, Memory to 8GB

# 3. Check peer database size
docker exec peer0.nitwarangal.nitw.edu du -sh /var/hyperledger/production

# 4. Enable caching in chaincode (already implemented in v1.2)

# 5. Use query for read operations instead of invoke
# Query: Fast, read-only
../bin/peer chaincode query -C academic-records-channel -n academic-records -c '{...}'

# Invoke: Slower, writes to ledger
../bin/peer chaincode invoke -o orderer... -C academic-records-channel -n academic-records -c '{...}'
```

---

### ❌ Problem: High memory usage

**Symptoms:**
```
docker stats shows containers using >500MB each
```

**Solutions:**
```bash
# 1. Restart containers
docker-compose -f docker/docker-compose-net.yaml restart

# 2. Clean old chaincode containers
docker ps -a | grep dev-peer
docker rm $(docker ps -a | grep dev-peer | awk '{print $1}')

# 3. Prune system
docker system prune

# 4. Check for memory leaks in API
tail -100 application-typescript/api-server.log

# 5. Restart API
pkill -f "npm run dev"
nohup npm run dev > api-server.log 2>&1 &
```

---

## General Debugging

### 🔍 Comprehensive Debug Commands

```bash
# 1. Check all container status
docker ps -a

# 2. Check specific container logs (last 100 lines)
docker logs --tail 100 orderer.nitw.edu
docker logs --tail 100 peer0.nitwarangal.nitw.edu
docker logs --tail 100 peer0.departments.nitw.edu

# 3. Follow logs in real-time
docker logs -f orderer.nitw.edu

# 4. Check peer chaincode logs
docker logs $(docker ps -q --filter name=dev-peer0.nitwarangal)

# 5. Test network connectivity
ping peer0.nitwarangal.nitw.edu
telnet peer0.nitwarangal.nitw.edu 7051
nc -zv peer0.nitwarangal.nitw.edu 7051

# 6. Check environment variables
env | grep CORE_PEER

# 7. Verify channel membership
../bin/peer channel list
../bin/peer channel getinfo -c academic-records-channel

# 8. Check chaincode status
../bin/peer lifecycle chaincode queryinstalled
../bin/peer lifecycle chaincode querycommitted -C academic-records-channel

# 9. Test chaincode query (read-only, fast)
../bin/peer chaincode query \
  -C academic-records-channel \
  -n academic-records \
  -c '{"function":"GetAllStudents","Args":[]}'

# 10. Check API logs
tail -100 ~/hyperledger/fabric-samples/nit-warangal-network/application-typescript/api-server.log

# 11. Test API health
curl http://localhost:3000/health

# 12. Check disk space
df -h

# 13. Check Docker disk usage
docker system df
```

---

### 🔄 Complete Reset (Nuclear Option)

**When nothing else works:**

```bash
# Navigate to project
cd ~/hyperledger/fabric-samples/nit-warangal-network

# 1. Stop API
pkill -f "npm run dev"

# 2. Stop and remove all containers and volumes
docker-compose -f docker/docker-compose-net.yaml down -v

# 3. Remove all generated artifacts
rm -rf organizations/
rm -rf channel-artifacts/*
rm -rf application-typescript/wallet/
rm -rf application-typescript/node_modules/
rm -f academic_records_*.tar.gz

# 4. Clean Docker completely
docker system prune -a --volumes
# Type 'y' to confirm

# 5. Verify clean state
docker ps -a
# Should show no containers

ls organizations/
# Should show "No such file or directory"

# 6. Start fresh from Step 2 of COMPLETE_SETUP_GUIDE.md
../bin/cryptogen generate --config=./crypto-config.yaml --output="organizations"

# Continue with full setup...
```

---

## 📊 Health Check Script

Create a health check script to diagnose issues:

```bash
#!/bin/bash
# Save as: check-health.sh

echo "=== NIT Warangal Blockchain Health Check ==="
echo ""

echo "1. Docker Status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "orderer|peer"
echo ""

echo "2. Network Connectivity:"
ping -c 1 peer0.nitwarangal.nitw.edu >/dev/null 2>&1 && echo "✅ DNS resolution OK" || echo "❌ DNS resolution FAILED"
echo ""

echo "3. Channel Status:"
export FABRIC_CFG_PATH=/Users/apple/hyperledger/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="NITWarangalMSP"
export CORE_PEER_ADDRESS=peer0.nitwarangal.nitw.edu:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/peers/peer0.nitwarangal.nitw.edu/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nitwarangal.nitw.edu/users/Admin@nitwarangal.nitw.edu/msp

../bin/peer channel list 2>/dev/null | grep academic-records-channel >/dev/null && echo "✅ Channel joined" || echo "❌ Channel NOT joined"
echo ""

echo "4. Chaincode Status:"
../bin/peer lifecycle chaincode querycommitted -C academic-records-channel -n academic-records 2>/dev/null | grep "Version:" >/dev/null && echo "✅ Chaincode committed" || echo "❌ Chaincode NOT committed"
echo ""

echo "5. API Status:"
curl -s http://localhost:3000/health >/dev/null 2>&1 && echo "✅ API running" || echo "❌ API NOT running"
echo ""

echo "6. Disk Space:"
df -h / | tail -1 | awk '{print $5 " used"}'
echo ""

echo "=== End Health Check ==="
```

**Usage:**
```bash
chmod +x check-health.sh
./check-health.sh
```

---

## 📞 Getting Additional Help

If you're still stuck after trying these solutions:

1. **Collect Logs:**
   ```bash
   # Save all logs
   docker logs orderer.nitw.edu > orderer.log 2>&1
   docker logs peer0.nitwarangal.nitw.edu > peer0-nitwarangal.log 2>&1
   docker logs peer0.departments.nitw.edu > peer0-departments.log 2>&1
   cp application-typescript/api-server.log ./api.log
   ```

2. **Check Documentation:**
   - Hyperledger Fabric Docs: https://hyperledger-fabric.readthedocs.io/
   - Fabric Samples: https://github.com/hyperledger/fabric-samples

3. **Community Support:**
   - Hyperledger Discord: https://discord.gg/hyperledger
   - Stack Overflow: Tag `hyperledger-fabric`

4. **Review Project Docs:**
   - COMPLETE_SETUP_GUIDE.md
   - QUICK_REFERENCE.md
   - IMPLEMENTATION_SUCCESS_SUMMARY.md

---

**Remember:** Most issues can be resolved by:
1. Checking logs
2. Verifying environment variables
3. Ensuring all services are running
4. Using absolute paths
5. Restarting containers/API

**Version:** 1.2.0  
**Last Updated:** October 21, 2025

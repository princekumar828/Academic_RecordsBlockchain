# ✅ Orderer Configuration Update

## Changes Made - Single Orderer Configuration

**Date:** October 21, 2025  
**Status:** ✅ Complete

---

## 🔄 What Changed

Updated the network configuration from **3 orderers (1 active)** to **1 orderer** for consistency and clarity.

### Files Modified

1. ✅ **configtx.yaml** (root)
   - Removed orderer2 and orderer3 from OrdererEndpoints
   - Removed from Addresses list
   - Now only: orderer.nitw.edu:7050

2. ✅ **configtx/configtx.yaml**
   - Same changes as root configtx.yaml

3. ✅ **docker/docker-compose-net.yaml**
   - Removed orderer2.nitw.edu service
   - Removed orderer3.nitw.edu service
   - Removed orderer2 and orderer3 volumes
   - Now only: 1 orderer + 5 peers + 1 cli = 7 containers

4. ✅ **crypto-config.yaml**
   - Removed orderer2 and orderer3 from Specs
   - Now only generates certificates for: orderer.nitw.edu

---

## 📊 Before vs After

### Before
```yaml
OrdererEndpoints:
  - orderer.nitw.edu:7050
  - orderer2.nitw.edu:7052
  - orderer3.nitw.edu:7054

Addresses:
  - orderer.nitw.edu:7050
  - orderer2.nitw.edu:7052
  - orderer3.nitw.edu:7054

Docker Containers: 9 (3 orderers + 5 peers + 1 cli)
Crypto Specs: 3 orderers
```

### After
```yaml
OrdererEndpoints:
  - orderer.nitw.edu:7050

Addresses:
  - orderer.nitw.edu:7050

Docker Containers: 7 (1 orderer + 5 peers + 1 cli)
Crypto Specs: 1 orderer
```

---

## 🎯 Final Configuration

### Orderer
- **Count:** 1
- **Hostname:** orderer.nitw.edu
- **Port:** 7050
- **Admin Port:** 7053
- **Operations:** 9443
- **Consensus:** Raft (single node)

### Peers
- **NITWarangalMSP:** 2 peers (7051, 8051)
- **DepartmentsMSP:** 2 peers (9051, 10051)
- **VerifiersMSP:** 1 peer (11051)
- **Total:** 5 peers

### Channels
- **academic-records-channel**
  - All 3 organizations
  - All 5 peers
  - 1 orderer

---

## 🔐 /etc/hosts Update

Update your `/etc/hosts` file to only include:

```
127.0.0.1 orderer.nitw.edu
127.0.0.1 peer0.nitwarangal.nitw.edu
127.0.0.1 peer1.nitwarangal.nitw.edu
127.0.0.1 peer0.departments.nitw.edu
127.0.0.1 peer1.departments.nitw.edu
127.0.0.1 peer0.verifiers.nitw.edu
```

**Remove these lines (no longer needed):**
```
127.0.0.1 orderer2.nitw.edu
127.0.0.1 orderer3.nitw.edu
```

---

## ✅ Benefits of Single Orderer

1. **Simplicity** - Easier to understand and debug
2. **Consistency** - Configuration matches actual deployment
3. **Resource Efficient** - Lower CPU/memory usage
4. **Clean Documentation** - No confusion about active orderers
5. **Development Ready** - Perfect for dev/test environments

---

## 🚀 Next Steps

### To Apply These Changes:

1. **Clean old crypto materials:**
   ```bash
   rm -rf organizations/
   ```

2. **Regenerate certificates (only 1 orderer):**
   ```bash
   ../bin/cryptogen generate --config=./crypto-config.yaml --output="organizations"
   ```

3. **Regenerate genesis block:**
   ```bash
   export FABRIC_CFG_PATH=${PWD}/configtx
   ../bin/configtxgen -profile ThreeOrgsOrdererGenesis \
     -channelID system-channel \
     -outputBlock ./system-genesis-block/genesis.block
   ```

4. **Start network:**
   ```bash
   docker-compose -f docker/docker-compose-net.yaml up -d
   ```

5. **Verify only 7 containers:**
   ```bash
   docker ps
   # Should show: 1 orderer + 5 peers + 1 cli = 7 containers
   ```

---

## 📝 Documentation Updates Needed

The following docs should be updated to reflect 1 orderer:

- [ ] COMPLETE_SETUP_GUIDE.md - Update /etc/hosts section
- [ ] NEW_DEVICE_SETUP_CHECKLIST.md - Update /etc/hosts section
- [ ] TROUBLESHOOTING.md - Update references
- [ ] README.md - Update architecture diagram
- [ ] QUICK_REFERENCE.md - Update network info

---

## 🎉 Result

**Clean, consistent single-orderer configuration ready for GitHub!**

- ✅ 1 Orderer (orderer.nitw.edu:7050)
- ✅ 5 Peers across 3 organizations
- ✅ 1 Channel (academic-records-channel)
- ✅ Raft consensus (single node)
- ✅ All configuration files aligned

---

**Status:** ✅ **Ready for Production Deployment**

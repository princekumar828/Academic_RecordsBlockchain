# 📊 Network Configuration Summary

> ⚠️ **OUTDATED DOCUMENT - HISTORICAL REFERENCE ONLY**  
> This document shows the network configuration **before** optimization.  
> The network has been updated to use **only 1 orderer**.  
> For current configuration, see **[ORDERER_CONFIG_UPDATE.md](ORDERER_CONFIG_UPDATE.md)**

## Previous Network Configuration Analysis (Pre-Optimization)

**Date:** October 21, 2025 (Before Changes)  
**Status:** ⚠️ This configuration has been superseded

---

## 🔢 Orderer Configuration

### Number of Orderers: **3 Orderers**

| Orderer | Hostname | Port | Admin Port | Operations Port | Status |
|---------|----------|------|------------|-----------------|--------|
| Orderer 1 | orderer.nitw.edu | 7050 | 7053 | 9443 | Configured |
| Orderer 2 | orderer2.nitw.edu | 7052 | 7055 | 9444 | Configured |
| Orderer 3 | orderer3.nitw.edu | 7054 | 7057 | 9445 | Configured |

### Consensus Configuration
- **Type:** etcdraft (Raft consensus)
- **Active Consenters:** 1 (orderer.nitw.edu)
- **Configured Consenters:** 3 (orderer.nitw.edu, orderer2.nitw.edu, orderer3.nitw.edu)

⚠️ **Note:** Currently only **orderer.nitw.edu** is configured in the EtcdRaft consenters section in both configtx.yaml files. For full Raft cluster operation, all 3 orderers should be added as consenters.

---

## 📡 Channel Configuration

### Number of Channels: **1 Channel**

| Channel Name | Profile | Status | Organizations |
|--------------|---------|--------|---------------|
| academic-records-channel | ThreeOrgsChannel / AcademicRecordsChannel | Configured | 3 (NITWarangal, Departments, Verifiers) |

### Channel Details

**Channel Name:** `academic-records-channel`

**Member Organizations:**
1. **NITWarangalMSP** (2 peers)
   - peer0.nitwarangal.nitw.edu:7051
   - peer1.nitwarangal.nitw.edu:8051

2. **DepartmentsMSP** (2 peers)
   - peer0.departments.nitw.edu:9051
   - peer1.departments.nitw.edu:10051

3. **VerifiersMSP** (1 peer)
   - peer0.verifiers.nitw.edu:11051

**Total Peers:** 5 peers across 3 organizations

---

## 📋 Configuration Files Summary

### 1. Root configtx.yaml
**Location:** `./configtx.yaml`  
**Path Style:** Relative paths (`./organizations/`)  
**Usage:** Runtime channel creation

**Orderer Addresses:**
```yaml
Addresses:
  - orderer.nitw.edu:7050
  - orderer2.nitw.edu:7052
  - orderer3.nitw.edu:7054
```

**EtcdRaft Consenters:**
```yaml
Consenters:
  - Host: orderer.nitw.edu
    Port: 7050
```
⚠️ **Issue:** Only 1 consenter configured (should be 3 for full Raft)

### 2. configtx/configtx.yaml
**Location:** `./configtx/configtx.yaml`  
**Path Style:** Relative paths (`../organizations/`)  
**Usage:** Genesis block generation

**Same configuration as root configtx.yaml**

### 3. Docker Compose
**Location:** `./docker/docker-compose-net.yaml`

**Services Defined:**
- 3 Orderers (orderer, orderer2, orderer3)
- 5 Peers (2 NITWarangal, 2 Departments, 1 Verifiers)
- 1 CLI container

**Total Containers:** 9 (3 orderers + 5 peers + 1 cli)

---

## 📊 Network Topology

```
┌──────────────────────────────────────────────────────────────┐
│                  NIT Warangal Blockchain Network              │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌─────────────── ORDERER LAYER ──────────────────┐          │
│  │                                                  │          │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  │ Orderer 1    │  │ Orderer 2    │  │ Orderer 3    │    │
│  │  │ :7050        │  │ :7052        │  │ :7054        │    │
│  │  │ (ACTIVE)     │  │ (CONFIGURED) │  │ (CONFIGURED) │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘    │
│  │                                                  │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                │
│  ┌──────────────── PEER LAYER ──────────────────────┐        │
│  │                                                    │        │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  │ NITWarangal  │  │ Departments  │  │  Verifiers   │    │
│  │  ├──────────────┤  ├──────────────┤  ├──────────────┤    │
│  │  │ Peer0: 7051  │  │ Peer0: 9051  │  │ Peer0: 11051 │    │
│  │  │ Peer1: 8051  │  │ Peer1: 10051 │  │              │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘    │
│  │                                                    │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                │
│  ┌─────────────── CHANNEL ────────────────────────┐          │
│  │                                                  │          │
│  │  Channel: academic-records-channel              │          │
│  │  Members: All 3 Organizations (5 peers)         │          │
│  │                                                  │          │
│  └──────────────────────────────────────────────────┘          │
└──────────────────────────────────────────────────────────────┘
```

---

## ⚠️ Configuration Issues Found

### Issue 1: Incomplete Raft Configuration
**Problem:** Only 1 orderer is configured as a consenter in EtcdRaft, but 3 orderers are defined.

**Current Config:**
```yaml
EtcdRaft:
  Consenters:
    - Host: orderer.nitw.edu
      Port: 7050
      ClientTLSCert: ./organizations/...
      ServerTLSCert: ./organizations/...
```

**Should Be:**
```yaml
EtcdRaft:
  Consenters:
    - Host: orderer.nitw.edu
      Port: 7050
      ClientTLSCert: ...
      ServerTLSCert: ...
    - Host: orderer2.nitw.edu
      Port: 7052
      ClientTLSCert: ...
      ServerTLSCert: ...
    - Host: orderer3.nitw.edu
      Port: 7054
      ClientTLSCert: ...
      ServerTLSCert: ...
```

**Impact:** 
- Only orderer.nitw.edu participates in consensus
- No fault tolerance (single point of failure)
- Other 2 orderers are running but not participating

**Recommendation:** 
- Keep current single-orderer config (simpler, working)
- OR add all 3 orderers to consenters for fault tolerance

---

## 📈 Current vs Potential Configuration

### Current Configuration (Working)
✅ **Orderers:** 3 defined, 1 active  
✅ **Channels:** 1 channel  
✅ **Organizations:** 3 organizations  
✅ **Peers:** 5 peers  
✅ **Consensus:** Raft with 1 consenter  

### Potential Full Raft Configuration
🔄 **Orderers:** 3 defined, 3 active  
✅ **Channels:** 1 channel  
✅ **Organizations:** 3 organizations  
✅ **Peers:** 5 peers  
🔄 **Consensus:** Raft with 3 consenters  
✅ **Fault Tolerance:** Can survive 1 orderer failure  

---

## 🎯 Recommendations

### Option 1: Keep Current (Recommended for Development)
**Pros:**
- Simple, working configuration
- Easier to debug
- Lower resource usage
- Already tested and documented

**Cons:**
- No orderer fault tolerance
- Single point of failure

**Action:** None - already documented in guides

### Option 2: Enable Full Raft Cluster
**Pros:**
- Full fault tolerance
- Production-grade setup
- Can survive 1 orderer failure

**Cons:**
- More complex
- Requires reconfiguration
- Need to update all documentation
- Higher resource usage

**Action Required:**
1. Update both configtx.yaml files to include all 3 consenters
2. Regenerate genesis block
3. Recreate channel
4. Rejoin all peers
5. Redeploy chaincode
6. Update all documentation

---

## 📝 Summary

**Current Network:**
- ✅ **3 Orderers** (1 active in consensus, 2 configured but not participating)
- ✅ **1 Channel** (academic-records-channel)
- ✅ **3 Organizations** (NITWarangal, Departments, Verifiers)
- ✅ **5 Peers** (2+2+1 distribution)
- ✅ **Raft Consensus** (single-orderer mode)

**Status:** ✅ **Working and Documented**

**GitHub Ready:** ✅ **Yes** - Current configuration is clean and well-documented

---

## 💡 For GitHub Repository

When uploading to GitHub, mention in README:

```markdown
### Network Configuration
- **Orderers:** 3 (Raft consensus with single active orderer)
- **Channels:** 1 (academic-records-channel)
- **Organizations:** 3 (NITWarangal, Departments, Verifiers)
- **Peers:** 5 (2+2+1 distribution)
- **Consensus:** Raft (simplified single-orderer for development)
```

**Note:** The network is configured with 3 orderers but currently runs with a single active orderer for simplicity. This can be easily extended to full 3-orderer Raft consensus for production deployment.

---

**Analysis Date:** October 21, 2025  
**Configuration Version:** 1.2.0  
**Status:** ✅ Production-Ready (Single Orderer Mode)

# 🎓 NIT Warangal Academic Records - Blockchain System

[![Hyperledger Fabric](https://img.shields.io/badge/Hyperledger%20Fabric-2.5-blue)](https://www.hyperledger.org/use/fabric)
[![Go](https://img.shields.io/badge/Go-1.21-00ADD8?logo=go)](https://go.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.2-3178C6?logo=typescript)](https://www.typescriptlang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-16+-339933?logo=node.js)](https://nodejs.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

## 📖 Overview

A production-ready blockchain-based academic records management system built on **Hyperledger Fabric 2.5** for NIT Warangal. This system provides secure, transparent, and tamper-proof management of student records, academic transcripts, and credentials with automatic SGPA/CGPA calculation.

### 🌟 Key Features

- ✅ **Multi-Organization Network** - 3 organizations with 5 peers
- ✅ **Student Management** - Complete student lifecycle tracking
- ✅ **Academic Records** - Semester-wise grade management
- ✅ **Auto-Calculated Grades** - SGPA/CGPA automatically computed
- ✅ **Certificate Management** - Issuance and verification
- ✅ **REST API** - TypeScript-based API with 13 endpoints
- ✅ **Secure & Tamper-Proof** - Blockchain-backed immutability
- ✅ **TLS Encryption** - End-to-end encrypted communication

---

## 🏗️ Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                    NIT Warangal Blockchain                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐│
│  │ NITWarangal    │  │  Departments   │  │   Verifiers    ││
│  │ Organization   │  │  Organization  │  │  Organization  ││
│  ├────────────────┤  ├────────────────┤  ├────────────────┤│
│  │ • Peer0 (7051) │  │ • Peer0 (9051) │  │ • Peer0 (11051)││
│  │ • Peer1 (8051) │  │ • Peer1 (10051)│  │                ││
│  └────────────────┘  └────────────────┘  └────────────────┘│
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │    Orderer Service (Single-Node Raft Consensus)       │  │
│  │         • orderer.nitw.edu:7050 (Port 7050)           │  │
│  │         • Admin: 7053 | Operations: 9443              │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │      Channel: academic-records-channel                │  │
│  │      Smart Contract: academic-records v1.2            │  │
│  │      Total Containers: 7 (1 orderer + 5 peers + cli)  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Blockchain Platform | Hyperledger Fabric | 2.5 |
| Smart Contract | Go | 1.21 |
| REST API | TypeScript/Node.js | 16+ |
| API Framework | Express.js | 4.18.2 |
| State Database | LevelDB | - |
| Containerization | Docker/Docker Compose | Latest |
| Consensus | Raft | - |

---

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 16+
- Go 1.21+
- Hyperledger Fabric 2.5 binaries

### Installation

1. **Clone the repository**
```bash
cd ~/hyperledger/fabric-samples/
# Copy or clone the nit-warangal-network directory here
```

2. **Follow the setup guide**
```bash
cd nit-warangal-network
```

📚 **Read the complete setup guide:** [NEW_DEVICE_SETUP_CHECKLIST.md](NEW_DEVICE_SETUP_CHECKLIST.md)

---

## 📚 Documentation

We provide comprehensive documentation for all aspects of the project:

| Document | Description | Best For |
|----------|-------------|----------|
| **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** | 📑 Master index to all docs | Finding the right guide |
| **[NEW_DEVICE_SETUP_CHECKLIST.md](NEW_DEVICE_SETUP_CHECKLIST.md)** | ✅ Step-by-step setup checklist | First-time setup |
| **[COMPLETE_SETUP_GUIDE.md](COMPLETE_SETUP_GUIDE.md)** | 📗 Full command reference | Detailed setup |
| **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** | ⚡ Daily operations guide | Quick commands |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | 🔧 Problem solving guide | When issues arise |
| **[IMPLEMENTATION_SUCCESS_SUMMARY.md](IMPLEMENTATION_SUCCESS_SUMMARY.md)** | 📊 Project overview | Understanding the system |
| **[ORDERER_CONFIG_UPDATE.md](ORDERER_CONFIG_UPDATE.md)** | ✅ Single orderer config changes | What changed and why |
| **[NEXT_STEPS.md](NEXT_STEPS.md)** | 🎯 Future enhancements | Planning improvements |

**Start Here:** [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) for complete navigation

---

## 💻 Smart Contract Functions

The chaincode provides 15+ functions for comprehensive academic record management:

### Student Management
- `CreateStudent` - Register new student
- `GetStudent` - Retrieve student details
- `GetAllStudents` - List all students
- `UpdateStudent` - Modify student information
- `UpdateStudentStatus` - Change student status

### Academic Records
- `CreateAcademicRecord` - Create semester record
- `GetAcademicRecord` - Retrieve record
- `GetStudentRecords` - Get all records for a student
- `ApproveAcademicRecord` - Approve record (Departments)
- `VerifyAcademicRecord` - Final verification (NIT Admin)

### Certificates
- `IssueCertificate` - Issue graduation certificate
- `GetCertificate` - Retrieve certificate
- `VerifyCertificate` - Verify authenticity
- `GetStudentCertificates` - List student certificates

### Queries
- `QueryStudentsByDepartment` - Filter by department
- `QueryStudentsByStatus` - Filter by status
- `GetAllCertificates` - List all certificates

---

## 🌐 REST API

The TypeScript-based REST API provides 13 endpoints:

### Available Endpoints

```
GET  /health                          - API health check
GET  /api/students                    - Get all students
GET  /api/students/:id                - Get specific student
POST /api/students                    - Create new student
PUT  /api/students/:id                - Update student
POST /api/records                     - Create academic record
GET  /api/records/:id                 - Get specific record
GET  /api/records/student/:studentId  - Get student's records
PUT  /api/records/:id/approve         - Approve record
PUT  /api/records/:id/verify          - Verify record
POST /api/certificates                - Issue certificate
GET  /api/certificates/:id            - Get certificate
POST /api/certificates/verify         - Verify certificate
```

**API Server:** Runs on `http://localhost:3000`

---

## 🧪 Testing

### Test via CLI
```bash
# Set environment
cd ~/hyperledger/fabric-samples/nit-warangal-network
# (See QUICK_REFERENCE.md for environment setup)

# Create student
../bin/peer chaincode invoke ... -c '{"function":"CreateStudent","Args":[...]}'

# Query student
../bin/peer chaincode query ... -c '{"function":"GetStudent","Args":["STU001"]}'
```

### Test via REST API
```bash
# Health check
curl http://localhost:3000/health

# Get all students
curl http://localhost:3000/api/students

# Create student
curl -X POST http://localhost:3000/api/students \
  -H "Content-Type: application/json" \
  -d '{"studentId":"STU001","name":"John Doe",...}'
```

See **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** for more examples.

---

## 📁 Project Structure

```
nit-warangal-network/
├── 📄 Documentation
│   ├── README.md                           ← You are here
│   ├── DOCUMENTATION_INDEX.md              Complete guide index
│   ├── NEW_DEVICE_SETUP_CHECKLIST.md       Setup checklist
│   ├── COMPLETE_SETUP_GUIDE.md             Full setup guide
│   ├── QUICK_REFERENCE.md                  Quick commands
│   ├── TROUBLESHOOTING.md                  Problem solving
│   ├── IMPLEMENTATION_SUCCESS_SUMMARY.md   Project summary
│   └── NEXT_STEPS.md                       Future work
│
├── 🔐 Network Configuration
│   ├── crypto-config.yaml                  Certificate config
│   ├── configtx.yaml                       Channel config
│   ├── configtx/configtx.yaml             Channel genesis
│   └── docker/docker-compose-net.yaml      Container setup
│
├── 📦 Smart Contract
│   └── chaincode-go/academic-records/
│       ├── chaincode.go                    Main contract (v1.2)
│       └── go.mod                          Dependencies
│
├── 🌐 REST API
│   └── application-typescript/
│       ├── src/
│       │   ├── server.ts                   API server
│       │   └── enrollAdmin.ts              Admin enrollment
│       ├── package.json                    Dependencies
│       └── .env.example                    Config template
│
└── 🛠️ Scripts
    ├── network.sh                          Network control
    ├── deploy-chaincode.sh                 Chaincode deployment
    ├── upgrade-chaincode.sh                Chaincode upgrade
    └── test-chaincode.sh                   Testing script
```

---

## 🔐 Security Features

- ✅ **TLS Encryption** - All peer-to-peer communication encrypted
- ✅ **MSP-Based Authentication** - Organization-level access control
- ✅ **Endorsement Policies** - Multi-signature transaction validation
- ✅ **Private Data Collections** - Sensitive data isolation (planned)
- ✅ **Immutable Audit Trail** - Complete transaction history

---

## 🎯 Use Cases

1. **Student Registration** - Secure onboarding of new students
2. **Grade Management** - Transparent semester-wise record keeping
3. **Transcript Generation** - Automated SGPA/CGPA calculation
4. **Certificate Issuance** - Tamper-proof degree certificates
5. **Certificate Verification** - Instant verification by employers/universities
6. **Audit Trail** - Complete history of all academic records

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Hyperledger Fabric** - For the excellent blockchain framework
- **NIT Warangal** - For the use case and requirements
- **Hyperledger Community** - For documentation and support

---

## 📞 Support

For issues and questions:

- 📖 Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 📚 Read [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
- 💬 Open an issue on GitHub
- 🌐 Visit [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)

---

## ⚡ Quick Commands

### Start Network
```bash
docker-compose -f docker/docker-compose-net.yaml up -d
```

### Start API
```bash
cd application-typescript
npm run dev
```

### Check Status
```bash
docker ps
curl http://localhost:3000/health
```

### Stop Network
```bash
docker-compose -f docker/docker-compose-net.yaml down
```

For complete commands, see **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)**

---

## 📊 System Status

- ✅ **Network:** Operational
- ✅ **Chaincode:** v1.2 (Sequence 3)
- ✅ **API:** v1.0
- ✅ **Tests:** All passing
- ✅ **Documentation:** Complete

**Version:** 1.2.0  
**Last Updated:** October 21, 2025  
**Status:** 🟢 Production Ready

---

<div align="center">

**Built with ❤️ using Hyperledger Fabric**

[Documentation](DOCUMENTATION_INDEX.md) • [Setup Guide](NEW_DEVICE_SETUP_CHECKLIST.md) • [Quick Reference](QUICK_REFERENCE.md) • [Troubleshooting](TROUBLESHOOTING.md)

</div>

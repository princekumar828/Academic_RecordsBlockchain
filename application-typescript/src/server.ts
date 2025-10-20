import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import multer from 'multer';
import { Gateway, Wallets, Contract, Network } from 'fabric-network';
import * as path from 'path';
import * as fs from 'fs';
// import { create } from 'ipfs-http-client';
// const IpfsHttpClient = require('ipfs-http-client');
// IPFS temporarily disabled - can be enabled later when IPFS daemon is running

const app: Application = express();
const upload = multer({ storage: multer.memoryStorage() });

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// IPFS client configuration (disabled for now)
// const ipfsClient = IpfsHttpClient.create({ 
//   host: process.env.IPFS_HOST || 'localhost', 
//   port: parseInt(process.env.IPFS_PORT || '5001'), 
//   protocol: process.env.IPFS_PROTOCOL || 'http' 
// });
const ipfsClient: any = null; // Placeholder - IPFS can be enabled later

// Fabric network connection helper
async function connectToNetwork(userId: string = 'admin', orgName: string = 'NITWarangal'): Promise<{ gateway: Gateway; contract: Contract }> {
  try {
    const ccpPath = path.resolve(__dirname, '..', '..', 'organizations', 
      'peerOrganizations', `${orgName.toLowerCase()}.nitw.edu`, `connection-${orgName.toLowerCase()}.json`);
    
    let ccp;
    if (fs.existsSync(ccpPath)) {
      const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
      ccp = JSON.parse(ccpJSON);
    } else {
      throw new Error(`Connection profile not found at ${ccpPath}`);
    }

    const walletPath = path.join(process.cwd(), 'wallet');
    const wallet = await Wallets.newFileSystemWallet(walletPath);

    // Check if user exists in wallet
    const identity = await wallet.get(userId);
    if (!identity) {
      console.log(`Identity for user ${userId} not found in wallet. Using default admin identity.`);
    }

    const gateway = new Gateway();
    await gateway.connect(ccp, {
      wallet,
      identity: userId,
      discovery: { enabled: true, asLocalhost: true }
    });

    const network: Network = await gateway.getNetwork('academic-records-channel');
    const contract: Contract = network.getContract('academic-records');

    return { gateway, contract };
  } catch (error) {
    console.error(`Failed to connect to network: ${error}`);
    throw error;
  }
}

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', message: 'NIT Warangal Academic Records API is running' });
});

// ==================== STUDENT ENDPOINTS ====================

// Create student
app.post('/api/students', async (req: Request, res: Response) => {
  try {
    const { studentId, name, department, enrollmentYear, rollNumber, email } = req.body;
    
    if (!studentId || !name || !department || !enrollmentYear || !rollNumber || !email) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }

    const { gateway, contract } = await connectToNetwork('admin', 'NITWarangal');

    await contract.submitTransaction(
      'CreateStudent',
      studentId,
      name,
      department,
      enrollmentYear.toString(),
      rollNumber,
      email
    );

    gateway.disconnect();
    res.status(201).json({ 
      success: true, 
      message: 'Student created successfully',
      data: { studentId, name, department }
    });
  } catch (error: any) {
    console.error('Error creating student:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get student by ID
app.get('/api/students/:studentId', async (req: Request, res: Response) => {
  try {
    const { studentId } = req.params;
    const { gateway, contract } = await connectToNetwork('admin');

    const result = await contract.evaluateTransaction('GetStudent', studentId);
    gateway.disconnect();

    const student = JSON.parse(result.toString());
    res.json({ success: true, data: student });
  } catch (error: any) {
    console.error('Error getting student:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get all students
app.get('/api/students', async (req: Request, res: Response) => {
  try {
    const { gateway, contract } = await connectToNetwork('admin');

    const result = await contract.evaluateTransaction('GetAllStudents');
    gateway.disconnect();

    const students = JSON.parse(result.toString());
    res.json({ success: true, data: students, count: students.length });
  } catch (error: any) {
    console.error('Error getting students:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Update student status
app.put('/api/students/:studentId/status', async (req: Request, res: Response) => {
  try {
    const { studentId } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({ success: false, error: 'Status is required' });
    }

    const { gateway, contract } = await connectToNetwork('admin');

    await contract.submitTransaction('UpdateStudentStatus', studentId, status);
    gateway.disconnect();

    res.json({ success: true, message: 'Student status updated successfully' });
  } catch (error: any) {
    console.error('Error updating student status:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ==================== ACADEMIC RECORD ENDPOINTS ====================

// Create academic record
app.post('/api/records', async (req: Request, res: Response) => {
  try {
    const { recordId, studentId, semester, courses } = req.body;

    if (!recordId || !studentId || !semester || !courses) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }

    const { gateway, contract } = await connectToNetwork('admin', 'Departments');

    await contract.submitTransaction(
      'CreateAcademicRecord',
      recordId,
      studentId,
      semester.toString(),
      JSON.stringify(courses)
    );

    gateway.disconnect();
    res.status(201).json({ 
      success: true, 
      message: 'Academic record created successfully',
      data: { recordId, studentId, semester }
    });
  } catch (error: any) {
    console.error('Error creating academic record:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get academic record
app.get('/api/records/:recordId', async (req: Request, res: Response) => {
  try {
    const { recordId } = req.params;
    const { gateway, contract } = await connectToNetwork('admin');

    const result = await contract.evaluateTransaction('GetAcademicRecord', recordId);
    gateway.disconnect();

    const record = JSON.parse(result.toString());
    res.json({ success: true, data: record });
  } catch (error: any) {
    console.error('Error getting academic record:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Approve academic record
app.put('/api/records/:recordId/approve', async (req: Request, res: Response) => {
  try {
    const { recordId } = req.params;
    const { gateway, contract } = await connectToNetwork('admin', 'NITWarangal');

    await contract.submitTransaction('ApproveAcademicRecord', recordId);
    gateway.disconnect();

    res.json({ success: true, message: 'Academic record approved successfully' });
  } catch (error: any) {
    console.error('Error approving academic record:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get student academic history
app.get('/api/students/:studentId/history', async (req: Request, res: Response) => {
  try {
    const { studentId } = req.params;
    const { gateway, contract } = await connectToNetwork('admin');

    const result = await contract.evaluateTransaction('GetStudentHistory', studentId);
    gateway.disconnect();

    const history = JSON.parse(result.toString());
    res.json({ success: true, data: history, count: history.length });
  } catch (error: any) {
    console.error('Error getting student history:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ==================== CERTIFICATE ENDPOINTS ====================

// Issue certificate with PDF upload
app.post('/api/certificates', upload.single('pdf'), async (req: Request, res: Response) => {
  try {
    const { certificateId, studentId, type } = req.body;
    const pdfFile = req.file;

    if (!certificateId || !studentId || !type || !pdfFile) {
      return res.status(400).json({ success: false, error: 'Missing required fields or PDF file' });
    }

    // Upload PDF to IPFS
    const pdfBuffer = pdfFile.buffer;
    const added = await ipfsClient.add(pdfBuffer);
    const ipfsHash = added.path;

    // Convert PDF to base64 for blockchain storage (hash calculation)
    const pdfBase64 = pdfBuffer.toString('base64');

    const { gateway, contract } = await connectToNetwork('admin', 'NITWarangal');

    await contract.submitTransaction(
      'IssueCertificate',
      certificateId,
      studentId,
      type,
      pdfBase64,
      ipfsHash
    );

    gateway.disconnect();

    res.status(201).json({
      success: true,
      message: 'Certificate issued successfully',
      data: {
        certificateId,
        studentId,
        type,
        ipfsHash,
        ipfsUrl: `https://ipfs.io/ipfs/${ipfsHash}`
      }
    });
  } catch (error: any) {
    console.error('Error issuing certificate:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get certificate
app.get('/api/certificates/:certificateId', async (req: Request, res: Response) => {
  try {
    const { certificateId } = req.params;
    const { gateway, contract } = await connectToNetwork('admin');

    const result = await contract.evaluateTransaction('GetCertificate', certificateId);
    gateway.disconnect();

    const certificate = JSON.parse(result.toString());
    res.json({ 
      success: true, 
      data: {
        ...certificate,
        ipfsUrl: `https://ipfs.io/ipfs/${certificate.ipfsHash}`
      }
    });
  } catch (error: any) {
    console.error('Error getting certificate:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Verify certificate
app.post('/api/certificates/:certificateId/verify', upload.single('pdf'), async (req: Request, res: Response) => {
  try {
    const { certificateId } = req.params;
    const pdfFile = req.file;

    if (!pdfFile) {
      return res.status(400).json({ success: false, error: 'PDF file is required' });
    }

    const pdfBuffer = pdfFile.buffer;
    const pdfBase64 = pdfBuffer.toString('base64');

    const { gateway, contract } = await connectToNetwork('admin', 'Verifiers');

    const result = await contract.evaluateTransaction('VerifyCertificate', certificateId, pdfBase64);
    gateway.disconnect();

    const verified = result.toString() === 'true';

    res.json({
      success: true,
      verified,
      message: verified ? 'Certificate is authentic' : 'Certificate verification failed'
    });
  } catch (error: any) {
    console.error('Error verifying certificate:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: any) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ success: false, error: 'Internal server error' });
});

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({ success: false, error: 'Endpoint not found' });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`
  ╔════════════════════════════════════════════════════════════╗
  ║  NIT Warangal Academic Records Blockchain API              ║
  ║  Server running on port ${PORT}                              ║
  ║  Health check: http://localhost:${PORT}/health              ║
  ╚════════════════════════════════════════════════════════════╝
  `);
});

export default app;

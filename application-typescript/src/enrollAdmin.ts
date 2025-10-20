import { Wallets, X509Identity } from 'fabric-network';
import * as fs from 'fs';
import * as path from 'path';

async function enrollAdmin() {
    try {
        // Create a new file system based wallet for managing identities
        const walletPath = path.join(__dirname, 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check if admin identity already exists in the wallet
        const identity = await wallet.get('admin');
        if (identity) {
            console.log('An identity for the admin user already exists in the wallet');
            return;
        }

        // Load credentials from the peer organization's admin folder
        const orgPath = path.join(__dirname, '..', '..', 'organizations', 'peerOrganizations', 'nitwarangal.nitw.edu');
        const certPath = path.join(orgPath, 'users', 'Admin@nitwarangal.nitw.edu', 'msp', 'signcerts', 'Admin@nitwarangal.nitw.edu-cert.pem');
        const keyPath = path.join(orgPath, 'users', 'Admin@nitwarangal.nitw.edu', 'msp', 'keystore');
        
        const cert = fs.readFileSync(certPath, 'utf8');
        
        // Read the private key from the keystore directory
        const keyFiles = fs.readdirSync(keyPath);
        const keyPem = fs.readFileSync(path.join(keyPath, keyFiles[0]), 'utf8');

        // Create the identity
        const x509Identity: X509Identity = {
            credentials: {
                certificate: cert,
                privateKey: keyPem,
            },
            mspId: 'NITWarangalMSP',
            type: 'X.509',
        };

        // Import the identity into the wallet
        await wallet.put('admin', x509Identity);
        console.log('Successfully enrolled admin user and imported it into the wallet');

    } catch (error) {
        console.error(`Failed to enroll admin user: ${error}`);
        process.exit(1);
    }
}

enrollAdmin();

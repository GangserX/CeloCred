# 🔮 CeloCred Credit Score Oracle Backend

Automated service that calculates and updates merchant credit scores on the Celo blockchain.

## 🎯 What It Does

1. **Fetches merchant data** from Firebase (transactions, loans, profile)
2. **Calculates credit scores** using a FICO-like algorithm (300-850 range)
3. **Updates blockchain** via the CreditScoreOracle smart contract
4. **Runs automatically** every hour (configurable)

---

## 🚀 Quick Start (5 minutes)

### Step 1: Install Dependencies
```bash
cd backend
npm install
```

### Step 2: Configure Environment
```bash
# Copy example config
cp .env.example .env

# Edit .env file
# You need to set:
# - ORACLE_PRIVATE_KEY (generate new wallet)
# - FIREBASE_SERVICE_ACCOUNT_PATH (download from Firebase Console)
```

### Step 3: Get Firebase Service Account Key
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** → **Service Accounts**
4. Click **"Generate New Private Key"**
5. Save as `serviceAccountKey.json` in the `backend/` folder

### Step 4: Create Oracle Wallet
```bash
# Generate new wallet (or use existing)
node -e "console.log(require('ethers').Wallet.createRandom().privateKey)"

# Copy the private key to .env:
ORACLE_PRIVATE_KEY=0x123abc...

# Get the wallet address:
node -e "console.log(new (require('ethers').Wallet)('YOUR_PRIVATE_KEY').address)"

# Fund it with CELO:
# Visit: https://faucet.celo.org/alfajores
# Request 5 CELO (enough for months of updates)
```

### Step 5: Authorize Oracle Wallet
The oracle wallet must be authorized in the smart contract.

**Option A: Using Remix IDE**
1. Open [Remix](https://remix.ethereum.org/)
2. Load `CreditScoreOracle.sol`
3. Connect to Alfajores testnet
4. Call `setOracle(YOUR_ORACLE_ADDRESS, true)` with owner wallet

**Option B: Using Hardhat (recommended)**
```bash
cd ../contracts
npx hardhat console --network alfajores

# In console:
const oracle = await ethers.getContractAt("CreditScoreOracle", "0x62468b565962f7713f939590B819AFDB5177bD08")
await oracle.setOracle("YOUR_ORACLE_ADDRESS", true)
```

### Step 6: Test It (Dry Run)
```bash
npm run update-scores -- --dry-run
```

This will:
- ✅ Calculate scores for all merchants
- ✅ Show what would be updated
- ❌ NOT update blockchain (safe to test)

### Step 7: Run Manual Update
```bash
npm run update-scores
```

This will actually update the blockchain!

### Step 8: Start Automatic Service
```bash
npm start
```

Service will:
- Update scores immediately
- Schedule updates every hour
- Keep running until you stop it (Ctrl+C)

---

## 📋 Configuration Options

Edit `.env` to customize:

```bash
# Update frequency (cron format)
UPDATE_CRON_SCHEDULE=0 * * * *  # Every hour
# UPDATE_CRON_SCHEDULE=0 */2 * * *  # Every 2 hours
# UPDATE_CRON_SCHEDULE=0 0 * * *    # Once per day at midnight

# Minimum transactions before calculating score
MIN_TRANSACTIONS_FOR_SCORE=3  # Default: 3

# Enable/disable auto updates
AUTO_UPDATE_ENABLED=true
```

---

## 🧮 Credit Score Algorithm

### Score Range: 300-850 (FICO-like)

### Components (Weighted):

1. **Payment History (35%)**
   - On-time loan repayments: +100 points
   - Late payments: -100 points per occurrence
   - Defaults: -250 points per occurrence
   - Transaction consistency (if no loans)

2. **Credit Utilization (30%)**
   - Outstanding loans vs monthly revenue
   - <30% utilization: 850 points (excellent)
   - 30-50%: 750 points (good)
   - 50-70%: 650 points (fair)
   - >100%: 450 points (very high risk)

3. **Length of History (15%)**
   - 1+ years: 850 points
   - 6+ months: 750 points
   - 3+ months: 700 points
   - 1+ month: 650 points
   - <1 month: 600 points

4. **New Credit (10%)**
   - 0 recent loans: 750 points
   - 1 recent loan: 700 points
   - 2 recent loans: 650 points
   - 3+ recent loans: 550 points (risky)

5. **Credit Mix (10%)**
   - Multiple currencies used: +50 points
   - Diverse transaction sizes: +50 points
   - High volume (20+ transactions): +50 points

### Base Score:
- New merchants (< 3 transactions): **650**
- First score calculated: **650-850** (based on data)

---

## 📊 Commands

### Start Service (Auto-Updates)
```bash
npm start
```

### Manual Update (One-Time)
```bash
npm run update-scores
```

### Dry Run (No Blockchain Updates)
```bash
npm run update-scores -- --dry-run
```

### Individual Updates (Not Batch)
```bash
npm run update-scores -- --individual
```

### Development Mode (Auto-Restart)
```bash
npm run dev
```

---

## 🔍 Monitoring

### Check Oracle Status
```bash
node -e "
const { OracleService } = require('./oracleService.js');
const oracle = new OracleService();
await oracle.initialize();
console.log(await oracle.getStatus());
"
```

### Check Wallet Balance
```bash
node -e "
const ethers = require('ethers');
const provider = new ethers.JsonRpcProvider('https://alfajores-forno.celo-testnet.org');
const balance = await provider.getBalance('YOUR_ORACLE_ADDRESS');
console.log('Balance:', ethers.formatEther(balance), 'CELO');
"
```

### View Recent Updates (Blockchain)
Visit: https://alfajores.celoscan.io/address/YOUR_ORACLE_ADDRESS

---

## 🐛 Troubleshooting

### Error: "Not authorized"
**Problem:** Oracle wallet not authorized in contract

**Solution:**
```bash
# Authorize with contract owner:
cd ../contracts
npx hardhat console --network alfajores
const oracle = await ethers.getContractAt("CreditScoreOracle", "0x62468b565962f7713f939590B819AFDB5177bD08")
await oracle.setOracle("YOUR_ORACLE_ADDRESS", true)
```

### Error: "Insufficient funds"
**Problem:** Oracle wallet needs CELO for gas

**Solution:**
1. Visit: https://faucet.celo.org/alfajores
2. Enter your oracle wallet address
3. Request 5 CELO

### Error: "FIREBASE_SERVICE_ACCOUNT_PATH not found"
**Problem:** Missing Firebase credentials

**Solution:**
1. Download service account key from Firebase Console
2. Save as `serviceAccountKey.json`
3. Update `.env`: `FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json`

### Error: "Cannot find module"
**Problem:** Dependencies not installed

**Solution:**
```bash
npm install
```

---

## 💰 Cost Estimate

### Gas Costs (Alfajores Testnet = FREE)
- Single update: ~100,000 gas
- Batch update (10 merchants): ~600,000 gas

### Mainnet Costs:
- Gas price: ~0.5 Gwei (Celo is cheap!)
- Single update: ~$0.0001
- Batch update (10): ~$0.0006
- **Monthly (100 merchants, hourly updates):** ~$4-5

### Infrastructure:
- **Development:** $0/month (run locally)
- **Production:** $10-20/month (cloud hosting)

---

## 🚀 Production Deployment

### Option 1: Cloud Functions (Easiest)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize
firebase init functions

# Deploy
firebase deploy --only functions
```

### Option 2: Google Cloud Run (Recommended)
```bash
# Build Docker image
docker build -t celocred-oracle .

# Push to registry
docker tag celocred-oracle gcr.io/YOUR_PROJECT/celocred-oracle
docker push gcr.io/YOUR_PROJECT/celocred-oracle

# Deploy
gcloud run deploy celocred-oracle \
  --image gcr.io/YOUR_PROJECT/celocred-oracle \
  --region us-central1
```

### Option 3: DigitalOcean (Most Control)
```bash
# Create Droplet ($6/month)
# SSH into droplet
ssh root@YOUR_DROPLET_IP

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Clone repo
git clone YOUR_REPO
cd backend

# Install dependencies
npm install

# Set up environment
nano .env  # Add your config

# Install PM2 (process manager)
npm install -g pm2

# Start service
pm2 start index.js --name celocred-oracle

# Enable auto-restart on boot
pm2 startup
pm2 save
```

---

## 🔐 Security Best Practices

1. **Never commit `.env` or `serviceAccountKey.json`**
   - Already in `.gitignore`
   - Use environment variables in production

2. **Use dedicated oracle wallet**
   - Don't reuse personal wallet
   - Only fund with minimal CELO (~1 CELO)

3. **Rotate keys regularly**
   - Generate new oracle wallet every 6 months
   - Update authorization in contract

4. **Monitor for anomalies**
   - Set up alerts for failed updates
   - Check gas costs regularly

5. **Secure production server**
   - Use firewall (UFW)
   - Keep software updated
   - Use SSH keys (not passwords)

---

## 📈 Scaling

### Current Capacity:
- **10 merchants:** Batch update in ~10 seconds
- **100 merchants:** Batch update in ~30 seconds
- **1,000 merchants:** Need optimization

### Optimization for >100 Merchants:
1. **Increase batch size** (group 50 updates per transaction)
2. **Parallel processing** (calculate scores in parallel)
3. **Caching** (cache Firebase queries)
4. **Selective updates** (only update if score changed >10 points)

---

## 🆘 Support

**Issues?** Check:
1. Is wallet authorized? → `authorizedOracles(address)`
2. Does wallet have CELO? → Check on Celoscan
3. Is Firebase connected? → Test with `getMerchantProfile()`
4. Are contracts deployed? → Check addresses in `.env`

**Still stuck?**
- Check logs: `npm start` shows detailed output
- Run dry-run: `npm run update-scores -- --dry-run`
- Test individual components (Firebase, Ethers, etc.)

---

## 📝 License

MIT License - See LICENSE file

---

## ✅ Checklist

Before going live:
- [ ] Oracle wallet funded with CELO
- [ ] Oracle wallet authorized in contract
- [ ] Firebase service account configured
- [ ] `.env` file configured
- [ ] Tested with dry-run
- [ ] Tested with manual update
- [ ] Monitoring/alerts configured
- [ ] Backup oracle wallet created
- [ ] Documentation reviewed

---

**Ready to launch?** Run `npm start` and let it run! 🚀

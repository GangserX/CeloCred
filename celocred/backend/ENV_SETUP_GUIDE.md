# 📝 Backend .env Configuration Guide

## ✅ What's Already Configured:

1. **✅ Celo Network**
   ```env
   CELO_RPC_URL=https://alfajores-forno.celo-testnet.org
   CHAIN_ID=44787
   ```
   - This is the Alfajores testnet
   - No action needed

2. **✅ Smart Contract Address**
   ```env
   CREDIT_SCORE_ORACLE_ADDRESS=0x62468b565962f7713f939590B819AFDB5177bD08
   ```
   - Already deployed on Alfajores
   - No action needed

3. **✅ Oracle Wallet**
   ```env
   ORACLE_PRIVATE_KEY=0xd28e4fe6ca99456e393045cc3983bc14497427c687b1f08f2be2969406b18723
   ```
   - **Address:** 0x73F64A719b4f224C3cc2b89fF3A883bC005CCe8d
   - **Status:** ✅ Generated and saved
   - **Action needed:** Fund with CELO (see below)

4. **✅ Update Schedule**
   ```env
   UPDATE_CRON_SCHEDULE=0 * * * *  # Every hour
   MIN_TRANSACTIONS_FOR_SCORE=3
   AUTO_UPDATE_ENABLED=true
   ```
   - Good defaults
   - No action needed

---

## ⚠️ What YOU Need to Do:

### 1. Get Firebase Service Account Key (REQUIRED)

**Current Status:** ❌ Missing

**Steps:**
1. Go to: https://console.firebase.google.com/
2. Select your CeloCred project
3. Click ⚙️ Settings → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **"Generate New Private Key"** button
6. Save the downloaded JSON file
7. Rename it to: `serviceAccountKey.json`
8. Move it to: `C:\Users\bisha\Music\celocred_mobile\celocred\backend\`

**What it looks like:**
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
  ...
}
```

**Why you need it:**
- Backend needs admin access to Firebase
- Reads merchant/transaction data
- Writes calculated credit scores
- **WITHOUT THIS, BACKEND WON'T WORK**

---

### 2. Fund Oracle Wallet (REQUIRED)

**Oracle Address:** `0x73F64A719b4f224C3cc2b89fF3A883bC005CCe8d`

**Steps:**
1. Go to: https://faucet.celo.org/alfajores
2. Paste address: `0x73F64A719b4f224C3cc2b89fF3A883bC005CCe8d`
3. Click "Get Alfajores CELO"
4. Wait ~30 seconds
5. Check balance: https://alfajores.celoscan.io/address/0x73F64A719b4f224C3cc2b89fF3A883bC005CCe8d

**Why you need it:**
- Oracle wallet pays gas for blockchain updates
- Each update costs ~0.001 CELO (~$0.0001)
- 5 CELO = ~5,000 updates = months of operation
- **WITHOUT THIS, BLOCKCHAIN UPDATES WILL FAIL**

---

### 3. Authorize Oracle Wallet (REQUIRED)

**Status:** ❌ Not authorized yet

The smart contract needs to authorize your oracle wallet before it can update scores.

**Option A: Using Hardhat Console (Recommended)**
```bash
# From project root
cd C:\Users\bisha\Music\celocred_mobile\celocred\contracts

# Start Hardhat console
npx hardhat console --network alfajores

# In the console, run:
const oracle = await ethers.getContractAt("CreditScoreOracle", "0x62468b565962f7713f939590B819AFDB5177bD08")
await oracle.setOracle("0x73F64A719b4f224C3cc2b89fF3A883bC005CCe8d", true)
```

**Option B: Using Remix IDE**
1. Go to: https://remix.ethereum.org/
2. Load `CreditScoreOracle.sol`
3. Compile it
4. Connect to "Injected Provider - MetaMask"
5. Switch MetaMask to Alfajores testnet
6. Load contract at: `0x62468b565962f7713f939590B819AFDB5177bD08`
7. Call `setOracle("0x73F64A719b4f224C3cc2b89fF3A883bC005CCe8d", true)`

**Why you need it:**
- Only authorized oracles can update credit scores
- Security measure to prevent unauthorized updates
- **WITHOUT THIS, BLOCKCHAIN UPDATES WILL BE REJECTED**

---

## 🧪 Test Your Configuration

After completing all steps above, run:

```bash
cd C:\Users\bisha\Music\celocred_mobile\celocred\backend

# Test all connections
npm test
```

**Expected Output:**
```
✅ Firebase Connection      PASS
✅ Blockchain Connection    PASS
✅ Oracle Wallet            PASS (balance: 5.00 CELO)
✅ Smart Contract           PASS
✅ Oracle Authorization     PASS
✅ End-to-End Flow          PASS

🎉 All tests passed! Backend is ready to use.
```

---

## 🚀 Once Everything is Ready

### Manual Update (Test First):
```bash
# Dry run (no blockchain updates)
npm run update-scores -- --dry-run

# Real update
npm run update-scores
```

### Start Automatic Service:
```bash
npm start
```

This will:
- Update credit scores immediately
- Schedule updates every hour
- Keep running until you stop it (Ctrl+C)

---

## 📊 Configuration Summary

| Setting | Value | Status |
|---------|-------|--------|
| **RPC URL** | alfajores-forno.celo-testnet.org | ✅ OK |
| **Chain ID** | 44787 (Alfajores) | ✅ OK |
| **Contract** | 0x62468...8C3b | ✅ OK |
| **Oracle Wallet** | 0x73F64A...Ce8d | ✅ Generated |
| **Wallet Balance** | 0 CELO | ⚠️ **Need to fund** |
| **Firebase Key** | serviceAccountKey.json | ⚠️ **Need to download** |
| **Authorization** | Not set | ⚠️ **Need to authorize** |
| **Schedule** | Every hour | ✅ OK |

---

## 🔐 Security Reminders

**DO:**
- ✅ Keep `.env` file secret (already in .gitignore)
- ✅ Keep `serviceAccountKey.json` secret (already in .gitignore)
- ✅ Use separate oracle wallet (don't reuse personal wallet)
- ✅ Only fund oracle wallet with small amounts (1-5 CELO)

**DON'T:**
- ❌ Commit `.env` to git
- ❌ Commit `serviceAccountKey.json` to git
- ❌ Share private key with anyone
- ❌ Use this wallet for other purposes

---

## ❓ Troubleshooting

### "Cannot find module './serviceAccountKey.json'"
**Solution:** Download Firebase service account key (Step 1 above)

### "Insufficient funds for gas"
**Solution:** Fund oracle wallet at faucet (Step 2 above)

### "Not authorized oracle"
**Solution:** Authorize wallet in smart contract (Step 3 above)

### "Connection timeout"
**Solution:** Check internet connection, RPC might be slow

---

## 📞 Quick Reference

**Oracle Wallet Address:**
```
0x73F64A719b4f224C3cc2b89fF3A883bC005CCe8d
```

**Faucet:**
```
https://faucet.celo.org/alfajores
```

**Firebase Console:**
```
https://console.firebase.google.com/
```

**Contract on Explorer:**
```
https://alfajores.celoscan.io/address/0x62468b565962f7713f939590B819AFDB5177bD08
```

**Test Command:**
```bash
npm test
```

---

## ✅ Checklist

Before running backend:
- [ ] Downloaded `serviceAccountKey.json` from Firebase
- [ ] Placed in `/backend` folder
- [ ] Funded oracle wallet with CELO (5 CELO recommended)
- [ ] Authorized oracle wallet in smart contract
- [ ] Ran `npm test` - all tests passed
- [ ] Tried `npm run update-scores -- --dry-run` - works
- [ ] Ready to run `npm start`

---

**Once you complete these 3 steps, your backend will be fully operational! 🚀**

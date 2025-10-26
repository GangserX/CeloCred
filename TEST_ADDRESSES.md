# Test Addresses for CeloCred

## Your Wallet
- Address: `0x5850978373D187bd35210828027739b336546057`
- Balance: 2.727 CELO

## Test Merchant Addresses (Use these for testing payments)

### Test Merchant 1
- Address: `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1`
- Name: Test Merchant 1
- Use this address when testing MANUAL PAYMENT

### Test Merchant 2  
- Address: `0x0E3EfB5B6C2F6e2c3d5d9d8d8d8d8d8d8d8d8d8d`
- Name: Test Merchant 2
- Alternative test address

## Smart Contracts (Celo Alfajores Testnet)
- MerchantRegistry: `0x04B51b523e504274b74E52AeD936496DeF4A771F`
- PaymentProcessor: `0xdfF8Bf0Acf41F5E85a869a522921e132D5E20401`
- LoanEscrow: `0x758fac555708d9972BadB755a563382d2F4B844F`
- CreditScoreOracle: `0xCC54cE7e70F9680dce54c10Da3AC32b181b71098`

## How to Test Payments

1. **Open app** → Click "Manual Payment"
2. **Connect wallet** 
3. **Enter test merchant address**: Copy one of the test merchant addresses above
4. **Click Verify** (it will say "not registered" - that's OK!)
5. **Enter amount**: Try 0.0001 CELO
6. **Click Continue** 
7. **Process Payment** → You'll get REAL transaction hash!
8. **Verify on blockchain**: https://alfajores.celoscan.io

## Common Errors

### "Cannot pay yourself"
- You're trying to send to your own address
- Use one of the test merchant addresses above instead

### "Insufficient funds"
- Need at least 0.002 CELO buffer for gas
- Get more from faucet: https://faucet.celo.org

### "RPC Error -32000"
- Usually means insufficient balance or trying to pay yourself
- Check you're sending to a DIFFERENT address

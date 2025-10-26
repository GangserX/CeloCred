const hre = require("hardhat");

async function main() {
  console.log("🚀 Starting CeloCred Smart Contract Deployment to Celo Sepolia...\n");

  const [deployer] = await hre.ethers.getSigners();
  console.log("📝 Deploying contracts with account:", deployer.address);
  
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", hre.ethers.formatEther(balance), "CELO\n");

  if (balance === 0n) {
    console.log("❌ ERROR: No CELO balance! Get testnet CELO from:");
    console.log("   👉 https://faucet.celo.org\n");
    process.exit(1);
  }

  // cUSD token address on Sepolia testnet
  const CUSD_TOKEN = process.env.CUSD_TOKEN_ADDRESS;
  if (!CUSD_TOKEN) {
    console.log("❌ ERROR: CUSD_TOKEN_ADDRESS not found in .env file");
    process.exit(1);
  }
  console.log("📌 Using cUSD token at:", CUSD_TOKEN, "\n");

  // Deploy MerchantRegistry
  console.log("🏪 Deploying MerchantRegistry...");
  const MerchantRegistry = await hre.ethers.getContractFactory("MerchantRegistry");
  const merchantRegistry = await MerchantRegistry.deploy();
  await merchantRegistry.waitForDeployment();
  const merchantRegistryAddress = await merchantRegistry.getAddress();
  console.log("✅ MerchantRegistry deployed to:", merchantRegistryAddress, "\n");

  // Deploy PaymentProcessor (needs cUSD token AND merchant registry)
  console.log("💳 Deploying PaymentProcessor...");
  const PaymentProcessor = await hre.ethers.getContractFactory("PaymentProcessor");
  const paymentProcessor = await PaymentProcessor.deploy(CUSD_TOKEN, merchantRegistryAddress);
  await paymentProcessor.waitForDeployment();
  const paymentProcessorAddress = await paymentProcessor.getAddress();
  console.log("✅ PaymentProcessor deployed to:", paymentProcessorAddress, "\n");

  // Deploy LoanEscrow
  console.log("🏦 Deploying LoanEscrow...");
  const LoanEscrow = await hre.ethers.getContractFactory("LoanEscrow");
  const loanEscrow = await LoanEscrow.deploy(CUSD_TOKEN);
  await loanEscrow.waitForDeployment();
  const loanEscrowAddress = await loanEscrow.getAddress();
  console.log("✅ LoanEscrow deployed to:", loanEscrowAddress, "\n");

  // Deploy CreditScoreOracle
  console.log("📊 Deploying CreditScoreOracle...");
  const CreditScoreOracle = await hre.ethers.getContractFactory("CreditScoreOracle");
  const creditScoreOracle = await CreditScoreOracle.deploy();
  await creditScoreOracle.waitForDeployment();
  const creditScoreOracleAddress = await creditScoreOracle.getAddress();
  console.log("✅ CreditScoreOracle deployed to:", creditScoreOracleAddress, "\n");

  // Contracts are already linked! (PaymentProcessor constructor sets MerchantRegistry)
  console.log("🔗 Contracts linked during deployment\n");

  // Summary
  console.log("═══════════════════════════════════════════════════════════════");
  console.log("🎉 DEPLOYMENT SUCCESSFUL!");
  console.log("═══════════════════════════════════════════════════════════════\n");
  
  console.log("📋 CONTRACT ADDRESSES (Copy these to your Flutter app):\n");
  console.log("MerchantRegistry:", merchantRegistryAddress);
  console.log("PaymentProcessor:", paymentProcessorAddress);
  console.log("LoanEscrow:", loanEscrowAddress);
  console.log("CreditScoreOracle:", creditScoreOracleAddress);
  console.log("cUSD Token:", CUSD_TOKEN);
  console.log("\n═══════════════════════════════════════════════════════════════\n");

  console.log("📱 UPDATE YOUR FLUTTER APP:");
  console.log("File: celocred/lib/core/constants/celo_config.dart\n");
  console.log("Replace the contract addresses with the ones above.");
  console.log("\n🔍 View on Celo Sepolia Explorer:");
  console.log(`https://celo-sepolia.blockscout.com/address/${merchantRegistryAddress}`);
  console.log("\n✅ Deployment complete!\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });

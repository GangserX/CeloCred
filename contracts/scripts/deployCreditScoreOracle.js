const hre = require("hardhat");

async function main() {
  console.log("\n📝 Deploying CreditScoreOracle Contract...\n");

  const [deployer] = await hre.ethers.getSigners();
  console.log("👤 Deploying with account:", deployer.address);
  
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", hre.ethers.formatEther(balance), "CELO\n");

  // Deploy the contract
  console.log("⏳ Deploying CreditScoreOracle...");
  const CreditScoreOracle = await hre.ethers.getContractFactory("CreditScoreOracle");
  const oracle = await CreditScoreOracle.deploy();
  
  await oracle.waitForDeployment();
  const address = await oracle.getAddress();
  
  console.log("✅ CreditScoreOracle deployed to:", address);
  console.log("👤 Owner:", await oracle.owner());
  
  // Authorize the oracle wallet immediately
  const oracleWallet = "0xf2e92f2bde761fa4e7b1f81ccf1fe096aa74dc75";
  console.log("\n🔐 Authorizing oracle wallet:", oracleWallet);
  
  const authTx = await oracle.setOracle(oracleWallet, true);
  console.log("⏳ Authorization transaction:", authTx.hash);
  await authTx.wait();
  
  console.log("✅ Oracle wallet authorized!");
  
  // Verify authorization
  const isAuthorized = await oracle.authorizedOracles(oracleWallet);
  console.log("🔍 Verification - Is authorized:", isAuthorized);
  
  console.log("\n📋 IMPORTANT: Update your backend/.env file:");
  console.log(`   CREDIT_SCORE_ORACLE_ADDRESS=${address}`);
  console.log("\n🎉 Deployment complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Error:", error);
    process.exit(1);
  });

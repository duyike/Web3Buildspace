const main = async () => {
  const [owner] = await ethers.getSigners();
  const contractFactory = await hre.ethers.getContractFactory("PegsDai");
  const contract = await contractFactory.deploy();
  await contract.deployed();
  console.log("Contract deployed to:", contract.address);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();

const main = async () => {
  const [owner] = await ethers.getSigners();
  const contract = await hre.ethers.getContractAt(
    "PegsDai",
    "0x2399783bB684b4Da7d76e6EBD4e5e3cC11Fa8dee"
  );
  // buy PDAI
  // await contract.buy("10000000000000000000");
  // sell PDAI
  await contract.approve(contract.address, "10000000000000000000");
  await contract.sell("10000000000000000000");
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

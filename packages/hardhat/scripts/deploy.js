/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers } = require("hardhat");
const { utils, BigNumber } = require("ethers");
const R = require("ramda");




const main = async () => {

  console.log("\n\n 📡 Deploying...\n");

  // var privateKey = "0x0123456789012345678901234567890123456789012345678901234567890123";
  // var wallet = new Wallet(privateKey);

  // console.log("Address: " + wallet.address);
  // // "Address: 0x14791697260E4c9A71f18484C9f997B308e59325"


  //const yourContract = await deploy("YourContract") // <-- add in constructor args like line 16 vvvv



  // const exampleToken = await deploy("ExampleToken")
  // const examplePriceOracle = await deploy("ExamplePriceOracle")
  // const smartContractWallet = await deploy("SmartContractWallet",[exampleToken.address,examplePriceOracle.address])

  /*

  //If you want to send some ETH to a contract on deploy (make your constructor payable!)

  const yourContract = await deploy("YourContract", [], {
  value: ethers.utils.parseEther("0.05")
  });
  */


  

  //If you want to send value to an address from the deployer

  //const deployerWallet = ethers.provider.getSigner()
  // await deployerWallet.sendTransaction({
  //   to: "0x31D7326c1347239262C98bccFE13e9e5FD4E7357",
  //   value: ethers.utils.parseEther("1")
  // })
  //console.log(deployerWallet.address)

  //
  //
  //
  //
  //
  //
  // auto deploy to read contract directory and deploy them all (add ".args" files for arguments)
  //await autoDeploy();
  // OR   aasas
  // custom deploy (to use deployed addresses dynamically for example:)
  //const exampleToken = await deploy("ExampleToken")
  //const examplePriceOracle = await deploy("ExamplePriceOracle")
  //const smartContractWallet = await deploy("SmartContractWallet",[exampleToken.address,examplePriceOracle.address])
  //const [adminSigner] = await ethers.getAddress
  //admin = await adminSigner.getAddress();
  //console.log(account);
  const [owner, account1, account2, ] = await ethers.getSigners()
  console.log("account of owner + account addresses: ", owner.address, account1.address, account2.address)

  const token = await deploy("uToken", ["underlying", "u"])
  const tender = await deploy("TenderToken", ["tenter", "t"])
  const dex = await deploy("DEX",[token.address, tender.address])
  const staker = await deploy("Staker", [token.address, tender.address, dex.address])
  const manager = await deploy("Manager", [token.address, tender.address, dex.address, staker.address])

  await dex.initManager(manager.address)


  const myAddress = "0x31D7326c1347239262C98bccFE13e9e5FD4E7357"
  console.log("minting initial amount of underlying + transfering to acc1...")
  await token.mint(owner.address, ethers.utils.parseEther('10000'))
  await token.mint(account1.address, ethers.utils.parseEther('10000'))
  await token.transfer(account1.address, ethers.utils.parseEther('5000'))
  await token.transfer(myAddress, ethers.utils.parseEther('1000'))

  // minting tender + giving minting privilages to Manager
  // await tender.mint(owner.address, ethers.utils.parseEther('10000'))
  console.log("transferring token ownership to contracts...")
  await tender.transferOwnership(manager.address)
  await token.transferOwnership(staker.address)

  // familiraze staker with manager
  await staker.initManager(manager.address)


  //[addr1, addr2, addr3, addr4, _] = await ethers.getSigners()
    // Get the address of the Signer

  // '0x8ba1f109551bD432803012645Ac136ddd64DBA72'

  // paste in your address here to get 10 token on deploy:
  // await token.transfer(myAddress,""+(104*10**18))
  //await tender.transfer(myAddress,""+(204*10**18))

  // await tender.transfer(account1.address,""+(304*10**18))

  // uncomment to init pool on deploy:


  // console.log("Approving DEX ("+dex.address+") to take token from main account...")
    // await token.approve(dex.address,ethers.utils.parseEther('100'))
  // await tender.approve(dex.address,ethers.utils.parseEther('100'))

  // console.log("Approving Manger ("+manager.address+") + depositing from account1...")
  await token.connect(account1).approve(manager.address, ethers.utils.parseEther('2000'))
  await tender.connect(account1).approve(manager.address, ethers.utils.parseEther('2000'))
  await token.connect(account1).approve(dex.address, ethers.utils.parseEther('2000'))
  await tender.connect(account1).approve(dex.address, ethers.utils.parseEther('2000'))
  // await manager.connect(account1).deposit(ethers.utils.parseEther('1'))

  // console.log("mintTender...")
  // await manager.mintTender(ethers.utils.parseEther('1'))

  console.log("sharePrice: ", ethers.utils.formatEther(await manager.sharePrice()))

  console.log("Depositing...")
  // await tender.connect(account1).approve(manager.address,ethers.utils.parseEther('100'))
  await manager.connect(account1).deposit(ethers.utils.parseEther('300'))
  await manager.connect(account1).deposit(ethers.utils.parseEther('300'))
  await manager.connect(account1).deposit(ethers.utils.parseEther('200'))
  // await manager.connect(account1).deposit(ethers.utils.parseEther('400'))
  console.log("sharePrice: ", ethers.utils.formatEther(await manager.sharePrice()))
  

  console.log("Running rewards...")
  // await tender.connect(account1).approve(manager.address,ethers.utils.parseEther('100'))
  await staker.connect(account1)._runRewards(ethers.utils.parseEther('100'))
  // await staker.connect(account1)._runRewards(ethers.utils.parseEther('10'))
  // await staker.connect(account1)._runRewards(ethers.utils.parseEther('100'))
  console.log("sharePrice: ", ethers.utils.formatEther(await manager.sharePrice()))

  // console.log("Running staking...")
  // await token.connect(account1).approve(staker.address,ethers.utils.parseEther('100'))
  // await staker.connect(account1)._stake(ethers.utils.parseEther('10'))
  // await staker.connect(account1)._stake(ethers.utils.parseEther('10'))



  console.log("INIT pool...")

  // await token.transfer(manager.address, ethers.utils.parseEther('300'))
  // await tender.connect(account1).transfer(manager.address, ethers.utils.parseEther('300'))
  await manager.connect(account1).initPool(ethers.utils.parseEther('300'))
  console.log("tokenBalanceOfPool: ", ethers.utils.formatEther(await token.balanceOf(dex.address)))
  console.log("tenderBalanceOfPool: ", ethers.utils.formatEther(await tender.balanceOf(dex.address)))
 


  console.log("tenderPoolPrice: ", ethers.utils.formatEther(await dex.getSpotPrice()))


  // console.log("Running rewards...")
  // await staker.connect(account1)._runRewards(ethers.utils.parseEther('100'))
  // console.log("sharePrice: ", ethers.utils.formatEther(await manager.sharePrice()))



  // console.log("tokenBalanceOfManager: ", ethers.utils.formatEther(await token.balanceOf(manager.address)))
  // console.log("tenderBalanceOfManager: ", ethers.utils.formatEther(await tender.balanceOf(manager.address)))

  // console.log("Withdrawing...")
  // await manager.connect(account1).withdraw(ethers.utils.parseEther('30'))
  // await manager.connect(account1).withdraw(ethers.utils.parseEther('70'))

  console.log("PoolTokenIn...")
  await dex.connect(account1).tokenToTender(ethers.utils.parseEther('20'))
  console.log("tokenBalanceOfPool: ", ethers.utils.formatEther(await token.balanceOf(dex.address)))
  console.log("tenderBalanceOfPool: ", ethers.utils.formatEther(await tender.balanceOf(dex.address)))
  console.log("tenderPoolPrice: ", ethers.utils.formatEther(await dex.getSpotPrice()))
  console.log("sharePrice: ", ethers.utils.formatEther(await manager.sharePrice()))

  console.log("PoolTenderIn...")
  await dex.connect(account1).tenderToToken(ethers.utils.parseEther('10'))
  console.log("tokenBalanceOfPool: ", ethers.utils.formatEther(await token.balanceOf(dex.address)))
  console.log("tenderBalanceOfPool: ", ethers.utils.formatEther(await tender.balanceOf(dex.address)))
  console.log("tenderPoolPrice: ", ethers.utils.formatEther(await dex.getSpotPrice()))
  console.log("sharePrice: ", ethers.utils.formatEther(await manager.sharePrice()))


  console.log("Running rewards...")
  await staker.connect(account1)._runRewards(ethers.utils.parseEther('100'))
  console.log("sharePrice: ", ethers.utils.formatEther(await manager.sharePrice()))



  // console.log("sharePrice: ", ethers.utils.formatEther(await manager.sharePrice()))
  console.log("Depositing...")
  await manager.connect(account1).deposit(ethers.utils.parseEther('300'))
  await manager.connect(account1).deposit(ethers.utils.parseEther('300'))
  await manager.connect(account1).deposit(ethers.utils.parseEther('200'))
  // await manager.connect(account1).deposit(ethers.utils.parseEther('400'))
  console.log("sharePrice: ", ethers.utils.formatEther(await manager.sharePrice()))

  
  console.log("Withdrawing...")
  await manager.connect(account1).withdraw(ethers.utils.parseEther('30'))
  await manager.connect(account1).withdraw(ethers.utils.parseEther('60'))
  console.log("sharePrice: ", ethers.utils.formatEther(await manager.sharePrice()))
  


  // console.log("tokenBalanceOfStaker ", ethers.utils.formatEther(token.balanceOf(staker.address)))

  // await manager.initPool(ethers.utils.parseEther('5')) // dex.init(ethers.utils.parseEther('5'),{value:ethers.utils.parseEther('5')}) 


  // await tender.approve(dex.address,ethers.utils.parseEther('100'))
  // await tender.approve(manager.address,ethers.utils.parseEther('100')) // ,{from:myAddress} WE NEED to do This 
  // await manager.deposit(ethers.utils.parseEther('10'))

  // const tokenSupply = (new BigNumber.from(tokenStaker)).sub(new BigNumber.from(tokenManager))
  

  const tokenStaker = await token.balanceOf(staker.address)
  const tokenManager = await token.balanceOf(manager.address)
  const ts = tokenStaker.add(tokenManager)

  const tenderSupply = await tender.totalSupply()
  const mintedForPool = await manager.mintedForPool()
  const together = tenderSupply.sub(mintedForPool)  //(new BigNumber.from(tenderSupply)).sub(new BigNumber.from(mintedForPool))
  console.log("outstanding: ", ethers.utils.formatEther(ts))
  console.log("tenderSupply: ", ethers.utils.formatEther(together))
  console.log("sharePrice: ", ethers.utils.formatEther(await manager.sharePrice()))
  // console.log("together: ", ethers.utils.formatEther(together))



  // console.log("pool price...")
  // console.log("outstanding: ", ethers.utils.formatEther(await dex.getSpotPrice()))
  // await manager.deposit(ethers.utils.parseEther('1'))
  // await manager.withdraw(ethers.utils.parseEther('1'))
  // {from:myAdress}


  console.log("-------------------ALLL DONE------------------")

















  console.log(
    " 💾  Artifacts (address, abi, and args) saved to: ",
    chalk.blue("packages/hardhat/artifacts/"),
    "\n\n"
  );
};

const deploy = async (contractName, _args = [], overrides = {}) => {
  console.log(` 🛰  Deploying: ${contractName}`);

  const contractArgs = _args || [];
  const contractArtifacts = await ethers.getContractFactory(contractName);
  const deployed = await contractArtifacts.deploy(...contractArgs, overrides);
  const encoded = abiEncodeArgs(deployed, contractArgs);
  fs.writeFileSync(`artifacts/${contractName}.address`, deployed.address);

  console.log(
    " 📄",
    chalk.cyan(contractName),
    "deployed to:",
    chalk.magenta(deployed.address),
  );

  if (!encoded || encoded.length <= 2) return deployed;
  fs.writeFileSync(`artifacts/${contractName}.args`, encoded.slice(2));

  return deployed;
};

// ------ utils -------

// abi encodes contract arguments
// useful when you want to manually verify the contracts
// for example, on Etherscan
const abiEncodeArgs = (deployed, contractArgs) => {
  // not writing abi encoded args if this does not pass
  if (
    !contractArgs ||
    !deployed ||
    !R.hasPath(["interface", "deploy"], deployed)
  ) {
    return "";
  }
  const encoded = utils.defaultAbiCoder.encode(
    deployed.interface.deploy.inputs,
    contractArgs
  );
  return encoded;
};

// checks if it is a Solidity file
const isSolidity = (fileName) =>
  fileName.indexOf(".sol") >= 0 && fileName.indexOf(".swp") < 0 && fileName.indexOf(".swap") < 0;

const readArgsFile = (contractName) => {
  let args = [];
  try {
    const argsFile = `./contracts/${contractName}.args`;
    if (!fs.existsSync(argsFile)) return args;
    args = JSON.parse(fs.readFileSync(argsFile));
  } catch (e) {
    console.log(e);
  }
  return args;
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

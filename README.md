# 🏗 scaffold-eth

> is everything you need to get started building decentralized applications powered by smart contracts

---

## quickstart

```bash
git clone https://github.com/austintgriffith/scaffold-eth.git

cd scaffold-eth
```

```bash

yarn install

```

```bash

yarn start

```

> in a second terminal window:

```bash

yarn chain

```

> in a third terminal window:

```bash

yarn deploy

```

🔏 Edit your smart contract `YourContract.sol` in `packages/hardhat/contracts`

📝 Edit your frontend `App.jsx` in `packages/react-app/src`

💼 Edit your deployment script `deploy.js` in `packages/hardhat/scripts`

📱 Open http://localhost:3000 to see the app

📚 Keep [solidity by example](https://solidity-by-example.org) handy and check out the [Solidity globals and units](https://solidity.readthedocs.io/en/v0.6.6/units-and-global-variables.html)

> With everything up your dev environment starts looking something like this:

![image](https://user-images.githubusercontent.com/2653167/91858466-768bb080-ec26-11ea-9e9b-81519f7f1c90.png)

> React dev server, HardHat blockchain, deploy terminal, code IDE, and frontend browser.

---


🔁    You can `yarn run deploy` any time and get a fresh new contract in the frontend:


![deploy](https://user-images.githubusercontent.com/2653167/93149199-f8fa8280-f6b2-11ea-9da7-3b26413ec8ab.gif)


---


💵.   Each browser has an account in the top right and you can use the faucet (bottom left) to get ⛽️  testnet eth for gas:


![faucet](https://user-images.githubusercontent.com/2653167/93150077-6c04f880-f6b5-11ea-9ee8-5c646b5b7afc.gif)


---


🔨   Once you have funds, you can call `setPurpose` on your contract and "write" to the `purpose` storage:


![setp](https://user-images.githubusercontent.com/2653167/93229761-2d625300-f734-11ea-9036-44a75429ef0c.gif)



---


Look for the [HardHat](https://hardhat.org) console.log() output in the `yarn run chain` terminal:

![image](https://user-images.githubusercontent.com/2653167/93687934-2f534b80-fa7f-11ea-84b2-c0ba99533dc2.png)


---

👨‍🏫 Maybe start super simple and add a counter `uint8 public count = 1;`

⬇️ Then a `function dec() public {}` that does a `count = count - 1;`

![image](https://user-images.githubusercontent.com/2653167/93150263-dae25180-f6b5-11ea-94e1-b24ab2a63fa5.png)

---

🔬  What happens when you subtract 1 from 0? Try it out in the app to see what happens!

![underflow](https://user-images.githubusercontent.com/2653167/93688066-46466d80-fa80-11ea-85df-81fbafa46575.gif)

🚽 UNDERFLOW!

🧫 You can iterate and learn as you go. Test your assumptions!

---

💵 Send testnet ETH between browsers or even on an [instantwallet.io](https://instantwallet.io) selecting `localhost`:

![sendingaroundinstantwallet](https://user-images.githubusercontent.com/2653167/93688154-05028d80-fa81-11ea-8643-2c447af59b5c.gif)

---

🔐 Global variables like `msg.sender` and `msg.value` are cryptographically backed and can be used to make rules

📝 Keep this [cheat sheet](https://solidity.readthedocs.io/en/v0.7.0/cheatsheet.html?highlight=global#global-variables) handy

⏳ Maybe we could use `block.timestamp` or `block.number` to track time in our contract

🔏 Or maybe keep track of an `address public owner;` then make a rule like `require( msg.sender == owner );` for an important function

🧾 Maybe create a smart contract that keeps track of a `mapping ( address => uint256 ) public balance;`

🏦 It could be like a decentralized bank that you `function deposit() public payable {}` and `withdraw()`

📟 Events are really handy for signaling to the frontend. [Read more about events here.](https://solidity-by-example.org/0.6/events/)

📲 Spend some time in `App.jsx` in `packages/react-app/src` and learn about the 🛰 [Providers](https://github.com/austintgriffith/scaffold-eth#-web3-providers)

⚠️ Big numbers are stored as objects: `formatEther` and `parseEther` (ethers.js) will help with WEI->ETH and ETH->WEI.

🧳 The single page (searchable) [ethers.js docs](https://docs.ethers.io/v5/single-page/) are pretty great too.

🐜 The UI framework `Ant Design` has a [bunch of great components](https://ant.design/components/overview/).

📃 Check the console log for your app to see some extra output from hooks like `useContractReader` and `useEventListener`.

🏗 You'll notice the `<Contract />` component that displays the dynamic form as scaffolding for interacting with your contract.

🔲 Try making a `<Button/>` that calls `writeContracts.YourContract.setPurpose("👋 Hello World")` to explore how your UI might work...

💬 Wrap the call to `writeContracts` with a `tx()` helper that uses BlockNative's [Notify.js](https://www.blocknative.com/notify).

🧬 Next learn about [structs](https://solidity-by-example.org/0.6/structs/) in Solidity.

🗳 Maybe an make an array `YourStructName[] public proposals;` that could call be voted on with `function vote() public {}`

🔭 Your dev environment is perfect for *testing assumptions* and learning by prototyping.

📝 Next learn about the [fallback function](https://solidity-by-example.org/0.6/fallback/)

💸 Maybe add a `receive() external payable {}` so your contract will accept ETH?

🚁 OH! Programming decentralized money! 😎 So rad!

🛰 Ready to deploy to a testnet? Change the `defaultNetwork` in `packages/hardhat/hardhat.config.js`

🔐 Generate a deploy account with `yarn generate` and view it with `yarn account`

🔑 Create wallet links to your app with `yarn wallet` and `yarn fundedwallet`

⬇️ Installing a new package to your frontend? You need to `cd packages/react-app` and then `yarn add PACKAGE`

⬇️ Installing a new package to your backend? You need to `cd packages/harthat` and then `yarn add PACKAGE`

( You will probably want to take some of the 🔗 [hooks](#-hooks), 🎛 [components](#-components) with you from 🏗 scaffold-eth so we started 🖇 [eth-hooks](https://www.npmjs.com/package/eth-hooks) )

🚀 Good luck!

---

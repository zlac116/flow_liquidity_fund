import React, { Component } from "react";
import "./App.css";
import { getWeb3 } from "./getWeb3";
import map from "./artifacts/deployments/map.json";
import { getEthereum } from "./getEthereum";
import Web3 from "web3";

class App extends Component {
  state = {
    web3: null,
    accounts: null,
    chainid: null,
    flow: null,
    flowQuorum: 0,
    flowBalance: 0,
    depositAmount: 0,
    stablecoin: null,
    ierc20: null,
  };

  componentDidMount = async () => {
    // Get network provider and web3 instance.
    const web3 = await getWeb3();

    // Try and enable accounts (connect metamask)
    try {
      const ethereum = await getEthereum();
      ethereum.request({ method: "eth_requestAccounts" }); // prev. ethereum.enable()
    } catch (e) {
      console.log(`Could not enable accounts. Interaction with contracts not available.
            Use a modern browser with a Web3 plugin to fix this issue.`);
      console.log(e);
    }

    // Use web3 to get the user's accounts
    const accounts = await web3.eth.getAccounts();

    // Get the current chain id
    const chainid = parseInt(await web3.eth.getChainId());

    this.setState(
      {
        web3,
        accounts,
        chainid,
      },
      await this.loadInitialContracts
    );
  };

  loadInitialContracts = async () => {
    // <=42 to exclude Kovan, <42 to include kovan
    if (this.state.chainid < 42) {
      // Wrong Network!
      return;
    }
    console.log(this.state.chainid);

    var _chainID = 0;
    if (this.state.chainid === 42) {
      _chainID = 42;
    }
    if (this.state.chainid === 1337) {
      _chainID = "dev";
    }
    console.log(_chainID);
    // const vyperStorage = await this.loadContract(_chainID, "VyperStorage");
    const flow = await this.loadContract(_chainID, "Flow");

    // if (!vyperStorage || !solidityStorage) {
    //   return;
    // }

    // const vyperValue = await vyperStorage.methods.get().call();
    const flowBalance = await flow.methods.availableFunds().call();
    const networkId = _chainID;

    this.setState({
      // vyperStorage,
      // vyperValue,
      flow,
      flowBalance,
      networkId,
    });
  };

  loadContract = async (chain, contractName) => {
    // Load a deployed contract instance into a web3 contract object
    const { web3 } = this.state;

    // Get the address of the most recent deployment from the deployment map
    let address;
    try {
      address = map[chain][contractName][0];
    } catch (e) {
      console.log(
        `Couldn't find any deployed contract "${contractName}" on the chain "${chain}".`
      );
      return undefined;
    }

    console.log("contract addr " + address);

    // Load the artifact with the specified address
    let contractArtifact;
    try {
      contractArtifact = await import(
        `./artifacts/deployments/${chain}/${address}.json`
      );
    } catch (e) {
      console.log(
        `Failed to load contract artifact "./artifacts/deployments/${chain}/${address}.json"`
      );
      return undefined;
    }

    return new web3.eth.Contract(contractArtifact.abi, address);
  };

  // flowApprove = async (e) => {
  //   const { accounts, ierc20, depositAmount, stablecoin } = this.state;
  //   e.preventDefault();

  // }

  getAddress = (chain, contractName) => {
    let address;
    try {
      address = map[chain][contractName][0];
    } catch (e) {
      console.log(
        `Couldn't find any deployed contract "${contractName}" on the chain "${chain}".`
      );
      return undefined;
    }
    return address;
  };

  flowDeposit = async (e) => {
    const { networkId, accounts, flow, depositAmount, stablecoin } = this.state;
    e.preventDefault();
    // const value = 10;
    const value = Web3.utils.toWei(depositAmount, "ether");
    const ccy = stablecoin;
    if (isNaN(value)) {
      alert("invalid value");
      return;
    }

    console.log("value " + value);
    console.log("stablecoin " + ccy);
    console.log(networkId);

    let address = this.getAddress(networkId, "Flow");

    const stablecoinContract = await this.loadContract(
      networkId,
      "UsdCircleToken"
    );
    await stablecoinContract.methods
      .approve(address, value)
      .send({ from: accounts[0] });
    await flow.methods
      .deposit(ccy, value)
      .send({ from: accounts[0] })
      .on("receipt", async () => {
        this.setState({
          depositAmount: await flow.methods.availableFunds().call(),
        });
      });
  };

  render() {
    const {
      web3,
      accounts,
      chainid,
      flow,
      flowBalance,
      // flowInput,
      depositAmount,
      stablecoin,
    } = this.state;

    if (!web3) {
      return <div>Loading Web3, accounts, and contracts...</div>;
    }

    // <=42 to exclude Kovan, <42 to include Kovan
    if (isNaN(chainid) || chainid < 42) {
      return (
        <div>
          Wrong Network! Switch to your local RPC "Localhost: 8545" in your Web3
          provider (e.g. Metamask)
        </div>
      );
    }

    const isAccountsUnlocked = accounts ? accounts.length > 0 : false;

    return (
      <div className="App">
        <Navbar account={this.state.account}></Navbar>
        <h1>Flow Staking App</h1>
        <p>
          If your contracts compiled and deployed successfully, you can see the
          current storage values below.
        </p>
        {!isAccountsUnlocked ? (
          <p>
            <strong>
              Connect with Metamask and refresh the page to be able to edit the
              storage fields.
            </strong>
          </p>
        ) : null}

        <h2>Staking</h2>
        <div>Contract value is: {flowBalance}</div>
        <br />
        <form onSubmit={(e) => this.flowDeposit(e)}>
          <div>
            <label>Change the value to: </label>
            <br />
            <label>Stablecoin address: </label>
            <input
              name="stablecoin"
              type="text"
              onChange={(e) => this.setState({ stablecoin: e.target.value })}
            />
            <br />
            <label>Deposit amount: </label>
            <input
              name="amount"
              type="text"
              value={depositAmount}
              onChange={(e) => this.setState({ depositAmount: e.target.value })}
            />
            <br />
            <button type="submit" disabled={!isAccountsUnlocked}>
              Submit
            </button>
          </div>
        </form>
      </div>
    );
  }
}

export default App;

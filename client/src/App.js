import React, { Component } from "react";
import "./App.css";
import Main from "./Main";
import map from "./artifacts/deployments/map.json";
import Web3 from "web3";
import Navbar from "./Navbar";

import DaiToken from "./artifacts/contracts/DaiToken.json";
import Flow from "./artifacts/contracts/Flow.json";
import UsdCircleToken from "./artifacts/contracts/UsdCircleToken.json";
import UsdTetherToken from "./artifacts/contracts/UsdTetherToken.json";
import FlowReceiptToken from "./artifacts/contracts/FlowReceiptToken.json";

class App extends Component {
  async componentWillMount() {
    await this.loadWeb3();
    await this.loadBlockchainData();
  }

  async loadBlockchainData() {
    const web3 = window.web3;

    const accounts = await web3.eth.getAccounts();
    console.log("accounts: " + accounts);
    this.setState({ account: accounts[0] }); // load first account

    const networkId = parseInt(await web3.eth.getChainId());
    console.log("networkId: " + networkId);

    // Load DaiToken
    let daiAddress = map["dev"]["DaiToken"];
    // let daiContractArtifact = await import(
    //   `./artifacts/deployments/dev/${daiAddress}.json`
    // );
    console.log(daiAddress.toString());
    if (daiAddress) {
      const daiToken = new web3.eth.Contract(
        DaiToken.abi,
        daiAddress.toString()
      );
      this.setState({ daiToken });
      let daiTokenBalance = await daiToken.methods
        .balanceOf(this.state.account)
        .call();
      this.setState({ daiTokenBalance: daiTokenBalance.toString() });
    } else {
      window.alert("DaiToken contract not deployed to detected network.");
    }

    // Load UsdcToken
    let usdcAddress = map["dev"]["UsdCircleToken"];
    if (usdcAddress) {
      // && usdcContractArtifact) {
      const usdcToken = new web3.eth.Contract(
        UsdCircleToken.abi,
        usdcAddress.toString()
      );
      this.setState({ usdcToken });
      let usdcTokenBalance = await usdcToken.methods
        .balanceOf(this.state.account)
        .call();
      this.setState({ usdcTokenBalance: usdcTokenBalance.toString() });
    } else {
      window.alert("UsdCircleToken contract not deployed to detected network.");
    }

    // Load UsdtToken
    let usdtAddress = map["dev"]["UsdTetherToken"];
    if (usdtAddress) {
      const usdtToken = new web3.eth.Contract(
        UsdTetherToken.abi,
        usdtAddress.toString()
      );
      this.setState({ usdtToken });
      let usdtTokenBalance = await usdtToken.methods
        .balanceOf(this.state.account)
        .call();
      this.setState({ usdtTokenBalance: usdtTokenBalance.toString() });
    } else {
      window.alert("UsdTetherToken contract not deployed to detected network.");
    }

    // Load Flow
    let flowAddress = map["dev"]["Flow"];
    console.log(flowAddress.toString());
    if (flowAddress) {
      const flow = new web3.eth.Contract(Flow.abi, flowAddress.toString());
      this.setState({ flow: flow });
      const stakingBalanceDai = await flow.methods
        .investorStake(daiAddress.toString(), this.state.account)
        .call();
      const stakingBalanceUsdc = await flow.methods
        .investorStake(usdcAddress.toString(), this.state.account)
        .call();
      const stakingBalanceUsdt = await flow.methods
        .investorStake(usdtAddress.toString(), this.state.account)
        .call();
      console.log("dai staking balance: " + stakingBalanceDai);
      this.setState({
        stakingBalanceDai: stakingBalanceDai.toString(),
        stakingBalanceUsdc: stakingBalanceUsdc.toString(),
        stakingBalanceUsdt: stakingBalanceUsdt.toString(),
      });
    } else {
      window.alert("Flow contract not deployed to detected network.");
    }

    // Load FlowReceiptToken
    let flowTokenAddress = await this.state.flow.methods
      .flowReceiptTokenAddress()
      .call();
    if (flowTokenAddress) {
      const flowReceiptToken = new web3.eth.Contract(
        FlowReceiptToken.abi,
        flowTokenAddress.toString()
      );
      this.setState({ flowReceiptToken });
      let flowReceiptTokenBalance = await flowReceiptToken.methods
        .balanceOf(this.state.account)
        .call();
      this.setState({
        flowReceiptTokenBalance: flowReceiptTokenBalance.toString(),
      });
      console.log(flowReceiptTokenBalance);
    } else {
      window.alert(
        "FlowReceiptToken contract not deployed to detected network."
      );
    }

    this.setState({ loading: false });
  }

  async loadWeb3() {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum);
      await window.ethereum.enable();
    } else if (window.web3) {
      window.web3 = new Web3(window.web3.currentProvider);
    } else {
      window.alert(
        "Non-Ethereum browser detected. You should consider trying MetaMask!"
      );
    }
  }

  stakeTokens = (amount) => {
    this.setState({ loading: true });
    this.state.daiToken.methods
      .approve(this.state.flow._address, amount)
      .send({ from: this.state.account })
      .on("transactionHash", (hash) => {
        this.state.flow.methods
          .deposit(this.state.daiToken._address, amount)
          .send({ from: this.state.account })
          .on("transactionHash", (hash) => {
            this.setState({ loading: false });
          });
      });
  };

  unstakeTokens = (amount) => {
    this.setState({ loading: true });
    this.state.flow.methods
      .withdraw(this.state.daiToken._address, amount)
      .send({ from: this.state.account })
      .on("transactionHash", (hash) => {
        this.setState({ loading: false });
      });
  };

  constructor(props) {
    super(props);
    this.state = {
      account: "0x0",
      daiToken: {},
      usdcToken: {},
      usdtToken: {},
      flowReceiptToken: {},
      flow: {},
      daiTokenBalance: "0",
      usdcTokenBalance: "0",
      usdtTokenBalance: "0",
      flowReceiptTokenBalance: "0",
      stakingBalanceDai: "0",
      stakingBalanceUsdc: "0",
      stakingBalanceUsdt: "0",
      loading: true,
    };
  }

  render() {
    let content;
    if (this.state.loading) {
      content = (
        <p id="loader" className="text-center">
          Loading...
        </p>
      );
    } else {
      content = (
        <Main
          daiTokenBalance={this.state.daiTokenBalance}
          usdcTokenBalance={this.state.usdcTokenBalance}
          usdtTokenBalance={this.state.usdtTokenBalance}
          flowReceiptTokenBalance={this.state.flowReceiptTokenBalance}
          stakingBalanceDai={this.state.stakingBalanceDai}
          stakingBalanceUsdc={this.state.stakingBalanceUsdc}
          stakingBalanceUsdt={this.state.stakingBalanceUsdt}
          stakeTokens={this.stakeTokens}
          unstakeTokens={this.unstakeTokens}
        />
      );
    }
    return (
      <div>
        <Navbar account={this.state.account} />
        <div className="container-fluid mt-5">
          <div className="row">
            <main
              role="main"
              className="col-lg-12 ml-auto mr-auto"
              style={{ maxWidth: "600px" }}
            >
              <div className="content mr-auto ml-auto">
                <a
                  href="https://www.flowglobal.net/"
                  target="_blank"
                  rel="noopener noreferrer"
                ></a>

                {content}
              </div>
            </main>
          </div>
        </div>
      </div>
    );
  }
}

export default App;

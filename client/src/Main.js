import React, { Component } from "react";
import dai from "./images/dai.png";
// import usdc from "./images/usdc.png";
// import usdt from "./images/usdt.png";

class Main extends Component {
  render() {
    return (
      <div id="content" className="mt-3">
        <table className="table table-borderless text-muted text-center">
          <thead>
            <tr>
              <th scope="col">Staking Balance</th>
              <th scope="col">Reward Balance</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>
                {window.web3.utils.fromWei(
                  this.props.stakingBalanceDai,
                  "Ether"
                )}{" "}
                mDAI
              </td>
              <td>
                {window.web3.utils.fromWei(
                  this.props.flowReceiptTokenBalance,
                  "Ether"
                )}{" "}
                FRT
              </td>
            </tr>
            <tr>
              <td>
                {window.web3.utils.fromWei(
                  this.props.stakingBalanceUsdc,
                  "Ether"
                )}{" "}
                mUSDC
              </td>
              <td>
                {window.web3.utils.fromWei(
                  this.props.flowReceiptTokenBalance,
                  "Ether"
                )}{" "}
                FRT
              </td>
            </tr>
            <tr>
              <td>
                {window.web3.utils.fromWei(
                  this.props.stakingBalanceUsdt,
                  "Ether"
                )}{" "}
                mUSDT
              </td>
              <td>
                {window.web3.utils.fromWei(
                  this.props.flowReceiptTokenBalance,
                  "Ether"
                )}{" "}
                FRT
              </td>
            </tr>
          </tbody>
        </table>
        <div className="card mb-4">
          <div className="card-body">
            <form
              className="mb-3"
              onSubmit={(event) => {
                event.preventDefault();
                let amount;
                amount = this.input.value.toString();
                amount = window.web3.utils.toWei(amount, "Ether");
                this.props.stakeTokens(amount);
              }}
            >
              {/* DAI */}
              <div>
                <label className="float-start">
                  <b>Stake Tokens</b>
                </label>
                <span className="float-end text-muted">
                  Balance:{" "}
                  {window.web3.utils.fromWei(
                    this.props.daiTokenBalance,
                    "Ether"
                  )}
                </span>
              </div>
              <div className="input-group mb-4">
                <input
                  type="text"
                  ref={(input) => {
                    this.input = input;
                  }}
                  className="form-control form-control-lg"
                  placeholder="0"
                  required
                />
                <div className="input-group-append">
                  <div className="input-group-text">
                    <img src={dai} height="32" alt="" />
                    &nbsp;&nbsp;&nbsp; mDAI
                  </div>
                </div>
              </div>
              <button
                type="submit"
                className="btn btn-primary btn-block btn-lg"
              >
                DEPOSIT
              </button>
            </form>
            <button
              type="submit"
              className="btn btn-link btn-block btn-sm"
              onClick={(event) => {
                event.preventDefault();
                let amount;
                amount = this.props.stakingBalanceDai;
                this.props.unstakeTokens(amount);
              }}
            >
              WITHDRAW
            </button>
          </div>
        </div>
      </div>
    );
  }
}

export default Main;

from brownie import DaiToken, Flow, UsdCircleToken, UsdTetherToken, FlowReceiptToken, accounts, network

def main():
    quorum = 2
    maturity = 36 # in days
    admins = accounts[1:4] # 3 admins
    bank = accounts[7:9]
    investors = accounts[4:7]
    mUSDC = accounts[0].deploy(UsdCircleToken)
    mUSDT = accounts[0].deploy(UsdTetherToken)
    mDAI = accounts[0].deploy(DaiToken)
    permitted_tokens = [mUSDC.address, mDAI.address]

    flow = accounts[0].deploy(Flow, quorum, maturity, admins, bank, permitted_tokens)

    for investor in investors:
        mUSDC.transfer(investor, 100e18, {'from': accounts[0]})
        mUSDT.transfer(investor, 100e18, {'from': accounts[0]})
        mDAI.transfer(investor, 100e18, {'from': accounts[0]})

        print(f'mUSDC Balance of {investor} is {mUSDC.balanceOf(investor) / 1e18} mUSDC')
        print(f'mUSDT Balance of {investor} is {mUSDT.balanceOf(investor) / 1e18} mUSDT')
        print(f'mDAI Balance of {investor} is {mDAI.balanceOf(investor) / 1e18} mDAI')

    mUSDC.approve(flow.address, 100e18, {'from': investors[0]})
    flow.deposit(mUSDC.address, 100e18, {'from': investors[0]})
    network.chain.sleep(maturity * 24 * 60 * 60)
    mUSDC_get_interest = flow.getAccruedInterest(mUSDC.address, {"from":investors[0]})
    mDAI_get_interest = flow.getAccruedInterest(mDAI.address, {"from":investors[0]})
    print(f'mUSDC interest: {mUSDC_get_interest}')
    print(f'mDAI interest: {mDAI_get_interest}')

if __name__ == "__main__":
    main()
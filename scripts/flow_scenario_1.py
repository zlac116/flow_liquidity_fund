from unicodedata import decimal
from brownie import DaiToken, Flow, UsdCircleToken, UsdTetherToken, FlowReceiptToken, accounts
from brownie.network.state import Chain

chain = Chain()

def main():
    decimal = 1e18
    quorum = 2
    maturity = 365 # in days
    time_passed = 365 # in days
    secs_in_day = 24 * 60 * 60
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

        print(f'mUSDC Balance of {investor} is {mUSDC.balanceOf(investor) / decimal} mUSDC')
        print(f'mUSDT Balance of {investor} is {mUSDT.balanceOf(investor) / decimal} mUSDT')
        print(f'mDAI Balance of {investor} is {mDAI.balanceOf(investor) / decimal} mDAI')

    mUSDC.approve(flow.address, 100e18, {'from': investors[0]})
    flow.deposit(mUSDC.address, 100e18, {'from': investors[0]})
    chain.sleep(time_passed * secs_in_day)
    chain.mine()

    # print(f'start: {flow.start()}\nnow: {chain.time()}\nchange: {chain.time() - flow.start()}')
    mUSDC_get_interest = flow.getAccruedInterest(mUSDC.address, {"from":investors[0]}) / decimal
    # mDAI_get_interest = flow.getAccruedInterest(mDAI.address, {"from":investors[0]}) / decimal
    print(f'mUSDC interest: {mUSDC_get_interest}')
    # print(f'mDAI interest: {mDAI_get_interest}')

if __name__ == "__main__":
    main()
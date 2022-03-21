from brownie import Flow, UsdCircleToken, DaiToken, UsdTetherToken, accounts, network


def main():
    # requires brownie account to have been created
    if network.show_active()=='development':
        # add these accounts to metamask by importing private key
        owner = accounts[0]

        quorum = 2
        maturity = 2
        flow_admins = accounts[1:4]
        flow_withdrawal_addresses = accounts[7:9]
        usdc = owner.deploy(UsdCircleToken)
        dai = owner.deploy(DaiToken)
        usdt = owner.deploy(UsdTetherToken)
        stables = [usdc.address, dai.address]
        Flow.deploy(quorum, maturity, flow_admins, flow_withdrawal_addresses, stables, {'from':owner})

    # elif network.show_active() == 'kovan':
    #     # add these accounts to metamask by importing private key
    #     owner = accounts.load("main")
    #     SolidityStorage.deploy({'from':owner})
    #     VyperStorage.deploy({'from':owner})
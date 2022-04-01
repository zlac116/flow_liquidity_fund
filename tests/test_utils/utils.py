from brownie import Flow, UsdCircleToken, DaiToken, UsdTetherToken, accounts, chain, interface
import pytest

# CHAIN = network.Chain()
QUORUM = 2
START_DAYS = 2
START_SECS = START_DAYS * 24 * 60 * 60
MATURITY_DAYS = 10
MATURITY_SECS = MATURITY_DAYS * 24 * 60 * 60
RATE_BPS = 5000 # bps => 50% 
YEAR_SECS = 365 * 24 * 60 * 60
DEPOSIT_AMT = 100e18
WITHDRAW_AMT = 50e18

@pytest.fixture(scope='function', autouse=True)
def mUSDC(UsdCircleToken):
  return accounts[0].deploy(UsdCircleToken)

@pytest.fixture(scope='function', autouse=True)
def mDAI(DaiToken):
  return accounts[0].deploy(DaiToken)

@pytest.fixture(scope='function', autouse=True)
def mUSDT(UsdTetherToken):
  return accounts[0].deploy(UsdTetherToken)
  

@pytest.fixture(scope='function', autouse=True)
def flow(Flow, mUSDC, mDAI):
  return accounts[0].deploy(Flow,
    QUORUM,
    START_DAYS,
    MATURITY_DAYS,
    RATE_BPS,
    accounts[1:4],
    accounts[7:9],
    [mUSDC.address, mDAI.address]
  )

@pytest.fixture(autouse=True)
def isolation(fn_isolation):
  pass

# ************UTILITY FUNCTIONS************

def approve(token, spender, amount, owner):
  token.approve(spender, amount, {'from': owner})

def deposit(depositor, token, deposit_amt, contract):
  token.approve(contract.address, deposit_amt, {'from': depositor})
  contract.deposit(token.address, deposit_amt, {'from': depositor})

def withdraw(depositor, contract):
  contract.withdraw({'from': depositor})

def stop(contract, admin_1, admin_2):
  contract.flowCreateStop({'from': admin_1})
  contract.flowSetStop(0, {'from': admin_1})
  contract.flowSetStop(0, {'from': admin_2})

def flow_receipt_token(contract):
  return interface.IERC20(contract.flowReceiptToken())

def rewards(amount, rate, day_count_frac):
  return amount * rate * day_count_frac

# def create_transfer(flow, amt, to, token, admin):
#   flow.flowCreateTransfer(amt, to, token.address, {'from': admin})

def chain_sleep(secs):
  chain.sleep(secs)
  chain.mine()
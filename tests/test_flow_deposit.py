from brownie import Flow, UsdCircleToken, DaiToken, UsdTetherToken, accounts, interface
import pytest, brownie
from test_utils import utils

QUORUM = 2
DAYS_TO_SECS = 24 * 60 * 60
START_DAYS = 2
START_SECS = START_DAYS * DAYS_TO_SECS
TENOR_DAYS = 10
TENOR_SECS = TENOR_DAYS * DAYS_TO_SECS
RATE_BPS = 5000 # bps => 50% 
YEAR_SECS = 365 * DAYS_TO_SECS
DEPOSIT_AMT = 100e18
REWARDS_CONTRACT_DEPOSIT = 10e18
WITHDRAW_AMT = 50e18
REWARDS = utils.rewards(DEPOSIT_AMT, RATE_BPS / 10000, TENOR_SECS / YEAR_SECS)

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

  flow = accounts[0].deploy(Flow,
    QUORUM,
    START_DAYS,
    TENOR_DAYS,
    RATE_BPS,
    accounts[1:5],
    accounts[9],
    mUSDC.address,
  )
  mUSDC.transfer(flow.address, REWARDS_CONTRACT_DEPOSIT, {'from': accounts[0]})
  mDAI.transfer(flow.address, REWARDS_CONTRACT_DEPOSIT, {'from': accounts[0]})
  return flow

@pytest.fixture(autouse=True)
def isolation(fn_isolation):
  pass

#***********************Investor Deposit***********************

# should deposit to smart contract
def test_deposit(flow, mUSDC):
  depositor = accounts[0]
  init_balance = mUSDC.balanceOf(depositor)
  mUSDC.approve(flow.address, DEPOSIT_AMT, {'from': depositor})
  txn = flow.deposit(mUSDC.address, DEPOSIT_AMT, {'from': depositor})
  end_balance = mUSDC.balanceOf(depositor)

  assert mUSDC.balanceOf(flow.address) == DEPOSIT_AMT + REWARDS_CONTRACT_DEPOSIT
  assert flow.availableFunds() == DEPOSIT_AMT
  assert (init_balance - end_balance) == DEPOSIT_AMT
  assert utils.flow_receipt_token(flow).balanceOf(depositor) == DEPOSIT_AMT
  assert utils.flow_receipt_token(flow).totalSupply() == DEPOSIT_AMT
  assert txn.events['TokenMinted']['to'] == depositor
  assert txn.events['TokenMinted']['amt'] == DEPOSIT_AMT

# should not deposit if stablecoin is not permitted
def test_deposit_stable_not_permitted(flow, mUSDT):
  depositor = accounts[0]
  utils.approve(mUSDT, flow.address, DEPOSIT_AMT, depositor)
  with brownie.reverts('only permitted stablecoins'):
    flow.deposit(mUSDT.address, DEPOSIT_AMT, {'from': depositor})

# should not deposit if start reached
def test_deposit_fund_start_passed(flow, mUSDC):
  depositor = accounts[0]
  utils.approve(mUSDC, flow.address, DEPOSIT_AMT, depositor)
  utils.chain_sleep(START_SECS)
  with brownie.reverts('fund start passed'):
    flow.deposit(mUSDC.address, DEPOSIT_AMT, {'from': depositor})

# should not deposit if investor has insuffcient stablecoin balance
def test_deposit_balance_insufficient(flow, mUSDC):
  depositor = accounts[3]
  utils.approve(mUSDC, flow.address, DEPOSIT_AMT, depositor)
  with brownie.reverts('insuffcient stablecoin balance'):
    flow.deposit(mUSDC.address, DEPOSIT_AMT, {'from': depositor})
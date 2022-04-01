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

#***********************Investor Withdrawal***********************

# should withdraw entire investor balance
def test_withdraw(flow, mUSDC):
  depositor = accounts[0]
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  utils.chain_sleep(START_SECS + TENOR_SECS)
  utils.approve(utils.flow_receipt_token(flow), flow.address, DEPOSIT_AMT, depositor)
  init_balance_stable = mUSDC.balanceOf(depositor)
  init_balance_flow_receipt = utils.flow_receipt_token(flow).balanceOf(depositor)
  txn = flow.withdraw({'from': depositor})
  end_balance_stable = mUSDC.balanceOf(depositor)
  end_balance_flow_receipt = utils.flow_receipt_token(flow).balanceOf(depositor)
  
  assert (end_balance_stable - init_balance_stable) / 1e18 == (DEPOSIT_AMT + REWARDS) / 1e18
  assert end_balance_flow_receipt == 0
  assert (init_balance_flow_receipt - end_balance_flow_receipt) == DEPOSIT_AMT
  assert flow.availableFunds() == 0
  assert utils.flow_receipt_token(flow).totalSupply() == 0
  assert txn.events['TokenBurnt']['to'] == depositor
  assert txn.events['TokenBurnt']['amt'] == DEPOSIT_AMT

# should allow non-depositor to withdraw entire investor balance if they hold flow tokens
def test_withdraw_non_depositor_with_tokens(flow, mUSDC):
  depositor = accounts[0]
  redeemer = accounts[5]
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  utils.flow_receipt_token(flow).transfer(redeemer, DEPOSIT_AMT, {'from': depositor})
  utils.chain_sleep(START_SECS + TENOR_SECS)
  utils.approve(utils.flow_receipt_token(flow), flow.address, DEPOSIT_AMT, redeemer)
  init_balance_stable = mUSDC.balanceOf(redeemer)
  init_balance_flow_receipt = utils.flow_receipt_token(flow).balanceOf(redeemer)
  txn = flow.withdraw({'from': redeemer})
  end_balance_stable = mUSDC.balanceOf(redeemer)
  end_balance_flow_receipt = utils.flow_receipt_token(flow).balanceOf(redeemer)
  
  assert (end_balance_stable - init_balance_stable) / 1e18 == (DEPOSIT_AMT + REWARDS) / 1e18
  assert end_balance_flow_receipt == 0
  assert (init_balance_flow_receipt - end_balance_flow_receipt) == DEPOSIT_AMT
  assert flow.availableFunds() == 0
  assert utils.flow_receipt_token(flow).totalSupply() == 0
  assert txn.events['TokenBurnt']['to'] == redeemer
  assert txn.events['TokenBurnt']['amt'] == DEPOSIT_AMT

  utils.approve(utils.flow_receipt_token(flow), flow.address, DEPOSIT_AMT, depositor)
  with brownie.reverts('insufficient investor balance'):
    flow.withdraw({'from': depositor})

# should not withdraw if deadline not reached
def test_withdraw_deadline_not_reached(flow, mUSDC):
  depositor = accounts[0]
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  utils.chain_sleep(TENOR_SECS - 5)
  utils.approve(utils.flow_receipt_token(flow), flow.address, DEPOSIT_AMT, depositor)
  with brownie.reverts('deadline has not been reached'):
    flow.withdraw({'from': depositor})

# should not withdraw if investor does not have sufficient stables invested
def test_withdraw_balance_insufficient(flow, mUSDC):
  depositor = accounts[0]
  depositor_not_invested = accounts[8]
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  utils.chain_sleep(START_SECS + TENOR_SECS)
  utils.approve(utils.flow_receipt_token(flow), flow.address, DEPOSIT_AMT, depositor)
  with brownie.reverts('insufficient investor balance'):
    flow.withdraw({'from': depositor_not_invested})
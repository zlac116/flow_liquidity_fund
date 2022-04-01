from brownie import Flow, UsdCircleToken, DaiToken, UsdTetherToken, accounts, chain, interface
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

#***********************Create Transfer (Flow)***********************

# should create flow multisig transfer
def test_create_transfer(flow, mUSDC):
  depositor = accounts[0]
  bank = accounts[9]
  admin = accounts[1]
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  flow.flowCreateTransfer(WITHDRAW_AMT, {'from': admin})

  assert flow.flowTransfers(0)[0] == 0
  assert flow.flowTransfers(0)[1] == WITHDRAW_AMT
  assert flow.flowTransfers(0)[2] == mUSDC.address
  assert flow.flowTransfers(0)[3] == bank.address
  assert flow.flowTransfers(0)[4] == 0
  assert flow.flowTransfers(0)[5] == False
  assert flow.nextId() == 1

# should not create transfer if not admin
def test_create_transfer_not_admin(flow, mUSDC):
  depositor = accounts[0]
  admin_unauthorised = accounts[5] # not admin
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  with brownie.reverts('only flow admins allowed'):
    flow.flowCreateTransfer(WITHDRAW_AMT, {'from': admin_unauthorised})

# should not create transfer if stablecoin balance insufficient
def test_create_transfer_insufficient_balance(flow, mUSDC, mDAI):
  depositor = accounts[0]
  admin = accounts[1] # admin
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  utils.chain_sleep(START_SECS + TENOR_SECS)
  utils.withdraw(depositor, flow)
  with brownie.reverts('insufficent stablecoin balance'):
    flow.flowCreateTransfer(WITHDRAW_AMT, {'from': admin})

#***********************Transfer (Flow)***********************

# should transfer stablecoins to stored address if admin
def test_flow_transfer_to(flow, mUSDC):
  depositor = accounts[0]
  bank = accounts[9]
  admin_1 = accounts[1]
  admin_2 = accounts[2]
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  init_balance = mUSDC.balanceOf(bank)
  flow.flowCreateTransfer(WITHDRAW_AMT, {'from': admin_1})
  flow.flowTransferTo(0, {'from': admin_1})
  txn = flow.flowTransferTo(0, {'from': admin_2})
  end_balance = mUSDC.balanceOf(bank)

  assert mUSDC.balanceOf(flow.address) == DEPOSIT_AMT - WITHDRAW_AMT + REWARDS_CONTRACT_DEPOSIT
  assert (end_balance - init_balance) == WITHDRAW_AMT
  assert flow.flowActivity() == WITHDRAW_AMT
  assert flow.availableFunds() == DEPOSIT_AMT - WITHDRAW_AMT
  assert txn.events['Withdrawal']['to'] == bank
  assert txn.events['Withdrawal']['amt'] == WITHDRAW_AMT

# should not transfer stablecoins to stored address if not admin
def test_flow_transfer_to_not_admin(flow, mUSDC):
  depositor = accounts[0]
  admin_1 = accounts[1] # admin
  admin_unauthorised = accounts[5] # not admin
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  flow.flowCreateTransfer(WITHDRAW_AMT, {'from': admin_1})
  flow.flowTransferTo(0, {'from': admin_1})
  with brownie.reverts('only flow admins allowed'):
    flow.flowTransferTo(0, {'from': admin_unauthorised})

#***********************Emergency Stop (Flow)***********************

# should set contract state to INACTIVE and stop investor deposits and withdrawals
def test_flow_stop(flow, mUSDC):
  depositor = accounts[0]
  admin_1 = accounts[1]
  admin_2 = accounts[2]
  flow.flowCreateStop({'from': admin_1})
  flow.flowSetStop(0, {'from': admin_1})
  flow.flowSetStop(0, {'from': admin_2})

  assert flow.state() == 1
  with brownie.reverts('state must be ACTIVE'):
    utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  with brownie.reverts('state must be ACTIVE'):
    utils.withdraw(depositor, flow)

# should NOT set contract state to INACTIVE and stop investor deposits and withdrawals
def test_flow_stop_not_admin(flow):
  depositor = accounts[0]
  admin_2 = accounts[2]
  with brownie.reverts('only flow admins allowed'):
    flow.flowCreateStop({'from': depositor})
    flow.flowSetStop(0, {'from': depositor})
  flow.flowSetStop(0, {'from': admin_2})
  assert flow.state() == 0

#***********************Emergency Restart (Flow)***********************

# should set contract state to ACTIVE and restart investor deposits and withdrawals
def test_flow_start(flow, mUSDC):
  depositor = accounts[0]
  admin_1 = accounts[1]
  admin_2 = accounts[2]
  utils.stop(flow, admin_1, admin_2)
  assert flow.state() == 1 # state = INACTIVE
  flow.flowCreateRestart({'from': admin_1})
  flow.flowSetRestart(0, {'from': admin_1})
  flow.flowSetRestart(0, {'from': admin_2})

  assert flow.state() == 0 # state = ACTIVE
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  assert mUSDC.balanceOf(flow.address) == DEPOSIT_AMT + REWARDS_CONTRACT_DEPOSIT
  utils.chain_sleep(START_SECS + TENOR_SECS)
  utils.withdraw(depositor, flow)
  assert mUSDC.balanceOf(flow.address) / 1e18 == (REWARDS_CONTRACT_DEPOSIT - REWARDS) / 1e18

# should NOT set contract state to ACTIVE and start investor deposits and withdrawals
def test_flow_start_not_admin(flow, mUSDC):
  depositor = accounts[0]
  admin_1 = accounts[1]
  admin_2 = accounts[2]
  utils.stop(flow, admin_1, admin_2)
  with brownie.reverts('only flow admins allowed'):
    flow.flowCreateRestart({'from': depositor})
    flow.flowSetRestart(0, {'from': depositor})
  flow.flowSetRestart(0, {'from': admin_2})
  assert flow.state() == 1
  with brownie.reverts('state must be ACTIVE'):
    utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  with brownie.reverts('state must be ACTIVE'):
    utils.withdraw(depositor, flow)
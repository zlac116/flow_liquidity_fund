from brownie import Flow, UsdCircleToken, DaiToken, UsdTetherToken, accounts, chain, interface
import pytest, brownie
from test_utils import utils
from math import ceil

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
    accounts[1:4],
    accounts[7:9],
    [mUSDC.address, mDAI.address]
  )
  mUSDC.transfer(flow.address, REWARDS_CONTRACT_DEPOSIT, {'from': accounts[0]})
  mDAI.transfer(flow.address, REWARDS_CONTRACT_DEPOSIT, {'from': accounts[0]})
  return flow

@pytest.fixture(autouse=True)
def isolation(fn_isolation):
  pass

def test_constructor(flow, mUSDC, mDAI):
  chain.mine()
  now = chain.time()
  flow_admins = accounts[1:4]
  withdrawal_addr = accounts[7:9]
  permitted_stables = [mUSDC.address, mDAI.address]
  assert flow.quorum() == QUORUM
  assert abs(flow.deadline() - (now + START_SECS + TENOR_SECS)) <= 1
  assert all([True for i in range(len(flow_admins)) if flow.flowAdmins(i) in flow_admins])
  # assert all([True for i in flow_admins if flow.flowAdminsMap(i)])
  assert all([True for i in range(len(withdrawal_addr)) if flow.flowWithdrawalAddresses(i) in withdrawal_addr])
  assert all([True for i in range(len(permitted_stables)) if flow.permittedStablecoins(i) in permitted_stables])
  assert brownie.web3.isAddress(flow.flowReceiptToken())

#***********************Investor Deposit***********************

# should deposit to smart contract
def test_deposit(flow, mUSDC):
  depositor = accounts[0]
  init_balance = mUSDC.balanceOf(depositor)
  mUSDC.approve(flow.address, DEPOSIT_AMT, {'from': depositor})
  txn = flow.deposit(mUSDC.address, DEPOSIT_AMT, {'from': depositor})
  end_balance = mUSDC.balanceOf(depositor)

  assert flow.investorStake(mUSDC.address, depositor.address) == DEPOSIT_AMT
  assert flow.isInvesting(mUSDC.address, depositor.address) == True
  assert flow.hasInvested(mUSDC.address, depositor.address) == True
  assert mUSDC.balanceOf(flow.address) == DEPOSIT_AMT + REWARDS_CONTRACT_DEPOSIT
  assert flow.availableFunds(mUSDC.address) == DEPOSIT_AMT
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

#***********************Investor Withdrawal***********************

# should withdraw entire investor balance
def test_withdraw(flow, mUSDC):
  depositor = accounts[0]
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  utils.chain_sleep(START_SECS + TENOR_SECS)
  utils.approve(utils.flow_receipt_token(flow), flow.address, DEPOSIT_AMT, depositor)
  init_balance_stable = mUSDC.balanceOf(depositor)
  init_balance_flow_receipt = utils.flow_receipt_token(flow).balanceOf(depositor)
  txn = flow.withdraw(mUSDC.address, {'from': depositor})
  end_balance_stable = mUSDC.balanceOf(depositor)
  end_balance_flow_receipt = utils.flow_receipt_token(flow).balanceOf(depositor)
  
  assert (end_balance_stable - init_balance_stable) / 1e18 == (DEPOSIT_AMT + REWARDS) / 1e18
  assert end_balance_flow_receipt == 0
  assert (init_balance_flow_receipt - end_balance_flow_receipt) == DEPOSIT_AMT
  assert flow.investorStake(mUSDC.address, depositor.address) == 0
  assert flow.isInvesting(mUSDC.address, depositor.address) == False
  assert flow.hasInvested(mUSDC.address, depositor.address) == True
  assert flow.availableFunds(mUSDC.address) == 0
  assert utils.flow_receipt_token(flow).totalSupply() == 0
  assert txn.events['TokenBurnt']['to'] == depositor
  assert txn.events['TokenBurnt']['amt'] == DEPOSIT_AMT

# should not withdraw if deadline not reached
def test_withdraw_deadline_not_reached(flow, mUSDC):
  depositor = accounts[0]
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  utils.chain_sleep(TENOR_SECS - 5)
  utils.approve(utils.flow_receipt_token(flow), flow.address, DEPOSIT_AMT, depositor)
  with brownie.reverts('deadline has not been reached'):
    flow.withdraw(mUSDC.address, {'from': depositor})

# should not withdraw if investor does not have suffcient stables invested
def test_withdraw_balance_insufficient(flow, mUSDC):
  depositor = accounts[0]
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  utils.chain_sleep(START_SECS + TENOR_SECS)
  utils.approve(utils.flow_receipt_token(flow), flow.address, DEPOSIT_AMT, depositor)
  flow.withdraw(mUSDC.address, {'from': depositor})
  with brownie.reverts('insufficient investor balance'):
    flow.withdraw(mUSDC.address, {'from': depositor})

#***********************Create Transfer (Flow)***********************

# should create flow multisig transfer
def test_create_transfer(flow, mUSDC):
  depositor = accounts[0]
  bank = accounts[7]
  admin = accounts[1]
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  flow.flowCreateTransfer(WITHDRAW_AMT, bank, mUSDC.address, {'from': admin})

  assert flow.flowTransfers(0)[0] == 0
  assert flow.flowTransfers(0)[1] == WITHDRAW_AMT
  assert flow.flowTransfers(0)[2] == mUSDC.address
  assert flow.flowTransfers(0)[3] == bank.address
  assert flow.flowTransfers(0)[4] == 0
  assert flow.flowTransfers(0)[5] == False
  assert flow.nextId() == 1

# should not create transfer if stabelcoin is not permitted
def test_create_transfer_stable_not_permitted(flow, mUSDC, mUSDT):
  depositor = accounts[0]
  bank = accounts[7]
  admin = accounts[1] # admin
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  with brownie.reverts('only permitted stablecoins'):
    flow.flowCreateTransfer(WITHDRAW_AMT, bank, mUSDT.address, {'from': admin})

# should not create transfer if not admin
def test_create_transfer_not_admin(flow, mUSDC):
  depositor = accounts[0]
  bank = accounts[7]
  admin = accounts[4] # not admin
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  with brownie.reverts('only flow admins allowed'):
    flow.flowCreateTransfer(WITHDRAW_AMT, bank, mUSDC.address, {'from': admin})

# should not create transfer if stablecoin balance insufficient
def test_create_transfer_insufficient_balance(flow, mUSDC, mDAI):
  depositor = accounts[0]
  bank = accounts[7]
  admin = accounts[1] # admin
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  with brownie.reverts('insufficent stablecoin balance'):
    flow.flowCreateTransfer(WITHDRAW_AMT, bank, mDAI.address, {'from': admin})

#***********************Transfer (Flow)***********************

# should transfer stablecoins to stored address if admin
def test_flow_transfer_to(flow, mUSDC):
  depositor = accounts[0]
  bank = accounts[7]
  admin_1 = accounts[1]
  admin_2 = accounts[2]
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  init_balance = mUSDC.balanceOf(bank)
  flow.flowCreateTransfer(WITHDRAW_AMT, bank, mUSDC.address, {'from': admin_1})
  flow.flowTransferTo(0, {'from': admin_1})
  txn = flow.flowTransferTo(0, {'from': admin_2})
  end_balance = mUSDC.balanceOf(bank)

  assert mUSDC.balanceOf(flow.address) == DEPOSIT_AMT - WITHDRAW_AMT + REWARDS_CONTRACT_DEPOSIT
  assert (end_balance - init_balance) == WITHDRAW_AMT
  assert flow.flowActivity(mUSDC.address) == WITHDRAW_AMT
  assert flow.availableFunds(mUSDC.address) == DEPOSIT_AMT - WITHDRAW_AMT
  assert txn.events['Withdrawal']['to'] == bank
  assert txn.events['Withdrawal']['amt'] == WITHDRAW_AMT

# should not transfer stablecoins to stored address if not admin
def test_flow_transfer_to_not_admin(flow, mUSDC):
  depositor = accounts[0]
  bank = accounts[7]
  admin_1 = accounts[1] # admin
  admin_2 = accounts[4] # not admin
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  flow.flowCreateTransfer(WITHDRAW_AMT, bank, mUSDC.address, {'from': admin_1})
  flow.flowTransferTo(0, {'from': admin_1})
  with brownie.reverts('only flow admins allowed'):
    flow.flowTransferTo(0, {'from': admin_2})

# # should not withdraw stablecoins to stored address if not permitted
# def test_flow_transfer_to_stable_not_permitted(flow, mUSDC, mUSDT):
#   depositor = accounts[0]
#   bank = accounts[7]
#   admin = accounts[1]
#   deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
#   with brownie.reverts('only permitted stablecoins'):
#     flow.adminWithdrawTo(mUSDT.address, bank, WITHDRAW_AMT, {'from': admin})

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
    utils.withdraw(depositor, mUSDC, flow)

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
  rewards = utils.rewards(DEPOSIT_AMT, RATE_BPS / 10000, TENOR_SECS / YEAR_SECS)

  assert flow.state() == 0 # state = ACTIVE
  utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
  assert flow.investorStake(mUSDC, depositor) == DEPOSIT_AMT
  assert mUSDC.balanceOf(flow.address) == DEPOSIT_AMT + REWARDS_CONTRACT_DEPOSIT
  utils.chain_sleep(START_SECS + TENOR_SECS)
  utils.withdraw(depositor, mUSDC, flow)
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
    utils.withdraw(depositor, mUSDC, flow)

#***********************Accrued Interest***********************

# should return accrued interest rate
# def test_get_accrued_interest(flow, mUSDC):
#   depositor = accounts[0]
#   utils.deposit(depositor, mUSDC, DEPOSIT_AMT, flow)
#   utils.chain_sleep(int(MATURITY_SECS))
#   return_ = flow.getAccruedInterest(mUSDC.address, {'from': depositor})

#   assert ceil(return_ / 1e18) == ceil(DEPOSIT_AMT * (RATE_BPS / 10000) * MATURITY_SECS / YEAR_SECS / 1e18)
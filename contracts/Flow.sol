pragma solidity ^0.8.11;

import "../interfaces/IERC20.sol";
import "./FlowReceiptToken.sol";
import "./utils/SafeMath.sol";

contract Flow {
  using SafeMath for uint;
  // State Machine
  enum State {
    ACTIVE, // deposits and withdrawals allowed
    INACTIVE // deposits and withdrawals not allowed
  }
  State public state = State.ACTIVE;

  // Fund
  uint public deadline;
  uint public rate = 5000; // in % bp
  uint constant secondsInYear = 365 * 24 * 60 * 60;
  uint public start;
  address[] public permittedStablecoins;
  FlowReceiptToken public flowReceiptToken;
  
  // struct Share {
  //   uint amount;
  //   address investor;
  //   address stable;
  // }
  // Investors
  address[] public investors;
  mapping (address => mapping (address => bool)) public hasInvested;
  mapping (address => mapping (address => bool)) public isInvesting;
  mapping (address => mapping (address => uint)) public investorStake;
  uint public availableFunds;

  // Multi-sig
  uint public quorum;
  struct Transfer {
    uint id;
    uint amount;
    address stablecoin;
    address payable to;
    uint approvals;
    bool sent;
  }
  mapping(uint => Transfer) public flowTransfers;
  address[] public flowAdmins; // approvers
  mapping (address => mapping (uint => bool)) public approvals;
  address[] public flowWithdrawalAddresses;
  uint public nextId;

  // mapping (address => bool) public flowAdminsMap;
  mapping (address => mapping (address => uint)) public flowWithdrawals;

  // Events
  event TokenMinted (
    address to,
    uint amt
  );
  event TokenBurnt (
    address to,
    uint amt
  );
  event Withdrawal (
    address to,
    uint amt 
  );
  event Debug (
    uint amt
  );

  constructor (
    uint _quorum,
    uint maturity,
    address[] memory _flowAdmins,
    address[] memory _flowWithdrawalAddresses, 
    address[] memory _permittedStablecoins)
    {
      require (_flowAdmins.length <= 4, "maximum 4 admins");
      require (_flowAdmins.length >= 2, "minimum 2 admins");
      require (_quorum >= 2, "minimum quorum 2");
      require (_quorum <= 3, "maximum quorum 3");
      require(maturity > 0, "maturity must be greater than 0");
      require(_quorum < _flowAdmins.length, "quorum must be less than number of flow admins");
      require(_flowWithdrawalAddresses.length == 2, "must have 2 withdrawal addresses");
      // require that stablecoins are not address(0)
      quorum = _quorum;
      start = block.timestamp;
      deadline = start + maturity * 24 * 60 * 60;
      flowAdmins = _flowAdmins;
      // _initFlowAdmins(_flowAdmins);
      flowWithdrawalAddresses = _flowWithdrawalAddresses;
      permittedStablecoins = _permittedStablecoins;
      FlowReceiptToken _flowReceiptToken = new FlowReceiptToken();
      flowReceiptToken = _flowReceiptToken;
  }

  modifier flowAdminOnly () {
    bool allowed = false;
    for (uint i = 0; i < flowAdmins.length; i++) {
      if (flowAdmins[i] == msg.sender) {
        allowed = true;
      }
    }
    require(allowed, 'only flow admins allowed');
    _;
  }

  modifier permittedStablecoinsOnly (address _stablecoin) {
    bool isStablePermitted = false;
    for (uint i = 0; i < permittedStablecoins.length; i++) {
      if (_stablecoin == permittedStablecoins[i]) {
        isStablePermitted = true;
      }
    }
    require(isStablePermitted, "only permitted stablecoins");
    _;
  }

  // function _initFlowAdmins(address[] memory _flowAdmins) internal {
  //   for (uint i = 0; i < _flowAdmins.length; i++) {
  //     flowAdminsMap[_flowAdmins[i]] = true;
  //   }
  // }

  // 1. Deposit Stables (Investor)

  function deposit(address _stablecoin, uint _amount) permittedStablecoinsOnly(_stablecoin) public {
    // Require State Active
    require(state == State.ACTIVE);
    // Require deadline passed
    require(block.timestamp < deadline, "deadline passed");
    require(_amount > 0, "amount cannot be 0");

    require(IERC20(_stablecoin).balanceOf(msg.sender) >= _amount, "insuffcient stablecoin balance");

    // Transfer stablecoin to this contract  
    IERC20(_stablecoin).transferFrom(msg.sender, address(this), _amount);

    // Update invested balance
    investorStake[_stablecoin][msg.sender] += _amount;
    // Update available funds
    availableFunds += _amount;

    // Add user to investors array *only* if they haven't invested before
    if (!hasInvested[_stablecoin][msg.sender]) {
      investors.push(msg.sender);
    }

    // Update investing status
    isInvesting[_stablecoin][msg.sender] = true;
    hasInvested[_stablecoin][msg.sender] = true;

    // Mint receipt token
    flowReceiptToken.mint(msg.sender, _amount);

    emit TokenMinted(msg.sender, _amount);
  }

  // 2. Withdraw Stables (Investor)
  
  function withdraw(address _stablecoin, uint _amount) public {
    // Require State Active
    require(state == State.ACTIVE);
    // Require deadline passed
    require(block.timestamp >= deadline, "deadline has not been reached");

    // Fetch investing balance
    uint balance = investorStake[_stablecoin][msg.sender];

    // Require amount greater than 0
    require(balance >= _amount, "insufficient investor balance");

    // transfer stablecoin
    IERC20(_stablecoin).transfer(msg.sender, _amount);

    // Update investor stake
    investorStake[_stablecoin][msg.sender] -= _amount;
    // Update available funds
    availableFunds -= _amount;

    // Burn receipt token
    flowReceiptToken.burn(msg.sender, _amount);

    emit TokenBurnt(msg.sender, _amount);

    // Update investing status
    if (investorStake[_stablecoin][msg.sender] == 0) {
      isInvesting[_stablecoin][msg.sender] = false;
    }

  }

    // 3a. Create Flow Admin Transfer
  function flowCreateTransfer(
    uint _amount,
    address payable _to,
    address _stablecoin)
    external permittedStablecoinsOnly(_stablecoin) flowAdminOnly() {
      // Require State Active
      require(state == State.ACTIVE);
      // Require address is listed
      bool isWithdrawAddress = false;
      for (uint i = 0; i < flowWithdrawalAddresses.length; i++) {
        if (_to == flowWithdrawalAddresses[i]) {
          isWithdrawAddress = true;
        }
      }
      require(isWithdrawAddress == true, "withdrawal address is not listed");
      // Require balance is greater than amount
      IERC20 stablecoin = IERC20(_stablecoin);
      require(stablecoin.balanceOf(address(this)) > _amount, "insufficent stablecoin balance");
      flowTransfers[nextId] = Transfer(
        nextId,
        _amount,
        _stablecoin,
        _to,
        0,
        false
      );
      nextId ++;
  }

  // 3b. Send Flow Transfer
  function flowTransferTo(uint id) flowAdminOnly() external {
    // Require State Active
    require(state == State.ACTIVE);
    // require transfer has not been sent
    require(flowTransfers[id].sent == false, 'transfer has already been sent');

    if (approvals[msg.sender][id] == false) {
      approvals[msg.sender][id] = true;
      flowTransfers[id].approvals++;
    }
    // check sufficent approvals received
    if (flowTransfers[id].approvals >= quorum) {
      flowTransfers[id].sent = true;
      address payable to = flowTransfers[id].to;
      uint amount = flowTransfers[id].amount;

      IERC20 stablecoin = IERC20(flowTransfers[id].stablecoin);
      stablecoin.transfer(to, amount); // make transfer

      flowWithdrawals[address(stablecoin)][to] += amount; // update total flow withdrawals

      availableFunds -= amount; // Update available funds
      emit Withdrawal(to, amount);

      return;
    }
    // transfer stablecoin to permitted address
    // stablecoin.transfer(_to, _amount);

    // // update total flow withdrawals
    // flowWithdrawals[_stablecoin][_to] += _amount;

    // // Update available funds
    // availableFunds -= _amount;

    // emit Withdrawal(_to, _amount);

  }

  // 4a. Bank Deposit

  // receive() payable public {
  //   availableFunds += 
  // }

  // 4. Get Accured Interest
  function getAccruedInterest(address _stablecoin) external view returns(uint accrued) {
    require(isInvesting[_stablecoin][msg.sender] == true, "investors only");
    uint balance = investorStake[_stablecoin][msg.sender];
    
    uint duration = deadline.sub(start);
    uint durationBasis = duration.mul(100 * 100).div(secondsInYear); // in % bp

    uint timePassed = block.timestamp.sub(start);
    uint timePassedBasis = timePassed.mul(100 * 100).div(secondsInYear); // in % bp

    uint durationReturn = rate.mul(balance).mul(durationBasis).div(100 * 100 * 100 * 100); // in % bp
    uint timePassedReturn = rate.mul(balance).mul(timePassedBasis).div(100 * 100 * 100 * 100); // in % bp

    accrued = block.timestamp >= deadline ? durationReturn : timePassedReturn;

    return accrued;
  }

  // 5. Emergency STOP
  function flowStop() flowAdminOnly() external {
    require(state != State.INACTIVE, "state must be ACTIVE");
    state = State.INACTIVE;
  }
  
  // 5. Emergency START
  function flowRestart() flowAdminOnly() external {
    require(state != State.ACTIVE, "state must be INACTIVE");
    state = State.ACTIVE;
  }

}
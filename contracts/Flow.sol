pragma solidity ^0.8.11;

// import "./utils/SafeMath.sol";
// import "./ERC20.sol";
// import "./utils/Ownable.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract FlowReceiptToken is ERC20, Ownable {

  constructor () ERC20 ("Flow Receipt Token", "FRT") {}

  function mint(address to, uint amount) onlyOwner() external {
    _mint(to, amount);
  }

  function burn(address from, uint amount) onlyOwner() external {
    _burn(from, amount);
  }
}

contract Flow {
  using SafeMath for uint;
  // State Machine
  enum State {
    ACTIVE, // deposits and withdrawals allowed
    INACTIVE // deposits and withdrawals not allowed
  }
  State public state = State.ACTIVE;

  // Fund
  uint public start;
  uint public deadline;
  uint public duration;
  uint public rate; // in % bp
  uint public constant daysToSeconds = 24 * 60 * 60; 
  uint public constant secondsInYear = 365 * daysToSeconds;
  address[] public permittedStablecoins;
  FlowReceiptToken public flowReceiptToken;
  address public flowReceiptTokenAddress;
  
  struct Stake {
    uint id;
    uint amount;
    address stablecoin;
    uint timestamp;
    bool isDeposit;
  }
  // Investors
  address[] public investors;
  mapping (address => mapping (address => bool)) public hasInvested;
  mapping (address => mapping (address => bool)) public isInvesting;
  mapping (address => mapping (address => uint)) public investorStake;
  mapping (address => Stake) public investorStakeRecord;
  mapping(address => uint) public availableFunds;
  uint public nextStakeId;

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
  mapping (address => uint) public flowActivity;

  // Flow Stop multi-sig
  struct Stop {
      uint id;
      uint approvals;
      bool stopped;
  }
  mapping (uint => Stop) public flowStop;
  mapping (address => mapping (uint => bool)) public stopApprovals;
  uint public stopNextId;

  // Flow Start multi-sig
  struct Start {
      uint id;
      uint approvals;
      bool started;
  }
  mapping (uint => Start) public flowStart;
  mapping (address => mapping (uint => bool)) public startApprovals;
  uint public startNextId;

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
    uint _start,
    uint tenor,
    uint _rate,
    address[] memory _flowAdmins,
    address[] memory _flowWithdrawalAddresses, 
    address[] memory _permittedStablecoins)
    {
      require (_flowAdmins.length <= 4, "maximum 4 admins");
      require (_flowAdmins.length >= 2, "minimum 2 admins");
      require (_quorum >= 2, "minimum quorum 2");
      require (_quorum <= 3, "maximum quorum 3");
      require(tenor > 0, "tenor must be greater than 0");
      require(_rate > 500, "minimum rate is 5%");
      require(_quorum < _flowAdmins.length, "quorum must be less than number of flow admins");
      require(_flowWithdrawalAddresses.length == 2, "must have 2 withdrawal addresses");
      bool isStablecoinZeroAddr = false;
      for (uint i = 0; i < _permittedStablecoins.length; i++) {
        if (address(_permittedStablecoins[i]) == address(0)) {
            isStablecoinZeroAddr = true;
        }
      }
      // require that stablecoins are not address(0)
      require(!isStablecoinZeroAddr, "permitted stablecoin cannot be the zero address");
      quorum = _quorum;
      start = block.timestamp + _start.mul(daysToSeconds); // fund start in unix time
      deadline = start + tenor.mul(daysToSeconds); // fund end in unix time
      duration = deadline.sub(start); // in secs
      rate = _rate; // interest in bps
      flowAdmins = _flowAdmins;
      // _initFlowAdmins(_flowAdmins);
      flowWithdrawalAddresses = _flowWithdrawalAddresses;
      permittedStablecoins = _permittedStablecoins;
      FlowReceiptToken _flowReceiptToken = new FlowReceiptToken();
      flowReceiptToken = _flowReceiptToken;
      flowReceiptTokenAddress = address(flowReceiptToken);
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
    require(state == State.ACTIVE, "state must be ACTIVE");
    // Require before start
    require(block.timestamp < start, "fund start passed");
    // Require deadline passed
    // require(block.timestamp < deadline, "deadline passed");
    require(_amount > 0, "amount cannot be 0");

    require(IERC20(_stablecoin).balanceOf(msg.sender) >= _amount, "insuffcient stablecoin balance");

    // Transfer stablecoin to this contract  
    IERC20(_stablecoin).transferFrom(msg.sender, address(this), _amount);

    // Update invested balance
    investorStakeRecord[msg.sender] = Stake(
        nextStakeId,
        _amount,
        _stablecoin,
        block.timestamp,
        true
    );
    investorStake[_stablecoin][msg.sender] += _amount;
    nextStakeId++; // increment next stake id
    // Update available funds
    availableFunds[_stablecoin] += _amount;

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
  
  function withdraw(address _stablecoin) public {
    // Require State Active
    require(state == State.ACTIVE, "state must be ACTIVE");
    // Require deadline passed
    require(block.timestamp >= deadline, "deadline has not been reached");

    // Fetch investing balance
    uint balance = investorStake[_stablecoin][msg.sender];

    // Require amount greater than 0
    require(balance > 0, "insufficient investor balance");

    // transfer stablecoin
    IERC20(_stablecoin).transfer(msg.sender, balance + _getRewards(balance));

    // Update investor stake
    investorStakeRecord[msg.sender] = Stake(
        nextStakeId,
        balance,
        _stablecoin,
        block.timestamp,
        false
    );
    investorStake[_stablecoin][msg.sender] -= balance;
    nextStakeId ++; // increment next stake id
    // Update available funds
    availableFunds[_stablecoin] -= balance;

    // Burn receipt token
    flowReceiptToken.burn(msg.sender, balance);

    emit TokenBurnt(msg.sender, balance);

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
    //   require(state == State.ACTIVE);
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
    // require(state == State.ACTIVE);
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

      flowActivity[address(stablecoin)] += amount; // update total flow activity

      availableFunds[address(stablecoin)] -= amount; // Update available funds
      emit Withdrawal(to, amount);

      return;
    }
  }

  // 4. Flow Deposit

  function flowDeposit(uint _amount, address _stablecoin) 
    external permittedStablecoinsOnly(_stablecoin) flowAdminOnly() {
      // 
      require(_amount > 0, "amount cannot be 0");
      require(IERC20(_stablecoin).balanceOf(msg.sender) >= _amount, "insuffcient stablecoin balance");

      // Transfer stablecoin to this contract  
      IERC20(_stablecoin).transferFrom(msg.sender, address(this), _amount);
      
      flowActivity[_stablecoin] -= _amount; // Update total flow activity
      availableFunds[_stablecoin] += _amount; // Update available funds
      
  }

  // 5a. Emergency STOP

  function flowCreateStop() external flowAdminOnly() {
    // Require State is Active
    require(state == State.ACTIVE, "state must be ACTIVE");
    flowStop[stopNextId] = Stop(
      stopNextId,
      0,
      false
    );
    stopNextId ++;
  }

  function flowSetStop(uint id) flowAdminOnly() external {
    require(state == State.ACTIVE, "state must be ACTIVE");
    require(flowStop[id].stopped == false, 'state has aready been switched to INACTIVE');
    if (stopApprovals[msg.sender][id] == false) {
      stopApprovals[msg.sender][id] = true;
      flowStop[id].approvals++;
    }
    if (flowStop[id].approvals >= quorum) {
      flowStop[id].stopped = true;
      state = State.INACTIVE;
      return;
    }
  }
  
  // 5b. RESTART
  function flowCreateRestart() external flowAdminOnly() {
    // Require State is Inactive
    require(state == State.INACTIVE, "state must be INACTIVE");
    flowStart[startNextId] = Start(
      startNextId,
      0,
      false
    );
    startNextId ++;
  }

  function flowSetRestart(uint id) flowAdminOnly() external {
    require(state == State.INACTIVE, "state must be INACTIVE");
    require(flowStart[id].started == false, 'state has aready been switched to ACTIVE');
    if (startApprovals[msg.sender][id] == false) {
      startApprovals[msg.sender][id] = true;
      flowStart[id].approvals++;
    }
    if (flowStart[id].approvals >= quorum) {
      flowStart[id].started = true;
      state = State.ACTIVE;
      return;
    }
  }

  // 6. Get Accured Interest
  // function getAccruedInterest(address _stablecoin) external view returns(uint accrued) {
  //   require(isInvesting[_stablecoin][msg.sender] == true, "investors only");
  //   uint balance = investorStake[_stablecoin][msg.sender];
    
  //   uint duration = deadline.sub(start);
  //   uint durationBasis = duration.mul(100 * 100).div(secondsInYear); // in % bp

  //   uint timePassed = block.timestamp.sub(start);
  //   uint timePassedBasis = timePassed.mul(100 * 100).div(secondsInYear); // in % bp

  //   uint durationReturn = rate.mul(balance).mul(durationBasis).div(100 * 100 * 100 * 100); // in % bp
  //   uint timePassedReturn = rate.mul(balance).mul(timePassedBasis).div(100 * 100 * 100 * 100); // in % bp

  //   accrued = block.timestamp >= deadline ? durationReturn : timePassedReturn;

  //   return accrued;
  // }

  function _getRewards(uint balance) internal view returns(uint rewards) {
    // uint duration = deadline.sub(start);
    rewards = balance.mul(rate).div(10000).mul(duration).div(secondsInYear);
    return rewards;
  }

}
# Flow Bond

Overview of the Flow Bond smart contract functionalities.

* Comprised of 2 main smart contracts:
    * Master contract
    * Flow Bond token contract
* USDC deposits can strictly only be made within the deposits window before the fund start date/time (predefined at deployment)
* USDC withdrawals can strictly only be made after the maturity date/time and a the withdrawing address must have a Flow Bond token amount equivlent to the stablecoin withdrawal amount
* Multi-signature functionality has been added for all other withdrawals, with a quorum of 2 and 3 different approvers
* Multi-signature functionality also applies to the circuit breakers (kill/restart switch)
* Flow Bond token minting is owned by the Master contract and only occurs upon a deposit. Similarly, the Flow Bond token is burnt upon withdrawal of stablecoins after maturity

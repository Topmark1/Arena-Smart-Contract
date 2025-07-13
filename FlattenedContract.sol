// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20 ^0.8.28;

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

// lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

// lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol

// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/IERC1363.sol)

/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

// lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Variant of {safeTransfer} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Variant of {safeTransferFrom} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturnBool} that reverts if call fails to meet the requirements.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            // bubble errors
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silently catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return success && (returnSize == 0 ? address(token).code.length > 0 : returnValue == 1);
    }
}

// src/ArenaGround.sol

contract ArenaGround {
    /* 
    This is a Giveaway Contract that aims to gift out funds to users by joining arena and being alone inside the arena still the arena Lock time period expires
    Major functions:
    1. Deposit: for users to increase their icon value, icon value is used to enter arenas with as low as a cent worth of OP, this is just to prevent sybil attacks and ensure partcipants are actual users that need this giveaway and not bots
    2. withdraw: For users to withdraw thier funds while paying a little fragment as contract fee depending on public fee set by contract owner between 0% to 5%
    3. SetArena: This function is used by users to start an arena with the aim to remain alone there for a period of Lock time, this user stand the chance of owning as much as 90% of the contract reward or giveaway value
    4. JoinArena: This function sabotages a users chance of being a alone in their arena, and the joiner stand the chance of owning the fund used by all the users who are currently in that specific arena at the moment, The lock time reduces by half everytime a new user joins the arena
    */

    using SafeERC20 for IERC20;
    
    struct ArenaInfo {
        uint256 arenaAmount;
        uint256 currentArenaValue;
        uint256 creationTime;
        uint256 lockTimer;
        address iconInCharge;
        bool bigGiveAwayAim;
        string message; // emotional message to explain why you need the giveaway so that no one joins your arena
    }
  
    mapping(uint256 => ArenaInfo) public arena;
    uint256 public arenaCount;
    uint256 public currentArenaIdCap;
    address public arenaKingAddress;

    // to encourage creating an arena which earns reward if no icons join
    uint256 public small = 1e5; //0.1% default
    uint256 public big = 9e7; //90% default
    // from the last time anyone join or set arena it must cross 1000 seconds by all means
    uint256 public priceClaimDelay = 1000 seconds;
    // TODO: withdrawal fee percent 10**6 precision, fixed fee for now
    uint256 public accumulatedFee;
    uint256 public fee ;
    uint256 public fixedNonArenaJoinRewardCap;
    uint256 public launchTime;
    uint256 public minLockTimer;
    uint256 public minArenaAmount = 1e16;
   
    mapping(address => uint256) public iconValues;
    // to avoid frontrunning update when each icon calls it to ensure two icons cant call within same seconds or more
    // i.e if it is arena 1 the during creation update currentCall[1] = block.timestamp and validate before subsequent call to avoid time duplicate
    mapping(uint256 => uint256) public currentCall;
    address owner ;

    IERC20 public token;  // Optimism token (OP)
    

    constructor(
        uint256 _launchTime,
        address _tokenAddress
    ) {
        launchTime = _launchTime + block.timestamp;
        owner = msg.sender; //arenaKingAddress
        minLockTimer = 24 hours;
        token = IERC20(_tokenAddress);  // Set token address for Optimism (OP token)
    }
  
    function deposit( uint256 amount ) public payable {
      // Deposit OP (Optimism ERC-20 token)
        token.safeTransferFrom(msg.sender, address(this), amount);
        if(msg.sender == owner){
            fixedNonArenaJoinRewardCap += amount;
             return ;
        }
        iconValues[msg.sender] += amount;
    }
    function withdraw(uint256 amount, address recipient) public {
         //OP withdrawal
            if (recipient == address(0)) recipient = msg.sender ;
            if(msg.sender == owner){
            require(amount <= accumulatedFee + fixedNonArenaJoinRewardCap, "Owner cant Withdraw Users Fund");
                if( amount <= accumulatedFee){
                 accumulatedFee -= amount;
                }else{
                fixedNonArenaJoinRewardCap -= amount;
                }

            token.safeTransfer(recipient, amount); // Withdraw fee in OP token (ERC-20)
                if (address(this).balance > 0){ // to withdraw contract donations and accidental native tokens
                     (bool success, ) = recipient.call{value: address(this).balance}("");
                    require(success, "Transfer failed.");
                }
            return ;
            }
        // Ensure the sender has enough balance to withdraw
        require(iconValues[msg.sender] >= amount, "Insufficient balance");

        // Subtract the requested amount from sender's balance
        iconValues[msg.sender] -= amount;
        uint256 feeValue = fee * amount / 1e6 ;
        accumulatedFee += feeValue;

          if (amount > 0) {
            require(token.balanceOf(address(this)) >= (amount-feeValue), "Insufficient OP balance");
            token.safeTransfer(recipient, (amount-feeValue));
            }
    }

    /*
    *params 
    arenaAmout: the Amount used to to start arena and also determines the value needed by anyone that wants to join the arena
    LockTimer: the time period that arena setter must stay in the arena without having a new participant to have right to claim contract fund, the lowest possible is 24hours by default but subject to change depending on owner and contract economy
    bigGiveAwayAim: user can aim for a big contract reward of small if they remain alone in the contract
    _message :  Emotional message to explain why you need the giveaway so that no one joins your arena
    */
    function SetArena(
        uint256 arenaAmount,
        uint256 lockTimer,
        bool bigGiveAwayAim,
        string calldata _message
    ) public {
        require( arenaAmount >= minArenaAmount && lockTimer >= minLockTimer , "Invalid arenaAmount or lockTimer");
        require(bytes(_message).length <= 50, "Message too long");
        uint256 creationTime = block.timestamp;
        uint256 currentArenaValue = arenaAmount;
        address iconInCharge = msg.sender;
        
        iconValues[msg.sender] -= arenaAmount;
        
        uint256 dumbyArenaCount = 1;
        //to avoid arena id clash
        //look for the lowest available empty slot from 1
        while ( arena[dumbyArenaCount].arenaAmount != 0  ){
        dumbyArenaCount += 1;
        }
        arenaCount += 1;
        currentArenaIdCap = currentArenaIdCap < dumbyArenaCount? dumbyArenaCount: currentArenaIdCap;
        arena[dumbyArenaCount] =  ArenaInfo(
        arenaAmount,
        currentArenaValue,
        creationTime,
        lockTimer,
        iconInCharge,
        bigGiveAwayAim,
        _message
        );
        currentCall[dumbyArenaCount] = block.timestamp;
    }

    /// to participate in arrena and also used by winner to claim arena victory
    // Remain Alone in Your Arena to get contract win or be the last man standing and arena Owner to win!!!
    function JoinArena(
        uint256 arenaNumber, 
        uint amount,
        string calldata newMessage
        ) public {
        require(bytes(newMessage).length <= 50, "Message too long");
        
        ArenaInfo memory arenaToJoin = arena[arenaNumber];
        /// first check for pending Price to be claimed
        ///TODO: separate this part as a different function
        if (arenaToJoin.lockTimer == 0 || (block.timestamp - arenaToJoin.creationTime > arenaToJoin.lockTimer ) ){
            
            //to prevent flashloan Attack of claiming price automatically when it is claimable
            require ( block.timestamp - arenaToJoin.creationTime  > priceClaimDelay, "Cant Claim Price Yet"); 
            
            iconValues[msg.sender] += arenaToJoin.currentArenaValue; // claim price

            if (arenaToJoin.currentArenaValue == arenaToJoin.arenaAmount  ){
                uint256 reward; // to encourage creating an arena which earns reward if no icons join
                if (arenaToJoin.bigGiveAwayAim){ 
                reward = fixedNonArenaJoinRewardCap * big / 1e8;
                fixedNonArenaJoinRewardCap -= reward;
                iconValues[msg.sender] += reward; 
                }
                else{
                reward = fixedNonArenaJoinRewardCap * small / 1e8;
                fixedNonArenaJoinRewardCap -= reward;
                iconValues[msg.sender] += reward; 
                }
            }
            require ( msg.sender == arenaToJoin.iconInCharge , "Unauthroized Icon" );
            delete arena[arenaNumber]; /// delete arena after winning icon is settled 
            arenaCount -= 1; //update global count
            return ;
        }

        require (amount == arenaToJoin.arenaAmount , "Invalid arena Entry Amount");       

        uint256 newLockTimer  =  arenaToJoin.lockTimer/2;
        uint256 newCurrentArenaValue = arenaToJoin.currentArenaValue + amount;
        uint256 newCreationTimer = block.timestamp; 

        arena[arenaNumber] =  ArenaInfo(
        amount,
        newCurrentArenaValue,
        newCreationTimer,
        newLockTimer ,
        msg.sender ,
        arenaToJoin.bigGiveAwayAim,
        newMessage
        );

        iconValues[msg.sender] -= amount;
        //prevent multiple call at a goal to prevent attacker with mutiple entry
        require ( block.timestamp > currentCall[arenaNumber] , "multiple call in single Seconds");
        currentCall[arenaNumber] = block.timestamp;
    }

    function DonateToGiveAway(
        uint256 amount
        ) public {
        token.safeTransferFrom(msg.sender, address(this), amount);
        fixedNonArenaJoinRewardCap += amount;
    }

    ///// Views
    function checkArenaAffairs(
        uint256 arenaNumber
        ) public view returns (ArenaInfo memory) {
        return arena[arenaNumber];
    }
    function checkAllArenaAffairs() public view returns (ArenaInfo[] memory) {
            ArenaInfo[] memory arenas =  new ArenaInfo[](arenaCount+1); //plus 1 for validation purpose, the last array position must be empty
            uint256 j;
            for (uint256 i = 0; i <= currentArenaIdCap ; i++){
                if (arena[i].arenaAmount != 0)
                arenas[j++] = arena[i];
            }
            //uint256 arrayLength = arenas.length;
        return arenas ;
    }
    function checkUserBalance(
        address user
        ) public view returns (uint256) {
        return iconValues[user];
    }
       function ownerView() public view returns (address) {
        return owner;
    }

    /////Admin Setters 
    function setBigSmallRewardPercent(uint256 _big, uint256 _small ) external{
        require(owner == msg.sender, "Unauthorized Caller");
        require ( _big < 9e7 && small < 5e6, "GiveAwayReward Error");
        big = _big;
        small = _small;
    }
    function setPriceClaimDelay(uint256 _priceClaimDelay) external{
        require(owner == msg.sender, "Unauthorized Caller");
        priceClaimDelay = _priceClaimDelay;
    }
    function setFee(uint256 _newfee) external{
        require(owner == msg.sender, "Unauthorized Caller");
        require (_newfee <= 1e5,"Fee above 10%");
        fee = _newfee;
    }
    function setMinLockTimer(uint256 _newminLockTimer) external{
        require(owner == msg.sender, "Unauthorized Caller");
        minLockTimer = _newminLockTimer;
    }
    function setMinArenaAmount(uint256 _minArenaAmount) external{
        require(owner == msg.sender, "Unauthorized Caller");
        minArenaAmount = _minArenaAmount;
    }
    function activateWhitelist(address whitelist, uint256 value) public{
        require(owner == msg.sender, "Unauthorized Caller");
        require(block.timestamp < launchTime);
        iconValues[whitelist] = value; 
    }
    function setNewOwner(address _newOwner) external{
        require(owner == msg.sender, "Unauthorized Caller");
        owner = _newOwner;
    }
    receive() external payable{}
}


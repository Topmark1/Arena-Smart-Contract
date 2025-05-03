// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract ArenaGround {
    
    struct ArenaInfo {
        uint256 arenaAmount;
        uint256 currentArenaValue;
        uint256 creationTime;
        uint256 lockTimer;
        address iconInCharge;
    }
  
    mapping(uint256 => ArenaInfo) public arena;
    uint256 public arenaCount;
    address public arenaKingAddress;

    // to encourage creating an arena which earns reward if no icons join
    uint256 public fixedNonArenaJoinReward = 10000;
    // from the last time anyone join or set arena it must cross 1000 seconds by all means
    uint256 public priceClaimDelay = 1000 seconds;
    // TODO: withdrawal fee percent 10**6 precision, fixed fee for now
    uint256 public accumulatedFee;
    uint256 public fee ;
    uint256 public fixedNonArenaJoinRewardCap;
    uint256 public launchTime;
    uint256 public minLockTimer;
    uint256 public minArenaAmount = 1e15;
    uint256 private test = 777777;
  
    // test run at https://sepolia.etherscan.io/address/0xDE9C92bA7500B7ce214932dE47989CC9c858aaEa#readContract
    mapping(address => uint256) public iconValues;
    // to avoid frontrunning update when each icon calls it to ensure two icons cant call within same seconds or more
    // i.e if it is arena 1 the during creation update currentCall[1] = block.timestamp and validate before subsequent call to avoid time duplicate
    mapping(uint256 => uint256) public currentCall;
    address owner ;

    IERC20 public token;  // Optimism token (OP)
    // Chainlink Aggregator for ETH/OP price feed
    AggregatorV3Interface internal ethPriceFeed;
    AggregatorV3Interface internal opPriceFeed;
    bool allowNativeTransactions;

    constructor(
        uint256 _launchTime,
        address _tokenAddress,
        address _ethPriceFeed, 
        address _opPriceFeed
    ) {
        launchTime = _launchTime + block.timestamp;
        owner = msg.sender; //arenaKingAddress
        minLockTimer = 30 seconds;
        token = IERC20(_tokenAddress);  // Set token address for Optimism (OP token)
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
        opPriceFeed = AggregatorV3Interface(_opPriceFeed);
    }
  
    function deposit( uint256 amount ) public payable {
      if(msg.value > 0 && allowNativeTransactions){ //handle native deposit 
      uint256 OPamount = ethToOp(msg.value); //OP value of native deposit TODO
        if(msg.sender == owner){
            fixedNonArenaJoinRewardCap += OPamount;
             iconValues[address(this)] += OPamount;
             return ;
        }
        iconValues[msg.sender] += OPamount;
        iconValues[address(this)] += OPamount;
      }
      else{ //handle non native deposit 
      // Deposit OP (Optimism ERC-20 token)
        token.safeTransferFrom(msg.sender, address(this), amount);
        if(msg.sender == owner){
            fixedNonArenaJoinRewardCap += amount;
             iconValues[address(this)] += amount;
             return ;
        }
        iconValues[msg.sender] += amount;
        iconValues[address(this)] += amount;
      }
    }
    function withdraw(uint256 amount, address recipient,bool nativeWithdrawal) public {
        if(nativeWithdrawal && allowNativeTransactions){
        // convert the withdrawal value from OP to native
            if(msg.sender == owner){
            accumulatedFee -= amount;
            uint256 nativeValue = opToEth(amount) ;
            (bool success, ) = recipient.call{value: nativeValue}("");
            require(success, "Transfer failed");
            return ;
            }
        // Ensure the sender has enough balance to withdraw
        require(iconValues[msg.sender] >= amount, "Insufficient balance");

        // Subtract the requested amount from sender's balance
        iconValues[msg.sender] -= amount;
        uint256 feeValue = fee * amount / 1e6 ;
        iconValues[address(this)] -= (amount - feeValue);
        accumulatedFee += feeValue;

         // Send the requested native Value of amount of Ether to the sender
        uint256 nativeValue = opToEth(amount - feeValue) ;
        (bool success2, ) = recipient.call{value: nativeValue }("");
        require(success2, "Transfer failedd");
        }
        else{ //OP withdrawal
            if(msg.sender == owner){
            accumulatedFee -= amount;
            token.safeTransfer(recipient, amount); // Withdraw fee in OP token (ERC-20)
            return ;
            }
        // Ensure the sender has enough balance to withdraw
        require(iconValues[msg.sender] >= amount, "Insufficient balance");

        // Subtract the requested amount from sender's balance
        iconValues[msg.sender] -= amount;
        uint256 feeValue = fee * amount / 1e6 ;
        iconValues[address(this)] -= (amount - feeValue);
        accumulatedFee += feeValue;

          if (amount > 0) {
            require(token.balanceOf(address(this)) >= amount, "Insufficient OP balance");
            token.safeTransfer(recipient, amount);
            }
        }
    }

    function SetArena(
        uint256 arenaAmount,
        uint256 lockTimer 
    ) public {
        require( arenaAmount >= minArenaAmount && lockTimer > minLockTimer , "Invalid arenaAmount or lockTimer");
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
        arena[dumbyArenaCount] =  ArenaInfo(
        arenaAmount,
        currentArenaValue,
        creationTime,
        lockTimer,
        iconInCharge
        );
        currentCall[dumbyArenaCount] = block.timestamp;
    }

    /// to participate in arrena and also used by winner to claim arena victory
    // Remain Alone in Your Arena to get contract win or be the last man standing to win!!!
    function JoinArena(
        uint256 arenaNumber, 
        uint amount
        ) public {
        ArenaInfo memory arenaToJoin = arena[arenaNumber];
        /// first check for pending Price to be claimed
        ///TODO: separate this part as a different function
        if (arenaToJoin.lockTimer == 0 || (block.timestamp - arenaToJoin.creationTime > arenaToJoin.lockTimer ) ){
            
            //to prevent flashloan Attack of claiming price automatically when it is claimable
            require ( block.timestamp - arenaToJoin.creationTime  > priceClaimDelay ); 
            
            iconValues[msg.sender] += arenaToJoin.currentArenaValue; // claim price

            if (arenaToJoin.currentArenaValue == arenaToJoin.arenaAmount && fixedNonArenaJoinRewardCap >= fixedNonArenaJoinReward ){
                fixedNonArenaJoinRewardCap -= fixedNonArenaJoinReward;
                iconValues[msg.sender] += fixedNonArenaJoinReward; // to encourage creating an arena which earns reward if no icons join
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
        msg.sender
        );

        iconValues[msg.sender] -= amount;
        //prevent multiple call at a goal to prevent attacker with mutiple entry
        require ( block.timestamp > currentCall[arenaNumber] , "multiple call in single Seconds");
        currentCall[arenaNumber] = block.timestamp;

    }
    ///// Views
    function checkArenaAffairs(
        uint256 arenaNumber
        ) public view returns (ArenaInfo memory) {
        return arena[arenaNumber];
    }
       function ownerView() public view returns (address) {
        return owner;
    }
     // Convert ETH to OP value
    function ethToOp(uint256 ethAmount) public view returns (uint256) {
        // Fetch the ETH price in USD
        (,int ethPrice,,,) = ethPriceFeed.latestRoundData();

        // Fetch the OP price in USD
        (,int opPrice,,,) = opPriceFeed.latestRoundData();
        
        // Calculate the equivalent OP value based on ETH price in USD and OP price in USD
        require(ethPrice > 0 && opPrice > 0, "Invalid price data");

        // Perform the conversion (ethAmount * opPrice) / ethPrice
        return uint256((ethAmount * uint256(opPrice)) / uint256(ethPrice));
    }

    // Convert OP to ETH value
    function opToEth(uint256 opAmount) public view returns (uint256) {
        // Fetch the ETH price in USD
        (,int ethPrice,,,) = ethPriceFeed.latestRoundData();

        // Fetch the OP price in USD
        (,int opPrice,,,) = opPriceFeed.latestRoundData();
        
        // Calculate the equivalent ETH value based on OP price in USD and ETH price in USD
        require(ethPrice > 0 && opPrice > 0, "Invalid price data");

        // Perform the conversion (opAmount * ethPrice) / opPrice
        return uint256((opAmount * uint256(ethPrice)) / uint256(opPrice));
    }

    /////Admin Setters 
    function setFixedNonArenaJoinReward(uint256 _fixedNonArenaJoinReward) external{
        require(owner == msg.sender, "Unauthorized Caller");
        fixedNonArenaJoinReward = _fixedNonArenaJoinReward;
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
    function activateNativeTransactions(bool value) public{
        require(owner == msg.sender, "Unauthorized Caller");
        allowNativeTransactions = value; 
    }
    function setNewOwner(address _newOwner) external{
        require(owner == msg.sender, "Unauthorized Caller");
        owner = _newOwner;
    }
    receive() external payable{}
}

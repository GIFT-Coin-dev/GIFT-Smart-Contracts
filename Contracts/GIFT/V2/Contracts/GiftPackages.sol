 /*


           ██████████   ██   ████████   ██████████
           ██           ██   ██             ██
           ██           ██   ██             ██
           ██    ████   ██   ████████       ██
           ██      ██   ██   ██             ██
           ██████████   ██   ██             ██
           
         ███████████████████████████████████████████
         
                The gift that keeps on giving
           
*/

//SPDX-License-Identifier: MIT
//Author: Daniel Fong

pragma solidity >=0.6.0 <0.8.6;

import "https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter02.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/IERC20.sol"; 
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../Interfaces/IReferrals.sol";
import "../Interfaces/IGiftPackages.sol";

/*
A smart contract that handles decentralised referrals.
*/

contract GiftPackages is IGiftPackages, ReentrancyGuard, Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    //GIFT PACKAGES DATA
    
    struct Option {
        
        uint256 giftFee;
        uint256 redeemRefund;
        uint256 referralFee;
        uint256 gasTopUp;
        uint256 giftAmount;
        uint256 BnbCost;
        address[] tokens;
        uint256[] tokenWeights;
    } 
    
    struct giftSent {
        
        uint256 option;
        address payable sender;
        bytes32 hash;
        bool redeemed;

    }    
    
    giftSent[] private giftsSentArr;
    Option[] private OptionsArr;
    mapping(address => uint256[]) private addyToGiftsSent;
    
    uint256 redeemCounter;
    
    //ADDRESSES
    
    address payable private buybackAdmin;
    address payable private redeemer;
    
    IReferrals private referrals;
    IPancakeRouter02 private  _pancakeRouter;
    
    EnumerableSet.AddressSet managers;
    
    
    constructor(address payable _buybackAdmin, address payable _redeemer, address payable _pancakeRouterAddress, address payable _referralsAddress) {
        
        buybackAdmin = _buybackAdmin;
        redeemer = _redeemer;
        
        _pancakeRouter = IPancakeRouter02(_pancakeRouterAddress);
        referrals = IReferrals(_referralsAddress);
        
        redeemCounter = 0;
    }
    
    //ADMIN FUNCTIONS
    
    modifier onlyManager {
        require(EnumerableSet.contains(managers,msg.sender));
        _;
    }
    
    function addManager(address _manager) external override onlyOwner {
        EnumerableSet.add(managers, _manager);
    }
    
    function removeManager(address _manager) external override onlyOwner {
        EnumerableSet.remove(managers, _manager);
    }
    
    function changeBuybackAdmin(address payable _buybackAdmin) external override onlyOwner {
        buybackAdmin = _buybackAdmin;
    }
    
    function changeRedeemer(address payable _redeemer) external override onlyOwner {
        redeemer = _redeemer;
    }
    
    //PRODUCT CHOICE FUNCTIONS
    
    function addOption(uint256 _giftFee, uint256 _redeemRefund, uint256 _referralFee, uint256 _gasTopUp, uint256 _giftAmount, uint256 _bnbCost, address[] memory _tokens, uint256[] memory _tokenWeights) external override onlyManager {
        OptionsArr.push(Option(_giftFee, _redeemRefund, _referralFee, _gasTopUp, _giftAmount, _bnbCost, _tokens, _tokenWeights));
    }
    
    function changeOption(uint256 _giftFee, uint256 _referralFee, address[] memory _tokens, uint256[] memory _tokenWeights, uint256 _option) external override onlyManager {
        OptionsArr[_option].giftFee = _giftFee;
        OptionsArr[_option].referralFee = _referralFee;
        OptionsArr[_option].tokens = _tokens;
        OptionsArr[_option].tokenWeights = _tokenWeights;
    }
    
    //GIFTING
    
    function gift(uint256 _option, bytes32 _hash, uint256 _referralID) external override payable nonReentrant returns(uint256, uint256) {
        require(_option < OptionsArr.length, "NOT VALID OPTION");
        require(msg.value == OptionsArr[_option].BnbCost, "INCORRECT COST");
        
        giftsSentArr.push(giftSent(_option, payable(msg.sender), _hash, false));
        addyToGiftsSent[msg.sender].push(OptionsArr.length-1);
        
        buybackAdmin.transfer(OptionsArr[_option].giftFee);
       
        return(giftsSentArr.length-1, referrals.payReferrerAndRegister{value: OptionsArr[_option].referralFee}(_referralID));
        
    }
    
    function redeem(address payable _recipient, string memory _redemptionString, uint256 _giftID) external override nonReentrant{
        
        require(_giftID < giftsSentArr.length, "NOT VALID GIFT");
        require(giftsSentArr[_giftID].redeemed == false, "GIFT REDEEMED");
        require(keccak256(abi.encodePacked(_redemptionString)) == giftsSentArr[_giftID].hash, "WRONG REDEMPTION CODE");
                
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
                
        for(uint256 i = 0; i<OptionsArr[giftsSentArr[_giftID].option].tokens.length; i++) {
                
            path[1] = OptionsArr[giftsSentArr[_giftID].option].tokens[i];  //ChosenToken
            
            if (path[0] == path[1]) {
                _recipient.transfer(OptionsArr[giftsSentArr[_giftID].option].tokenWeights[i].mul(OptionsArr[giftsSentArr[_giftID].option].giftAmount).div(100));
            } else {
                _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: (OptionsArr[giftsSentArr[_giftID].option].tokenWeights[i].mul(OptionsArr[giftsSentArr[_giftID].option].giftAmount)).div(100)}(
                0,
                path,
                _recipient,
                block.timestamp+10
                );                
            }
                
                        
        }
        
        redeemer.transfer(OptionsArr[giftsSentArr[_giftID].option].redeemRefund);
        _recipient.transfer(OptionsArr[giftsSentArr[_giftID].option].gasTopUp);
        
        giftsSentArr[_giftID].redeemed = true;  
        redeemCounter++;
    }
    
    function recover(uint256 _giftID) external override nonReentrant{
        require(msg.sender == giftsSentArr[_giftID].sender, "NOT ORIGINAL SENDER");
        require(giftsSentArr[_giftID].redeemed == false, "ALREADY REDEEMED");
        
        payable(msg.sender).transfer(OptionsArr[giftsSentArr[_giftID].option].giftAmount.add(OptionsArr[giftsSentArr[_giftID].option].gasTopUp).add(OptionsArr[giftsSentArr[_giftID].option].redeemRefund));
        
        giftsSentArr[_giftID].redeemed = true;
    }
    
    //VIEWS
    
    function viewTotal() external override view returns(uint256) {
        return(giftsSentArr.length);
    }
    
    function viewGift(uint256 _giftID) external override view returns(uint256, bool) {
        return(giftsSentArr[_giftID].option, giftsSentArr[_giftID].redeemed);
    }
    
    function viewGiftIndexes(address _address) external override view returns(uint256[] memory) {
        return(addyToGiftsSent[_address]);
        
    }
    
    function viewOption(uint256 _option) external override view returns(uint256, uint256, uint256, uint256, uint256, address[] memory, uint256[] memory) {
        return(OptionsArr[_option].giftFee, OptionsArr[_option].referralFee, OptionsArr[_option].redeemRefund, OptionsArr[_option].gasTopUp, OptionsArr[_option].giftAmount, OptionsArr[_option].tokens, OptionsArr[_option].tokenWeights);
    }
    
    function viewOptionsLength() external override view returns(uint256) {
        return(OptionsArr.length);
        
    }
}
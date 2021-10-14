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

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Interfaces/IReferrals.sol";
/*
A smart contract that handles decentralised referrals.
*/
    

contract Referrals is IReferrals, ReentrancyGuard {

    using SafeMath for uint256;
    
    struct referrer {

        uint256 balance;
        uint256 totalEarned;
        uint256 referrals;
        uint256 referralSales;
    }    
    
    mapping(address => uint256) private refaddyToUID;
    mapping(address => uint256) private customerToReferrerUID;
    mapping(uint256 => referrer) private UIDToReferrer;
    
    uint256 private currentID;
    
    constructor(address _marketing) {
        currentID = 2;
        refaddyToUID[_marketing] = 1;
        UIDToReferrer[1] = referrer(0, 0, 0, 0);
    }
    
    function payReferrerAndRegister(uint256 _UID) external payable override returns(uint256){

        if(customerToReferrerUID[tx.origin]==0) {

            if(_UID == 0 || _UID >= currentID) {
                customerToReferrerUID[tx.origin] = 1;
            } else {
                customerToReferrerUID[tx.origin] = _UID;
            }
            UIDToReferrer[customerToReferrerUID[tx.origin]].referrals++;
        }
        
        UIDToReferrer[customerToReferrerUID[tx.origin]].referralSales++;
        UIDToReferrer[customerToReferrerUID[tx.origin]].balance = UIDToReferrer[customerToReferrerUID[tx.origin]].balance + msg.value;

        if (refaddyToUID[tx.origin] == 0) {

            return(registerReferrer());
            
        } else {

            return(refaddyToUID[tx.origin]);
        }
    }

    function payReferrer(uint256 _UID) external payable override {

        if(customerToReferrerUID[tx.origin]==0) {

            if(_UID == 0 || _UID >= currentID) {
                customerToReferrerUID[tx.origin] = 1;
            } else {
                customerToReferrerUID[tx.origin] = _UID;
            }
            UIDToReferrer[customerToReferrerUID[tx.origin]].referrals++;
        }
        
        UIDToReferrer[customerToReferrerUID[tx.origin]].referralSales++;
        UIDToReferrer[customerToReferrerUID[tx.origin]].balance = UIDToReferrer[customerToReferrerUID[tx.origin]].balance + msg.value;
    }    


    
    function registerReferrer() public returns (uint256) {
        
        require(refaddyToUID[tx.origin]==0, "ALREADY REGISTERED");
        refaddyToUID[tx.origin]=currentID;
        UIDToReferrer[currentID] = referrer(0,0,0,0);
        currentID++;
        return refaddyToUID[tx.origin];
        
    }
    
    function changeReferrerAddress(address payable _newAddress) external override  {
        require(refaddyToUID[msg.sender] != 0, "WRONG ADDRESS");
        require(refaddyToUID[_newAddress] == 0, "NEW ADDRESS TAKEN");

        refaddyToUID[_newAddress] = refaddyToUID[msg.sender];
        refaddyToUID[msg.sender] = 0;
    }
    
    function withdrawReferralFunds() external nonReentrant override {
        
        require(refaddyToUID[msg.sender] != 0, "INVALID ADDRESS");
        require(UIDToReferrer[refaddyToUID[msg.sender]].balance > 0, "BALANCE IS ZERO");
        payable(msg.sender).transfer(UIDToReferrer[refaddyToUID[msg.sender]].balance);
        UIDToReferrer[refaddyToUID[msg.sender]].totalEarned = UIDToReferrer[refaddyToUID[msg.sender]].totalEarned + UIDToReferrer[refaddyToUID[msg.sender]].balance;
        UIDToReferrer[refaddyToUID[msg.sender]].balance = 0;
         
    }
    
    //Returns data for referrer by address, if address in unregistered returns false
    function queryReferrerByAddress(address _referrer) external view override returns(uint256, uint256, uint256, uint256, uint256, bool) {
        if(refaddyToUID[_referrer] == 0) {
            return(0,0,0,0,0, false);
        } else {
            return(refaddyToUID[_referrer], UIDToReferrer[refaddyToUID[_referrer]].balance, UIDToReferrer[refaddyToUID[_referrer]].totalEarned, UIDToReferrer[refaddyToUID[_referrer]].referrals, UIDToReferrer[refaddyToUID[_referrer]].referralSales, true);

        }
        
    }    
    
}
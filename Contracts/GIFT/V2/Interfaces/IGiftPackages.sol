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

// SPDX-License-Identifier: MIT
// Author: Daniel Fong

pragma solidity >=0.6.0 <0.8.6;

/*
A smart contract interface to handle Gift Package. These packages allow the user to pay in the native chain token in order to
put a gift into escrow with a predefined purchase order for when the giftee redeems his gift.

The contract redeem function is only accessible through our server backend, this is due to how the redemption process
operates, neutralizing the threat of frontrunning for gift redemption.

Each gift has 4 Added costs:

- Gift Fee -> Forwarded to BuybackAdmin to buyback GIFT tokens
- Redeem Refund Fee -> Goes to our backend server to cover redemption costs
- Gas Top Up -> A small amount of native token balance is sent to the giftee in order to fund his initial transactions
- Referral Fee -> Forwarded to the referral contract for the product referrer

The GiftAmount indicates the amount of native token balance to be used to purchase the package on redemption.
Packages are stored as arrays of token addresses with matching weights set by the admin. These indicate to the tokens
that will be bought through DEX and their proportional weightings with regard to the giftAmount.

The Manager can add Gift Package options over time and modify some of the package features (except the redeem refund and gas topups). 

The Owner can add/remove Managers, change the BuybackAdmin and change the redeemer address.

*/


interface IGiftPackages {
    
    function addManager(address) external;
    function removeManager(address) external;
    
    function changeBuybackAdmin(address payable) external;
    function changeRedeemer(address payable) external;
    
    function addOption(uint256, uint256, uint256, uint256, uint256, uint256, address[] memory, uint256[] memory) external;
    function changeOption(uint256, uint256, address[] memory, uint256[] memory, uint256) external;
    
    function gift(uint256 , bytes32 , uint256 ) external payable returns(uint256, uint256);
    function redeem(address payable, string memory, uint256) external;
    function recover(uint256) external;
    
    function viewTotal() external view returns(uint256);
    function viewGift(uint256) external view returns(uint256, bool);
    function viewGiftIndexes(address) external view returns(uint256[] memory);
    
    function viewOption(uint256) external view returns(uint256, uint256, uint256, uint256, uint256, address[] memory, uint256[] memory);
    function viewOptionsLength() external view returns(uint256);
    
}
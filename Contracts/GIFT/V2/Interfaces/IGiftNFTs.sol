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
A smart contract interface to handle Gift NFTs. This allows users to gift NFTs through a decentralised protocol.

The contract redeem function is only accessible through our server backend, this is due to how the redemption process
operates, neutralizing the threat of frontrunning for gift redemption.

Each gift has 4 Added costs:

- Gift Fee -> Forwarded to BuybackAdmin to buyback GIFT tokens
- Redeem Refund Fee -> Goes to our backend server to cover redemption costs
- Gas Top Up -> A small amount of native token balance is sent to the giftee in order to fund his initial transactions
- Referral Fee -> Forwarded to the referral contract for the product referrer

*/


interface IGiftNFTs {
    
    function changeBuybackAdmin(address) external;
    function changeRedeemer(address) external;
    function changeNFTCosts(uint256, uint256) external;
    
    function giftNFT(bytes32, uint256, address, uint256) external payable returns(uint256, uint256);
    function redeemNFT(address payable, string memory, uint256) external;
    function recoverNFT(uint256) external;
    
    function viewTotalGiftedNFTs() external view returns(uint256);
    function viewGiftedNFT(uint256) external view returns(address, uint256, bool);
    function viewGiftedNFTIndexes(address) external view returns(uint256[] memory);
    function viewNFTGiftCosts() external view returns(uint256, uint256, uint256, uint256);
    
}
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
contract GameAward is Ownable {

    Game[] public games;
    Jury[] public juries;

    mapping(address => bool) public voters;

    struct GameCategory {
        string id;
        string categoryTitle;
        Game[] games;
    }

    struct Jury {
        string username;
        address walletAddress;
    }

    struct Game {
        string id;
        string name;
        string platform;
        string price;
        string description;
        string release;
        string url;
        address originUserAddress;
    }

    //function addGame(string name, string platform, string price, string description, string release, string url,
      //  address originUserAddress) public view returns (Game){
        //create the game
        //return game;
    //}

    //function hasVoted(address gameAddress) public view returns (bool){
        // check if voter has already voted
        //require(!voters[msg.sender], "Already voted");
        //todo check if game exists
        //adding vote
        //voters[msg.sender] = true;
        //return true;
    //}

    //function getWinner() public view returns (Game) {
      //  return null;
    //}

    //function vote(string id) {
        //check if user has already voted else add vote
        //check if vote comes from jury member to add more weight to the vote (still need to determine the amount)
    //}

    //function addJury(address juryCandidate) public onlyOwner {
        // check if can be judge ?? how to tho ?
   // }

   // function isAdmin() public returns(bool){
     //   if (onlyOwner){
      //      return true;
      //  }else{
       //     return false;
       // }

   // }
}
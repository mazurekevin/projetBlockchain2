pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract GameAward is Ownable {

struct Jury {
    string username;
    address walletAddress;
    string pictureUrl;
}

Jury[] public juries;

struct Game {
    uint id;
    string name;
    string platform;
    string price;
    string description;
    string release;
    string url;
    address originUserAddress;
    string pictureUrl;
}
uint public gameId = 1;
Game[] public games;

struct GameCategory {
    uint id;
    string categoryTitle;
    uint gameCount;
}

uint public gameCategoryId = 1;
mapping(uint => uint) categoryGames;
GameCategory[] public gameCategories;

mapping(address => bool) public juryMembers;
mapping(address => Jury) public juryMembersData;

function isOwner() public view returns (bool) {
    return owner() == msg.sender;
}

function addJuryMember(address addr) public onlyOwner {
    require(msg.sender == owner(), "Only the contract owner can add jury members.");
    require(!juryMembers[addr], "The address is already a jury member.");
    juryMembers[addr] = true;
    juryMembersData[msg.sender] = Jury("username", msg.sender, "pictureUrl");
}

function updateJuryMember(string memory _name, string memory _pictureUrl) public {
    require(juryMembers[msg.sender], "The address is not a jury member.");
    juryMembersData[msg.sender].username = _name;
    juryMembersData[msg.sender].pictureUrl = _pictureUrl;
}

function removeJuryMember(address addr) public onlyOwner {
    require(msg.sender == owner(), "Only the contract owner can remove jury members.");
    require(juryMembers[addr], "The address is not a jury member.");
    juryMembers[addr] = false;
    delete juryMembersData[addr];
}

function addGame(string memory _name, string memory _platform, string memory _price, string memory _description, string memory _release, string memory _url, string memory _pictureUrl) public {
    require(juryMembers[msg.sender], "Only jury members can add games.");
    games.push(Game(gameId, _name, _platform, _price, _description, _release, _url, msg.sender, _pictureUrl));
    gameId++;
}

function removeGame(uint _id) public {
    require(juryMembers[msg.sender], "Only jury members can remove games.");
    require(games[_id].originUserAddress == msg.sender, "Only the game owner can remove the game.");
    require(games[_id].id == _id, "The game does not exist.");
    delete games[_id];
}

function addGameCategory(string memory _categoryTitle) public onlyOwner {
    require(msg.sender == owner(), "Only the contract owner can add game categories.");
    gameCategories.push(GameCategory(gameCategoryId, _categoryTitle, 0));
    gameCategoryId++;
}

function removeGameCategory(uint _id) public onlyOwner {
    require(msg.sender == owner(), "Only the contract owner can remove game categories.");
    require(gameCategories[_id].id != 0, "The category does not exist.");
    for (uint i = 0; i < games.length; i++) {
        if(categoryGames[games[i].id] == _id) {
            delete categoryGames[games[i].id];
        }
    }
    delete gameCategories[_id];
}

function addGameInCategory(uint _gameId, uint _categoryId) public {
    require(juryMembers[msg.sender], "Only jury members can add games in categories.");
    require(gameCategories[_categoryId].id == _categoryId, "The category does not exist.");
    require(categoryGames[_gameId] == 0, "The game is already registered in this category.");
    categoryGames[_gameId] = _categoryId;
    gameCategories[_categoryId].gameCount++;
}

function removeGameInCategory(uint _gameId, uint _categoryId) public {
    require(juryMembers[msg.sender], "Only jury members can remove games in categories.");
    require(gameCategories[_categoryId].id == _categoryId, "The category does not exist.");
    require(categoryGames[_gameId] != 0, "The game is not registered in this category.");
    delete categoryGames[_gameId];
    gameCategories[_categoryId].gameCount--;
}

function getAllGames() public view returns (Game[] memory) {
    return games;
}

function getGamesByCategory(uint _categoryId) public view returns (Game[] memory) {
    Game[] memory gamesByCategory = new Game[](gameCategories[_categoryId].gameCount);
    uint counter = 0;
    for (uint i = 0; i < games.length; i++) {
        if(categoryGames[games[i].id] == _categoryId) {
            gamesByCategory[counter] = games[i];
            counter++;
        }
    }
    return gamesByCategory;
}

function getGameById(uint _gameId) public view returns (Game memory) {
    return games[_gameId];
}

function getJuries() public view returns (Jury[] memory) {
    return juries;
}

}

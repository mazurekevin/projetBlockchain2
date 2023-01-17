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

struct VoteSession {
    uint id;
    string sessionTitle;
    bool started;
    bool ended;
    uint rounds;
    uint currentRound;
    uint creationDate;
    uint startAt;
}

struct VoteSessionRound {
    uint id;
    uint roundNumber;
    uint[] availableGames;
    uint endedAt;
}

uint public voteSessionId = 1;
uint public roundId = 1;

VoteSession[] public voteSession;

mapping(uint => VoteSessionRound[]) voteSessionRounds;
mapping(uint => Vote[]) voteSessionRoundsVote;
mapping(uint => uint) voteScore;

struct Vote {
    address voter;
    uint gameId;
}

struct GameScore {
    Game game;
    uint score;
}

struct GameScoreRound {
    uint roundNumber;
    GameScore[] games;
}

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

function getAllGameIds(Game[] memory gameList) public view returns (uint[] memory) {
    uint[] memory gameIds = new uint[](gameList.length);
    for (uint i = 0; i < gameList.length; i++) {
        gameIds[i] = gameList[i].id;
    }
    return gameIds;
}

function createVoteSession(string memory _sessionTitle, uint _rounds) public onlyOwner {
    require(msg.sender == owner(), "Only the contract owner can create vote sessions.");
    require(_rounds > 0, "A vote need at least one round.");

    voteSessionRounds[voteSessionId].push(VoteSessionRound(roundId,1, getAllGameIds(games), 0));
    roundId++;
    voteSession.push(VoteSession(voteSessionId,_sessionTitle, false, false, _rounds, 1, block.timestamp, 0));
    voteSessionId++;
}

function passToNextRound(uint _voteSessionId) public onlyOwner {
    require(msg.sender == owner(), "Only the contract owner can pass to the next round.");
    require(!voteSession[_voteSessionId].ended, "The vote session is ended.");

    if(voteSession[_voteSessionId].currentRound == voteSession[_voteSessionId].rounds -1) {
        voteSession[_voteSessionId].ended = true;
        voteSessionRounds[_voteSessionId][voteSession[_voteSessionId].currentRound].endedAt = block.timestamp;
    } else {
        GameScore[] memory leadingGames = getCurrentRoundLeadingGames(_voteSessionId, voteSession[_voteSessionId].currentRound);
        Game[] memory nextRoundGames = new Game[](leadingGames.length);
        for (uint i = 0; i < leadingGames.length; i++) {
            nextRoundGames[i] = leadingGames[i].game;
        }
        voteSessionRounds[_voteSessionId][voteSession[_voteSessionId].currentRound].endedAt = block.timestamp;
        voteSession[_voteSessionId].currentRound++;
        voteSessionRounds[_voteSessionId].push(VoteSessionRound(roundId,voteSession[_voteSessionId].currentRound, getAllGameIds(nextRoundGames), 0));
        roundId++;
    }
}

function getCurrentRoundLeadingGames(uint _voteSessionId, uint round) public returns (GameScore[] memory) {
    uint leadingGamesRange = 1;
    if(round < voteSession[_voteSessionId].rounds - 1) {
        leadingGamesRange = (voteSession[_voteSessionId].rounds - round -1) * 3;
        if(voteSessionRounds[_voteSessionId][round].availableGames.length < leadingGamesRange){
            leadingGamesRange = voteSessionRounds[_voteSessionId][round].availableGames.length;
        }
    }
    Vote[] memory roundVotes = voteSessionRoundsVote[voteSessionRounds[_voteSessionId][round].id];
    uint[] memory availableGames = voteSessionRounds[_voteSessionId][round].availableGames;
    for (uint i = 0; i < availableGames.length; i++) {
        voteScore[availableGames[i]] = 0;
    }
    for(uint i = 0; i < roundVotes.length; i++) {
        if(juryMembers[roundVotes[i].voter]){
            voteScore[availableGames[i]] += 30;
        } else {
            voteScore[availableGames[i]] += 1;
        }
    }

    uint score = 0;
    uint game = 0;
    uint index = 0;
    GameScore[] memory leadingGames = new GameScore[](leadingGamesRange);
    for(uint i = 0; i < leadingGamesRange; i++) {
        for (uint j = 0; j < availableGames.length; j++) {
            if(voteScore[availableGames[j]] > score) {
                score = voteScore[availableGames[j]];
                game = availableGames[j];
                index = j;
            }
        }
        leadingGames[i] = GameScore(games[game], score);
        delete availableGames[index];
        score = 0;
        game = 0;
        index = 0;
    }
    return leadingGames;
}

function getCurrentRoundVoteGameId(uint _voteSessionId, address _userAddress) public view returns (uint) {
    Vote[] memory roundVotes = voteSessionRoundsVote[voteSessionRounds[_voteSessionId][voteSession[_voteSessionId].currentRound].id];
    for(uint i = 0; i < roundVotes.length; i++) {
        if(roundVotes[i].voter == _userAddress) {
            return roundVotes[i].gameId;
        }
    }
    return 0;
}

function hasVotedThisTurn(uint _voteSessionId, address _userAddress) public view returns (bool) {
    if(getCurrentRoundVoteGameId(_voteSessionId, _userAddress) != 0) {
        return true;
    }
    return false;
}

function vote(uint _voteSessionId, uint _gameId) public {
    require(voteSession[_voteSessionId].started, "The vote session is not started.");
    require(!voteSession[_voteSessionId].ended, "The vote session is ended.");
    require(voteSessionRounds[_voteSessionId][voteSession[_voteSessionId].currentRound].availableGames.length > 0, "The vote session is ended.");
    require(voteSessionRounds[_voteSessionId][voteSession[_voteSessionId].currentRound].availableGames[_gameId] != 0, "The game is not available for this round.");
    require(hasVotedThisTurn(_voteSessionId, msg.sender), "You have already voted this turn.");
    voteSessionRoundsVote[voteSessionRounds[_voteSessionId][voteSession[_voteSessionId].currentRound].id].push(Vote(msg.sender, _gameId));
}

function getVoteRoundGameIds(uint _voteSessionId) public view returns (uint) {
    return getCurrentRoundVoteGameId(_voteSessionId, msg.sender);
}

function getGameWinner(uint _voteSessionId) public returns (Game memory) {
    require(voteSession[_voteSessionId].ended, "The vote session is not ended.");
    return getCurrentRoundLeadingGames(_voteSessionId, voteSession[_voteSessionId].currentRound)[0].game;
}

function getRoundResults(uint _voteSessionId) public returns (GameScoreRound[] memory) {
    require(voteSession[_voteSessionId].ended, "The vote session is not ended.");

    GameScoreRound[] memory results = new GameScoreRound[](voteSession[_voteSessionId].rounds);
    for(uint i = 0; i < voteSession[_voteSessionId].rounds; i++) {
        results[i] = GameScoreRound(i, getCurrentRoundLeadingGames(_voteSessionId, i + 1));
    }
    return results;
}
}

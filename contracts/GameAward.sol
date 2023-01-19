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
    mapping(address => bool) public juryMembers;
    mapping(address => Jury) public juryMembersData;

    struct Game {
        uint id;
        string name;
        string platform;
        string price;
        string description;
        string release;
        string url;
        address originUserAddress;
    }

    uint public gameId;
    Game[] public games;
    uint[] public sessionsIds;

    struct VoteSession {
        uint id;
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

    struct Vote {
        address voter;
        uint gameId;
    }

    mapping(uint => VoteSession) public voteSessions;
    mapping(uint => VoteSessionRound[]) voteSessionRounds;
    mapping(uint => Vote[]) voteSessionRoundVotes;
    uint public roundSessionNumber;
    uint public voteSessionId;
    uint public roundId;

    struct GameScore {
        Game game;
        uint score;
    }

    struct GameScoreRound {
        uint roundNumber;
        GameScore[] games;
    }

    constructor(uint _roundSessionNumber) {
        gameId = 1;
        voteSessionId = 1;
        roundId = 1;
        if (_roundSessionNumber > 0) {
            roundSessionNumber = _roundSessionNumber;
        } else {
            roundSessionNumber = 2;
        }
    }

    function isOwner() public view returns (bool) {
        return owner() == msg.sender;
    }

    function getAllGames() public view returns (Game[] memory) {
        return games;
    }

    function getGameById(uint _gameId) public view returns (Game memory) {
        return games[_gameId];
    }

    function getJuries() public view returns (Jury[] memory) {
        return juries;
    }

    function addJuryMember(address addr, string memory _name, string memory _pictureUr) public onlyOwner {
        require(msg.sender == owner(), "Only the contract owner can add jury members.");
        require(!juryMembers[addr], "The address is already a jury member.");
        juryMembers[addr] = true;
        juries.push(Jury(_name, addr, _pictureUr));
    }

    function removeJuryMember(address addr) public onlyOwner {
        require(msg.sender == owner(), "Only the contract owner can remove jury members.");
        require(juryMembers[addr], "The address is not a jury member.");
        juryMembers[addr] = false;
        for (uint i = 0; i < juries.length; i++) {
            if (juries[i].walletAddress == addr) {
                juries[i] = juries[juries.length - 1];
                juries.pop();
            }
        }
    }

    function addGame(string memory _name, string memory _platform, string memory _price, string memory _description, string memory _release, string memory _url) public {
        games.push(Game(gameId, _name, _platform, _price, _description, _release, _url, msg.sender));
        gameId++;
    }

    function getGameIds(Game[] memory gameList) public view returns (uint[] memory) {
        uint[] memory gameIds = new uint[](gameList.length);
        for (uint i = 0; i < gameList.length; i++) {
            gameIds[i] = gameList[i].id;
        }
        return gameIds;
    }

    function createVoteSession() public onlyOwner {
        require(msg.sender == owner(), "Only the contract owner can create vote sessions.");
        sessionsIds.push(voteSessionId);
        voteSessionRounds[voteSessionId].push(VoteSessionRound(roundId, 1, getGameIds(games), 0));
        voteSessions[voteSessionId] = VoteSession(voteSessionId, false, false, roundSessionNumber, 1, block.timestamp, 0);
        roundId++;
        voteSessionId++;
    }

    function getLastVoteSessionId() public view returns (uint) {
        return sessionsIds[sessionsIds.length - 1];
    }

    function getCurrentVoteSessionId() public view returns (uint) {
        return voteSessionId;
    }

    function startVoteSession(uint _voteSessionId) public onlyOwner {
        require(msg.sender == owner(), "Only the contract owner can start vote sessions.");
        require(voteSessions[_voteSessionId].id == _voteSessionId, "The vote session does not exist.");
        require(!voteSessions[_voteSessionId].ended, "The vote session is already ended.");
        require(!voteSessions[_voteSessionId].started, "The vote session has already started.");
        voteSessions[_voteSessionId].started = true;
        voteSessions[_voteSessionId].startAt = block.timestamp;
    }

    function passToNextRound(uint _voteSessionId) public onlyOwner {
        require(msg.sender == owner(), "Only the contract owner can pass to the next round.");
        require(voteSessions[_voteSessionId].started, "The vote is not started.");
        require(!voteSessions[_voteSessionId].ended, "The vote session is ended.");

        uint currentRound = getCurrentRound(_voteSessionId);
        if (currentRound == voteSessions[_voteSessionId].rounds) {
            voteSessions[_voteSessionId].ended = true;
            voteSessionRounds[_voteSessionId][currentRound - 1].endedAt = block.timestamp;
        } else {
            GameScore[] memory leadingGames = getCurrentRoundLeadingGames(_voteSessionId, currentRound);
            Game[] memory nextRoundGames = new Game[](leadingGames.length);
            for (uint i = 0; i < leadingGames.length; i++) {
                nextRoundGames[i] = leadingGames[i].game;
            }
            voteSessionRounds[_voteSessionId][currentRound - 1].endedAt = block.timestamp;
            voteSessions[_voteSessionId].currentRound++;
            voteSessionRounds[_voteSessionId].push(VoteSessionRound(roundId, currentRound, getGameIds(nextRoundGames), 0));
            roundId++;
        }
    }

    function getCurrentRound(uint _voteSessionId) public view returns (uint) {
        return voteSessions[_voteSessionId].currentRound;
    }

    function getCurrentRoundVoteGameId(uint _voteSessionId, address _userAddress) public view returns (uint) {
        uint currentRound = getCurrentRound(_voteSessionId);
        Vote[] memory roundVotes = voteSessionRoundVotes[voteSessionRounds[_voteSessionId][currentRound - 1].id];
        for (uint i = 0; i < roundVotes.length; i++) {
            if (roundVotes[i].voter == _userAddress) {
                return roundVotes[i].gameId;
            }
        }
        return 0;
    }

    function hasVotedThisTurn(uint _voteSessionId, address _userAddress) public view returns (bool) {
        if (getCurrentRoundVoteGameId(_voteSessionId, _userAddress) != 0) {
            return true;
        }
        return false;
    }

    function vote(uint _voteSessionId, uint _gameId) public {
        require(voteSessions[_voteSessionId].started, "The vote session is not started.");
        require(!voteSessions[_voteSessionId].ended, "The vote session is ended.");
        uint currentRound = getCurrentRound(_voteSessionId);
        require(voteSessionRounds[_voteSessionId][currentRound - 1].availableGames[_gameId - 1] > 0, "The game is not available for this round.");
        require(!hasVotedThisTurn(_voteSessionId, msg.sender), "You have already voted this turn.");
        voteSessionRoundVotes[voteSessionRounds[_voteSessionId][currentRound - 1].id].push(Vote(msg.sender, _gameId));
    }

    function getVoteRoundGameIds(uint _voteSessionId) public view returns (uint) {
        return getCurrentRoundVoteGameId(_voteSessionId, msg.sender);
    }

    function getGameWinner(uint _voteSessionId) public returns (Game memory) {
        require(voteSessions[_voteSessionId].ended, "The vote session is not ended.");
        return getCurrentRoundLeadingGames(_voteSessionId, voteSessions[_voteSessionId].rounds)[0].game;
    }

    function getRoundsResults(uint _voteSessionId) public returns (GameScoreRound[] memory) {
        require(voteSessions[_voteSessionId].ended, "The vote session is not ended.");
        GameScoreRound[] memory results = new GameScoreRound[](voteSessions[_voteSessionId].rounds);
        for (uint i = 0; i < voteSessions[_voteSessionId].rounds; i++) {
            results[i] = GameScoreRound(i, getCurrentRoundLeadingGames(_voteSessionId, i + 1));
        }
        return results;
    }

    function getCurrentRoundLeadingGames(uint _voteSessionId, uint round) public view returns (GameScore[] memory) {
        uint leadingGamesRange = 1;
        if (round < voteSessions[_voteSessionId].rounds) {
            leadingGamesRange = (voteSessions[_voteSessionId].rounds - round) * 3;
            if (voteSessionRounds[_voteSessionId][round - 1].availableGames.length < leadingGamesRange) {
                leadingGamesRange = voteSessionRounds[_voteSessionId][round - 1].availableGames.length;
            }
        }
        Vote[] memory roundVotes = voteSessionRoundVotes[voteSessionRounds[_voteSessionId][round - 1].id];
        uint[] memory availableGames = voteSessionRounds[_voteSessionId][round - 1].availableGames;
        uint[] memory voteScore = new uint[](voteSessionRounds[_voteSessionId][round - 1].availableGames.length);
        for (uint i = 0; i < availableGames.length; i++) {
            voteScore[i] = 0;
        }
        for (uint i = 0; i < roundVotes.length; i++) {
            for (uint j = 0; j < availableGames.length; j++) {
                if (roundVotes[i].gameId == availableGames[j]) {
                    if (juryMembers[roundVotes[i].voter] == true) {
                        voteScore[j] += 30;
                    } else {
                        voteScore[j]++;
                    }
                }
            }
        }
        uint score = 0;
        uint game = 0;
        uint index = 0;
        GameScore[] memory leadingGames = new GameScore[](leadingGamesRange);
        for (uint i = 0; i < leadingGamesRange; i++) {
            for (uint j = 0; j < availableGames.length; j++) {
                if (voteScore[j] > score) {
                    score = voteScore[j];
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

    function getVoteSession(uint _voteSessionId) public view returns (VoteSession memory) {
        return voteSessions[_voteSessionId];
    }

    function getVoteSessions() public view returns (VoteSession[] memory) {
        VoteSession[] memory results = new VoteSession[](sessionsIds.length);
        for (uint i = 0; i < sessionsIds.length; i++) {
            results[i] = voteSessions[sessionsIds[i]];
        }
        return results;
    }
}

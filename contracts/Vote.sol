pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Vote {
    mapping(address => bool) public voters;

    address[] public candidates;
    mapping(address => uint256) public votes;
    function addCandidate() public{
        candidates.push(msg.sender);
    }


    function vote(address candidat) public payable{
        require(!voters[msg.sender],"Already voted");
        require(msg.value == 1 ether, "You need to seed 1 ether");
        voters[msg.sender] = true;
        votes[candidat] ++ ;
    }

    function voteWithERC20(address candidat) public payable{
        require(!voters[msg.sender],"Already voted");
        require(msg.value == 1 ether, "You need to seed 1 ether");
        voters[msg.sender] = true;
        votes[candidat] ++ ;
    }

    function getWinner() public view returns (address){
        address winner = address (0);
        uint256 maxVotes = 0;
        for(uint256 i=0; i<candidates.length;i++){
            if (votes[candidates[i]] > maxVotes){
                maxVotes = votes[candidates[i]];
                winner = candidates[i];
            }
        }
        return winner;
    }

    function withdraw() public{
        require(msg.sender == getWinner(), "You are not the winner");
        payable(msg.sender).transfer(address(this).balance);
    }

}

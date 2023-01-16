// This is an example test file. Hardhat will run every *.js file in `test/`,
// so feel free to add new ones.

// Hardhat tests are normally written with Mocha and Chai.

// We import Chai to use its asserting functions here.
const { expect } = require("chai");

// We use `loadFixture` to share common setups (or fixtures) between tests.
// Using this simplifies your tests and makes them run faster, by taking
// advantage of Hardhat Network's snapshot functionality.
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const {ethers} = require("hardhat");

// `describe` is a Mocha function that allows you to organize your tests.
// Having your tests organized makes debugging them easier. All Mocha
// functions are available in the global scope.
//
// `describe` receives the name of a section of your test suite, and a
// callback. The callback must define the tests of that section. This callback
// can't be an async function.
describe("Token contract", function () {
    // We define a fixture to reuse the same setup in every test. We use
    // loadFixture to run this setup once, snapshot that state, and reset Hardhat
    // Network to that snapshot in every test.
    async function deployTokenFixture() {
        // Get the ContractFactory and Signers here.
        const Token = await ethers.getContractFactory("Token");
        const [owner, addr1, addr2] = await ethers.getSigners();

        // To deploy our contract, we just have to call Token.deploy() and await
        // its deployed() method, which happens once its transaction has been
        // mined.
        const hardhatToken = await Token.deploy();

        await hardhatToken.deployed();

        // Fixtures can return anything you consider useful for your tests
        return { Token, hardhatToken, owner, addr1, addr2 };
    }

    // You can nest describe calls to create subsections.
    describe("Deployment", function () {
        // `it` is another Mocha function. This is the one you use to define each
        // of your tests. It receives the test name, and a callback function.
        //
        // If the callback function is async, Mocha will `await` it.
        it("Should set the right owner", async function () {
            // We use loadFixture to setup our environment, and then assert that
            // things went well
            const { hardhatToken, owner } = await loadFixture(deployTokenFixture);

            // `expect` receives a value and wraps it in an assertion object. These
            // objects have a lot of utility methods to assert values.

            // This test expects the owner variable stored in the contract to be
            // equal to our Signer's owner.
            expect(await hardhatToken.owner()).to.equal(owner.address);
        });

        it("Should assign the total supply of tokens to the owner", async function () {
            const { hardhatToken, owner } = await loadFixture(deployTokenFixture);
            const ownerBalance = await hardhatToken.balanceOf(owner.address);
            expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
        });
    });


    describe("Transactions", function () {
        it("Should transfer tokens between accounts", async function () {
            const { hardhatToken, owner, addr1, addr2 } = await loadFixture(
                deployTokenFixture
            );
            // Transfer 50 tokens from owner to addr1
            await expect(
                hardhatToken.transfer(addr1.address, 50)
            ).to.changeTokenBalances(hardhatToken, [owner, addr1], [-50, 50]);

            // Transfer 50 tokens from addr1 to addr2
            // We use .connect(signer) to send a transaction from another account
            await expect(
                hardhatToken.connect(addr1).transfer(addr2.address, 50)
            ).to.changeTokenBalances(hardhatToken, [addr1, addr2], [-50, 50]);
        });

        it("should emit Transfer events", async function () {
            const { hardhatToken, owner, addr1, addr2 } = await loadFixture(
                deployTokenFixture
            );

            // Transfer 50 tokens from owner to addr1
            await expect(hardhatToken.transfer(addr1.address, 50))
                .to.emit(hardhatToken, "Transfer")
                .withArgs(owner.address, addr1.address, 50);

            // Transfer 50 tokens from addr1 to addr2
            // We use .connect(signer) to send a transaction from another account
            await expect(hardhatToken.connect(addr1).transfer(addr2.address, 50))
                .to.emit(hardhatToken, "Transfer")
                .withArgs(addr1.address, addr2.address, 50);
        });

        it("Should fail if sender doesn't have enough tokens", async function () {
            const { hardhatToken, owner, addr1 } = await loadFixture(
                deployTokenFixture
            );
            const initialOwnerBalance = await hardhatToken.balanceOf(owner.address);

            // Try to send 1 token from addr1 (0 tokens) to owner.
            // `require` will evaluate false and revert the transaction.
            await expect(
                hardhatToken.connect(addr1).transfer(owner.address, 1)
            ).to.be.revertedWith("Not enough tokens");

            // Owner balance shouldn't have changed.
            expect(await hardhatToken.balanceOf(owner.address)).to.equal(
                initialOwnerBalance
            );
        });
    });
});

/*const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Vote", function () {
  let candidat1, candidat2, voteur1, voteur2;
  let candidat1Address, candidat2Address, voteur1Address, voteur2Address;
  let VoteFactory, vote;

  before(async () => {
    VoteFactory = await ethers.getContractFactory("Vote");
    vote = await VoteFactory.deploy();
    [candidat1, candidat2, voteur1, voteur2] = await ethers.getSigners();
    candidat1Address = await candidat1.getAddress();
  });

  it("Should add a new candidate", async function () {
    await vote.connect(candidat1).addCandidate();

    const getFirstCandidate = await vote.candidates(0);
    expect(getFirstCandidate).to.equal(candidat1Address);
  });

  it("Should vote for a candidate and get winner", async function () {
    await vote.connect(voteur1).vote(candidat1Address, {
      value: ethers.utils.parseEther("1"),
    });

    const winner = await vote.getWinner();
    expect(winner).to.equal(candidat1Address);
  });
});


Test sol

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vote {
    mapping(address => bool) public voters;

    address[] public candidates;
    mapping(address => uint256) public votes;
    IERC20 public ESGIToken;

    constructor(address ESGITokenAddress) {
        ESGIToken = IERC20(ESGITokenAddress);
    }

    function addCandidate() public {
        candidates.push(msg.sender);
    }

    function vote(address candidat) public payable {
        require(!voters[msg.sender], "Already voted");
        require(msg.value == 1 ether, "You need to send 1 ether");

        voters[msg.sender] = true;
        votes[candidat]++;
    }

    function voteWithERC20(address candidat) public {
        require(!voters[msg.sender], "Already voted");
        require(
            ESGIToken.allowance(address(this), msg.sender) >= 10**18,
            "You need to approve for 10 tokens"
        );
        ESGIToken.transferFrom(msg.sender, address(this), 10**18);
        voters[msg.sender] = true;
        votes[candidat]++;
    }

    function getWinner() public view returns (address) {
        address winner = address(0);
        uint256 maxVotes = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (votes[candidates[i]] > maxVotes) {
                maxVotes = votes[candidates[i]];
                winner = candidates[i];
            }
        }
        return winner;
    }

    function withdraw() public {
        require(msg.sender == getWinner(), "You are not the winner");
        payable(msg.sender).transfer(address(this).balance);
    }
}*/
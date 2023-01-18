const {expect} = require("chai");

const {loadFixture} = require("@nomicfoundation/hardhat-network-helpers");
const {ethers} = require("hardhat");


describe("GameAward contract", function () {
    async function deployContractFixture() {
        const GameAward = await ethers.getContractFactory("GameAward");
        const gameAward = await GameAward.deploy(2);
        await gameAward.deployed();
        return {gameAward};
    }

    it("Should return true if caller is owner", async function () {
        const {gameAward} = await loadFixture(deployContractFixture);

        expect(await gameAward.isOwner()).to.equal(true);
    });

    it("Should add a jury member", async function () {
        const [owner] = await ethers.getSigners();
        const {gameAward} = await loadFixture(deployContractFixture);

        await gameAward.addJuryMember(owner.address, "name", "pictureUrl");

        const juries = await gameAward.getJuries();
        expect(juries[0].walletAddress).to.equal(owner.address);
    });

    it("Should remove a jury member", async function () {
        const [addr] = await ethers.getSigners();
        const {gameAward} = await loadFixture(deployContractFixture);

        await gameAward.addJuryMember(addr.address, "name", "pictureUrl");
        await gameAward.removeJuryMember(addr.address);

        const juries = await gameAward.getJuries();
        expect(juries.length).to.equal(1);
    });

    it("Should add a new game", async function () {
        const {gameAward} = await loadFixture(deployContractFixture);

        await gameAward.addGame("Game1", "PS5", "130€", "jeu", "samedi", "photo");
        const getFirstGame = await gameAward.games(0);

        expect(getFirstGame.name).to.equal("Game1");
    });

    it("Should create a new voting session", async function () {
        const [addr] = await ethers.getSigners();
        const {gameAward} = await loadFixture(deployContractFixture);

        await gameAward.createVoteSession();
        const sessionId = await gameAward.getLastVoteSessionId();
        const session = await gameAward.getVoteSession(sessionId)

        expect(sessionId).to.equal(session.id);
    });


});

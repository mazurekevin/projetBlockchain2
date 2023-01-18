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
        const [owner] = await ethers.getSigners();
        const {gameAward} = await loadFixture(deployContractFixture);

        expect(await gameAward.isOwner()).to.equal(true);
    });

    it("Should add a jury member", async function () {
        const [owner] = await ethers.getSigners();
        const {gameAward} = await loadFixture(deployContractFixture);
        try {
            await gameAward.addJuryMember(owner.address, "name", "pictureUrl");
        } catch (e) {
            console.log(e);
        } finally {
            console.log(await gameAward.getJuries());
        }
        const juries = await gameAward.getJuries();
        expect(juries[0].walletAddress).to.equal(owner.address);
    });

    it("Should add a new game", async function () {
        const {gameAward} = await loadFixture(deployContractFixture);

        await gameAward.addGame("Game1", "PS5", "130€", "jeu", "samedi", "photo");
        const getFirstGame = await gameAward.games(0);

        expect(getFirstGame.name).to.equal("Game1");
    });
});

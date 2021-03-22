const Lotto = artifacts.require("Lotto");

module.exports = async function(deployer) {
	//deploy Token
	await deployer.deploy(Lotto, 2);
	//assign token into variable to get it's address
	const lotto = await Lotto.deployed()
};

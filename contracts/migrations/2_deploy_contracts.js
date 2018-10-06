let ContinuousOrganization = artifacts.require("./ContinuousOrganization.sol");

module.exports = function(deployer) {
  const slope = 1000; // parametrize the buying linear curve
  const alpha = 100; // fraction put into selling reserves when investors buy
  const beta = 300; // fraction put into selling reserves when the CO has revenues

  deployer.deploy(ContinuousOrganization, slope, alpha, beta);
};
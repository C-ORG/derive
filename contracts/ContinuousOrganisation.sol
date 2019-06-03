pragma solidity ^0.4.24;

contract ContinuousOrganisation {

    /* The parameters of the Continuous Organisation. All are multiplied by base */
    uint base = 10000;
    uint slope = base; // parametrize the buying linear curve
    uint alpha = base/10; // fraction put into selling reserves when investors buy
    uint beta = base/3; // fraction put into selling reserves when the CO has revenues

    /* The tokens of the Continuous Organisation */
    uint nTokens = 0;
    mapping(address => uint) public balances;
    address public owner; // owner of the smart contract
    uint public sellReserve = 0;


    /* Permission rights */
    modifier isOwner(address sender) { require(sender == owner); _; }

    /* Events */
    event UpdateTokens(uint tokens, uint sellReserve);


    /* This is the constructor. Solidity does not implement float number so we have to multiply constants by base and rounding them before creating the smart contract.
    */
    constructor(uint _base) public {
        owner = msg.sender;
        slope = _base;
        alpha = _base/10;
        beta = _base/3;
    }

    /* Getters and setters */
    function setSlope(uint paramSlope) public isOwner(msg.sender) {
        slope = paramSlope;
    }
    function setAlpha(uint paramAlpha) public isOwner(msg.sender) {
        alpha = paramAlpha;
    }
    function setBeta(uint paramBeta) public isOwner(msg.sender) {
        beta = paramBeta;
    }
    function getBalance()
        public
        view
        returns (uint y) {
        y = balances[msg.sender];
    }
    function getSellReserve()
        public
        view
        returns (uint y) {
        y = sellReserve;
    }
    function getNumTokens()
        public
        view
        returns (uint y) {
        y = nTokens;
    }
    function getPriceForQuarter()
        public
        view
        returns (uint y) {
        y = (sellReserve / (2 * nTokens * slope / alpha));
    }


    /* Babylonian method for square root. See: https://ethereum.stackexchange.com/a/2913 */
    function sqrt(uint x)
        public
        pure
        returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /* Minting and burning tokens */
    // #TODO protection against overflows
    function buy() public payable {
        require(msg.value > 0);

        // create tokens
        uint invest = msg.value;
        uint tokens = sqrt(2*invest*base/slope + nTokens*nTokens) - nTokens + 1;
        balances[msg.sender] += tokens;
        nTokens += tokens;

        // redistribute tokens
        sellReserve += alpha*invest;
        owner.transfer((base-alpha)/base*invest);

        emit UpdateTokens(nTokens, sellReserve);
    }

    function sell(uint tokens) public {
        // check funds
        require(tokens > 0);
        require(balances[msg.sender] >= tokens);

        balances[msg.sender] -= tokens;
        uint withdraw = sellReserve*tokens/nTokens/nTokens*(2*nTokens - tokens);
        sellReserve -= withdraw;
        withdraw /= base;
        msg.sender.transfer(withdraw);

        emit UpdateTokens(nTokens, sellReserve);
    }

    function revenue()
        public
        isOwner(msg.sender)
        payable {

        require(msg.value > 0);
        uint revenue = msg.value;
        // create tokens
        uint tokens = sqrt(2*revenue*base/slope + nTokens*nTokens) - nTokens;
        balances[owner] += tokens;
        nTokens += tokens;

        // redistribute tokens
        sellReserve += beta*revenue;
        owner.transfer((1-beta)*revenue/base);

        emit UpdateTokens(nTokens, sellReserve);
    }

    function freeTokens(uint amount)
        public
        isOwner(msg.sender) {

        require(amount > 0);
        nTokens += amount;
    }
}

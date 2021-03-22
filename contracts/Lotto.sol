pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Pausable.sol';

contract Lotto is Ownable , Pausable  {

  struct Lottery{
    uint startBlock;
    uint endBlock;
    bytes32 blockHash;
    address winner;
    Participant[] participants;
  }
  struct Participant {
    address addr;
  }

  uint256 public amount;
  address public ownerAddress;
  uint256 public totalPlayedAmount;
  uint256 public totalOwnerAmount;
  uint16 public ownerRatio;
  uint constant WAIT_TIME = 38117;
  uint16 public currentLottery;

  mapping(uint => Lottery) public lotteries;

  event LotteryRunFinished(address winner, uint256 ownerAmount, uint256 jackpot);
  event ApplicationDone(uint applicationNumber);


  constructor(uint256 _amount) public {
    if (_amount == 0){
      amount = 0.001 ether; //approx 1 USD
    }else{
      amount = _amount;
    }
    _pause();
    initialise();
    _unpause();
    ownerAddress = msg.sender;
    ownerRatio = 1;
  }

function play() public payable whenNotPaused returns (uint256) {
  require(msg.value == amount * 10**18, 'Wrong amount');

  lotteries[currentLottery].participants.push(Participant(msg.sender));
  ApplicationDone(lotteries[currentLottery].participants.length - 1);
  return lotteries[currentLottery].participants.length - 1;
}

function getCurrentCount() public view returns (uint256) {
  return lotteries[currentLottery].participants.length;
}

function getCurrentLottery() public view returns(uint endBlock, uint startBlock, bytes32 blockHash, address winner, uint participants) {
  Lottery storage lottery = lotteries[currentLottery];
  return (lottery.endBlock, lottery.startBlock, lottery.blockHash, lottery.winner, lottery.participants.length);
}

function initialise() public whenPaused onlyOwner {
   require(address(this).balance == 0);
   currentLottery++;
   lotteries[currentLottery].startBlock = block.number;
   lotteries[currentLottery].blockHash = blockhash(lotteries[currentLottery].startBlock);

   lotteries[currentLottery].endBlock = block.number + WAIT_TIME;
 }

  function setOwnerRatio(uint16 newRatio) public onlyOwner {
    require(newRatio < 101);
    ownerRatio = newRatio;
  }

  function setOwnerAddress(address _ownerAddress) public onlyOwner {
    require(_ownerAddress != address(0));
    ownerAddress = _ownerAddress;
  }

  function run() public onlyOwner returns (uint256, address) {
    require(lotteries[currentLottery].participants.length >= 2);

    _pause();

    uint256 ownerAmount = (address(this).balance * ownerRatio) / 100;
    address payable payableOwnerAddress = payable(ownerAddress);
    payableOwnerAddress.transfer(ownerAmount);
    totalOwnerAmount += ownerAmount;

    uint256 randomValue = random();
    address winner = lotteries[currentLottery].participants[randomValue].addr;
    address payable winnerPayable = payable(winner);

    uint256 winningPrice = address(this).balance;
    if (winningPrice > 0) {
      winnerPayable.transfer(winningPrice);
    }

    lotteries[currentLottery].winner = winner;
    totalPlayedAmount += winningPrice;

    initialise();
    _unpause();
    LotteryRunFinished(winner, ownerAmount, winningPrice);
    return (randomValue, winner);
  }

  function random() internal view returns(uint256) {
    uint256 r1 = uint256(blockhash(block.number-1));
    uint256 r2 = uint256(blockhash(lotteries[currentLottery].startBlock));

    uint256 val;

    assembly {
      val := xor(r1, r2)
    }
    return val % lotteries[currentLottery].participants.length;
  }
}

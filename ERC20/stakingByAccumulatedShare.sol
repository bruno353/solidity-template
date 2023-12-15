
pragma solidity ^0.8.0;

contract StakingContract {
    struct Stake {
        uint256 amount;
        uint256 rewardDebt;
    }

    // Interface simplificada do token EGLD.
    interface IEGLDToken {
        function transfer(address to, uint256 amount) external;
        function transferFrom(address from, address to, uint256 amount) external;
    }

    IEGLDToken public token;
    uint256 public constant REWARD_PER_SECOND = 0.0003 ether;
    uint256 public totalStaked;
    uint256 public accRewardPerShare;
    uint256 public lastRewardTime;

    mapping(address => Stake) public stakes;

    constructor(address _tokenAddress) {
        token = IEGLDToken(_tokenAddress);
        lastRewardTime = block.timestamp;
    }

    function updatePool() internal {
        if (block.timestamp <= lastRewardTime) {
            return;
        }
        if (totalStaked == 0) {
            lastRewardTime = block.timestamp;
            return;
        }
        uint256 elapsedTime = block.timestamp - lastRewardTime;
        uint256 reward = elapsedTime * REWARD_PER_SECOND;
        accRewardPerShare += reward / totalStaked;
        lastRewardTime = block.timestamp;
    }

    function stake(uint256 amount) public {
        updatePool();
        if (stakes[msg.sender].amount > 0) {
            uint256 pendingReward = stakes[msg.sender].amount * accRewardPerShare - stakes[msg.sender].rewardDebt;
            token.transfer(msg.sender, pendingReward);
        }
        token.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].rewardDebt = stakes[msg.sender].amount * accRewardPerShare;
        totalStaked += amount;
    }

    function unstake(uint256 amount) public {
        require(stakes[msg.sender].amount >= amount, "Not enough staked");
        updatePool();
        uint256 pendingReward = stakes[msg.sender].amount * accRewardPerShare - stakes[msg.sender].rewardDebt;
        if(pendingReward > 0) {
            token.transfer(msg.sender, pendingReward);
        }
        stakes[msg.sender].amount -= amount;
        stakes[msg.sender].rewardDebt = stakes[msg.sender].amount * accRewardPerShare;
        token.transfer(msg.sender, amount);
        totalStaked -= amount;
    }

    function claimRewards() public {
        updatePool();
        uint256 pendingReward = stakes[msg.sender].amount * accRewardPerShare - stakes[msg.sender].rewardDebt;
        if (pendingReward > 0) {
            token.transfer(msg.sender, pendingReward);
            stakes[msg.sender].rewardDebt = stakes[msg.sender].amount * accRewardPerShare;
        }
    }
}

SC address :0x663279b4b2d85ba36a4d4b22a59c966f86db78f7


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol";

contract SmapleStake is ReentrancyGuard {
    //sushi router 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
    //    usdt/ wmatic
    //  ["0xBD21A10F619BE90d6066c941b04e340841F1F989","0x5B67676a984807a212b1c59eBFc9B3568a474F0a"]

    //link erc20
    //0x326C977E6efc84E512bB9C30f76E30c160eD06FB  0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1

    //RIJ 0x09d66cA91765a49d9A69c40B44FaDE5e842F5247

    IERC20 public _token = IERC20(0x09d66cA91765a49d9A69c40B44FaDE5e842F5247);
    uint256 private usdAmount = 1000000;
    bool public paused;
    address public admin;

    enum userStatus {
        Active,
        unstaked,
        rewardnotclaimed,
        rewardclaimed
    }

    struct Userdetails {
        userStatus activestatus;
        uint256 stakeid;
        address userAddress;
        uint256 amount;
        uint256 yearduration;
        uint256 onemonth;
        uint256 reward;
        userStatus rewardstatus;
    }
    struct UserAmounts {
        uint256 value;
        address member;
    }
    struct cooldown {
        uint256 stakeid;
        address member;
        uint256 amount;
        uint256 coolduration;
        bool alreadycooling;
    }

    mapping(uint256 => Userdetails) public Usermap;
    mapping(address => UserAmounts[]) public UserFeeList;
    mapping(uint256 => cooldown) public coolingids;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender);
        _;
    }

    function setAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    function setnewToken(address newtoken) public onlyAdmin {
        _token = IERC20(newtoken);
    }

    function changeUsdvalue(uint256 usd) public onlyAdmin {
        usdAmount = usd;
    }

    function setPaused(bool _paused) public onlyAdmin {
        require(msg.sender == admin, "You are not the owner");
        paused = _paused;
    }

    function poolShare() public view returns (uint256 poolbalance) {
        return (IERC20(_token).balanceOf(address(this)));
    }

    function buytoken(
        uint256 tokenValue,
        uint256 rijamount,
        address tokenAdress,
        address rij
    ) public {
        address caller = msg.sender;
        IERC20(tokenAdress).transferFrom(caller, admin, tokenValue);
        IERC20(rij).transferFrom(admin, caller, rijamount); //admin to sc
    }

    // RIJ: "0x09d66cA91765a49d9A69c40B44FaDE5e842F5247"
    // _daysofmonth: 1700283289126
    // _year: 1729313689126
    // amount: "2000000000000000000"
    // stakeid: "1"
    function stake(
        uint256 stakeid,
        uint256 amount,
        uint256 _year,
        uint256 _daysofmonth,
        address RIJ
    ) public nonReentrant {
        require(paused == false, "Function Paused");
        require(
            IERC20(RIJ).balanceOf(msg.sender) > 0,
            "balance must be greaterthan  0"
        );
        address member = msg.sender;

        Usermap[stakeid] = Userdetails(
            userStatus.Active,
            stakeid,
            member,
            amount,
            _year,
            _daysofmonth,
            0,
            userStatus.rewardnotclaimed
        );

        UserAmounts memory useramt = UserAmounts({
            value: amount,
            member: member
        });
        UserFeeList[member].push(useramt);
        IERC20(RIJ).transferFrom(msg.sender, address(this), amount);
    }

    function Cooldown_unstake(
        uint256 stakeid,
        uint256 _amount,
        uint256 _sixcoolingtime
    ) public nonReentrant {
        require(
            Usermap[stakeid].activestatus == userStatus.Active,
            "already unstaked"
        );
        require(paused == false, "Function Paused");

        require(
            coolingids[stakeid].alreadycooling == false,
            "you are already cooling an amount"
        );
        require(
            Usermap[stakeid].amount == _amount,
            "Please give staked amount"
        );

        address member = msg.sender;
        coolingids[stakeid] = cooldown(
            stakeid,
            member,
            _amount,
            _sixcoolingtime,
            true
        );
    }

    function unstake(
        uint256 stakeid,
        address RIJ,
        uint256 amount
    ) external nonReentrant {
        require(
            coolingids[stakeid].alreadycooling == true,
            "you cannot unstake"
        );
        require(
            Usermap[stakeid].activestatus == userStatus.Active,
            "already unstaked"
        );
        require(amount == coolingids[stakeid].amount, "amount is not same");
        require(paused == false, "Function Paused");
        address user = coolingids[stakeid].member;
        IERC20(RIJ).transfer(user, amount);
        Usermap[stakeid].activestatus == userStatus.unstaked;
    }

    /*
    reward calculation
    0.000001×(1+0.08)=0.00000108
    0.00000108−0.000001 =0.00000008
    */

    function reward(
        uint256 stakeid,
        uint256 amount,
        address RIJ
    ) external nonReentrant {
        require(
            Usermap[stakeid].rewardstatus == userStatus.rewardnotclaimed,
            "reward  claimed"
        );
        require(paused == false, "Function Paused");
        address user = Usermap[stakeid].userAddress;

        IERC20(RIJ).transfer(user, amount);
        Usermap[stakeid].reward = amount;
        Usermap[stakeid].activestatus == userStatus.rewardclaimed;
    }

    function getUserbyid(uint256 stakeid)
        public
        view
        returns (Userdetails memory)
    {
        return Usermap[stakeid];
    }

    function showlistofstakes(address user)
        external
        view
        returns (UserAmounts[] memory)
    {
        return UserFeeList[user];
    }

    function balanceUser(address user)
        public
        view
        returns (uint256 Userbalance)
    {
        return (IERC20(_token).balanceOf(user));
    }


    function sendTosc(address RIJ)public onlyAdmin returns (uint256 balanceofSc)
    {
        uint256 bal=IERC20(RIJ).balanceOf(address(this));
        uint256 thousand=1000000000000000000000;
        uint256 amt=thousand-bal;

        if(bal < thousand)
        {
            IERC20(RIJ).transferFrom(admin ,address(this) ,amt);
        }
        return IERC20(RIJ).balanceOf(address(this));

    }

     function balancediff(address RIJ,uint256 amount)public   view returns (uint256 balanceofSc)
    {
        uint256 bal=IERC20(RIJ).balanceOf(address(this));
        uint256 amt=amount-bal;
        return amt;

    }


    function emergencyWithdraw(address RIJ, uint256 amount) public onlyAdmin {
        // IERC20(RIJ).transferFrom(address(this),admin,IERC20(RIJ).balanceOf(address(this)));
        IERC20(RIJ).transferFrom(address(this), admin, amount);
    }
}

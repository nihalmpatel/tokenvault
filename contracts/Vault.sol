pragma solidity ^0.4.4;

// ----------------------------------------------------------------------------
// Safe math
// ----------------------------------------------------------------------------

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

// ----------------------------------------------------------------------------
// GBT FIXED ERC20 Token (As an Example)
// ----------------------------------------------------------------------------

contract GamblingToken {
    
    using SafeMath for uint256;
    
    string public constant name = "Gambling Token";                  
    uint8 public constant decimals = 0;                
    string public constant symbol = "GBT";
    uint256 public totalSupply = 1000000;
    address public owner;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function GamblingToken() public payable {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    function totalSupply() view public returns (uint256 supply) {
        return totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value); 
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if(_value>0 && _spender != address(0x0)) {
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        } else { return false; }
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
}

// ----------------------------------------------------------------------------
// Token Vault contract
//
// Lock certain amount of tokens for specific duration.
//
// ( HERE: 10% of Tokens for 10 months of period )
// ----------------------------------------------------------------------------

contract Vault {
    
    GamblingToken gt;
    address public owner;
    uint public creationTime;
    
    struct _userVault {
        uint lastMilestone;
        uint allowedAmount;
        uint redeemedMilestones;
    }
    
    mapping(address => _userVault) userVault; 
    
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }
    
    function Vault() public {
        owner = msg.sender;
        creationTime = now;
        gt = new GamblingToken();
    }
    
    // only admin can transfer the tokens
    function transferTokens(address user,uint amount) public ownerOnly returns(bool) {
        return gt.transfer(user,amount);
    }
    
    function withdraw() public returns(bool) {
        // admin can't withdraw tokens as he can tranfer tokens to any address and even to himself
        require( msg.sender != owner );
        uint amount = calculateAmount();
        require(amount > 0);
        userVault[msg.sender].redeemedMilestones += 1;
        userVault[msg.sender].lastMilestone = now;
        return gt.transfer(msg.sender,amount);
    }
    
    function getBalance(address a) public view returns(uint) {
        return gt.balanceOf(a);
    }
    
    // calculate amount based on intervals and milestones (here: 10% amount in an interval upto 10 milestones)
    function calculateAmount() public returns(uint) {
        // interval in months
        uint interval = (now - userVault[msg.sender].lastMilestone) / 30 days;
        if (interval > 0 && interval > userVault[msg.sender].redeemedMilestones && userVault[msg.sender].redeemedMilestones <= 10) {
            uint availableMilestones = interval - userVault[msg.sender].redeemedMilestones;
            // returns 10% of availableMilestones of allowedAmount
            return (availableMilestones * userVault[msg.sender].allowedAmount) * 10 / 100;
        } else { return 0; }
    }
    
    // Only admin can lock user account for certain period and amount.
    function lockAccount(address user,uint amount) public ownerOnly {
        _userVault memory uv;
        uv.lastMilestone = now;
        //uv.lastMilestone = now - 60 days; // FOR Testing, REMOVE while deploying 
        uv.allowedAmount = amount;
        uv.redeemedMilestones = 0;
        userVault[user] = uv;
    }
    
    // ----------------------------------------------------------------------------
    //
    // FOR Testing ONLY! Remove below methods while deploying
    //
    // ----------------------------------------------------------------------------
    
    function availableMilestones() public view returns(uint) {
        uint interval = (now - userVault[msg.sender].lastMilestone) / 30 days;
        return interval - userVault[msg.sender].redeemedMilestones;
    }
    
    function withdrawableBalance() public view returns(uint) {
        return (availableMilestones() * userVault[msg.sender].allowedAmount) * 10 / 100;
    }
    
    function lastMilestone() public view returns(uint) {
        return userVault[msg.sender].lastMilestone;
    }
    
    function allowedAmount() public view returns(uint) {
        return userVault[msg.sender].allowedAmount;
    }
    
    function timenow() public view returns(uint) {
        return now;
    }
    
}

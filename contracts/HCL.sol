// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HCL is ERC20, Ownable {
	
	/**
	* @dev Total Supply
	*/ 
	uint256 private constant TOTAL_SUPPLY = 2500000000;

	/**
	* @dev Constructor
	*/ 
	constructor() ERC20('Hiwkcircle', 'HCL') 
	{
		_mint(_msgSender(), TOTAL_SUPPLY*10**decimals());
	}

	/**
	* @dev Allocation Struct
	*/ 
	struct Allocation
	{
		address account;
		uint256 amount;
		string role;
		bool isSet;
	}
	
	/**
	* @dev List of Registered allocation
	*/ 
	mapping(address => Allocation) private _allocations;

	/**
	* @dev Array of Registerd allocation address
	*/ 
	address[] private _allocationAddresses;
	
	/**
	* @dev Set Allocation
	* @param account The address to be allocated
	* @param amount The amount to be allocated
	* @param role The role to be allocated
	*/
	function setAllocation(address account, uint256 amount, string memory role) external onlyOwner
	{
		require(account != address(0), "HCL: account from the zero address");
		
		address owner = _msgSender();
		
		require(balanceOf(owner) >= amount, "HCL: allocation amount exceeds balance");
		require(_allocations[account].isSet != true, "HCL: already registered allocation address");
		
		_allocations[account] = Allocation(account, amount, role, true);
		_allocationAddresses.push(account);

		transfer(account, amount);
	}

	/**
	 * @dev Returns the allocation information by 'account'
	 */
	function getAllocation(address account) public view returns(Allocation memory)
	{
		return _allocations[account];
	}

	/**
	 * @dev Returns all of allocation information
	 */
	function getAllocations() public view returns(Allocation[] memory)
	{
		Allocation[] memory allocations = new Allocation[](_allocationAddresses.length);
		
		for (uint i = 0; i < _allocationAddresses.length; i++) 
		{
			address addr = _allocationAddresses[i];
			Allocation storage allocation = _allocations[addr];
			allocations[i] = allocation;
		}

		return allocations;
	}

	/**
	* @dev Vesting Struct
	*/ 
	struct Vesting
	{
		address account;
		uint256 amount;
		uint256 start;
		uint256[] timelock;
		string role;
		bool isSet;
	}
	
	/**
	 * @dev List of Registered vesting
	 */ 
	mapping(address => Vesting) private _vestings;

	/**
	 * @dev Array of Registerd vesting address
	 */ 
	address[] private _vestingAddresses;

	/**
	 * @dev Set Vesting
	 * @param account The address to be vested
	 * @param amount The amount to be vested
	 * @param start The start date(timestamp) to be vested
	 * @param timelock The timelock timestamp
	 */
	function setVesting(address account, uint256 amount, uint256 start, uint256[] memory timelock) public
	{
		address owner = _msgSender();
		
		/**
		* @dev Only addresses registered in '_allocation' are permitted to execute.
		*/
		require(_allocations[owner].isSet == true, "HCL: address is not registered in allocation ");
		require(balanceOf(owner) >= amount, "HCL: vesting amount exceeds balance");
		
		require(_vestings[account].isSet != true, "HCL: already registered in vesting");

		_vestings[account] = Vesting(account, amount, start, timelock, _allocations[owner].role, true);
		_vestingAddresses.push(account);

		transfer(account, amount);
	}

	/**
	 * @dev Returns the vesting information by 'account'
	 */
	function getVesting(address account) public view returns(Vesting memory)
	{
		return _vestings[account];
	}

	/**
	 * @dev Returns all of vesting information
	 */
	function getVestings() public view returns(Vesting[] memory)
	{
		Vesting[] memory vestings = new Vesting[](_vestingAddresses.length);
		
		for (uint i = 0; i < _vestingAddresses.length; i++) 
		{
			address addr = _vestingAddresses[i];
			Vesting storage vesting = _vestings[addr];
			vestings[i] = vesting;
		}

		return vestings;
	}
	
	/**
	 * @dev Change Vesting start date
	 * @param account The vested adddress
	 * @param start The start date(timestamp) to be vested
	 * @param timelock The timelock timestamp
	 */
	function changeVestingDate(address account, uint256 start, uint256[] memory timelock) public
	{
		address owner = _msgSender();

		require(_allocations[owner].isSet == true, "HCL: address is not registered in allocation ");
		require(_vestings[account].isSet == true, "HCL: account is not registered in vesting");

		_vestings[account].start = start;
		_vestings[account].timelock = timelock;
	}

	/**
	* @dev Get the amount of locked tokens 
	* @param account address
	* @return lockedToken Amount of locked tokens
	*/
	function getLockedBalance(address account) public view returns (uint256) 
	{
		if(_vestings[account].isSet != true)
		{
			return 0;
		}
		
		uint256 per = _vestings[account].amount / _vestings[account].timelock.length;
		uint256 unlocked = 0;
		
		for (uint i = 0; i < _vestings[account].timelock.length; i++) 
		{
			if(_vestings[account].timelock[i] < block.timestamp)
			{
				unlocked += per;
			}
		}
		
		return _vestings[account].amount - unlocked;
	}
	
	/**
	* @dev _beforeTokenTransfer
	* @param from from address
	* @param to to address
	* @param amount amount
	*/
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal override 
	{
		super._beforeTokenTransfer(from, to, amount);
		
		// Skip mint
		if (from != address(0)) {
			uint256 locked = getLockedBalance(from);
			uint256 accountBalance = balanceOf(from);
			require(accountBalance - locked >= amount, "HCL: Transfer amount exeeds balance or some amounts are locked.");
		}
	}
}
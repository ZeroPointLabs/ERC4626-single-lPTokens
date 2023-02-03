// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/ILPToken.sol";

contract BaseVault is ERC4626, AccessControl {
    using Math for uint256;
    using SafeERC20 for IERC20;

    // TODO remeber approve to transfer
    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");

    ILPToken lpToken;

    mapping(address => uint256) public lastDepositAt;
    uint256 public cooldownDuration = 15 minutes;

    constructor(
        address _asset,
        address _lpToken,
        string memory _name,
        string memory _symbol
    ) ERC4626(IERC20(_asset)) ERC20(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        lpToken = ILPToken(_lpToken);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override onlyRole(ROUTER_ROLE) returns (uint256) {
        uint256 amount = super.deposit(assets, address(lpToken));
        lpToken.mint(receiver, amount);
        return amount;
    }

    function mint(
        uint256 shares,
        address receiver
    ) public virtual override onlyRole(ROUTER_ROLE) returns (uint256) {
        uint256 amount = super.mint(shares, address(lpToken));
        lpToken.mint(receiver, amount);
        return amount;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override onlyRole(ROUTER_ROLE) returns (uint256) {
        require(
            lastDepositAt[_msgSender()] + cooldownDuration <= block.timestamp,
            "cooldown duration not yet passed"
        );

        uint256 amount = super.withdraw(assets, receiver, address(lpToken));
        lpToken.burn(owner, amount);
        return amount;
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override onlyRole(ROUTER_ROLE) returns (uint256) {
        require(
            lastDepositAt[_msgSender()] + cooldownDuration <= block.timestamp,
            "cooldown duration not yet passed"
        );
        uint256 amount = super.redeem(shares, receiver, owner);
        lpToken.burn(owner, amount);
        return amount;
    }

    function maxRedeem(
        address owner
    ) public view virtual override returns (uint256) {
        return lpToken.balanceOf(owner);
    }
}

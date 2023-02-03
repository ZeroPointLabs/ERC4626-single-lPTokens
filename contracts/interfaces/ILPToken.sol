//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ILPToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

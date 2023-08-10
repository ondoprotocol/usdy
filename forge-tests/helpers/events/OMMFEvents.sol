pragma solidity 0.8.16;

contract OMMFEvents {
  event TransferShares(
    address indexed from,
    address indexed to,
    uint256 sharesValue
  );

  event Transfer(address indexed from, address indexed to, uint256 value);

  event SharesBurnt(
    address indexed account,
    uint256 preRebaseTokenAmount,
    uint256 postRebaseTokenAmount,
    uint256 sharesAmount
  );

  event TokensBurnt(address indexed account, uint256 tokensBurnt);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

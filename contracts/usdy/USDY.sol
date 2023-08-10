/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "contracts/external/openzeppelin/contracts-upgradeable/token/ERC20/ERC20PresetMinterPauserUpgradeable.sol";
import "contracts/usdy/blocklist/BlocklistClientUpgradeable.sol";
import "contracts/usdy/allowlist/AllowlistClientUpgradeable.sol";
import "contracts/sanctions/SanctionsListClientUpgradeable.sol";

contract USDY is
  ERC20PresetMinterPauserUpgradeable,
  BlocklistClientUpgradeable,
  AllowlistClientUpgradeable,
  SanctionsListClientUpgradeable
{
  bytes32 public constant LIST_CONFIGURER_ROLE =
    keccak256("LIST_CONFIGURER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    string memory name,
    string memory symbol,
    address blocklist,
    address allowlist,
    address sanctionsList
  ) public initializer {
    __ERC20PresetMinterPauser_init(name, symbol);
    __BlocklistClientInitializable_init(blocklist);
    __AllowlistClientInitializable_init(allowlist);
    __SanctionsListClientInitializable_init(sanctionsList);
  }

  /**
   * @notice Sets the blocklist address
   *
   * @param blocklist New blocklist address
   */
  function setBlocklist(
    address blocklist
  ) external override onlyRole(LIST_CONFIGURER_ROLE) {
    _setBlocklist(blocklist);
  }

  /**
   * @notice Sets the allowlist address
   *
   * @param allowlist New allowlist address
   */
  function setAllowlist(
    address allowlist
  ) external override onlyRole(LIST_CONFIGURER_ROLE) {
    _setAllowlist(allowlist);
  }

  /**
   * @notice Sets the sanctions list address
   *
   * @param sanctionsList New sanctions list address
   */
  function setSanctionsList(
    address sanctionsList
  ) external override onlyRole(LIST_CONFIGURER_ROLE) {
    _setSanctionsList(sanctionsList);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    super._beforeTokenTransfer(from, to, amount);

    // Check constraints when `transferFrom` is called to facliitate
    // a transfer between two parties that are not `from` or `to`.
    if (from != msg.sender && to != msg.sender) {
      require(!_isBlocked(msg.sender), "USDY: 'sender' address blocked");
      require(!_isSanctioned(msg.sender), "USDY: 'sender' address sanctioned");
      require(
        _isAllowed(msg.sender),
        "USDY: 'sender' address not on allowlist"
      );
    }

    if (from != address(0)) {
      // If not minting
      require(!_isBlocked(from), "USDY: 'from' address blocked");
      require(!_isSanctioned(from), "USDY: 'from' address sanctioned");
      require(_isAllowed(from), "USDY: 'from' address not on allowlist");
    }

    if (to != address(0)) {
      // If not burning
      require(!_isBlocked(to), "USDY: 'to' address blocked");
      require(!_isSanctioned(to), "USDY: 'to' address sanctioned");
      require(_isAllowed(to), "USDY: 'to' address not on allowlist");
    }
  }

  /**
   * @notice Burns a specific amount of tokens
   *
   * @param from The account whose tokens will be burned
   * @param amount The amount of token to be burned
   *
   * @dev This function can be considered an admin-burn and is only callable
   *      by an address with the `BURNER_ROLE`
   */
  function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
    _burn(from, amount);
  }
}

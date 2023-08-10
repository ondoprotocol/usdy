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

import "contracts/interfaces/IAllowlist.sol";
import "contracts/interfaces/IAllowlistClient.sol";

/**
 * @title AllowlistClient
 * @author Ondo Finance
 * @notice This abstract contract manages state required for clients
 *         of the allowlist
 */
abstract contract AllowlistClient is IAllowlistClient {
  // allowlist address
  IAllowlist public override allowlist;

  /**
   * @notice Constructor
   *
   * @param _allowlist Address of the blocklist contract
   */
  constructor(address _allowlist) {
    _setAllowlist(_allowlist);
  }

  /**
   * @notice Sets the allowlist address for this client
   *
   * @param _allowlist The new allowlist address
   */
  function _setAllowlist(address _allowlist) internal {
    if (_allowlist == address(0)) {
      revert AllowlistZeroAddress();
    }
    address oldAllowlist = address(allowlist);
    allowlist = IAllowlist(_allowlist);
    emit AllowlistSet(oldAllowlist, _allowlist);
  }

  /**
   * @notice Checks whether an address has been Blocked
   *
   * @param account The account to check
   */
  function _isAllowed(address account) internal view returns (bool) {
    return allowlist.isAllowed(account);
  }
}

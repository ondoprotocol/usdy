// SPDX-License-Identifier: GPL-3.0-or-later

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

contract DSTestPlus is Test {
  uint256 constant ALMOST_EQ_PERCENT = 1;

  function assertAlmostEq(uint256 a, uint256 b) internal {
    uint256 delta = (a * ALMOST_EQ_PERCENT) / 100;
    if (a < b - delta || a > b + delta) {
      emit log("Error: a == b not satisfied [uint]");
      emit log_named_uint("  Expected", b);
      emit log_named_uint("    Actual", a);
      fail();
    }
  }

  function assertAlmostEq(
    uint256 a,
    uint256 b,
    uint256 _acceptableError
  ) internal {
    // Handle underflow scenario where acceptableError > b by setting the
    // lower bound of comparison to 0 rather than a negative number
    uint256 lowerBound = _acceptableError >= b ? 0 : b - _acceptableError;

    if (a < lowerBound || a > b + _acceptableError) {
      emit log("Error: a == b not satisfied w/n acceptable error");
      emit log_named_uint("  Expected", b);
      emit log_named_uint("    Actual", a);
      fail();
    }
  }

  function assertAlmostEqBps(
    uint256 a,
    uint256 b,
    uint256 bpsAcceptableError
  ) internal {
    uint256 delta = (a * bpsAcceptableError) / 10000;
    if (a < b - delta || a > b + delta) {
      emit log("Error: a == b not satisfied [uint]");
      emit log_named_uint("  Expected", b);
      emit log_named_uint("    Actual", a);
      fail();
    }
  }

  function assertAlmostEq(uint256 a, uint256 b, string memory err) internal {
    uint256 delta = (a * ALMOST_EQ_PERCENT) / 100;
    if (a < b - delta || a > b + delta) {
      emit log_named_string("Error", err);
      assertEq(a, b);
    }
  }
}

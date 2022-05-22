//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IPancakePair {
    function getReserves() external view returns (
        uint112 _reserve0, 
        uint112 _reserve1, 
        uint32 _blockTimestampLast
    );
}
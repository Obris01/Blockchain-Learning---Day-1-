// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IDelphoConfigProvider } from "../../configurators/interfaces/IDelphoConfigProvider.sol";
import { ICoreWriter } from "../../interfaces/external/ICoreWriter.sol";
import { ISwapper } from "../../interfaces/external/ISwapper.sol";
import { IDelphoVault } from "../../interfaces/IDelphoVault.sol";
import { IDelphoRewardDistributor } from "../../interfaces/IDelphoRewardDistributor.sol";

library BaseExecutorLib {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                             CORE HELPERS
    //////////////////////////////////////////////////////////////*/

    function sendCoreAction(
        IDelphoConfigProvider cfg,
        bytes3 actionId,
        bytes memory encoded
    ) external {
        bytes memory payload =
            bytes.concat(bytes1(cfg.encodingVersion()), actionId, encoded);

        ICoreWriter(cfg.coreWriterAddress()).sendRawAction(payload);
    }

    function sendLimitOrder(
        IDelphoConfigProvider cfg,
        bytes3 actionId,
        uint32 assetOrSpotId,
        bool isBuy,
        uint64 limitPx,
        uint64 sz,
        bool reduceOnly
    ) external {
        bytes memory encoded =
            abi.encode(assetOrSpotId, isBuy, limitPx, sz, reduceOnly, uint8(3), uint64(0));

        BaseExecutorLib.sendCoreAction(cfg, actionId, encoded);
    }

    /*//////////////////////////////////////////////////////////////
                           CORE ACTIONS
    //////////////////////////////////////////////////////////////*/

    function transferUsdt2Core(
        IDelphoConfigProvider cfg
    ) external returns (uint256 bal) {
        IERC20 usdt = IERC20(cfg.usdt());
        bal = usdt.balanceOf(address(this));
        if (bal == 0) revert Delpho__NoBalance(address(usdt));

        usdt.safeTransfer(cfg.usdtSystemAddress(), bal);
    }

    function swapUsdtUsdc(
        IDelphoConfigProvider cfg,
        bool isBuy,
        uint64 limitPx,
        uint64 sz
    ) external {
        bytes memory encoded =
            abi.encode(cfg.usdtUsdcSpotId(), isBuy, limitPx, sz, false, uint8(3), uint64(0));

        BaseExecutorLib.sendCoreAction(
            cfg,
            bytes3(cfg.actionIdLimitOrder()),
            encoded
        );
    }

    function transferUsdcBetweenSpotPerp(
        IDelphoConfigProvider cfg,
        uint64 ntl,
        bool toPerp
    ) external {
        bytes memory encoded = abi.encode(ntl, toPerp);

        BaseExecutorLib.sendCoreAction(
            cfg,
            bytes3(cfg.actionIdUsdcClassTransfer()),
            encoded
        );
    }

    function openHypeShort(
        IDelphoConfigProvider cfg,
        bool isBuy,
        uint64 limitPx,
        uint64 sz
    ) external {
        BaseExecutorLib.sendLimitOrder(
            cfg,
            bytes3(cfg.actionIdLimitOrder()),
            cfg.hypePerpId(),
            isBuy,
            limitPx,
            sz,
            false
        );
    }

    function closeHypeShort(
        IDelphoConfigProvider cfg,
        uint64 limitPx,
        uint64 sz
    ) external {
        BaseExecutorLib.sendLimitOrder(
            cfg,
            bytes3(cfg.actionIdLimitOrder()),
            cfg.hypePerpId(),
            true,
            limitPx,
            sz,
            true
        );
    }

    function cancelOrderByOid(
        IDelphoConfigProvider cfg,
        uint32 asset,
        uint64 oid
    ) external {
        BaseExecutorLib.sendCoreAction(
            cfg,
            bytes3(cfg.actionIdCancelByOid()),
            abi.encode(asset, oid)
        );
    }

    function transferUsdtToHyperEvm(
        IDelphoConfigProvider cfg,
        uint64 weiAmount
    ) external {
        BaseExecutorLib.sendCoreAction(
            cfg,
            bytes3(cfg.actionIdSpotSend()),
            abi.encode(cfg.usdtSystemAddress(), cfg.usdtToken(), weiAmount)
        );
    }

    /*//////////////////////////////////////////////////////////////
                             TOKEN LOGIC
    //////////////////////////////////////////////////////////////*/

    function clawBack(
        address token,
        uint256 amount
    ) external {
        uint256 nativeBal = address(this).balance;
        if (nativeBal != 0) {
            (bool success,) = payable(msg.sender).call{ value: nativeBal }("");
            if (!success) revert Delpho__Call_Failed();
        }

        if (token != address(0)) {
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            if (tokenBalance != 0) {
                uint256 sendAmount =
                    amount < tokenBalance ? amount : tokenBalance;

                IERC20(token).safeTransfer(msg.sender, sendAmount);
            }
        }
    }

    function swapTokens(
        IDelphoConfigProvider cfg,
        address inputToken,
        address outputToken,
        uint256 minOutputAmount,
        bytes calldata swapExecuteData,
        bool useGlueX,
        uint32 deadline
    ) external returns (uint256 inputBalance, uint256 received) {
        if (inputToken == address(0) || outputToken == address(0))
            revert Delpho__AddressZero();

        inputBalance = IERC20(inputToken).balanceOf(address(this));
        if (inputBalance == 0) return (0, 0);

        uint256 beforeOutput =
            IERC20(outputToken).balanceOf(address(this));

        if (useGlueX) {
            address glueX = cfg.gluexRouter();

            IERC20(inputToken).forceApprove(glueX, 0);
            IERC20(inputToken).forceApprove(glueX, inputBalance);

            (bool ok,) = glueX.call(swapExecuteData);
            if (!ok) revert Delpho__Call_Failed();

            received =
                IERC20(outputToken).balanceOf(address(this)) -
                beforeOutput;

            if (received < minOutputAmount)
                revert Delpho__SlippageExceeded();
        } else {
            address swapper = cfg.swapper();

            IERC20(inputToken).forceApprove(swapper, 0);
            IERC20(inputToken).forceApprove(swapper, inputBalance);

            address;
            path[0] = inputToken;
            path[1] = outputToken;

            ISwapper(swapper)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    inputBalance,
                    minOutputAmount,
                    path,
                    address(this),
                    address(this),
                    deadline
                );

            received =
                IERC20(outputToken).balanceOf(address(this)) -
                beforeOutput;
        }
    }

    function transferFundsToVault(
        IDelphoConfigProvider cfg,
        address token,
        uint256 toExecutor,
        uint256 toWithdrawals
    ) external {
        if (token == address(0)) revert Delpho__AddressZero();
        if (toExecutor == 0 && toWithdrawals == 0)
            revert Delpho__InvalidAmount();

        IDelphoVault vault =
            IDelphoVault(cfg.delphoVault());

        IERC20(token).forceApprove(
            address(vault),
            toExecutor + toWithdrawals
        );

        vault.returnExecutorFunds(
            token,
            toExecutor,
            toWithdrawals
        );
    }

    function setApiWallet(
        IDelphoConfigProvider cfg,
        address apiWallet,
        string calldata apiWalletName
    ) external {
        BaseExecutorLib.sendCoreAction(
            cfg,
            bytes3(cfg.actionIdAddApiWallet()),
            abi.encode(apiWallet, apiWalletName)
        );
    }

    function notifyRewardAmount(
        IDelphoConfigProvider cfg,
        address token,
        uint256 amount
    ) external {
        IERC20(token).forceApprove(cfg.rewardDistributor(), amount);

        IDelphoRewardDistributor(cfg.rewardDistributor())
            .notifyRewardAmount(IERC20(token), amount);
    }
}

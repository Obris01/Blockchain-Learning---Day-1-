// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DelphoBase } from "../../base/DelphoBase.sol";
import { IDelphoConfigProvider } from "../../configurators/interfaces/IDelphoConfigProvider.sol";
import { IDelphoExecutorBase } from "./interfaces/IDelphoExecutorBase.sol";
import { IDelphoOracle } from "../../interfaces/IDelphoOracle.sol";
import { BaseExecutorLib } from "../../libs/executor/BaseExecutorLib.sol";

abstract contract DelphoBaseExecutor is DelphoBase, IDelphoExecutorBase {

    address public override collateralAsset;

    constructor() {
        _disableInitializers();
    }

    function __DelphoExecutorBaseInit(
        address _delphoConfig,
        address _owner,
        address _collateralAsset
    ) internal onlyInitializing {
        if (_delphoConfig == address(0) || _owner == address(0))
            revert Delpho__AddressZero();

        __DelphoBase_Init(_delphoConfig, _owner);

        _grantRole(
            IDelphoConfigProvider(_delphoConfig).EXECUTOR_ROLE(),
            _owner
        );

        collateralAsset = _collateralAsset;
    }

    function _getConfig()
        internal
        view
        returns (IDelphoConfigProvider)
    {
        return IDelphoConfigProvider(delphoConfigProvider);
    }

    /*//////////////////////////////////////////////////////////////
                           CORE ACTIONS
    //////////////////////////////////////////////////////////////*/

    function transferUsdt2Core()
        public
        virtual
        onlyRole(_getConfig().EXECUTOR_ROLE())
    {
        uint256 bal =
            BaseExecutorLib.transferUsdt2Core(_getConfig());

        emit TransferUsdt2Core(bal);
    }

    function swapUsdtUsdc(
        bool isBuy,
        uint64 limitPx,
        uint64 sz
    ) public virtual onlyRole(_getConfig().EXECUTOR_ROLE()) {
        BaseExecutorLib.swapUsdtUsdc(
            _getConfig(),
            isBuy,
            limitPx,
            sz
        );

        emit SwapUsdt2Usdc(isBuy, limitPx, sz);
    }

    function transferUsdcBetweenSpotPerp(
        uint64 ntl,
        bool toPerp
    ) public virtual onlyRole(_getConfig().EXECUTOR_ROLE()) {
        BaseExecutorLib.transferUsdcBetweenSpotPerp(
            _getConfig(),
            ntl,
            toPerp
        );

        emit TransferUsdcFromSpotToPerp(ntl, toPerp);
    }

    function openHypeShort(
        bool isBuy,
        uint64 limitPx,
        uint64 sz
    ) public virtual onlyRole(_getConfig().EXECUTOR_ROLE()) {
        BaseExecutorLib.openHypeShort(
            _getConfig(),
            isBuy,
            limitPx,
            sz
        );

        emit OpenHypeShort(isBuy, limitPx, sz);
    }

    function closeHypeShort(
        uint64 limitPx,
        uint64 sz
    ) public virtual onlyRole(_getConfig().EXECUTOR_ROLE()) {
        BaseExecutorLib.closeHypeShort(
            _getConfig(),
            limitPx,
            sz
        );

        emit CloseHypeShort(limitPx, sz);
    }

    function cancelOrderByOid(
        uint32 asset,
        uint64 oid
    ) public virtual onlyRole(_getConfig().EXECUTOR_ROLE()) {
        BaseExecutorLib.cancelOrderByOid(
            _getConfig(),
            asset,
            oid
        );
    }

    function transferUsdtToHyperEvm(
        uint64 weiAmount
    ) public virtual onlyRole(_getConfig().EXECUTOR_ROLE()) {
        BaseExecutorLib.transferUsdtToHyperEvm(
            _getConfig(),
            weiAmount
        );

        emit TransferUsdtToHyperEvm(weiAmount);
    }

    function clawBack(
        address token,
        uint256 amount
    ) public virtual onlyRole(_getConfig().EXECUTOR_ROLE()) {
        BaseExecutorLib.clawBack(token, amount);
    }

    function swapTokens(
        address inputToken,
        address outputToken,
        uint256 minOutputAmount,
        bytes calldata swapExecuteData,
        bool useGlueX,
        uint32 deadline
    ) external virtual onlyRole(_getConfig().EXECUTOR_ROLE()) {
        (uint256 inputBalance, uint256 received) =
            BaseExecutorLib.swapTokens(
                _getConfig(),
                inputToken,
                outputToken,
                minOutputAmount,
                swapExecuteData,
                useGlueX,
                deadline
            );

        if (inputBalance != 0)
            emit TokensSwapped(
                inputToken,
                outputToken,
                inputBalance,
                received
            );
    }

    function transferFundsToVault(
        address token,
        uint256 toExecutor,
        uint256 toWithdrawals
    ) external onlyRole(_getConfig().EXECUTOR_ROLE()) {
        BaseExecutorLib.transferFundsToVault(
            _getConfig(),
            token,
            toExecutor,
            toWithdrawals
        );
    }

    function setApiWallet(
        address apiWallet,
        string calldata apiWalletName
    ) external virtual onlyRole(_getConfig().EXECUTOR_ROLE()) {
        BaseExecutorLib.setApiWallet(
            _getConfig(),
            apiWallet,
            apiWalletName
        );

        emit ApiWalletUpdated(
            apiWallet,
            apiWalletName,
            apiWallet != address(0)
        );
    }

    function notifyRewardAmount(
        address token,
        uint256 amount
    )
        external
        override
        nonReentrant
        whenNotPaused
        onlyRole(_getConfig().EXECUTOR_ROLE())
    {
        BaseExecutorLib.notifyRewardAmount(
            _getConfig(),
            token,
            amount
        );
    }
}

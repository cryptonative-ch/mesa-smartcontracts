// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/ISale.sol";
import "../interfaces/IMesaFactory.sol";
import "../libraries/TransferHelper.sol";
import "../utils/cloneFactory.sol";

contract SaleLauncher is CloneFactory {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Sale {
        bool exists;
        uint64 templateId;
        uint128 index;
    }

    address[] public sales;
    uint256 public saleTemplateId;
    mapping(uint256 => address) private saleTemplates;
    mapping(address => uint256) private saleTemplateToId;
    mapping(address => Sale) public saleInfo;

    event TemplateAdded(address indexed template, uint256 templateId);
    event TemplateRemoved(address indexed template, uint256 templateId);
    event SaleLaunched(address indexed sale, uint256 templateId);
    event SaleInitialized(address indexed sale, uint256 templateId, bytes data);

    address public factory;

    constructor(address _factory) public {
        factory = _factory;
    }

    function createSale(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        address _tokenSupplier,
        bytes calldata _data
    ) external payable returns (address newSale) {
        require(
            msg.value >= IMesaFactory(factory).saleFee(),
            "SaleLauncher: SALE_FEE_NOT_PROVIDED"
        );
        require(
            saleTemplates[_templateId] != address(0),
            "SaleLauncher: INVALID_TEMPLATE"
        );

        newSale = _deploySale(_templateId);

        if (_tokenSupply > 0) {
            uint256 feeDenominator = IMesaFactory(factory).feeDenominator();
            uint256 feeNumerator = IMesaFactory(factory).feeNumerator();

            uint256 depositAmount =
                _tokenSupply.mul(feeDenominator.add(feeNumerator)).div(
                    feeDenominator
                );

            TransferHelper.safeTransferFrom(
                _token,
                _tokenSupplier,
                address(this),
                depositAmount
            );
            TransferHelper.safeApprove(_token, newSale, _tokenSupply);
            TransferHelper.safeTransfer(
                _token,
                IMesaFactory(factory).feeTo(),
                depositAmount.sub(_tokenSupply)
            );
        }
        ISale(newSale).init(_data);
        emit SaleInitialized(newSale, _templateId, _data);
        return address(newSale);
    }

    function _deploySale(uint256 _templateId)
        internal
        returns (address newSale)
    {
        newSale = createClone(saleTemplates[_templateId]);
        saleInfo[address(newSale)] = Sale(
            true,
            uint64(_templateId),
            uint128(sales.length)
        );
        sales.push(address(newSale));
        emit SaleLaunched(address(newSale), _templateId);
        return address(newSale);
    }

    function addTemplate(address _template) external returns (uint256) {
        require(
            msg.sender == IMesaFactory(factory).templateManager(),
            "SaleLauncher: FORBIDDEN"
        );
        require(
            saleTemplateToId[_template] == 0,
            "SaleLauncher: TEMPLATE_DUPLICATE"
        );

        saleTemplateId++;
        saleTemplates[saleTemplateId] = _template;
        saleTemplateToId[_template] = saleTemplateId;
        emit TemplateAdded(_template, saleTemplateId);
        return saleTemplateId;
    }

    function removeTemplate(uint256 _templateId) external {
        require(
            msg.sender == IMesaFactory(factory).templateManager(),
            "SaleLauncher: FORBIDDEN"
        );
        require(saleTemplates[_templateId] != address(0));
        address template = saleTemplates[_templateId];
        saleTemplates[_templateId] = address(0);
        delete saleTemplateToId[template];
        emit TemplateRemoved(template, _templateId);
    }

    function getTemplate(uint256 _templateId)
        public
        view
        returns (address template)
    {
        return saleTemplates[_templateId];
    }

    function getTemplateId(address _template) public view returns (uint256) {
        return saleTemplateToId[_template];
    }

    function getDepositAmountWithFees(uint256 _tokenSupply)
        public
        view
        returns (uint256)
    {
        uint256 feeDenominator = IMesaFactory(factory).feeDenominator();
        uint256 feeNumerator = IMesaFactory(factory).feeNumerator();
        return
            _tokenSupply.mul(feeDenominator.add(feeNumerator)).div(
                feeDenominator
            );
    }

    function numberOfSales() public view returns (uint256) {
        return sales.length;
    }
}

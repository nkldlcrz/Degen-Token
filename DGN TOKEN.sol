pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DegenToken is ERC20, Ownable {
    event ItemTraded(address indexed from, address indexed to, string item, uint256 quantity);
    event TradeCreated(uint256 tradeId, address indexed seller, string itemName, uint256 quantity, uint256 price);
    event ItemRedeemed(address indexed redeemer, string item, uint256 quantity);

    struct Item { uint256 quantity; uint256 price; }

    struct Trade { address seller; string itemName; uint256 quantity; uint256 price; }

    mapping(string => Item) public items;
    mapping(uint256 => Trade) public trades;
    uint256 public tradeCounter;

    constructor(address initialOwner) Ownable(initialOwner) ERC20("Degen", "DGN") {}

    function mint(address to, uint256 amount) external onlyOwner { _mint(to, amount); }

    function burn(uint256 amount) external { _burn(msg.sender, amount); }

    function transfer(address to, uint256 amount) public override returns (bool) { _transfer(_msgSender(), to, amount); return true; }

    function redeem(string memory itemName, uint256 quantity) external {
        Item storage item = items[itemName];
        require(item.quantity >= quantity && item.price * quantity <= balanceOf(msg.sender), "Invalid redemption");
        _burn(msg.sender, item.price * quantity);
        item.quantity -= quantity;
        emit ItemRedeemed(msg.sender, itemName, quantity);
    }   

    function listItem(string memory itemName, uint256 quantity, uint256 price) public onlyOwner {
        items[itemName] = Item({ quantity: quantity, price: price });
    }

    function createTrade(string memory itemName, uint256 quantity, uint256 price) external {
        require(quantity > 0, "Quantity must be greater than zero");
        require(price > 0, "Price must be greater than zero");

        uint256 tradeId = tradeCounter++; // Generate unique trade ID
        trades[tradeId] = Trade({
            seller: msg.sender,
            itemName: itemName,
            quantity: quantity,
            price: price
        });
        emit TradeCreated(tradeId, msg.sender, itemName, quantity, price);
    }

    function completeTrade(uint256 tradeId) external {
        Trade storage trade = trades[tradeId];
        require(trade.quantity > 0 && trade.price * trade.quantity <= balanceOf(msg.sender), "Invalid trade completion");
        _burn(msg.sender, trade.price * trade.quantity);
        _mint(trade.seller, trade.price * trade.quantity);
        emit ItemTraded(trade.seller, msg.sender, trade.itemName, trade.quantity);
        delete trades[tradeId];
    }

    function getTrade(uint256 tradeId) external view returns (address seller, string memory itemName, uint256 quantity, uint256 price) {
        Trade storage trade = trades[tradeId];
        return (trade.seller, trade.itemName, trade.quantity, trade.price);
    }

    function checkTheBalance(address account) external view returns (uint256) { return balanceOf(account); }
}


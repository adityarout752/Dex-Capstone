// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Dex {   
  
  enum Side {
      BUY,
      SELL
  }

  struct Token{
      bytes32 ticker;
      address tokenAddress;
  }

  struct Order{
      uint id;
      address trader;
      Side side;
      bytes32 ticker;
      uint amount;
      uint price;
      uint filled;
      uint date;

  }

  mapping(bytes32 => Token) public tokens;
  bytes32[] public tokenList;
  
  mapping(address => mapping(bytes32 => uint))  traderBalances;
   
   mapping(bytes32 =>mapping(uint => Order[])) orderBook;

   address public admin;

   uint public nextOrderId;
   uint public nextTradeId;

   bytes32 constant DAI = bytes32('DAI');

   event NewTrade(
       uint tradeId,
       uint orderId,
       bytes32 indexed trader,
       address indexed trader1,
       address indexed trader2,
       uint amount,
       uint price,
       uint date
   );

     constructor() {
        admin = msg.sender;
    }


    function getOrders(
        bytes32 ticker,
        Side side

    ) external view returns(Order [] memory) {
      return orderBook[ticker][uint(side)];

    }

    function getTokens()
    external view returns(Token[] memory) {
        Token[] memory _tokens = new Token[](tokenList.length);
        for(uint i=0;i<tokenList.length;i++) {
            _tokens[i] = Token(
                tokens[tokenList[i]].ticker,
                tokens[tokenList[i]].tokenAddress

            );
        }
        return _tokens;
    }


    function addToken(
        bytes32 ticker,
        address tokenAddress
    ) onlyAdmin() external {

     tokens[ticker] = Token(ticker,tokenAddress);
     tokenList.push(ticker);
    }

    function deposit(
        uint amount,
        bytes32 ticker
    ) tokenExists(ticker)
    external
     {
         IERC20(tokens[ticker].tokenAddress).transferFrom
         (msg.sender,
          address(this)
          ,amount);

        traderBalances[msg.sender][ticker] + = amount;
    }

    function withdraw(
        uint amount,
        bytes32 ticker,
    )   tokenExist(ticker)
        external {
           
           require(  traderBalances[msg.sender][ticker] >= amount,"balance is too low");

            traderBalances[msg.sender][ticker] - = amount;
            IERC20(tokens[ticker].tokenAddress).transfer(
                msg.sender,
                amount
            )

        }

        function createLimitOrder(
            bytes32 ticker,
            uint amount,
            uint price,
            Side side
        ) tokenExist(ticker)
        tokenIsNotDai(ticker)
        external{

            if(side == Side.sell) {
                require(  traderBalances[msg.sender][ticker] >= amount,"balance is less to be sell");
            } else {
                            require(traderBalances[msg.sender][DAI] >= amount * price,  'dai balance too low');
            }

            Order [] storage orders = orderBook[ticker][uint(side)];
            orders.push(
                Order(
                    nextOrderId,
                    msg.sender,
                    side,
                    ticker,
                    amount,
                    0,
                    price,
                    block.timestamp
                )
            );

             uint i = orders.length > 0 ? orders.length - 1 : 0;

            while(i>0)  {

            if(side == Side.BUY && orders[i-1].price > orders[i].price )
            {
                           break;
            }

              if(side == Side.SELL && orders[i-1].price <orders[i].price )
              {
                           break;
              }
           
           Order memory order = orders[i-1];
           orders[i-1] = orders[i];
           order[i] = order;
           i--;
            }
            nextOrderId++;
            

        }

        }




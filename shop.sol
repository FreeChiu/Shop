pragma solidity ^0.4.18;

contract Shop {

    //address public Owner = 0xcbb4366513D8e7119925a9AeADcb4ca2891A3EB4; //卖家地址
    address public Owner; // 地址变量owner
    address public MyAddress = msg.sender; //当前用户地址
    
    function OwnableOwner() public { // 构造函数
        Owner = 0xc08C43932A48Dc08b3155E8776F2A29C2F08ac64; // owner初始化为智能合约拥有者的地址
    }
    
    modifier onlyOwner() { //修改器
        require(msg.sender == Owner); //如果操作为非拥有者，则抛出异常
        _;
    }
    
    // 出售状态
    enum ProductStatus {
        Selling, //正在出售
        SoldOut //下架
    }

    uint public productIndex; //产品id
    mapping(address => mapping(uint => Product)) store; //卖家地址 => 产品字典(id => 产品信息)
    mapping(uint => address) productIdInStore; //产品id => 卖家钱包地址

    // 已买商品
    uint public boughtIndex; //产品id
    mapping(uint => mapping(uint => Buyer)) boughtList;
    mapping(address => uint) bought; //买家地址 => 产品

    // 商品信息结构体
    struct Product {
        uint id; //商品id
        string name; //商品名称
        string picLink; //商品照片
        string descLink; //商品描述
        uint productTotal; //商品数量
        uint price; //商品价格
        uint soldTotal; //已售出数量
        ProductStatus status; //出售状态
    }

    // 初始化商品id
    function productIndex() public{
        productIndex = 0;
    }

    // 产品id
    function productId() public view returns(uint) {
        return productIndex;
    }
    
    // 初始化商品id
    function boughtIndex() public{
        boughtIndex = 0;
    }

    // 产品id
    function boughtID() public view returns(uint) {
        return boughtIndex;
    }

    // 买家信息结构体
    struct Buyer {
        uint id;
        address buyerAddress; //买家地址
        uint productId; //产品id
    }

    // 监听NewProduct事件
    event NewProduct(
        uint id,
        string name,
        string picLink,
        string descLink,
        uint productTotal,
        uint price
    );

    // 监听BuyProduct事件
    event BuyProduct(
        address buyer,
        address seller,
        uint productId,
        uint value
    );
    
    event BoughtProduct(
        uint id,
        address buyer,
        uint productId
    );

    // 购买
    function buy(uint _productId) public payable returns(bool) {
        Product storage product = store[productIdInStore[_productId]][_productId]; //获取卖家钱包地址 然后获取产品信息
        require(product.productTotal > 0); //产品数量大于0
        require(product.status == ProductStatus.Selling); //产品处于正在出售状态
        require(MyAddress.balance >= msg.value); //账户余额大于等于支付的金额
        require(msg.value == product.price);  //向合约发送的以太等于商品价格
        Owner.transfer(msg.value);
        emit BuyProduct(msg.sender,Owner, _productId, msg.value);
        
        boughtIndex += 1;
        Buyer memory buyer = Buyer(boughtIndex, msg.sender, productIndex);
        boughtList[boughtIndex][productIndex] = buyer;
        bought[msg.sender] = boughtIndex;
        emit BoughtProduct(boughtIndex, msg.sender, productIndex);
        product.soldTotal += 1; //已售出数量加一
        product.productTotal -= 1; //产品数量减一
        // 商品数量为零时,商品状态改为下架
        if (product.productTotal == 0){
            product.status = ProductStatus.SoldOut;
        }
        return true;
    }

    // 获取商品
    function getProduct(uint _productId) public view returns(uint, string, string, string, uint, uint, uint, ProductStatus) {
        Product memory product = store[productIdInStore[_productId]][_productId]; //获取卖家钱包地址 然后获取产品信息
        //返回(产品id, 产品名称, 产品照片, 产品描述, 产品数量, 产品价格, 已售出数量, 出售状态)
        return (
            product.id, 
            product.name, 
            product.picLink, 
            product.descLink, 
            product.productTotal, 
            product.price, 
            product.soldTotal, 
            product.status
        );
    }

    // 添加商品
    function addProductToStore(string _name, string _picLink, string _descLink, uint _productTotal, uint _price) public onlyOwner{
        require(_productTotal > 0); //商品数量大于0
        require(_price > 0); //定价大于0
        productIndex += 1; //产品编号自增一
        Product memory product = Product(productIndex, _name, _picLink, _descLink, _productTotal, _price, 0, ProductStatus.Selling);
        store[Owner][productIndex] = product;
        productIdInStore[productIndex] = Owner;
        emit NewProduct(productIndex, _name, _picLink, _descLink, _productTotal, _price);
    }
    
    function getBuyer(address _address) public view returns(address, uint){
        Buyer storage buyer = boughtList[bought[_address]][bought[_address]];
        return(buyer.buyerAddress, buyer.productId);
    }
    
    

}

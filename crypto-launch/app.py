import os
import json
import time
import smtplib
from flask import Flask, request, jsonify
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from solcx import compile_standard, install_solc
from web3 import Web3
import requests

app = Flask(__name__)


#b4a keys and app id
APPLICATION_ID = "4AzhqGJcNjNKWpaA5O98BHnqJsGjcLoN9nYfisvv"
REST_API_KEY = "9ctyWy2q00TjIh578ZHFxP1DRyeidliStEIEfWvO"
SERVER_URL = "https://parseapi.back4app.com"

# infura api blockchain and central wallet private key
PROJECT_ID = "9f1930d45ffc4e6f8f905f578d1539cb"
PRIVATE_KEY = "a77402a3dff5993dfdb2be3310bb6c1b3ce828b1fe2361e35c07fe09d2345f11"

# helper function to send confirmation email
def send_confirmation_email(
    receiver_email: str,
    coin_name: str,
    coin_symbol: str,
    total_supply: int,
    coin_address: str,
    image_url: str
) -> bool:
    sender_email = "brian.todi03@gmail.com"
    sender_password = "rjce fuai ojbu oozp"
    receiver_emails = [receiver_email]

    message = MIMEMultipart()
    message["From"] = sender_email
    message["To"] = receiver_email
    message["Subject"] = f"Your Coin '{coin_name}' Is Live!"

    polygonscan_link = f"https://polygonscan.com/token/{coin_address}"
    dex_link = f"https://app.uniswap.org/explore/tokens/polygon/{coin_address}"

    #email body with some basic hrml/css to make it look decent
    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8" />
    <title>Coin Launch Confirmation</title>
    </head>
    <body style="font-family: Arial, sans-serif; color: #333;">

    <h2>Your coin is live!</h2>

    <p><strong>{coin_name}</strong> has been successfully launched on Polygon.</p>

    <p>
        <img src="{image_url}" 
            style="width: 150px; height: 150px; object-fit: cover; border-radius: 10px;"
            alt="Coin Image"/>
    </p>

    <table style="border-collapse: collapse; margin-top: 10px; margin-bottom: 20px;">
        <tr><td style="padding: 4px 8px;"><strong>Name:</strong> {coin_name}</td></tr>
        <tr><td style="padding: 4px 8px;"><strong>Symbol:</strong> {coin_symbol}</td></tr>
        <tr><td style="padding: 4px 8px;"><strong>Total Supply:</strong> {total_supply:,}</td></tr>
        <tr><td style="padding: 4px 8px;"><strong>Contract Address:</strong> {coin_address}</td></tr>
    </table>

    <p><strong>View your coin:</strong> <a href="{polygonscan_link}" target="_blank">PolygonScan Link</a></p>
    <p><strong>Trade your coin:</strong> <a href="{dex_link}" target="_blank">Uniswap Link</a></p>

    </body>
    </html>
    """

    message.attach(MIMEText(html_body, "html"))

    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(sender_email, sender_password)
        server.sendmail(sender_email, receiver_email, message.as_string())
        server.quit()
        print("Email sent successfully!")
        return True
    except Exception as e:
        print(f"Error sending email: {e}")
        return False


# main function to start deployment
def startRunning(contract_name, contract_symbol):

    # deploy contract with EIP-1559 fees, call addLiqduitiy with new nonce
    # https://docs.openzeppelin.com/contracts/5.x/erc20#:~:text=An%20ERC%2D20%20token%20contract,rights%2C%20staking%2C%20and%20more.
    SOLIDITY_SOURCE_MAIN = r"""
    // SPDX-License-Identifier: MIT
    pragma solidity >=0.8.18;

    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    interface INonfungiblePositionManager {
        struct MintParams {
            address token0;
            address token1;
            uint24 fee;
            int24 tickLower;
            int24 tickUpper;
            uint256 amount0Desired;
            uint256 amount1Desired;
            uint256 amount0Min;
            uint256 amount1Min;
            address recipient;
            uint256 deadline;
        }
        function mint(MintParams calldata params) external payable returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );
        function createAndInitializePoolIfNecessary(
            address token0,
            address token1,
            uint24 fee,
            uint160 sqrtPriceX96
        ) external payable returns (address pool);
    }

    contract CoinContract is ERC20 {
        INonfungiblePositionManager posMan = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
        address constant weth = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // Polygon wMatic
        uint supply = 1_000_000 * 10 ** decimals();
        uint24 constant fee = 500;
        uint160 constant sqrtPriceX96 = 79228162514264337593543950336; // ~ 1:1
        int24 minTick;
        int24 maxTick;
        address public pool;
        address token0;
        address token1;
        uint amount0Desired;
        uint amount1Desired;
        
        constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
            _mint(address(this), supply);
            fixOrdering();
            pool = posMan.createAndInitializePoolIfNecessary(token0, token1, fee, sqrtPriceX96);
        }

        function addLiquidity() public {
            IERC20(address(this)).approve(address(posMan), supply);
            posMan.mint(INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: fee,
                tickLower: minTick,
                tickUpper: maxTick,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 1200
            }));
        }

        function fixOrdering() private {
            if (address(this) < weth) {
                token0 = address(this);
                token1 = weth;
                amount0Desired = supply;
                amount1Desired = 0;
                minTick = 0;
                maxTick = 887270;
            } else {
                token0 = weth;
                token1 = address(this);
                amount0Desired = 0;
                amount1Desired = supply;
                minTick = -887270;
                maxTick = 0;
            }
        }
    }
    """

    # openzeppelin files
    # https://www.cyfrin.io/glossary/erc-20-solidity-code-example
    OZ_ERC20 = r"""
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
    import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
    import "@openzeppelin/contracts/utils/Context.sol";

    contract ERC20 is Context, IERC20, IERC20Metadata {
        mapping(address => uint256) private _balances;
        mapping(address => mapping(address => uint256)) private _allowances;
        uint256 private _totalSupply;
        string private _name;
        string private _symbol;

        constructor(string memory name_, string memory symbol_) {
            _name = name_;
            _symbol = symbol_;
        }

        function name() public view virtual override returns (string memory) {
            return _name;
        }

        function symbol() public view virtual override returns (string memory) {
            return _symbol;
        }

        function decimals() public view virtual override returns (uint8) {
            return 18;
        }

        function totalSupply() public view virtual override returns (uint256) {
            return _totalSupply;
        }

        function balanceOf(address account) public view virtual override returns (uint256) {
            return _balances[account];
        }

        function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }

        function allowance(address owner, address spender) public view virtual override returns (uint256) {
            return _allowances[owner][spender];
        }

        function approve(address spender, uint256 amount) public virtual override returns (bool) {
            _approve(_msgSender(), spender, amount);
            return true;
        }

        function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) public virtual override returns (bool) {
            _transfer(sender, recipient, amount);
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
            return true;
        }

        function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
            _approve(_msgSender(), spender, allowance(_msgSender(), spender) + addedValue);
            return true;
        }

        function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
            uint256 currentAllowance = _allowances[_msgSender()][spender];
            require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
            unchecked {
                _approve(_msgSender(), spender, currentAllowance - subtractedValue);
            }
            return true;
        }

        function _transfer(
            address sender,
            address recipient,
            uint256 amount
        ) internal virtual {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");

            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);
        }

        function _mint(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: mint to the zero address");
            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);
        }

        function _burn(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: burn from the zero address");
            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
            unchecked {
                _balances[account] = accountBalance - amount;
            }
            _totalSupply -= amount;
            emit Transfer(account, address(0), amount);
        }

        function _approve(
            address owner,
            address spender,
            uint256 amount
        ) internal virtual {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
    }
    """

    OZ_IERC20 = r"""
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    interface IERC20 {
        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) external returns (bool);

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }
    """

    OZ_IERC20METADATA = r"""
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

    interface IERC20Metadata is IERC20 {
        function name() external view returns (string memory);
        function symbol() external view returns (string memory);
        function decimals() external view returns (uint8);
    }
    """

    OZ_CONTEXT = r"""
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }

        function _msgData() internal view virtual returns (bytes calldata) {
            return msg.data;
        }
    }
    """

    # get the correct sol version
    SOLC_VERSION = "0.8.18"
    try:
        install_solc(SOLC_VERSION)
    except:
        pass

    # compile in memory
    compiled_sol = compile_standard(
        {
            "language": "Solidity",
            "sources": {
                "CoinContract.sol": {"content": SOLIDITY_SOURCE_MAIN},
                "@openzeppelin/contracts/token/ERC20/ERC20.sol": {"content": OZ_ERC20},
                "@openzeppelin/contracts/token/ERC20/IERC20.sol": {"content": OZ_IERC20},
                "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol": {"content": OZ_IERC20METADATA},
                "@openzeppelin/contracts/utils/Context.sol": {"content": OZ_CONTEXT},
            },
            "settings": {
                "optimizer": {"enabled": True, "runs": 200},
                "outputSelection": {
                    "*": {
                        "*": ["abi", "metadata", "evm.bytecode", "evm.sourceMap"]
                    }
                },
            },
        },
        solc_version=SOLC_VERSION,
    )

    contract_interface = compiled_sol["contracts"]["CoinContract.sol"]["CoinContract"]
    abi = contract_interface["abi"]
    bytecode = contract_interface["evm"]["bytecode"]["object"]

    #use infura and connect to polygon mainnet
    POLYGON_RPC_URL = "https://polygon-mainnet.infura.io/v3/" + PROJECT_ID
    w3 = Web3(Web3.HTTPProvider(POLYGON_RPC_URL))

    if not w3.is_connected():
        print("Could not connect to the Polygon mainnet RPC.")
        return ""

    # deploy contract using eip-1559 params
    account = w3.eth.account.from_key(PRIVATE_KEY)
    from_address = account.address

    CoinContract = w3.eth.contract(abi=abi, bytecode=bytecode)
    constructor_txn = CoinContract.constructor(contract_name, contract_symbol)

    nonce = w3.eth.get_transaction_count(from_address)
    # nonce = w3.eth.get_transaction_count(from_address, 'pending')


    # should be 50 but im paying 100 wei max fee to speed things up
    gas_estimate = constructor_txn.estimate_gas({"from": from_address})
    max_fee = w3.to_wei('100', 'gwei')
    priority_fee = w3.to_wei('40', 'gwei')

    deploy_txn = constructor_txn.build_transaction({
        "chainId": 137,
        "from": from_address,
        "nonce": nonce,
        # adding 50k as a buffer so it moves faster
        "gas": gas_estimate + 50_000,
        "maxFeePerGas": max_fee,
        "maxPriorityFeePerGas": priority_fee,
    })

    signed_deploy_txn = account.sign_transaction(deploy_txn)
    tx_hash = w3.eth.send_raw_transaction(signed_deploy_txn.rawTransaction)
    print(f"token sent, hash: {tx_hash.hex()}")

    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    if tx_receipt.status != 1:
        print("deployment failed")
        return ""
        #sleep after deployment
    time.sleep(2)

    deployed_address = tx_receipt.contractAddress
    # succesfully deployed
    print(f"Contract deployed at address: {deployed_address}")

    #make a new nonce and call addliqudiity
    nonce += 1  #increment for next transaction

    contract_instance = w3.eth.contract(address=deployed_address, abi=abi)

    #call addliquidity using from address
    addliq_gas_estimate = contract_instance.functions.addLiquidity().estimate_gas({"from": from_address})

    #chain id set to polygon
    add_liquidity_txn = contract_instance.functions.addLiquidity().build_transaction({
        "chainId": 137,
        "from": from_address,
        "nonce": nonce,
        #extra gas again to make it work 
        "gas": addliq_gas_estimate + 50_000,
        "maxFeePerGas": max_fee,
        "maxPriorityFeePerGas": priority_fee,
    })

    signed_liquidity_txn = account.sign_transaction(add_liquidity_txn)
    addliq_hash = w3.eth.send_raw_transaction(signed_liquidity_txn.rawTransaction)
    print(f"calling add liquidity on contract, hash: {addliq_hash.hex()}")

    addliq_receipt = w3.eth.wait_for_transaction_receipt(addliq_hash)
    if addliq_receipt.status != 1:
        print("addLiquidity transaction failed!")
        return ""
    # print("addliq")
    print("addLiquidity transaction went through!")
    return deployed_address

#launch coin route
@app.route('/cryptolaunch/launchCoin', methods=['POST'])
def launch_coin():

    # database class info
    HTTP_CLIENT = "parseapi.back4app.com"
    SCHEMA = "https://"
    PARSE_APP_ID = "4AzhqGJcNjNKWpaA5O98BHnqJsGjcLoN9nYfisvv"
    PARSE_MASTER_KEY = "CKgNuSayZTpRs5B2ndMLc7vYG1kHKwVWoH7TLIUW"

    # parse user input from app form
    user_id = request.form.get('user_id')
    name = request.form.get('name')
    ticker = request.form.get('ticker')
    description = request.form.get('description')
    initial_supply = request.form.get('initial_supply')
    email = request.form.get('email')
    
    if not all([user_id, name, ticker, description, initial_supply, email]):
        return jsonify({"error": "Missing required fields."}), 400

    # upload the posted image to parse files
    icon_url = ""
    if "image" in request.files:
        file = request.files["image"]
        filename = file.filename
        content_type = file.content_type or "application/octet-stream"
        file_data = file.read()

        # parse files headers
        file_upload_url = f"{SCHEMA}{HTTP_CLIENT}/files/{filename}"
        file_upload_headers = {
            "X-Parse-Application-Id": PARSE_APP_ID,
            "X-Parse-Master-Key": PARSE_MASTER_KEY,
            "Content-Type": content_type
        }

        #upload to files
        file_resp = requests.post(file_upload_url, headers=file_upload_headers, data=file_data)

        if file_resp.status_code == 201:
            #resp
            icon_url = file_resp.json().get("url", "")
            print("File uploaded successfully:", icon_url)
        else:
            print("File upload failed:", file_resp.text)
            return jsonify({"error": "File upload failed", "details": file_resp.json()}), 400

    else:
        # leave blank if no file uploaded
        icon_url = ""

    # add new row to b4a with completion false
    new_row_data = {
        "user_id": user_id,
        "name": name,
        "ticker": ticker,
        "description": description,
        "initial_supply": initial_supply,
        "email": email,
        "completed": False,
        "chain": "Polygon",
        "icon": icon_url
    }

    # if launch never goes through, row will always exist as pending
    headers = {
        "X-Parse-Application-Id": APPLICATION_ID,
        "X-Parse-REST-API-Key": REST_API_KEY,
        "Content-Type": "application/json"
    }
    save_url = f"{SERVER_URL}/parse/classes/Launch"
    save_resp = requests.post(save_url, headers=headers, data=json.dumps(new_row_data))
    if save_resp.status_code != 201:
        return jsonify({"error": "Failed to save coin row", "details": save_resp.json()}), 400
    objectId = save_resp.json().get("objectId", "")

    #call startrunning to begin deploying coin
    coin_address = startRunning(name, ticker)

    #cgeck if it worked
    if not coin_address:
        print("Coin creation failed on chain.")
        return jsonify({"error": "On-chain coin creation failed."}), 500

    # setup the links for view and trade buttons
    polygonscan_link = f"https://polygonscan.com/token/{coin_address}"
    

    # https://app.uniswap.org/explore/tokens/polygon/
    dex_link = f"https://app.uniswap.org/explore/tokens/polygon/{coin_address}"

    # once completed update rows with the new links and CA
    update_data = {
        "completed": True,
        "wallet_address": coin_address, #final CA
        "dex_link": dex_link, #Uniswap
        "polyscan_link": polygonscan_link
    }
    update_url = f"{SERVER_URL}/parse/classes/Launch/{objectId}"
    update_resp = requests.put(update_url, headers=headers, data=json.dumps(update_data))
    if update_resp.status_code not in [200, 201]:
        print("Warning: row update failed", update_resp.json())

    #call send confirmation email
    try:
        total_supply_int = int(initial_supply)
    except Exception:
        total_supply_int = 1_000_000

        #pass in all the user token info
    email_ok = send_confirmation_email(
        receiver_email=email,
        coin_name=name,
        coin_symbol=ticker,
        total_supply=total_supply_int,
        coin_address=coin_address,
        image_url=icon_url
    )
    if not email_ok:
        #failed email
        print("Email sending failed, but coin is created + row updated.")
    else:
        print("All done: coin created, row updated, email sent.")

    return jsonify({
        #everything went through?
        "message": "Coin launched, contract created, row updated, email sent.",
        "objectId": objectId,
        "wallet_address": coin_address,
        "dex_link": dex_link,
        "polyscan_link": polygonscan_link
    }), 200


#getcoins route to load in all the coin data for homepage
@app.route("/cryptolaunch/getCoins", methods=["POST"])
def get_coins():
    req = request.get_json() or {}
    print("HIT with req:", req)
    viral_url = "https://api.coingecko.com/api/v3/coins/markets"

    #parameters for viral
    viral_params = {
        "vs_currency": "usd",
        "category": "solana-meme-coins",
        "order": "market_cap_desc",
        "per_page": 15,
        "page": 1,
        "sparkline": "false",
        "price_change_percentage": "1h,24h,7d"
    }
    viral_response = requests.get(viral_url, params=viral_params)
    if viral_response.status_code != 200:
        return jsonify(data=[], msg="Error fetching viral coins", status=viral_response.status_code)
    viral_coins = viral_response.json()

    #api url to get polyogn top gainers  coins
    biggest_url = "https://api.coingecko.com/api/v3/coins/markets"
    biggest_params = {
        "vs_currency": "usd",
        "category": "polygon-ecosystem",
        "order": "market_cap_desc",
        "per_page": 50,
        "page": 1,
        "sparkline": "false",
        "price_change_percentage": "1h,24h,7d"
    }
    #get data form api
    biggest_response = requests.get(biggest_url, params=biggest_params)
    if biggest_response.status_code != 200:
        return jsonify(data=[], msg="Error fetching biggest gainers", status=biggest_response.status_code)
    all_coins_for_gainers = biggest_response.json()
    all_coins_for_gainers.sort(key=lambda x: x.get("price_change_percentage_24h", 0), reverse=True)
    biggest_gainers = all_coins_for_gainers[:8]

    #API url to get top markets
    top_url = "https://api.coingecko.com/api/v3/coins/markets"
    top_params = {
        "vs_currency": "usd",
        "category": "polygon-ecosystem",
        "order": "market_cap_desc",
        "per_page": 5,
        "page": 1,
        "sparkline": "false",
        "price_change_percentage": "1h,24h,7d"
    }
    top_response = requests.get(top_url, params=top_params)
    if top_response.status_code != 200:
        return jsonify(data=[], msg="Error fetching top market cap", status=top_response.status_code)
    top_market_cap = top_response.json()

    # return all three batches in one
    data = {
        "viralCoins": viral_coins,#top section
        "biggestGainers": biggest_gainers,
        "topMarketCap": top_market_cap #buggest market cap at bottom
    }
    return jsonify(data=data, msg="", status=200)

#route to get additional coin details
@app.route('/cryptolaunch/getCoinDetails', methods=["POST"])
def get_coin_details():

    #get coin id from user
    req = request.get_json()
    coin_id = req.get('coin_id')

    #send req to get deeper analytics for coin chart page
    if not coin_id:
        return jsonify(data=None, msg="coin_id is required", status=400)
    coin_details = fetch_coin_details(coin_id)
    if not coin_details:
        return jsonify(data=None, msg=f"Error fetching details for {coin_id}", status=500)
    return jsonify(data=coin_details, msg="", status=200)

#route to get market data to construct chart
@app.route('/cryptolaunch/getCoinMarketChart', methods=["POST"])
def get_coin_market_chart():
    req = request.get_json()

    #get coin id from user
    coin_id = req.get('coin_id')
    days = req.get('days', '1')
    vs_currency = req.get('vs_currency', 'usd')
    if not coin_id:
        return jsonify(data=None, msg="coin_id is required", status=400)

    #send req to get market chart data from helper
    market_chart_data = fetch_coin_market_chart(coin_id, vs_currency, days)
    if not market_chart_data:
        # print("error")
        return jsonify(data=None, msg=f"Error fetching market chart data for {coin_id}", status=500)
    return jsonify(data=market_chart_data, msg="", status=200)

#route to fetch the coins that the user has created
@app.route("/cryptolaunch/getUserCoins", methods=["POST"])
def get_user_coins():
    req = request.get_json() or {}

    #get user if from user
    user_id = req.get("user_id")
    if not user_id:
        return jsonify(data=[], msg="Missing user_id", status=400)
    import json

    #query back4app with the user id to collect history of launched coins
    where_clause = {"user_id": user_id}
    query_params = {"where": json.dumps(where_clause), "order": "-createdAt"}
    parse_url = f"{SERVER_URL}/parse/classes/Launch"
    headers = {
        "X-Parse-Application-Id": APPLICATION_ID,
        "X-Parse-REST-API-Key": REST_API_KEY
    }
    response = requests.get(parse_url, headers=headers, params=query_params)
    if response.status_code != 200:
        return jsonify(data=[], msg="Error fetching user coins", status=response.status_code, details=response.text)
    result_json = response.json()

    #return array of launched coins
    coins = result_json.get("results", [])
    return jsonify(data=coins, msg="", status=200)


#helper function to get coin details
def fetch_coin_details(coin_id):
    base_url = 'https://api.coingecko.com/api/v3'
    coin_details_url = f'{base_url}/coins/{coin_id}'

    #specific params for details page
    params = {
        'localization': 'false',
        'tickers': 'false',
        'market_data': 'true',
        'community_data': 'false',
        'developer_data': 'false',
        'sparkline': 'false'
    }
    response = requests.get(coin_details_url, params=params)
    if response.status_code != 200:
        print(f"Error fetching details for {coin_id}: {response.status_code} - {response.text}")
        return None
    try:
        #try to get pill data
        coin_details = response.json()
        market_data = coin_details.get("market_data", {})
        return {
            #all data we use in the 6 pills
            "market_cap": market_data.get("market_cap", {}).get("usd", 0),
            "volume_24h": market_data.get("total_volume", {}).get("usd", 0),
            "fdv": market_data.get("fully_diluted_valuation", {}).get("usd", 0),
            "circulating_supply": market_data.get("circulating_supply", 0),
            "total_supply": market_data.get("total_supply", 0),
            "max_supply": market_data.get("max_supply", 0)
        }
    except Exception as e:
        print(f"Exception parsing coin details for {coin_id}: {e}")
        return None

#helper function to get chart history
def fetch_coin_market_chart(coin_id, vs_currency='usd', days='1'):
    base_url = 'https://api.coingecko.com/api/v3'
    market_chart_url = f'{base_url}/coins/{coin_id}/market_chart'

    #days and price as axes?
    params = {
        'vs_currency': vs_currency,
        'days': days
    }
    response = requests.get(market_chart_url, params=params)
    if response.status_code != 200:
        print(f"Error fetching market chart data for {coin_id}: {response.status_code} - {response.text}")
        return None
    try:
        #get price ay each dat
        market_chart_data = response.json()
        if "prices" not in market_chart_data:
            print(f"No 'prices' field in market chart response for {coin_id}")
            return None
            #return array of price history
        return market_chart_data["prices"]
    except Exception as e:
        print(f"Exception parsing market chart data for {coin_id}: {e}")
        return None

#main function to run script
if __name__ == "__main__":
    app.run(debug=True)

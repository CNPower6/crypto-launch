A Mobile Platform to Launch L2 Cryptocurrencies that are Immediately Tradable Without Seeding Liquidity 

Abstract 

Blockchain technology has continued to transform the landscape of decentralized financial (DeFi) applications, yet many of its core capabilities are simply inaccessible to non technical users. This thesis report outlines a mobile platform that allows users to easily create, deploy, and trade their own Polygon ERC-20 tokens without requiring a wallet or seeding liquidity. The project’s flow for launching a cryptocurrency integrates an automation for creating a single-sided liquidity pool through Uniswap’s Nonfungible Position Manager. Newly launched tokens approve this Uniswap contract to access the entire balance of created tokens. Then, the token gets a market pair – in this case token/wMatic, which enables users to trade the new coin on platforms that interact with Uniswap V3 pools. In manual methods of launching cryptocurrencies, once launched the token exists on-chain – but cannot be traded via decentralized exchanges as there is no market pair for liquidity. This project bypasses the conventional need to manually provide paired liquidity on third party exchanges. The app utilizes a user-friendly mobile interface connected to a Flask backend and Parse database. The flask backend handles smart contract operations and deployment, effectively abstracting all technical barriers which include wallet creation, smart contract writing and signing, gas fee payments, liquidity pool creation, etc. Using the technology in this project, beginners can create and deploy tokens without a deep understanding of the underlying solidity contracts that are being deployed. This paves the way for a much broader adoption of DeFi tools since it greatly reduces the entry barriers which previously boxed out crypto from non highly technical users.  







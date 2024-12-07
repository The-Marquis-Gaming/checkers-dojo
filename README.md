# Checkers

![Checkers Game](/the-marquis/packages/nextjs/public/landingpage/BannerChecker2.png)

Checkers is a classic board game implemented in a web environment using the Dojo Engine. This project leverages Starknet’s Layer 2 to create a fully decentralized, on-chain checkers game. All game logic, including player moves, validations, and win conditions, is implemented with smart contracts on Starknet, ensuring transparency and fairness.

- Create Burners
- Controller

## Prerequisites

Before you begin, ensure you have the following installed on your machine:

- **[Node.js](https://nodejs.org/)**
- **[pnpm](https://pnpm.io/)**
- **[Dojo v1.0.2](https://book.dojoengine.org/)**

---

## Quick Start Guide

### Terminal 1: The Marquis

Open a terminal and run:

```bash
cd the-marquis
yarn install 
yarn start
```

### Terminal 2: Start Katana

Open a terminal and run:

```bash
cd dojo-starter
katana --disable-fee --allowed-origins "*"
```

### Terminal 3: Build and Migrate the Project

In a second terminal, execute:

```bash
cd dojo-starter
sozo build
sozo migrate
torii --world 0x07e0aa9c93c6b71781b605aeeeb85ee7d097b592c85db0383515c7a17f262af3 --allowed-origins "*"
```

### Terminal 4: Start the Client

In a third terminal, navigate to the client folder and run:

```bash
cd client
pnpm i
pnpm dev
```

## Cartridge Controller
To test the connection with the controller, follow these steps:

Use ngrok: ngrok http 5173.
With this, you will be able to use the connection with the controller.

Related commands for the Katana slot:

```bash
slot deployments logs checkers-controller-1 katana -f
slot deployments logs checkers-controller-1 torii -f 
```

### Related links for the Katana slot:

#### Configuration:

World: 0x7e0aa9c93c6b71781b605aeeeb85ee7d097b592c85db0383515c7a17f262af3
RPC: https://api.cartridge.gg/x/checkers-controller-1/katana
Start Block: 1
Endpoints:

GRAPHQL: https://api.cartridge.gg/x/checkers-controller-1/torii/graphql
GRPC: https://api.cartridge.gg/x/checkers-controller-1/torii



## Play

After completing the steps above, access the Checkers game by navigating to `http://localhost:3000` in your web browser.

---

## Notes

- Ensure all terminals are running in the background to maintain an active environment while you play.
- Feel free to modify the configurations and styles in the source code to personalize your gaming experience.

---

# Checkers

Checkers is a classic board game implemented in a web environment using the Dojo Engine. This project leverages Starknet’s Layer 2 to create a fully decentralized, on-chain checkers game. All game logic, including player moves, validations, and win conditions, is implemented with smart contracts on Starknet, ensuring transparency and fairness.

- Create Burners
- Controller

## Prerequisites

Before you begin, ensure you have the following installed on your machine:

- **[Node.js](https://nodejs.org/)**
- **[pnpm](https://pnpm.io/)**
- **[Dojo v1.0.9](https://book.dojoengine.org/)**

---

## Quick Start Guide

### Terminal 1: Start Katana

Open a terminal and run:

```bash
cd dojo-starter
katana --dev --dev.no-fee --http.cors_origins=*
```

### Terminal 2: Build and Migrate the Project

In a second terminal, execute:

```bash
cd dojo-starter
sozo build
sozo migrate
torii --world 0x01dfabd3b24f954fff521af09a053f718b4255e4cc37ceaa5137bce73854d8ca --http.cors_origins=*
```

### Terminal 3: Start the Client

In a third terminal, navigate to the client folder and run:

```bash
cd client
pnpm i
pnpm dev
```

## Cartridge Controller

To test the connection with the controller, follow these steps:

### Configure mkcert for HTTPS

You can configure mkcert to enable HTTPS and work with the controller directly, without requiring ngrok. Follow the steps below based on your operating system:

#### Windows

For Windows installation and configuration of mkcert, follow the guide in the link below:\
[mkcert Windows Setup Guide](https://github.com/FiloSottile/mkcert/issues/357#issuecomment-1466762021)

#### Linux

For Linux installation and configuration of mkcert, follow the official guidelines provided in these links:

- [Linux Installation Steps](https://github.com/FiloSottile/mkcert#linux)
- [mkcert Installation Guide](https://github.com/FiloSottile/mkcert?tab=readme-ov-file#mkcert)

These guides provide detailed steps to set up mkcert on various Linux distributions.

#### Check HTTPS Security in the Browser

- After completing the mkcert configuration, visit your local site.
- The browser should display **"This page is secure (valid HTTPS)"**.
- If the page shows as **insecure**, the mkcert configuration is incorrect.

### Alternative to mkcert: Use ngrok

Run the following command to use ngrok:

```bash
ngrok http 5173
```

With this, you will be able to use the connection with the controller.

### Related commands for the Katana slot

```bash
slot deployments logs checkers-controller-1 katana -f
slot deployments logs checkers-controller-1 torii -f 

```

### Related links for the Katana slot

#### Configuration

World: 0x01dfabd3b24f954fff521af09a053f718b4255e4cc37ceaa5137bce73854d8ca

RPC: <https://api.cartridge.gg/x/checkers-scaffold/katana>

Start Block: 1

Endpoints:

GRAPHQL: <https://api.cartridge.gg/x/checkers-scaffold/torii/graphql>

GRPC: <https://api.cartridge.gg/x/checkers-scaffold/torii>

## Play

After completing the steps above, access the Checkers game by navigating to `http://localhost:5173` in your web browser.

---

### Burner Wallet Gameplay
If you cannot use the Cartridge Controller, you can still play Checkers using Burner Wallets. This alternative method provides a seamless gaming experience:

- Create multiple Burner Wallets instantly for gameplay
- Delete Burner Wallets at any time
- No controller installation required
- Quick and easy account management
- Start playing immediately after wallet creation

To use Burner Wallets:
1. Navigate to the game interface
2. Click on "Create Burner Wallet"
3. Your new wallet will be generated automatically
4. Start playing immediately

You can create and manage multiple Burner Wallets as needed, making it easy to test different strategies or play against yourself. When you're done, simply delete the Burner Wallet or create a new one for your next gaming session.

## Notes

- Ensure all terminals are running in the background to maintain an active environment while you play.
- Feel free to modify the configurations and styles in the source code to personalize your gaming experience.

---

# 🔱 Atlantis Protocol - Token System

Atlantis Protocol's token system consists of a dual-token model with staking capabilities. The system includes AQUA (the primary utility token), xAQUA (the escrowed token), and a staking mechanism that connects them.

## Core Components

### AQUA Token

AQUA is the primary utility token of the Atlantis Protocol with the following features:

- **Supply Management**: Configurable pre-mine supply and maximum supply limits
- **Minter System**: Authorized addresses can mint new tokens within the maximum supply limit
- **Burning Capability**: Tokens can be burned to reduce supply
- **Ownership Controls**: Owner can manage minter permissions

### xAQUA Token

xAQUA is an escrowed token that represents locked AQUA tokens:

- **Linked to AQUA**: Shares the same maximum supply as AQUA
- **Escrow Mechanism**: Users can lock AQUA to receive xAQUA at a 1:1 ratio
- **Redemption System**: xAQUA can be redeemed back to AQUA through the staking contract
- **Minter Management**: Similar to AQUA, with controlled minting permissions

### Atlantis Staking

The staking system connects AQUA and xAQUA tokens:

- **Flexible Lock Periods**: Users can lock tokens for 15 to 90 days
- **Reward Scaling**: Longer lock periods provide higher rewards (50% to 100% ratio)
- **Two-Step Redemption**: Initialize redemption to lock tokens, then finalize after the lock period
- **User Management**: Tracks all user lock positions with detailed information

## Technical Architecture

The token system is built with modularity and security in mind:

- Uses OpenZeppelin contracts for security and standard compliance
- Implements ERC20 standard with extensions for additional functionality
- Enforces strict access controls through ownership and minter systems
- Maintains mathematical safety with SafeMath for all calculations

## Development

For developers looking to build on or integrate with Atlantis Protocol's token system:

```bash
# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test
```

## License

[License information to be added]

## Contact

[Contact information to be added]

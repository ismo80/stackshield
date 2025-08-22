# StackShield Smart Contract

A decentralized insurance protocol built on Stacks blockchain that enables peer-to-peer insurance pools with democratic claim resolution.

## Overview

StackShield allows users to:
- Create insurance pools with customizable premiums
- Join existing pools by contributing STX
- Submit insurance claims
- Vote on claim validity
- Execute approved claims

## Key Features

- **Decentralized Governance**: Claims are approved through member voting
- **Flexible Pool Creation**: Any user can create an insurance pool with custom parameters
- **Secure Fund Management**: Built-in checks and balances for fund transfers
- **Transparent Operations**: All actions are recorded on-chain
- **Oracle Integration**: Prepared for external data verification

## Contract Functions

### Pool Management
- `create-pool`: Create a new insurance pool with specified premium
- `join-pool`: Join an existing pool by paying the premium

### Claims Processing  
- `submit-claim`: Submit a new insurance claim
- `vote-claim`: Vote on pending claims
- `execute-claim`: Process approved claims for payout

## Constants

```clarity
MIN_PREMIUM: u10
```

## Error Codes

- `ERR_UNAUTHORIZED (u100)`: Unauthorized access attempt
- `ERR_NOT_FOUND (u101)`: Requested resource not found
- `ERR_INVALID_AMOUNT (u102)`: Invalid amount specified
- `ERR_ALREADY_EXISTS (u103)`: Resource already exists
- `ERR_POOL_INACTIVE (u104)`: Pool is no longer active
- `ERR_DUPLICATE_CLAIM (u105)`: Claim already submitted
- `ERR_NOT_MEMBER (u106)`: User is not a pool member
- `ERR_ALREADY_VOTED (u107)`: User has already voted

## Security Considerations

- All financial transactions require explicit authorization
- Built-in guards against double-voting and duplicate claims
- Protected against unauthorized claim execution
- Input validation on all public functions



## License

MIT License

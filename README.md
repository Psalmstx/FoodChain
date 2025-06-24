# FoodChain 🍽️

A decentralized restaurant review and reputation system built on the Stacks blockchain using Clarity smart contracts.

## Overview

FoodChain enables restaurants to register on-chain and allows customers to submit verified reviews that cannot be manipulated or deleted. The system maintains transparent reputation scores and ensures authentic feedback through blockchain immutability.

## Features

- **Restaurant Registration**: Restaurants can register with their details (name, cuisine type, location)
- **Decentralized Reviews**: Users can submit rated reviews (1-5 stars) with comments
- **Reputation System**: Automatic calculation of average ratings and review counts
- **One Review Per User**: Prevents spam by allowing only one review per user per restaurant
- **Owner Controls**: Restaurant owners can toggle their active status
- **Transparent Data**: All reviews and ratings are publicly verifiable on-chain

## Smart Contract Functions

### Public Functions

- `register-restaurant(name, cuisine-type, location)` - Register a new restaurant
- `submit-review(restaurant-id, rating, comment)` - Submit a review (1-5 rating)
- `toggle-restaurant-status(restaurant-id)` - Toggle restaurant active status (owner only)

### Read-Only Functions

- `get-restaurant(restaurant-id)` - Get restaurant details
- `get-review(review-id)` - Get review details
- `has-user-reviewed(reviewer, restaurant-id)` - Check if user has reviewed
- `get-next-restaurant-id()` - Get current restaurant ID counter
- `get-next-review-id()` - Get current review ID counter

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd foodchain
```

2. Check the contract
```bash
clarinet check
```

3. Run tests
```bash
clarinet test
```

## Usage Example

```clarity
;; Register a restaurant
(contract-call? .foodchain register-restaurant "Mario's Pizza" "Italian" "123 Main St, City")

;; Submit a review
(contract-call? .foodchain submit-review u1 u5 "Amazing pizza! Great service and atmosphere.")

;; Get restaurant details
(contract-call? .foodchain get-restaurant u1)
```

## Contract Details

- **Network**: Stacks Blockchain
- **Language**: Clarity
- **License**: MIT
- **Version**: 1.0.0

## Data Structure

### Restaurants
- Restaurant ID (unique identifier)
- Name, cuisine type, location
- Owner principal
- Active status
- Total reviews and average rating

### Reviews
- Review ID (unique identifier)
- Restaurant ID reference
- Reviewer principal
- Rating (1-5) and comment
- Block height timestamp

## Security Features

- One review per user per restaurant
- Owner-only restaurant management
- Input validation for ratings
- Principal-based access control

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `clarinet check` to validate
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For questions or issues, please open a GitHub issue or contact the development team.
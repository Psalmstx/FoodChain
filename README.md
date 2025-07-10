# FoodChain 🍽️

A decentralized restaurant review and reputation system built on the Stacks blockchain using Clarity smart contracts.

## Overview

FoodChain enables restaurants to register on-chain and allows customers to submit verified reviews that cannot be manipulated or deleted. The system maintains transparent reputation scores and ensures authentic feedback through blockchain immutability.

## Features

- **Restaurant Registration**: Restaurants can register with their details (name, cuisine type, location)
- **Decentralized Reviews**: Users can submit rated reviews (1-5 stars) with comments
- **Reputation System**: Automatic calculation of average ratings and review counts
- **Multi-Token Reward System**: STX token rewards for high-quality reviewers and restaurant loyalty programs
- **Reviewer Rewards**: Earn STX tokens for submitting high-quality reviews (4+ stars)
- **Loyalty Programs**: Customers earn rewards for frequent visits to restaurants
- **One Review Per User**: Prevents spam by allowing only one review per user per restaurant
- **Owner Controls**: Restaurant owners can toggle their active status
- **Transparent Data**: All reviews and ratings are publicly verifiable on-chain

## Smart Contract Functions

### Public Functions

- `register-restaurant(name, cuisine-type, location)` - Register a new restaurant
- `submit-review(restaurant-id, rating, comment)` - Submit a review (1-5 rating)
- `toggle-restaurant-status(restaurant-id)` - Toggle restaurant active status (owner only)
- `fund-reward-pool(amount)` - Add STX tokens to reward pool (owner only)

### Read-Only Functions

- `get-restaurant(restaurant-id)` - Get restaurant details
- `get-review(review-id)` - Get review details
- `has-user-reviewed(reviewer, restaurant-id)` - Check if user has reviewed
- `get-next-restaurant-id()` - Get current restaurant ID counter
- `get-next-review-id()` - Get current review ID counter
- `get-reviewer-stats(reviewer)` - Get reviewer statistics and rewards earned
- `get-loyalty-info(restaurant-id, customer)` - Get customer loyalty information
- `get-reward-pool()` - Get current reward pool balance

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

;; Fund the reward pool (owner only)
(contract-call? .foodchain fund-reward-pool u10000000)

;; Submit a review (automatically checks for rewards)
(contract-call? .foodchain submit-review u1 u5 "Amazing pizza! Great service and atmosphere.")

;; Get restaurant details
(contract-call? .foodchain get-restaurant u1)

;; Check reviewer stats
(contract-call? .foodchain get-reviewer-stats 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Check loyalty rewards
(contract-call? .foodchain get-loyalty-info u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
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

### Reviewer Statistics
- Total reviews submitted
- High-quality reviews count (4+ stars)
- Total rewards earned
- Last reward block height

### Restaurant Loyalty
- Visit count per customer
- Total rewards earned from restaurant
- Last visit block height

## Security Features

- One review per user per restaurant
- Owner-only restaurant management
- Input validation for ratings
- Principal-based access control
- Reward pool protection with owner-only funding
- Automatic reward distribution based on review quality
- Loyalty tracking with visit-based rewards

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `clarinet check` to validate
5. Submit a pull request

## Future Upgrade Features 🚀

We have exciting plans to enhance FoodChain with these upcoming features:

1. **~~Multi-Token Reward System~~** ✅ **COMPLETED** - Implemented STX token rewards for high-quality reviewers and restaurant loyalty programs

2. **Photo & Media Upload** - Add IPFS integration for uploading restaurant photos, food images, and video reviews with on-chain verification

3. **Advanced Analytics Dashboard** - Create comprehensive analytics for restaurants including review trends, peak hours, customer demographics, and sentiment analysis

4. **Geolocation & Discovery** - Implement location-based restaurant discovery with radius search, GPS verification, and neighborhood trending

5. **Restaurant Verification System** - Add multi-tier verification process with business license validation, health department scores, and official certification badges

6. **Social Features & Following** - Enable users to follow favorite reviewers, create friend networks, and see personalized recommendations based on social connections

7. **Dispute Resolution & Moderation** - Implement decentralized governance system for handling fake reviews, disputes, and community-driven content moderation

8. **Delivery Integration & Tracking** - Connect with delivery services for order tracking, delivery ratings, and integrated payment systems using Clarity smart contracts

9. **Dynamic Pricing & Promotions** - Allow restaurants to create time-based promotions, happy hour discounts, and loyalty rewards directly through smart contracts

10. **Multi-Chain Bridge & Cross-Platform** - Expand to other blockchains with cross-chain review aggregation and unified reputation scores across different networks

*Want to contribute to any of these features? Check our GitHub issues or reach out to join our development roadmap!*

## License

MIT License - see LICENSE file for details

## Support

For questions or issues, please open a GitHub issue or contact the development team.

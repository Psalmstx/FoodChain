# FoodChain 🍽️📸

A decentralized restaurant review and reputation system built on the Stacks blockchain using Clarity smart contracts, now with **IPFS multimedia support** for photos, videos, and audio content.

## Overview

FoodChain enables restaurants to register on-chain and allows customers to submit verified reviews with multimedia content that cannot be manipulated or deleted. The system maintains transparent reputation scores and ensures authentic feedback through blockchain immutability, while supporting rich media experiences through IPFS integration.

## Features

### Core Features
- **Restaurant Registration**: Restaurants can register with their details (name, cuisine type, location)
- **Decentralized Reviews**: Users can submit rated reviews (1-5 stars) with comments
- **Reputation System**: Automatic calculation of average ratings and review counts
- **One Review Per User**: Prevents spam by allowing only one review per user per restaurant
- **Owner Controls**: Restaurant owners can toggle their active status
- **Transparent Data**: All reviews and ratings are publicly verifiable on-chain

### 🆕 New IPFS Media Features
- **Photo & Video Reviews**: Attach up to 10 photos, videos, or audio files to reviews
- **Restaurant Media Gallery**: Restaurant owners can upload profile images and gallery media
- **IPFS Integration**: Decentralized storage for all multimedia content
- **Media Validation**: Built-in validation for IPFS hashes and media types
- **Rich Media Experience**: Support for image, video, and audio content types

## Smart Contract Functions

### Public Functions

#### Core Functions
- `register-restaurant(name, cuisine-type, location, profile-image-hash?)` - Register a new restaurant with optional profile image
- `submit-review(restaurant-id, rating, comment, media-hashes, media-types)` - Submit a review with multimedia attachments
- `toggle-restaurant-status(restaurant-id)` - Toggle restaurant active status (owner only)

#### 🆕 New Media Functions
- `add-restaurant-media(restaurant-id, media-hashes, media-types)` - Add media to restaurant gallery (owner only)
- `update-restaurant-profile-image(restaurant-id, new-image-hash)` - Update restaurant profile image (owner only)

#### Reward System
- `fund-reward-pool(amount)` - Fund the reward pool (owner only)

### Read-Only Functions

#### Core Read Functions
- `get-restaurant(restaurant-id)` - Get restaurant details including media count
- `get-review(review-id)` - Get review details including media count
- `has-user-reviewed(reviewer, restaurant-id)` - Check if user has reviewed
- `get-next-restaurant-id()` - Get current restaurant ID counter
- `get-next-review-id()` - Get current review ID counter

#### 🆕 New Media Read Functions
- `get-media-item(media-id)` - Get media item details and IPFS hash
- `get-restaurant-media(restaurant-id, media-index)` - Get restaurant media by index
- `get-review-media(review-id, media-index)` - Get review media by index
- `get-next-media-id()` - Get current media ID counter

#### Statistics Functions
- `get-reviewer-stats(reviewer)` - Get reviewer statistics and rewards
- `get-loyalty-info(restaurant-id, customer)` - Get customer loyalty information
- `get-reward-pool()` - Get current reward pool balance

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing
- IPFS node or service (for media uploads)

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

## Usage Examples

### Basic Restaurant Registration
```clarity
;; Register a restaurant without profile image
(contract-call? .foodchain register-restaurant "Mario's Pizza" "Italian" "123 Main St, City" none)

;; Register a restaurant with profile image
(contract-call? .foodchain register-restaurant 
  "Luigi's Bistro" 
  "Italian" 
  "456 Oak Ave, City" 
  (some "QmYourIPFSHashHere1234567890"))
```

### Submit Review with Media
```clarity
;; Submit a review with photos and video
(contract-call? .foodchain submit-review 
  u1 
  u5 
  "Amazing pizza! Great atmosphere and fantastic service."
  (list "QmPhotoHash1" "QmPhotoHash2" "QmVideoHash1")
  (list "image" "image" "video"))
```

### Add Restaurant Media Gallery
```clarity
;; Restaurant owner adds media to gallery
(contract-call? .foodchain add-restaurant-media
  u1
  (list "QmInteriorPhoto" "QmFoodPhoto" "QmMenuPhoto")
  (list "image" "image" "image"))
```

### Retrieve Media Content
```clarity
;; Get restaurant details with media info
(contract-call? .foodchain get-restaurant u1)

;; Get specific restaurant media item
(contract-call? .foodchain get-restaurant-media u1 u0)

;; Get review media item
(contract-call? .foodchain get-review-media u1 u0)

;; Get media item details
(contract-call? .foodchain get-media-item u1)
```

## IPFS Integration Guide

### Supported Media Types
- **image**: Photos, illustrations, graphics (JPEG, PNG, GIF, etc.)
- **video**: Video content (MP4, AVI, MOV, etc.)
- **audio**: Audio files (MP3, WAV, OGG, etc.)

### IPFS Hash Requirements
- Minimum length: 10 characters
- Maximum length: 100 characters
- Must be valid IPFS content identifiers (CIDs)

### Media Upload Workflow
1. **Upload to IPFS**: Upload your media files to IPFS using:
   - [Pinata](https://pinata.cloud/)
   - [Infura IPFS](https://infura.io/product/ipfs)
   - Local IPFS node
   - [Web3.Storage](https://web3.storage/)

2. **Get IPFS Hash**: Obtain the content identifier (CID) from your upload

3. **Submit to Contract**: Use the IPFS hash in contract functions

### Example IPFS Integration (JavaScript)
```javascript
// Using Pinata for IPFS upload
const pinFileToIPFS = async (file) => {
  const formData = new FormData();
  formData.append('file', file);
  
  const response = await fetch('https://api.pinata.cloud/pinning/pinFileToIPFS', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${PINATA_JWT_TOKEN}`
    },
    body: formData
  });
  
  const result = await response.json();
  return result.IpfsHash; // Use this hash in your contract call
};

// Submit review with uploaded media
const submitReviewWithMedia = async (files) => {
  const ipfsHashes = [];
  const mediaTypes = [];
  
  for (const file of files) {
    const hash = await pinFileToIPFS(file);
    ipfsHashes.push(hash);
    mediaTypes.push(file.type.startsWith('image') ? 'image' : 
                   file.type.startsWith('video') ? 'video' : 'audio');
  }
  
  // Call contract function
  await contractCall({
    contractAddress: 'YOUR_CONTRACT_ADDRESS',
    contractName: 'foodchain',
    functionName: 'submit-review',
    functionArgs: [
      uintCV(restaurantId),
      uintCV(rating),
      stringAsciiCV(comment),
      listCV(ipfsHashes.map(hash => stringAsciiCV(hash))),
      listCV(mediaTypes.map(type => stringAsciiCV(type)))
    ]
  });
};
```

## Contract Details

- **Network**: Stacks Blockchain
- **Language**: Clarity
- **License**: MIT
- **Version**: 2.0.0 (IPFS Media Support)

## Data Structure

### Restaurants
- Restaurant ID (unique identifier)
- Name, cuisine type, location
- Owner principal
- Active status
- Total reviews and average rating
- **🆕 Profile image IPFS hash (optional)**
- **🆕 Media count**

### Reviews
- Review ID (unique identifier)
- Restaurant ID reference
- Reviewer principal
- Rating (1-5) and comment
- Block height timestamp
- **🆕 Media count**

### 🆕 Media Items
- Media ID (unique identifier)
- IPFS hash for content
- Media type (image/video/audio)
- Uploader principal
- Associated restaurant or review ID
- Upload timestamp
- Active status

### Media Mapping
- **Restaurant Media**: Links restaurants to their media gallery
- **Review Media**: Links reviews to their attached media

## Security Features

- One review per user per restaurant
- Owner-only restaurant management
- Input validation for ratings and IPFS hashes
- Principal-based access control
- **🆕 Media type validation**
- **🆕 IPFS hash format validation**
- **🆕 Media count limits (max 10 items)**
- Overflow protection for all counters
- Proper error handling for all functions

## Reward System

### Reviewer Rewards
- **High-Quality Review Threshold**: 4+ stars
- **Reward Amount**: 1,000,000 micro-STX
- **Minimum Reviews Required**: 3 reviews

### Loyalty Rewards
- **Reward Amount**: 500,000 micro-STX
- **Trigger**: Every 5th visit/review
- **Minimum Visits**: 3 visits

## API Reference

### Error Codes
- `u100`: Owner only operation
- `u101`: Resource not found
- `u102`: Resource already exists
- `u103`: Invalid rating (must be 1-5)
- `u104`: Unauthorized operation
- `u105`: Insufficient funds
- `u106`: Transfer failed
- `u107`: Invalid input parameter
- `u108`: Invalid IPFS hash format

### Media Limits
- **Maximum Media Items per Review**: 10
- **Maximum Media Items per Restaurant**: 10
- **IPFS Hash Length**: 10-100 characters
- **Supported Media Types**: image, video, audio

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run `clarinet check` to validate
5. Add tests for new functionality
6. Submit a pull request

## Testing

```bash
# Run all tests
clarinet test

# Check contract syntax
clarinet check

# Test IPFS integration
clarinet test --filter "media"
```

## License

MIT License - see LICENSE file for details

## Support

For questions or issues, please open a GitHub issue or contact the development team.

## Changelog

### Version 2.0.0 - IPFS Media Support
- ✅ Added IPFS integration for multimedia content
- ✅ Restaurant profile images and media galleries
- ✅ Review media attachments (photos, videos, audio)
- ✅ Media validation and type checking
- ✅ Enhanced security with proper input validation
- ✅ New read-only functions for media retrieval
- ✅ Updated data structures with media support

### Version 1.0.0 - Initial Release
- ✅ Basic restaurant registration and reviews
- ✅ Reputation system with average ratings
- ✅ Reward system for reviewers and loyal customers
- ✅ One review per user per restaurant
- ✅ Owner controls for restaurant management
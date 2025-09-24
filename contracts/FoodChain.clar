;; FoodChain - Decentralized Restaurant Review System with IPFS Media Support
;; A smart contract for managing restaurant registrations, reviews, and multimedia content

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-rating (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-transfer-failed (err u106))
(define-constant err-invalid-input (err u107))
(define-constant err-invalid-hash (err u108))

;; Reward constants
(define-constant high-quality-review-threshold u4)
(define-constant reviewer-reward-amount u1000000)
(define-constant loyalty-reward-amount u500000)
(define-constant min-reviews-for-reward u3)

;; IPFS constants
(define-constant max-ipfs-hash-length u100)
(define-constant max-media-items u10)

;; Data Variables with bounds checking
(define-data-var next-restaurant-id uint u1)
(define-data-var next-review-id uint u1)
(define-data-var next-media-id uint u1)
(define-data-var reward-pool uint u0)

;; Additional constants for validation
(define-constant max-uint u340282366920938463463374607431768211455)
(define-constant max-safe-counter u1000000)

;; Data Maps
(define-map restaurants
  { restaurant-id: uint }
  {
    name: (string-ascii 100),
    owner: principal,
    cuisine-type: (string-ascii 50),
    location: (string-ascii 200),
    is-active: bool,
    total-reviews: uint,
    average-rating: uint,
    profile-image-hash: (optional (string-ascii 100)),
    media-count: uint
  }
)

(define-map reviews
  { review-id: uint }
  {
    restaurant-id: uint,
    reviewer: principal,
    rating: uint,
    comment: (string-ascii 500),
    timestamp: uint,
    media-count: uint
  }
)

(define-map user-reviews
  { reviewer: principal, restaurant-id: uint }
  { review-id: uint }
)

(define-map reviewer-stats
  { reviewer: principal }
  {
    total-reviews: uint,
    high-quality-reviews: uint,
    total-rewards-earned: uint,
    last-reward-block: uint
  }
)

(define-map restaurant-loyalty
  { restaurant-id: uint, customer: principal }
  {
    visit-count: uint,
    total-rewards: uint,
    last-visit-block: uint
  }
)

;; New maps for IPFS media support
(define-map media-items
  { media-id: uint }
  {
    ipfs-hash: (string-ascii 100),
    media-type: (string-ascii 20),
    uploader: principal,
    restaurant-id: (optional uint),
    review-id: (optional uint),
    timestamp: uint,
    is-active: bool
  }
)

(define-map restaurant-media
  { restaurant-id: uint, media-index: uint }
  { media-id: uint }
)

(define-map review-media
  { review-id: uint, media-index: uint }
  { media-id: uint }
)

;; Private helper functions for validation
(define-private (is-valid-ipfs-hash (hash (string-ascii 100)))
  (and 
    (>= (len hash) u10)
    (<= (len hash) max-ipfs-hash-length)
  )
)

(define-private (is-valid-media-type (media-type (string-ascii 20)))
  (or 
    (is-eq media-type "image")
    (is-eq media-type "video")
    (is-eq media-type "audio")
  )
)

;; Public Functions

;; Register a new restaurant with optional profile image
(define-public (register-restaurant 
  (name (string-ascii 100)) 
  (cuisine-type (string-ascii 50)) 
  (location (string-ascii 200))
  (profile-image-hash (optional (string-ascii 100)))
)
  (let ((restaurant-id (var-get next-restaurant-id)))
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> (len cuisine-type) u0) err-invalid-input) 
    (asserts! (> (len location) u0) err-invalid-input)
    (asserts! (< restaurant-id max-safe-counter) err-invalid-input)
    
    ;; Validate profile image hash if provided
    (match profile-image-hash
      hash (asserts! (is-valid-ipfs-hash hash) err-invalid-hash)
      true
    )
    
    (let ((final-profile-hash profile-image-hash))
        (map-set restaurants
          { restaurant-id: restaurant-id }
          {
            name: name,
            owner: tx-sender,
            cuisine-type: cuisine-type,
            location: location,
            is-active: true,
            total-reviews: u0,
            average-rating: u0,
            profile-image-hash: final-profile-hash,
            media-count: u0
          }
        )
        (var-set next-restaurant-id (+ restaurant-id u1))
        (ok restaurant-id)
      )
    )
)

;; Submit a review for a restaurant with optional media
(define-public (submit-review 
  (restaurant-id uint) 
  (rating uint) 
  (comment (string-ascii 500))
  (media-hashes (list 5 (string-ascii 100)))
  (media-types (list 5 (string-ascii 20)))
)
  (let (
    (review-id (var-get next-review-id))
  )
    (asserts! (> restaurant-id u0) err-invalid-input)
    (asserts! (< restaurant-id (var-get next-restaurant-id)) err-not-found)
    (let ((restaurant-data (unwrap! (map-get? restaurants { restaurant-id: restaurant-id }) err-not-found)))
      (asserts! (> (len comment) u0) err-invalid-input)
      (asserts! (< review-id max-safe-counter) err-invalid-input)
      (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
      (asserts! (is-none (map-get? user-reviews { reviewer: tx-sender, restaurant-id: restaurant-id })) err-already-exists)
      (asserts! (get is-active restaurant-data) err-unauthorized)
      (asserts! (is-eq (len media-hashes) (len media-types)) err-invalid-input)
      (asserts! (<= (len media-hashes) max-media-items) err-invalid-input)
      
      ;; Validate all media hashes and types if provided
      (if (> (len media-hashes) u0)
        (begin
          (asserts! (is-eq 
            (len (filter is-valid-ipfs-hash media-hashes))
            (len media-hashes)
          ) err-invalid-hash)
          (asserts! (is-eq 
            (len (filter is-valid-media-type media-types))
            (len media-types)
          ) err-invalid-input)
        )
        true
      )
      
      ;; Create the review
      (map-set reviews
        { review-id: review-id }
        {
          restaurant-id: restaurant-id,
          reviewer: tx-sender,
          rating: rating,
          comment: comment,
          timestamp: stacks-block-height,
          media-count: (len media-hashes)
        }
      )
      
      ;; Track user's review for this restaurant
      (map-set user-reviews
        { reviewer: tx-sender, restaurant-id: restaurant-id }
        { review-id: review-id }
      )
      
      ;; Add media items using simple iteration
      (if (> (len media-hashes) u0)
        (begin
          (try! (add-review-media-item review-id (unwrap! (element-at media-hashes u0) err-invalid-input) (unwrap! (element-at media-types u0) err-invalid-input) u0))
          (if (> (len media-hashes) u1)
            (try! (add-review-media-item review-id (unwrap! (element-at media-hashes u1) err-invalid-input) (unwrap! (element-at media-types u1) err-invalid-input) u1))
            true
          )
          (if (> (len media-hashes) u2)
            (try! (add-review-media-item review-id (unwrap! (element-at media-hashes u2) err-invalid-input) (unwrap! (element-at media-types u2) err-invalid-input) u2))
            true
          )
          (if (> (len media-hashes) u3)
            (try! (add-review-media-item review-id (unwrap! (element-at media-hashes u3) err-invalid-input) (unwrap! (element-at media-types u3) err-invalid-input) u3))
            true
          )
          (if (> (len media-hashes) u4)
            (try! (add-review-media-item review-id (unwrap! (element-at media-hashes u4) err-invalid-input) (unwrap! (element-at media-types u4) err-invalid-input) u4))
            true
          )
        )
        true
      )
      
      ;; Update restaurant statistics with overflow protection
      (let (
        (current-total (get total-reviews restaurant-data))
        (current-avg (get average-rating restaurant-data))
      )
        (asserts! (< current-total max-safe-counter) err-invalid-input)
        (let (
          (new-total (+ current-total u1))
          (current-total-points (* current-avg current-total))
        )
          (asserts! (<= current-total-points (- max-uint rating)) err-invalid-input)
          (let (
            (total-rating-points (+ current-total-points rating))
            (new-average (/ total-rating-points new-total))
          )
            (map-set restaurants
              { restaurant-id: restaurant-id }
              (merge restaurant-data {
                total-reviews: new-total,
                average-rating: new-average
              })
            )
          )
        )
      )
      
      ;; Update reviewer stats and check for rewards
      (let (
        (current-reviewer-stats (default-to 
          { total-reviews: u0, high-quality-reviews: u0, total-rewards-earned: u0, last-reward-block: u0 }
          (map-get? reviewer-stats { reviewer: tx-sender })
        ))
        (new-total-reviews (+ (get total-reviews current-reviewer-stats) u1))
        (is-high-quality (>= rating high-quality-review-threshold))
        (new-high-quality-count (if is-high-quality 
          (+ (get high-quality-reviews current-reviewer-stats) u1)
          (get high-quality-reviews current-reviewer-stats)
        ))
      )
        (map-set reviewer-stats
          { reviewer: tx-sender }
          (merge current-reviewer-stats {
            total-reviews: new-total-reviews,
            high-quality-reviews: new-high-quality-count
          })
        )
        
        ;; Award reviewer reward for high-quality reviews
        (if (and is-high-quality (>= new-total-reviews min-reviews-for-reward))
          (try! (distribute-reviewer-reward tx-sender))
          true
        )
      )
      
      ;; Update restaurant loyalty for customer
      (let (
        (current-loyalty (default-to
          { visit-count: u0, total-rewards: u0, last-visit-block: u0 }
          (map-get? restaurant-loyalty { restaurant-id: restaurant-id, customer: tx-sender })
        ))
        (new-visit-count (+ (get visit-count current-loyalty) u1))
      )
        (map-set restaurant-loyalty
          { restaurant-id: restaurant-id, customer: tx-sender }
          (merge current-loyalty {
            visit-count: new-visit-count,
            last-visit-block: stacks-block-height
          })
        )
        
        ;; Award loyalty reward for frequent customers
        (if (and (> new-visit-count u2) (is-eq (mod new-visit-count u5) u0))
          (try! (distribute-loyalty-reward tx-sender restaurant-id))
          true
        )
      )
      
      (var-set next-review-id (+ review-id u1))
      (ok review-id)
    )
  )
)

;; Add media to a restaurant (owner only)
(define-public (add-restaurant-media 
  (restaurant-id uint) 
  (media-hashes (list 5 (string-ascii 100)))
  (media-types (list 5 (string-ascii 20)))
)
  (begin
    (asserts! (> restaurant-id u0) err-invalid-input)
    (asserts! (< restaurant-id (var-get next-restaurant-id)) err-not-found)
    (let ((restaurant-data (unwrap! (map-get? restaurants { restaurant-id: restaurant-id }) err-not-found)))
      (asserts! (is-eq tx-sender (get owner restaurant-data)) err-unauthorized)
      (asserts! (is-eq (len media-hashes) (len media-types)) err-invalid-input)
      (asserts! (<= (len media-hashes) max-media-items) err-invalid-input)
      (asserts! (> (len media-hashes) u0) err-invalid-input)
      
      ;; Validate all media hashes and types
      (asserts! (is-eq 
        (len (filter is-valid-ipfs-hash media-hashes))
        (len media-hashes)
      ) err-invalid-hash)
      (asserts! (is-eq 
        (len (filter is-valid-media-type media-types))
        (len media-types)
      ) err-invalid-input)
      
      (let ((current-media-count (get media-count restaurant-data)))
        (asserts! (<= (+ current-media-count (len media-hashes)) max-media-items) err-invalid-input)
        
        ;; Add media items using simple iteration
        (if (> (len media-hashes) u0)
          (try! (add-restaurant-media-item restaurant-id (unwrap! (element-at media-hashes u0) err-invalid-input) (unwrap! (element-at media-types u0) err-invalid-input) current-media-count))
          true
        )
        (if (> (len media-hashes) u1)
          (try! (add-restaurant-media-item restaurant-id (unwrap! (element-at media-hashes u1) err-invalid-input) (unwrap! (element-at media-types u1) err-invalid-input) (+ current-media-count u1)))
          true
        )
        (if (> (len media-hashes) u2)
          (try! (add-restaurant-media-item restaurant-id (unwrap! (element-at media-hashes u2) err-invalid-input) (unwrap! (element-at media-types u2) err-invalid-input) (+ current-media-count u2)))
          true
        )
        (if (> (len media-hashes) u3)
          (try! (add-restaurant-media-item restaurant-id (unwrap! (element-at media-hashes u3) err-invalid-input) (unwrap! (element-at media-types u3) err-invalid-input) (+ current-media-count u3)))
          true
        )
        (if (> (len media-hashes) u4)
          (try! (add-restaurant-media-item restaurant-id (unwrap! (element-at media-hashes u4) err-invalid-input) (unwrap! (element-at media-types u4) err-invalid-input) (+ current-media-count u4)))
          true
        )
        
        ;; Update restaurant media count
        (map-set restaurants
          { restaurant-id: restaurant-id }
          (merge restaurant-data {
            media-count: (+ current-media-count (len media-hashes))
          })
        )
        (ok true)
      )
    )
  )
)

;; Toggle restaurant active status (owner only)
(define-public (toggle-restaurant-status (restaurant-id uint))
  (begin
    (asserts! (> restaurant-id u0) err-invalid-input)
    (asserts! (< restaurant-id (var-get next-restaurant-id)) err-not-found)
    (let ((restaurant-data (unwrap! (map-get? restaurants { restaurant-id: restaurant-id }) err-not-found)))
      (asserts! (is-eq tx-sender (get owner restaurant-data)) err-unauthorized)
      (map-set restaurants
        { restaurant-id: restaurant-id }
        (merge restaurant-data { is-active: (not (get is-active restaurant-data)) })
      )
      (ok true)
    )
  )
)

;; Update restaurant profile image (owner only)
(define-public (update-restaurant-profile-image (restaurant-id uint) (new-image-hash (string-ascii 100)))
  (begin
    (asserts! (> restaurant-id u0) err-invalid-input)
    (asserts! (< restaurant-id (var-get next-restaurant-id)) err-not-found)
    (asserts! (is-valid-ipfs-hash new-image-hash) err-invalid-hash)
    (let ((restaurant-data (unwrap! (map-get? restaurants { restaurant-id: restaurant-id }) err-not-found)))
      (asserts! (is-eq tx-sender (get owner restaurant-data)) err-unauthorized)
      (map-set restaurants
        { restaurant-id: restaurant-id }
        (merge restaurant-data { profile-image-hash: (some new-image-hash) })
      )
      (ok true)
    )
  )
)

;; Helper function to add single restaurant media item
(define-private (add-restaurant-media-item 
  (restaurant-id uint)
  (ipfs-hash (string-ascii 100))
  (media-type (string-ascii 20))
  (media-index uint)
)
  (let ((media-id (var-get next-media-id)))
    (asserts! (< media-id max-safe-counter) err-invalid-input)
    (map-set media-items
      { media-id: media-id }
      {
        ipfs-hash: ipfs-hash,
        media-type: media-type,
        uploader: tx-sender,
        restaurant-id: (some restaurant-id),
        review-id: none,
        timestamp: stacks-block-height,
        is-active: true
      }
    )
    (map-set restaurant-media
      { restaurant-id: restaurant-id, media-index: media-index }
      { media-id: media-id }
    )
    (var-set next-media-id (+ media-id u1))
    (ok true)
  )
)

;; Helper function to add single review media item
(define-private (add-review-media-item 
  (review-id uint)
  (ipfs-hash (string-ascii 100))
  (media-type (string-ascii 20))
  (media-index uint)
)
  (let ((media-id (var-get next-media-id)))
    (asserts! (< media-id max-safe-counter) err-invalid-input)
    (map-set media-items
      { media-id: media-id }
      {
        ipfs-hash: ipfs-hash,
        media-type: media-type,
        uploader: tx-sender,
        restaurant-id: none,
        review-id: (some review-id),
        timestamp: stacks-block-height,
        is-active: true
      }
    )
    (map-set review-media
      { review-id: review-id, media-index: media-index }
      { media-id: media-id }
    )
    (var-set next-media-id (+ media-id u1))
    (ok true)
  )
)

;; Reward system functions

;; Fund the reward pool (owner only)
(define-public (fund-reward-pool (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-input)
    (let ((current-pool (var-get reward-pool)))
      ;; Check for overflow before adding
      (asserts! (<= amount (- max-uint current-pool)) err-invalid-input)
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (var-set reward-pool (+ current-pool amount))
      (ok true)
    )
  )
)

;; Distribute reviewer reward
(define-private (distribute-reviewer-reward (reviewer principal))
  (let ((current-pool (var-get reward-pool)))
    (if (>= current-pool reviewer-reward-amount)
      (begin
        (try! (as-contract (stx-transfer? reviewer-reward-amount tx-sender reviewer)))
        (var-set reward-pool (- current-pool reviewer-reward-amount))
        (let (
          (current-stats (unwrap! (map-get? reviewer-stats { reviewer: reviewer }) err-not-found))
        )
          (map-set reviewer-stats
            { reviewer: reviewer }
            (merge current-stats {
              total-rewards-earned: (+ (get total-rewards-earned current-stats) reviewer-reward-amount),
              last-reward-block: stacks-block-height
            })
          )
        )
        (ok true)
      )
      (ok false)
    )
  )
)

;; Distribute loyalty reward
(define-private (distribute-loyalty-reward (customer principal) (restaurant-id uint))
  (let ((current-pool (var-get reward-pool)))
    (if (>= current-pool loyalty-reward-amount)
      (begin
        (try! (as-contract (stx-transfer? loyalty-reward-amount tx-sender customer)))
        (var-set reward-pool (- current-pool loyalty-reward-amount))
        (let (
          (current-loyalty (unwrap! (map-get? restaurant-loyalty { restaurant-id: restaurant-id, customer: customer }) err-not-found))
        )
          (map-set restaurant-loyalty
            { restaurant-id: restaurant-id, customer: customer }
            (merge current-loyalty {
              total-rewards: (+ (get total-rewards current-loyalty) loyalty-reward-amount)
            })
          )
        )
        (ok true)
      )
      (ok false)
    )
  )
)

;; Read-only Functions

;; Get restaurant details
(define-read-only (get-restaurant (restaurant-id uint))
  (if (and (> restaurant-id u0) (< restaurant-id (var-get next-restaurant-id)))
    (map-get? restaurants { restaurant-id: restaurant-id })
    none
  )
)

;; Get review details
(define-read-only (get-review (review-id uint))
  (if (and (> review-id u0) (< review-id (var-get next-review-id)))
    (map-get? reviews { review-id: review-id })
    none
  )
)

;; Get media item details
(define-read-only (get-media-item (media-id uint))
  (if (and (> media-id u0) (< media-id (var-get next-media-id)))
    (map-get? media-items { media-id: media-id })
    none
  )
)

;; Get restaurant media by index
(define-read-only (get-restaurant-media (restaurant-id uint) (media-index uint))
  (if (and (> restaurant-id u0) (< restaurant-id (var-get next-restaurant-id)))
    (match (map-get? restaurant-media { restaurant-id: restaurant-id, media-index: media-index })
      media-ref (map-get? media-items { media-id: (get media-id media-ref) })
      none
    )
    none
  )
)

;; Get review media by index
(define-read-only (get-review-media (review-id uint) (media-index uint))
  (if (and (> review-id u0) (< review-id (var-get next-review-id)))
    (match (map-get? review-media { review-id: review-id, media-index: media-index })
      media-ref (map-get? media-items { media-id: (get media-id media-ref) })
      none
    )
    none
  )
)

;; Check if user has reviewed a restaurant
(define-read-only (has-user-reviewed (reviewer principal) (restaurant-id uint))
  (if (and (> restaurant-id u0) (< restaurant-id (var-get next-restaurant-id)))
    (is-some (map-get? user-reviews { reviewer: reviewer, restaurant-id: restaurant-id }))
    false
  )
)

;; Get current restaurant ID counter
(define-read-only (get-next-restaurant-id)
  (var-get next-restaurant-id)
)

;; Get current review ID counter
(define-read-only (get-next-review-id)
  (var-get next-review-id)
)

;; Get current media ID counter
(define-read-only (get-next-media-id)
  (var-get next-media-id)
)

;; Get reviewer statistics
(define-read-only (get-reviewer-stats (reviewer principal))
  (map-get? reviewer-stats { reviewer: reviewer })
)

;; Get restaurant loyalty information
(define-read-only (get-loyalty-info (restaurant-id uint) (customer principal))
  (if (and (> restaurant-id u0) (< restaurant-id (var-get next-restaurant-id)))
    (map-get? restaurant-loyalty { restaurant-id: restaurant-id, customer: customer })
    none
  )
)

;; Get current reward pool balance
(define-read-only (get-reward-pool)
  (var-get reward-pool)
)
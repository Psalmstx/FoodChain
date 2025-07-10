;; FoodChain - Decentralized Restaurant Review System
;; A smart contract for managing restaurant registrations and reviews

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-rating (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-transfer-failed (err u106))

;; Reward constants
(define-constant high-quality-review-threshold u4)
(define-constant reviewer-reward-amount u1000000)
(define-constant loyalty-reward-amount u500000)
(define-constant min-reviews-for-reward u3)

;; Data Variables with bounds checking
(define-data-var next-restaurant-id uint u1)
(define-data-var next-review-id uint u1)
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
    average-rating: uint
  }
)

(define-map reviews
  { review-id: uint }
  {
    restaurant-id: uint,
    reviewer: principal,
    rating: uint,
    comment: (string-ascii 500),
    timestamp: uint
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

;; Public Functions

;; Register a new restaurant
(define-public (register-restaurant (name (string-ascii 100)) (cuisine-type (string-ascii 50)) (location (string-ascii 200)))
  (let ((restaurant-id (var-get next-restaurant-id)))
    (asserts! (> (len name) u0) err-invalid-rating)
    (asserts! (> (len cuisine-type) u0) err-invalid-rating) 
    (asserts! (> (len location) u0) err-invalid-rating)
    (asserts! (< restaurant-id max-safe-counter) err-invalid-rating)
    
    (map-set restaurants
      { restaurant-id: restaurant-id }
      {
        name: name,
        owner: tx-sender,
        cuisine-type: cuisine-type,
        location: location,
        is-active: true,
        total-reviews: u0,
        average-rating: u0
      }
    )
    (var-set next-restaurant-id (+ restaurant-id u1))
    (ok restaurant-id)
  )
)

;; Submit a review for a restaurant
(define-public (submit-review (restaurant-id uint) (rating uint) (comment (string-ascii 500)))
  (let (
    (review-id (var-get next-review-id))
  )
    (asserts! (> restaurant-id u0) err-invalid-rating)
    (asserts! (< restaurant-id (var-get next-restaurant-id)) err-not-found)
    (let ((restaurant (unwrap! (map-get? restaurants { restaurant-id: restaurant-id }) err-not-found)))
      (asserts! (> (len comment) u0) err-invalid-rating)
      (asserts! (< review-id max-safe-counter) err-invalid-rating)
      (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
      (asserts! (is-none (map-get? user-reviews { reviewer: tx-sender, restaurant-id: restaurant-id })) err-already-exists)
      (asserts! (get is-active restaurant) err-unauthorized)
      
      ;; Create the review
      (map-set reviews
        { review-id: review-id }
        {
          restaurant-id: restaurant-id,
          reviewer: tx-sender,
          rating: rating,
          comment: comment,
          timestamp: stacks-block-height
        }
      )
      
      ;; Track user's review for this restaurant
      (map-set user-reviews
        { reviewer: tx-sender, restaurant-id: restaurant-id }
        { review-id: review-id }
      )
      
      ;; Update restaurant statistics with overflow protection
      (let (
        (current-total (get total-reviews restaurant))
        (current-avg (get average-rating restaurant))
      )
        (asserts! (< current-total max-safe-counter) err-invalid-rating)
        (let (
          (new-total (+ current-total u1))
          (current-total-points (* current-avg current-total))
        )
          (asserts! (<= current-total-points (- max-uint rating)) err-invalid-rating)
          (let (
            (total-rating-points (+ current-total-points rating))
            (new-average (/ total-rating-points new-total))
          )
            (map-set restaurants
              { restaurant-id: restaurant-id }
              (merge restaurant {
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
        (and (if (and is-high-quality (>= new-total-reviews min-reviews-for-reward))
       (try! (distribute-reviewer-reward tx-sender))
       true
     )
     true)
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
        (and (if (and (> new-visit-count u2) (is-eq (mod new-visit-count u5) u0))
       (try! (distribute-loyalty-reward tx-sender restaurant-id))
       true
     )
     true)
      )
      
      (var-set next-review-id (+ review-id u1))
      (ok review-id)
    )
  )
)

;; Toggle restaurant active status (owner only)
(define-public (toggle-restaurant-status (restaurant-id uint))
  (begin
    (asserts! (> restaurant-id u0) err-invalid-rating)
    (asserts! (< restaurant-id (var-get next-restaurant-id)) err-not-found)
    (let ((restaurant (unwrap! (map-get? restaurants { restaurant-id: restaurant-id }) err-not-found)))
      (asserts! (is-eq tx-sender (get owner restaurant)) err-unauthorized)
      (map-set restaurants
        { restaurant-id: restaurant-id }
        (merge restaurant { is-active: (not (get is-active restaurant)) })
      )
      (ok true)
    )
  )
)

;; Reward system functions

;; Fund the reward pool (owner only)
(define-public (fund-reward-pool (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (let ((current-pool (var-get reward-pool)))
      ;; Check for overflow before adding
      (asserts! (<= amount (- max-uint current-pool)) err-invalid-rating)
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
  (map-get? reviews { review-id: review-id })
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
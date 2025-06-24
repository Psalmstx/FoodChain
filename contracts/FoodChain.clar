;; FoodChain - Decentralized Restaurant Review System
;; A smart contract for managing restaurant registrations and reviews

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-rating (err u103))
(define-constant err-unauthorized (err u104))

;; Data Variables with bounds checking
(define-data-var next-restaurant-id uint u1)
(define-data-var next-review-id uint u1)

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
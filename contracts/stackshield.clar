;; ------------------------
;; Constants and Traits
;; ------------------------

(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_POOL_INACTIVE (err u104))
(define-constant ERR_DUPLICATE_CLAIM (err u105))
(define-constant ERR_NOT_MEMBER (err u106))
(define-constant ERR_ALREADY_VOTED (err u107))

(define-constant MIN_PREMIUM u10)

;; Stub oracle trait
(define-trait oracle-trait
  (
    (get-btc-price () (response uint uint))
    (get-event-verification (uint) (response bool uint))
  )
)

;; ------------------------
;; Data Vars & Maps
;; ------------------------

(define-data-var pool-count uint u0)
(define-data-var claim-count uint u0)

(define-map insurance-pools
  {pool-id: uint}
  {
    owner: principal,
    premium: uint,
    active: bool,
    total-contributions: uint
  }
)

(define-map user-contributions
  {
    pool-id: uint,
    user: principal
  }
  {
    amount: uint
  }
)

(define-map claims
  {claim-id: uint}
  {
    pool-id: uint,
    claimant: principal,
    amount: uint,
    approved: bool,
    executed: bool,
    votes-for: uint,
    votes-against: uint
  }
)

(define-map claim-votes
  {
    claim-id: uint,
    voter: principal
  }
  bool
)

;; ------------------------
;; Function: Create Pool
;; ------------------------

(define-public (create-pool (premium uint))
  (begin
    (if (< premium MIN_PREMIUM)
        ERR_INVALID_AMOUNT
        (let
            ((new-id (+ (var-get pool-count) u1)))
          (begin
            (map-set insurance-pools
              {pool-id: new-id}
              {
                owner: tx-sender,
                premium: premium,
                active: true,
                total-contributions: u0
              }
            )
            (var-set pool-count new-id)
            (ok new-id)
          )
        )
    )
  )
)

;; ------------------------
;; Function: Join Pool
;; ------------------------

(define-public (join-pool (pool-id uint))
  (begin
    ;; Validate pool-id
    (asserts! (< pool-id (var-get pool-count)) ERR_NOT_FOUND)
    (match (map-get? insurance-pools {pool-id: pool-id})
      some-pool (if (is-eq (get active some-pool) false)
        ERR_POOL_INACTIVE
        (begin
          (try! (stx-transfer? (get premium some-pool) tx-sender (get owner some-pool)))
          (map-set user-contributions
            {
              pool-id: pool-id,
              user: tx-sender
            }
            {
              amount: (get premium some-pool)
            })
          (map-set insurance-pools
            {pool-id: pool-id}
            (merge some-pool { total-contributions: (+ (get total-contributions some-pool) (get premium some-pool)) }))
          (ok true)))
      ERR_NOT_FOUND)))

;; ------------------------
;; Function: Submit Claim
;; ------------------------

(define-public (submit-claim (pool-id uint) (amount uint))
  (begin
    ;; Validate pool-id and amount
    (asserts! (< pool-id (var-get pool-count)) ERR_NOT_FOUND)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (let ((pool (unwrap! (map-get? insurance-pools {pool-id: pool-id}) ERR_NOT_FOUND))
          (user-contrib (unwrap! (map-get? user-contributions { pool-id: pool-id, user: tx-sender }) ERR_NOT_MEMBER)))
      (let ((new-claim-id (+ (var-get claim-count) u1)))
        (begin
          (map-set claims
            {claim-id: new-claim-id}
            {
              pool-id: pool-id,
              claimant: tx-sender,
              amount: amount,
              approved: false,
              executed: false,
              votes-for: u0,
              votes-against: u0
            })
          (var-set claim-count new-claim-id)
          (ok new-claim-id))))))

;; ------------------------
;; Function: Vote on Claim
;; ------------------------

(define-public (vote-claim (claim-id uint) (vote-for bool))
  (begin
    ;; Validate claim-id
    (asserts! (< claim-id (var-get claim-count)) ERR_NOT_FOUND)
    (let ((prev-claim (unwrap! (map-get? claims {claim-id: claim-id}) ERR_NOT_FOUND)))
      (match (map-get? claim-votes { claim-id: claim-id, voter: tx-sender })
        prev-vote ERR_ALREADY_VOTED
        (begin
          (map-set claim-votes
            { claim-id: claim-id, voter: tx-sender }
            vote-for)
          (map-set claims
            {claim-id: claim-id}
            {
              pool-id: (get pool-id prev-claim),
              claimant: (get claimant prev-claim),
              amount: (get amount prev-claim),
              approved: (get approved prev-claim),
              executed: (get executed prev-claim),
              votes-for: (if vote-for (+ (get votes-for prev-claim) u1) (get votes-for prev-claim)),
              votes-against: (if vote-for (get votes-against prev-claim) (+ (get votes-against prev-claim) u1))
            })
          (ok true))))))

;; ------------------------
;; Function: Execute Claim (if passed)
;; ------------------------

(define-public (execute-claim (claim-id uint))
  (begin
    ;; Validate claim-id
    (asserts! (< claim-id (var-get claim-count)) ERR_NOT_FOUND)
    (let ((claim (unwrap! (map-get? claims {claim-id: claim-id}) ERR_NOT_FOUND)))
      (begin
        (asserts! (not (or (get executed claim) (is-eq tx-sender (get claimant claim)))) ERR_UNAUTHORIZED)
        (if (> (get votes-for claim) (get votes-against claim))
          (begin
            ;; Here you could add oracle/event verification
            (let ((pool (unwrap! (map-get? insurance-pools {pool-id: (get pool-id claim)}) ERR_NOT_FOUND)))
              (begin
                (try! (stx-transfer? (get amount claim) (get owner pool) (get claimant claim)))
                (map-set claims {claim-id: claim-id} (merge claim { approved: true, executed: true }))
                (ok true))))
          (err u108))))))

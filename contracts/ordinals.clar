;; Updated Ordinal Contract with Security Considerations

;; Define the data map to store ordinal information
(define-data-var ordinals (map uint uint))
(define-data-var listings (map uint (tuple (principal uint uint))))
(define-data-var staked-ordinals (map principal uint))

;; Function to mint a new ordinal
(define-public (mint-ordinal (token-id : uint) (ordinal : uint))
  (assert (is-none (map-get? ordinals token-id)) "Ordinal already exists")
  (map-set! ordinals token-id ordinal))

;; Function to list an ordinal for sale
(define-public (list-ordinal-for-sale (token-id : uint) (price : uint))
  (assert (is-some (map-get? ordinals token-id)) "Ordinal does not exist")
  (assert (is-none (map-get? listings token-id)) "Ordinal is already listed")
  (map-set! listings token-id (tuple (tx-sender) price 0)))

;; Function to buy an ordinal from the marketplace
(define-public (buy-ordinal (token-id : uint))
  (let ((listing (map-get listings token-id (some (tuple (principal 0 0))))))
    (let ((seller (tuple-get listing 0))
          (price (tuple-get listing 1)))
      (assert (and (> (get-balance seller) price) (= (get-balance tx-sender) 0)) "Insufficient funds")
      (transfer (contract-caller) seller price)
      (transfer tx-sender contract-caller price)
      (map-remove! listings token-id))))

;; Function to cancel a listing
(define-public (cancel-listing (token-id : uint))
  (let ((listing (map-get listings token-id (some (tuple (principal 0 0))))))
    (assert (= tx-sender (tuple-get listing 0)) "Unauthorized to cancel listing")
    (transfer contract-caller tx-sender (tuple-get listing 1))
    (map-remove! listings token-id)))

;; Function to stake an ordinal
(define-public (stake-ordinal (token-id : uint))
  (let ((ordinal (map-get ordinals token-id (some 0))))
    (map-set! staked-ordinals tx-sender ordinal)
    (map-set! ordinals token-id 0)  ;; Remove ordinal from regular circulation
    (assert (>= (get-stx-amount) 1000000) "Staking requires a minimum of 1 STX")))

;; Function to claim rewards from staking (assuming a simple reward mechanism)
(define-public (claim-rewards)
  (let ((staked-ordinal (map-get staked-ordinals tx-sender (some 0))))
    (assert (> staked-ordinal 0) "No ordinal staked")
    (let ((reward (div (u256-mul staked-ordinal 10) 100))) ; Reward is 10% of the staked ordinal
      (transfer contract-caller tx-sender reward)
      (map-set! staked-ordinals tx-sender 0))))

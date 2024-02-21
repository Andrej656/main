;; Pool Contract (pool.clar)

;; Define error constants
(define-constant err-not-found (err u404))
(define-constant err-non-positive-amount (err u500))
(define-constant err-no-stacker-info (err u501))
(define-constant err-no-user-info (err u502))
(define-constant err-decrease-forbidden (err u503))
(define-constant err-stacking-permission-denied (err u609))

;; Define storage maps
(define-map allowance-contract-callers
  { sender: principal, contract-caller: principal}
  { until-burn-ht: (optional uint)})

(define-map user-data principal { pox-addr: { hashbytes: (buff 32), version: (buff 1) }, cycle: uint })

(define-map grouped-stackers { pool: principal, reward-cycle: uint, index: uint }
  (list 30 { lock-amount: uint, stacker: principal, unlock-burn-height: uint, pox-addr: { hashbytes: (buff 32), version: (buff 1) }, cycle: uint }))

(define-map grouped-stackers-len { pool: principal, reward-cycle: uint } uint)

(define-map grouped-totals { pool: principal, reward-cycle: uint } uint)

;; Define helper functions
(define-private (merge-details (stacker { lock-amount: uint, stacker: principal, unlock-burn-height: uint }) (user { pox-addr: { hashbytes: (buff 32), version: (buff 1) }, cycle: uint }))
  { lock-amount: (get lock-amount stacker),
    stacker: (get stacker stacker),
    unlock-burn-height: (get unlock-burn-height stacker),
    pox-addr: (get pox-addr user),
    cycle: (get cycle user) })

(define-private (insert-in-new-list (pool principal) (reward-cycle uint) (last-index uint) (details { lock-amount: uint, stacker: principal, unlock-burn-height: uint, pox-addr: { hashbytes: (buff 32), version: (buff 1) }, cycle: uint }))
  (let ((index (+ last-index u1)))
    (map-insert grouped-stackers (print { pool: pool, reward-cycle: reward-cycle, index: index }) (list details))
    (map-set grouped-stackers-len { pool: pool, reward-cycle: reward-cycle } index)))

(define-private (map-set-details (pool principal) (details { lock-amount: uint, stacker: principal, unlock-burn-height: uint, pox-addr: { hashbytes: (buff 32), version: (buff 1) }, cycle: uint }))
  (let ((reward-cycle (+ (contract-call? 'SP000000000000000000002Q6VF78.pox-2 current-pox-reward-cycle) u1))
        (last-index (get-status-lists-last-index pool reward-cycle))
        (stacker-key { pool: pool, reward-cycle: reward-cycle, index: last-index }))
    (match (map-get? grouped-stackers stacker-key)
      stackers (match (as-max-len? (append stackers details) u30)
                 updated-list (map-set grouped-stackers stacker-key updated-list)
                 (insert-in-new-list pool reward-cycle last-index details))
      (map-insert grouped-stackers stacker-key (list details)))
    (map-set grouped-totals { pool: pool, reward-cycle: reward-cycle } (+ (get total pool reward-cycle) (get lock-amount details)))))

;; Define public functions

;; Delegate stacking rights to a pool
(define-public (delegate-stx (amount-ustx uint) (delegate-to principal) (until-burn-ht (optional uint)) (pool-pox-addr { hashbytes: (buff 32), version: (buff 1) }) (user-pox-addr { hashbytes: (buff 32), version: (buff 1) }))
  (begin
    ;; Must be called directly by the tx-sender or by an allowed contract-caller
    (asserts! (check-caller-allowed) err-stacking-permission-denied)
    (map-set user-data tx-sender { pox-addr: user-pox-addr, cycle: (contract-call? 'SP000000000000000000002Q6VF78.pox-2 current-pox-reward-cycle) })
    (pox-delegate-stx amount-ustx delegate-to until-burn-ht)))

;; Lock stacks of pool members in batches for 1 cycle
(define-public (delegate-stack-stx (users (list 30 { user: principal, amount-ustx: uint })) (pox-address { version: (buff 1), hashbytes: (buff 32) }) (start-burn-ht uint))
  (begin
    (asserts! (check-caller-allowed) err-stacking-permission-denied)
    (ok (get result
             (fold delegate-stack-stx-fold users { start-burn-ht: start-burn-ht, pox-address: pox-address, result: (list) })))))

;; Lock stacks of pool members in batches for a lock period of 1 cycle
(define-public (delegate-stack-stx-simple (users (list 30 principal)) (pox-address { version: (buff 1), hashbytes: (buff 32) }) (start-burn-ht uint))
  (begin
    (asserts! (check-caller-allowed) err-stacking-permission-denied)
    (ok (get result
             (fold delegate-stack-stx-simple-fold users { start-burn-ht: start-burn-ht, pox-address: pox-address, result: (list) })))))

;; Read-only functions

(define-read-only (get-status (pool principal) (user principal))
  (let ((stacker-info (unwrap! (pox-get-stacker-info user) err-no-stacker-info)))
    (ok { stacker-info: stacker-info,
          user-info: (unwrap! (map-get? user-data user) err-no-user-info),
          total: (get-total pool (get first-reward-cycle stacker-info)) })))

(define-read-only (get-status-lists-last-index (pool principal) (reward-cycle uint))
  (default-to u0 (map-get? grouped-stackers-len { pool: pool, reward-cycle: reward-cycle })))

(define-read-only (get-status-list (pool principal) (reward-cycle uint) (index uint))
  { total: (get-total pool reward-cycle),
    status-list: (map-get? grouped-stackers { pool: pool, reward-cycle: reward-cycle, index: index }) })

(define-read-only (get-delegated-amount (user principal))
  (default-to u0 (get amount-ustx (contract-call? 'SP000000000000000000002Q6VF78.pox-2 get-delegation-info user))))

(define-read-only (get-user-data (user principal))
  (map-get? user-data user))

(define-read-only (get-stx-account (user principal))
  (stx-account user))

(define-read-only (get-total (pool principal) (reward-cycle uint))
  (default-to u0 (map-get? grouped-totals { pool: pool, reward-cycle: reward-cycle })))

;; Functions for allowance of delegation/stacking contract calls

(define-public (allow-contract-caller (caller principal) (until-burn-ht (optional uint)))
  (begin
    (asserts! (is-eq tx-sender contract-caller) err-stacking-permission-denied)
    (ok (map-set allowance-contract-callers
                 { sender: tx-sender, contract-caller: caller }
                 { until-burn-ht: until-burn-ht }))))

(define-public (disallow-contract-caller (caller principal))
  (begin
    (asserts! (is-eq tx-sender contract-caller) err-stacking-permission-denied)
    (ok (map-delete allowance-contract-callers { sender: tx-sender, contract-caller: caller }))))

(define-read-only (check-caller-allowed)
  (or (is-eq tx-sender contract-caller)
      (let ((caller-allowed
             (unwrap! (map-get? allowance-contract-callers
                                { sender: tx-sender, contract-caller: contract-caller })
                      false))
            (expires-at
             (unwrap! (get until-burn-ht caller-allowed) true)))
        (< burn-block-height expires-at))))

(define-read-only (get-allowance-contract-callers (sender principal) (calling-contract principal))
  (map-get? allowance-contract-callers { sender: sender, contract-caller: calling-contract }))

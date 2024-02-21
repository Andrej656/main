;; STX20 Protocol contract

(define-public (deploy-stx20 (ticker (string-ascii 8)) (total-supply uint) (limit-per-mint uint))
  (if (is-user-msg-sender? (contract-call? 'ST1J861WZ0AT3AFCPNBAMCTZT7KW6D5B6BS0B802H.stx20 get-owner (tuple ticker)))
    (begin
      (map-set stx20-tokens ticker (tuple total-supply limit-per-mint))
      (ok true)
    )
    (err "You are not authorized to deploy this STX20 token")
  )
)

(define-public (mint-stx20 (ticker (string-ascii 8)) (amount uint))
  (let ((token-details (map-get stx20-tokens ticker)))
    (if (is-some token-details)
      (let ((total-supply (tuple-get (unwrap token-details) 0))
            (limit-per-mint (tuple-get (unwrap token-details) 1)))
        (if (is-user-msg-sender? (contract-call? 'ST1J861WZ0AT3AFCPNBAMCTZT7KW6D5B6BS0B802H.stx20 get-owner (tuple ticker)))
          (begin
            (if (<= (+ amount (unwrap (map-get stx20-balances tx-sender ticker))) total-supply)
              (begin
                (map-set stx20-balances tx-sender ticker (+ amount (unwrap (map-get stx20-balances tx-sender ticker)))))
                (ok true)
              )
              (err "Mint amount exceeds total supply")
            )
          )
          (err "You are not authorized to mint this STX20 token")
        )
      )
      (err "Token details not found")
    )
  )
)

(define-public (transfer-stx20 (ticker (string-ascii 8)) (amount uint) (to-principal principal))
  (let ((token-details (map-get stx20-tokens ticker)))
    (if (is-some token-details)
      (let ((total-supply (tuple-get (unwrap token-details) 0)))
        (if (<= amount (unwrap (map-get stx20-balances tx-sender ticker)))
          (begin
            (map-set stx20-balances tx-sender ticker (- (unwrap (map-get stx20-balances tx-sender ticker)) amount))
            (map-set stx20-balances to-principal ticker (+ amount (unwrap (map-get stx20-balances to-principal ticker)))))
            (ok true)
          )
          (err "Insufficient balance to transfer")
        )
      )
      (err "Token details not found")
    )
  )


(define-read-only (get-stx20-balance (address principal) (ticker (string-ascii 8)))
  (unwrap (map-get stx20-balances address ticker))
)

;; Define storage variables
(define-data-var stx20-tokens (map string-ascii (tuple uint uint)))
(define-data-var stx20-balances (map principal (map string-ascii uint)))

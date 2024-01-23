;; Define the SIP010 FT Trait
(define-trait ft-trait
    (
        (transfer (principal uint principal) (response bool))
    )
)

;; Implement the SIP010 FT Trait
(define-public (transfer (amount uint) (recipient principal) (sender principal))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (ft-transfer? amazing-coin amount recipient))
    (ok true)
)

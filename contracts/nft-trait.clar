;; Define the SIP009 NFT Trait
(define-trait nft-trait)
    (
        (mint (principal uint) (response uint))
        (get-owner (uint) (response principal))
    )
)

;; Implement the SIP009 NFT Trait
(define-public (mint (recipient principal) (token-id uint))
    (let ((token-id (+ (var-get sip009-token-id-nonce) u1)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (try! (nft-mint? stacksies token-id recipient))
        (asserts! (var-set sip009-token-id-nonce token-id) err-token-id-failure)
        (ok token-id)
    )
)

(define-public (get-owner (token-id uint))
    (nft-get-owner? stacksies token-id)
)

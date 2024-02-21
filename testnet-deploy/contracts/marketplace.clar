;; Marketplace Contract

;; Define NFT structure
(define-data-var nfts (map uint (tuple principal uint uint uint uint uint bool uint uint)))

;; Define collection structure
(define-data-var collections (map principal (tuple (map uint (tuple principal uint uint uint uint uint bool uint)) bool)))

;; Define balances for rewards and fees
(define-data-var balances (map principal uint))

;; Define protocol fees
(define-constant protocol-fee 5) ;; 5% protocol fee

;; Define collection types
(define-read-only (is-finite-collection? (collection principal))
  (tuple-get (unwrap (map-get collections collection)) 1)
)

(define-read-only (is-infinite-collection? (collection principal))
  (not (is-finite-collection? collection))
)

;; Function to mint an NFT
(define-public (mint-nft (collection principal) (nft-id uint) (price uint) (market-value uint))
  (if (is-infinite-collection? collection)
    (begin
      (map-set nfts nft-id (tuple collection nft-id price market-value tx-sender u0 false u0 u0))
      (ok true)
    )
    (err "Cannot mint NFT in infinite collection")
  )
)

;; Function to list an NFT for sale
(define-public (list-nft-for-sale (nft-id uint) (price uint))
  (let ((nft-details (map-get nfts nft-id)))
    (if (is-some nft-details)
      (let ((collection (tuple-get (unwrap nft-details) 0))
            (nft-owner (tuple-get (unwrap nft-details) 4)))
        (if (is-user-msg-sender? nft-owner)
          (begin
            (map-set nfts nft-id (tuple-set (unwrap nft-details) 6 true))
            (map-set nfts nft-id (tuple-set (unwrap nft-details) 7 price))
            (ok true)
          )
          (err "You are not the owner of this NFT")
        )
      )
      (err "NFT not found")
    )
  )
)

;; Function to buy an NFT
(define-public (buy-nft (nft-id uint))
  (let ((nft-details (map-get nfts nft-id)))
    (if (is-some nft-details)
      (let ((price (tuple-get (unwrap nft-details) 7))
            (nft-owner (tuple-get (unwrap nft-details) 4)))
        (if (is-user-msg-sender? tx-sender)
          (begin
            (transfer-stx (contract-principal) price nft-owner)
            (map-set nfts nft-id (tuple-set (unwrap nft-details) 6 false))
            (map-set nfts nft-id (tuple-set (unwrap nft-details) 8 (+ (unwrap (map-get balances tx-sender)) (* protocol-fee (/ price 100)))))
            (map-set nfts nft-id (tuple-set (unwrap nft-details) 4 tx-sender))
            (map-set nfts nft-id (tuple-set (unwrap nft-details) 5 (+ (unwrap (map-get nft-details 5)) price)))
            (ok true)
          )
          (err "You are not authorized to buy this NFT")
        )
      )
      (err "NFT not found")
    )
  )
)

;; Function to cancel listing of an NFT
(define-public (cancel-listing (nft-id uint))
  (let ((nft-details (map-get nfts nft-id)))
    (if (is-some nft-details)
      (let ((nft-owner (tuple-get (unwrap nft-details) 4)))
        (if (is-user-msg-sender? nft-owner)
          (begin
            (map-set nfts nft-id (tuple-set (unwrap nft-details) 6 false))
            (ok true)
          )
          (err "You are not the owner of this NFT")
        )
      )
      (err "NFT not found")
    )
  )
)

;; Function to distribute rewards
(define-public (distribute-rewards (nft-id uint))
  (let ((nft-details (map-get nfts nft-id)))
    (if (is-some nft-details)
      (let ((nft-owner (tuple-get (unwrap nft-details) 4))
            (price (tuple-get (unwrap nft-details) 7)))
        (if (is-user-msg-sender? nft-owner)
          (begin
            (transfer-stx (contract-principal) (* protocol-fee (/ price 100)) nft-owner)
            (ok true)
          )
          (err "You are not authorized to distribute rewards for this NFT")
        )
      )
      (err "NFT not found")
    )
  )
)

;; Function to compound rewards
(define-public (compound-rewards (nft-id uint))
  (let ((nft-details (map-get nfts nft-id)))
    (if (is-some nft-details)
      (let ((nft-owner (tuple-get (unwrap nft-details) 4))
            (rewards (unwrap (map-get nfts nft-id 8))))
        (if (is-user-msg-sender? nft-owner)
          (begin
            (map-set balances tx-sender (+ rewards (unwrap (map-get balances tx-sender)))))
            (map-set nfts nft-id (tuple-set (unwrap nft-details) 8 u0))
            (ok true)
          )
          (err "You are not authorized to compound rewards for this NFT")
        )
      )
      (err "NFT not found")
    )
  )


;; Function to collect fees
(define-public (collect-fees (nft-id uint))
  (let ((nft-details (map-get nfts nft-id)))
    (if (is-some nft-details)
      (let ((nft-owner (tuple-get (unwrap nft-details) 4))
            (fees (unwrap (map-get nfts nft-id 8))))
        (if (is-user-msg-sender? nft-owner)
          (begin
            (transfer-stx (contract-principal) fees nft-owner)
            (map-set nfts nft-id (tuple-set (unwrap nft-details) 8 u0))
            (ok true)
          )
          (err "You are not authorized to collect fees for this NFT")
        )
      )
      (err "NFT not found")
    )
  )
)

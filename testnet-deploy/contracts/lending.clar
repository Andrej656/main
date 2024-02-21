;; Lending Contract (lending.clar)

;; Define error constants
(define-constant err-not-found (err u404))
(define-constant err-insufficient-balance (err u405))
(define-constant err-invalid-amount (err u406))
(define-constant err-insufficient-collateral (err u407))
(define-constant err-nft-not-found (err u408))
(define-constant err-nft-already-lent (err u409))
(define-constant err-invalid-duration (err u410))
(define-constant err-invalid-operation (err u411))

;; Define data structures for lending NFTs
(define-data-var lending-nft (id uint) (owner principal) (lender principal) (duration uint) (start-block-height uint))

;; Define data structures for lending STX
(define-data-var lending-stx (owner principal) (lender principal) (amount-ustx uint) (duration uint) (start-block-height uint))

;; Define storage maps for lending NFTs and STX
(define-map lending-nfts { id uint } lending-nft)
(define-map lending-stx { owner principal } lending-stx)

;; Define lending contract functions

;; Function to lend an NFT
(define-public (lend-nft (id uint) (lender principal) (duration uint))
  (let ((nft (get lending-nfts id)))
    (if (is-none? nft)
      (err err-nft-not-found)
      (let ((nft-data (unwrap nft))
            (current-block-height (block-height)))
        (if (> (current-block-height) (+ (get start-block-height nft-data) (get duration nft-data)))
          (err err-invalid-operation) ;; Lending duration expired
          (if (is-eq (get owner nft-data) (get lender nft-data))
            (err err-invalid-operation) ;; Owner and lender cannot be the same
            (if (> (get duration nft-data) duration)
              (err err-invalid-duration) ;; New duration cannot be shorter than the current duration
              (begin
                (map-set lending-nfts id { id: id, owner: (get owner nft-data), lender: lender, duration: duration, start-block-height: current-block-height })
                (ok true))))))))

;; Function to lend STX
(define-public (lend-stx (lender principal) (amount-ustx uint) (duration uint))
  (let ((current-block-height (block-height))
        (owner (tx-sender)))
    (if (>= (balance owner) amount-ustx)
      (begin
        (transfer amount-ustx lender)
        (map-set lending-stx owner { owner: owner, lender: lender, amount-ustx: amount-ustx, duration: duration, start-block-height: current-block-height })
        (ok true))
      (err err-insufficient-balance))))

;; Function to retrieve lent NFT
(define-public (retrieve-nft (id uint))
  (let ((nft (get lending-nfts id)))
    (if (is-none? nft)
      (err err-nft-not-found)
      (let ((nft-data (unwrap nft))
            (current-block-height (block-height)))
        (if (> (current-block-height) (+ (get start-block-height nft-data) (get duration nft-data)))
          (err err-invalid-operation) ;; Lending duration expired
          (if (not (is-eq tx-sender (get lender nft-data)))
            (err err-invalid-operation) ;; Only lender can retrieve the NFT
            (begin
              (map-set lending-nfts id { id: id, owner: (get owner nft-data), lender: (get owner nft-data), duration: u0, start-block-height: u0 })
              (ok true))))))))

;; Function to retrieve lent STX
(define-public (retrieve-stx)
  (let ((lent-stx (get lending-stx (tx-sender))))
    (if (is-none? lent-stx)
      (err err-not-found)
      (let ((stx-data (unwrap lent-stx))
            (current-block-height (block-height)))
        (if (> (current-block-height) (+ (get start-block-height stx-data) (get duration stx-data)))
          (err err-invalid-operation) ;; Lending duration expired
          (begin
            (transfer (get amount-ustx stx-data) tx-sender)
            (map-set lending-stx tx-sender { owner: tx-sender, lender: tx-sender, amount-ustx: u0, duration: u0, start-block-height: u0 })
            (ok true)))))))

;; Define read-only functions

;; Function to get lending details of an NFT
(define-read-only (get-lending-details-nft (id uint))
  (unwrap (get lending-nfts id)))

;; Function to get lending details of an STX
(define-read-only (get-lending-details-stx)
  (unwrap (get lending-stx (tx-sender))))



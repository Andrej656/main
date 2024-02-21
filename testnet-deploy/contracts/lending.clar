;; Define lending contract logic here

(define-map lending-nfts { id: uint } lending-nft)
(define-map lending-stx { owner: principal } uint)

(define-public (lend-nft (id uint) (lender principal) (duration uint))
  (map-set lending-nfts { id: id } { owner: lender, duration: duration }))

(define-public (borrow-nft (id uint) (borrower principal))
  (let ((nft-info (map-get lending-nfts { id: id })))
    (match nft-info
      (some info
        (if ( (get owner info) borrower)
          (map-set lending-nfts { id: id } { owner: none, duration: 0 })
          (err u1000 "NFT not available for borrowing")))
      (none (err u1000 "NFT not found")))))

(define-public (lend-stx (amount-ustx uint) (lender principal))
  (map-set lending-stx { owner: lender } amount-ustx))

(define-public (borrow-stx (amount-ustx uint) (borrower principal))
  (let ((stx-info (map-get lending-stx { owner: borrower })))
    (match stx-info
      (some info
        (if (>= (get amount-ustx info) amount-ustx)
          (map-set lending-stx { owner: borrower } (- (get amount-ustx info) amount-ustx))
          (err u1000 "Insufficient STX available for borrowing")))
      (none (err u1000 "No STX available for borrowing")))))

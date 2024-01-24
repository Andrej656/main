(define-data-var user-nfts (map principal (list uint)))
(define-data-var user-primary-nft (map principal uint))
(define-data-var nft-status (map uint string))
(define-data-var nft-prices (map uint uint))
(define-data-var nft-earnings (map uint uint))
(define-data-var last-price-oracle-response (tuple (stx-usd uint)))
(define-data-var coingecko-api-url "https://api.coingecko.com/api/v3/simple/price?ids=stacks&vs_currencies=usd")
(define-data-var admin-address "SP1GDFGHR0DJESZNCN4HZDGW4ZBNM1M7X1A7TFV3W")

(define-public (get-user-nfts)
  (ok (map-entries (at-block user-nfts))))

(define-public (get-user-primary-nft)
  (ok (map-entries (at-block user-primary-nft))))

(define-public (get-nft-info (_nft-id uint))
  (ok (map-merge
       (map-merge
        (map-merge
         (map-merge
          (map (at-block user-nfts))
          (map (at-block user-primary-nft)))
         (map (at-block nft-status)))
        (map (at-block nft-prices)))
       (map (at-block nft-earnings)))))

(define-read-only (get-last-price)
  (ok (at-block last-price-oracle-response)))

(define-public (update-price-oracle)
  (if (principals-equal? (get-principal (tx-sender)) (stx-principal))
      (begin
        (let ((oracle-response (http-get coingecko-api-url)))
          (if (err? oracle-response)
              (err "Error fetching price from Coingecko")
              (begin
                (map-set last-price-oracle-response (get-principal (tx-sender)) oracle-response)
                (ok "Price oracle updated")))))
      (err "Unauthorized access")))

(define-private (is-admin)
  (if (principals-equal? (get-principal (tx-sender)) admin-address)
      true
      false))

(define-private (is-contract-caller-admin)
  (if (principals-equal? (contract-principal) (stx-principal))
      true
      false))

(define-public (mint-nft (_creator principal) (_collection principal) (_type uint) (_metadata string) (_intrinsic-value uint))
  (if (and (is-contract-caller-admin) (is-admin))
      (begin
        (let ((nft-id (get-nft-id _creator _collection _type)))
          (map-set user-nfts (get-principal (tx-sender)) (append (map-get user-nfts (get-principal (tx-sender))) nft-id))
          (map-set user-primary-nft (get-principal (tx-sender)) nft-id)
          (map-set nft-status nft-id "Minted")
          (map-set nft-prices nft-id 0)
          (map-set nft-earnings nft-id 0)
          (ok nft-id)))
      (err "Unauthorized access"))

(define-public (list-nft-for-sale (_nft-id uint) (_sale-price uint) (_duration uint))
  (if (is-contract-caller-admin)
      (begin
        (map-set nft-status _nft-id "For Sale")
        (map-set nft-prices _nft-id _sale-price)
        (ok "NFT listed for sale"))
      (err "Unauthorized access")))

(define-public (buy-nft (_nft-id uint) (_bid-amount uint))
  (if (is-contract-caller-admin)
      (begin
        (let ((seller (get-principal (map-get user-nfts _nft-id))))
          (stx-transfer? _bid-amount (stx-principal) seller)
          (map-set nft-status _nft-id "Sold")
          (map-set nft-earnings _nft-id (+ (map-get nft-earnings _nft-id) _bid-amount))
          (ok "NFT bought")))
      (err "Unauthorized access")))

(define-public (recharge (_nft-id uint) (_amount uint))
  (if (is-contract-caller-admin)
      (begin
        (let ((owner (get-principal (map-get user-nfts _nft-id))))
          (stx-transfer? _amount (stx-principal) owner)
          (ok "NFT recharged")))
      (err "Unauthorized access")))

(define-public (charge (_nft-id uint) (_amount uint))
  (if (is-contract-caller-admin)
      (begin
        (map-set nft-earnings _nft-id (+ (map-get nft-earnings _nft-id) _amount))
        (ok "NFT charged")))
      (err "Unauthorized access"))

(define-public (withdraw (_amount uint))
  (if (is-contract-caller-admin)
      (begin
        (stx-transfer? _amount (stx-principal) (get-principal (tx-sender)))
        (ok "STX withdrawn")))
      (err "Unauthorized access"))

(define-public (enable-compounding)
  (if (and (is-contract-caller-admin) (is-admin))
      (begin
        ;; Logic for enabling compounding
        (ok "Compounding enabled"))
      (err "Unauthorized access")))

(define-public (cancel-compounding)
  (if (and (is-contract-caller-admin) (is-admin))
      (begin
        ;; Logic for canceling compounding
        (ok "Compounding canceled"))
      (err "Unauthorized access")))

(define-public (set-intrinsic-value (_nft-id uint) (_value uint))
  (if (and (is-contract-caller-admin) (is-admin))
      (begin
        (map-set nft-earnings _nft-id _value)
        (ok "Intrinsic value set"))
      (err "Unauthorized access")))

(define-public (get-nft-price (_nft-id uint))
  (ok (map-merge (map (at-block nft-prices)) (map (at-block nft-earnings)))))

(define-public (get-earnings (_nft-id uint))
  (ok (map (at-block nft-earnings))))

(define-public (dashboard-info)
  (if (is-contract-caller-admin)
      (begin
        ;; Logic for fetching dashboard information
        (ok "Dashboard information fetched"))
      (err "Unauthorized access")))

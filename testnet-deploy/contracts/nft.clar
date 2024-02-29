;; Define NFT contract logic here

(define-data-var nft-tokens (map u256 { name: string, creator: principal, owner: principal, status: string, image_uri: string }))

(define-data-var nft-collections (map string (list u256)))

(define-read-only (get-nft-token (token-id uint))
  (match (map-get nft-tokens token-id)
    (some token-info token-info)
    (none (tuple (name "") (creator none) (owner none) (status "") (image_uri "")))))

(define-read-only (get-nft-collection (collection-id string))
  (match (map-get nft-collections collection-id)
    (some tokens tokens)
    (none (list))))

(define-public (create-nft-token (token-id uint) (name string) (creator principal) (image_uri string))
  (map-set nft-tokens token-id { name: name, creator: creator, owner: creator, status: "available", image_uri: image_uri }))

(define-public (transfer-nft-token (token-id uint) (to principal))
  (map-set nft-tokens token-id { name: (get name (get-nft-token token-id)), creator: (get creator (get-nft-token token-id)), owner: to, status: "available", image_uri: (get image_uri (get-nft-token token-id)) }))

(define-public (mint-nft-token (name string) (creator principal) (image_uri string))
  (let ((new-token-id (+ (length nft-tokens) 1)))
    (create-nft-token new-token-id name creator image_uri)))

(define-public (create-nft-collection (collection-id string))
  (map-set nft-collections collection-id (list)))

(define-public (add-token-to-collection (token-id uint) (collection-id string))
  (match (map-get? nft-collections collection-id)
    (some collection-tokens
      (map-set nft-collections collection-id (append collection-tokens (list token-id))))
    (none (map-set nft-collections collection-id (list token-id)))))

(define-public (remove-token-from-collection (token-id uint) (collection-id string))
  (match (map-get? nft-collections collection-id)
    (some collection-tokens
      (map-set nft-collections collection-id (filter (fn (x) (not ( x token-id))) collection-tokens)))
    (none (map-set nft-collections collection-id (list)))))

(define-read-only (get-collection-tokens (collection-id string))
  (default-to (list) (map-get? nft-collections collection-id)))

(define-read-only (get-token-collection (token-id uint))
  (let ((token-info (get-nft-token token-id)))
    (filter (map nft-collections (fn (collection-id tokens)
                                   (map (list tokens) (fn (token-id) ( token-id token-id))))))))

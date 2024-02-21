;; Dashboard Contract

(define-data-var users (map principal (tuple uint uint uint)))

(define-data-var total-staked-stx u0)

(define-data-var total-rewards-distributed u0)

(define-data-var pox-progress (tuple uint uint))

;; Function to update user dashboard
(define-public (update-dashboard)
  (let ((total-users (length users))
        (total-staked-stx (unwrap total-staked-stx))
        (total-rewards-distributed (unwrap total-rewards-distributed))
        (pox-progress (unwrap pox-progress)))
    (ok (tuple total-users total-staked-stx total-rewards-distributed pox-progress))
  )
)

;; Function to update user demographics
(define-public (update-demographics)
  (let ((total-users (length users))
        (total-collectors 0)
        (total-creators 0))
    (map
      (lambda (user)
        (let ((user-data (unwrap (map-get users user))))
          (if (> (at user-data 2) 0)
            (set total-collectors (+ total-collectors 1))
            (set total-creators (+ total-creators 1))
          )
        )
      )
      (keys users)
    )
    (ok (tuple total-users total-collectors total-creators))
  )
)

;; Function to update user TVL
(define-public (update-tvl)
  (let ((total-tvl 0))
    (map
      (lambda (user)
        (let ((user-data (unwrap (map-get users user))))
          (set total-tvl (+ total-tvl (at user-data 1)))
        )
      )
      (keys users)
    )
    (ok total-tvl)
  )
)

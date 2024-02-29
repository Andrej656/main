;; Dashboard Contract

;; Define a map to hold user information. Each user is identified by their principal with their data held in a tuple.
(define-map users 
    principal 
    (tuple 
        (staked-stx uint) 
        (rewards-distributed uint) 
        (pox-progress uint)
    )
)

;; Define data variables to track overall statistics.
(define-data-var total-users uint u0)
(define-data-var total-staked-stx uint u0)
(define-data-var total-rewards-distributed uint u0)
(define-data-var global-pox-progress uint u0) ;; Renamed to avoid naming conflict.

;; Function to register or update a user's data.
(define-public (register-or-update-user 
    (user principal) 
    (staked-stx uint) 
    (rewards-distributed uint) 
    (user-pox-progress uint)) ;; Parameter name changed for clarity.
    (begin
        ;; Update or add the user's data to the map.
        (map-set users 
            user 
            (tuple 
                (staked-stx staked-stx) 
                (rewards-distributed rewards-distributed) 
                (pox-progress user-pox-progress) ;; This refers to the user-specific field.
            )
        )
        ;; Increment the total-staked-stx and total-rewards-distributed with the provided values.
        (var-set total-staked-stx (+ (var-get total-staked-stx) staked-stx))
        (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) rewards-distributed))
        ;; Note: Logic to accurately manage total-users count and prevent overcounting should be considered.
        (var-set total-users (+ (var-get total-users) u1))
        (ok true)
    )
)

;; Function to retrieve a user's data.
(define-read-only (get-user (user principal))
    (map-get? users user)
)

;; Function to get global statistics for the dashboard.
(define-read-only (get-dashboard-stats)
    (ok (tuple 
        (total-users (var-get total-users))
        (total-staked-stx (var-get total-staked-stx))
        (total-rewards-distributed (var-get total-rewards-distributed))
        (pox-progress (var-get global-pox-progress)) ;; Adjusted to the new variable name.
    ))
)

;; Example function to simulate updating the global PoX progress.
(define-public (update-global-pox-progress (new-pox-progress uint))
    (begin
        (var-set global-pox-progress new-pox-progress) ;; Adjusted to the new variable name.
        (ok true)
    )
)

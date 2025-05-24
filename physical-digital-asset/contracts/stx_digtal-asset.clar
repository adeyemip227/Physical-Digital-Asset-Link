;; Digital Twin for Products Smart Contract
;; Represents physical assets on-chain with comprehensive metadata

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PRODUCT-NOT-FOUND (err u101))
(define-constant ERR-PRODUCT-EXISTS (err u102))
(define-constant ERR-INVALID-STATUS (err u103))

;; Product status constants
(define-constant STATUS-MANUFACTURED u1)
(define-constant STATUS-IN-TRANSIT u2)
(define-constant STATUS-DELIVERED u3)
(define-constant STATUS-MAINTENANCE u4)
(define-constant STATUS-RETIRED u5)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Product metadata structure
(define-map products
  { product-id: (string-ascii 64) }
  {
    name: (string-utf8 100),
    manufacturer: principal,
    manufacture-date: uint,
    batch-number: (string-ascii 32),
    model: (string-utf8 50),
    serial-number: (string-ascii 64),
    materials: (list 10 (string-utf8 50)),
    weight: uint, ;; in grams
    dimensions: { length: uint, width: uint, height: uint }, ;; in mm
    current-owner: principal,
    status: uint,
    location: (optional (string-utf8 100)),
    certification: (optional (string-utf8 100)),
    warranty-expiry: uint,
    created-at: uint,
    updated-at: uint
  }
)

;; Product ownership history
(define-map ownership-history
  { product-id: (string-ascii 64), timestamp: uint }
  {
    previous-owner: principal,
    new-owner: principal,
    transfer-reason: (string-utf8 100)
  }
)

;; Product lifecycle events
(define-map lifecycle-events
  { product-id: (string-ascii 64), event-id: uint }
  {
    event-type: (string-utf8 50),
    description: (string-utf8 200),
    location: (optional (string-utf8 100)),
    timestamp: uint,
    recorded-by: principal,
    additional-data: (optional (string-utf8 500))
  }
)

;; Event counter for each product
(define-map event-counters
  { product-id: (string-ascii 64) }
  { count: uint }
)

;; Read-only functions

;; Get product details
(define-read-only (get-product (product-id (string-ascii 64)))
  (map-get? products { product-id: product-id })
)

;; Get product ownership history
(define-read-only (get-ownership-history (product-id (string-ascii 64)) (timestamp uint))
  (map-get? ownership-history { product-id: product-id, timestamp: timestamp })
)

;; Get lifecycle event
(define-read-only (get-lifecycle-event (product-id (string-ascii 64)) (event-id uint))
  (map-get? lifecycle-events { product-id: product-id, event-id: event-id })
)

;; Get current event count for product
(define-read-only (get-event-count (product-id (string-ascii 64)))
  (default-to u0 (get count (map-get? event-counters { product-id: product-id })))
)

;; Check if product exists
(define-read-only (product-exists (product-id (string-ascii 64)))
  (is-some (map-get? products { product-id: product-id }))
)

;; Public functions

;; Create a new digital twin
(define-public (create-product 
  (product-id (string-ascii 64))
  (name (string-utf8 100))
  (batch-number (string-ascii 32))
  (model (string-utf8 50))
  (serial-number (string-ascii 64))
  (materials (list 10 (string-utf8 50)))
  (weight uint)
  (dimensions { length: uint, width: uint, height: uint })
  (certification (optional (string-utf8 100)))
  (warranty-months uint)
)
  (let
    (
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
      (warranty-expiry (+ current-time (* warranty-months u2629746))) ;; approx seconds in a month
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (not (product-exists product-id)) ERR-PRODUCT-EXISTS)
    
    ;; Create product record
    (map-set products
      { product-id: product-id }
      {
        name: name,
        manufacturer: tx-sender,
        manufacture-date: current-time,
        batch-number: batch-number,
        model: model,
        serial-number: serial-number,
        materials: materials,
        weight: weight,
        dimensions: dimensions,
        current-owner: tx-sender,
        status: STATUS-MANUFACTURED,
        location: none,
        certification: certification,
        warranty-expiry: warranty-expiry,
        created-at: current-time,
        updated-at: current-time
      }
    )
    
    ;; Initialize event counter
    (map-set event-counters { product-id: product-id } { count: u0 })
    
    ;; Record initial lifecycle event
    (unwrap-panic (add-lifecycle-event 
      product-id 
      u"MANUFACTURED" 
      u"Product created and manufactured" 
      none 
      none
    ))
    
    (ok product-id)
  )
)

;; Transfer ownership
(define-public (transfer-ownership 
  (product-id (string-ascii 64))
  (new-owner principal)
  (transfer-reason (string-utf8 100))
)
  (let
    (
      (product (unwrap! (get-product product-id) ERR-PRODUCT-NOT-FOUND))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (asserts! (is-eq tx-sender (get current-owner product)) ERR-NOT-AUTHORIZED)
    
    ;; Record ownership history
    (map-set ownership-history
      { product-id: product-id, timestamp: current-time }
      {
        previous-owner: (get current-owner product),
        new-owner: new-owner,
        transfer-reason: transfer-reason
      }
    )
    
    ;; Update product owner
    (map-set products
      { product-id: product-id }
      (merge product {
        current-owner: new-owner,
        updated-at: current-time
      })
    )
    
    ;; Record lifecycle event
    (unwrap-panic (add-lifecycle-event 
      product-id 
      u"OWNERSHIP_TRANSFER" 
      transfer-reason
      none
      (some (concat u"New owner: " (principal-to-string new-owner)))
    ))
    
    (ok true)
  )
)

;; Update product status
(define-public (update-status 
  (product-id (string-ascii 64))
  (new-status uint)
  (location (optional (string-utf8 100)))
  (notes (optional (string-utf8 200)))
)
  (let
    (
      (product (unwrap! (get-product product-id) ERR-PRODUCT-NOT-FOUND))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
      (status-name (get-status-name new-status))
    )
    (asserts! (is-eq tx-sender (get current-owner product)) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-status STATUS-RETIRED) ERR-INVALID-STATUS)
    (asserts! (>= new-status STATUS-MANUFACTURED) ERR-INVALID-STATUS)
    
    ;; Update product
    (map-set products
      { product-id: product-id }
      (merge product {
        status: new-status,
        location: location,
        updated-at: current-time
      })
    )
    
    ;; Record lifecycle event
    (unwrap-panic (add-lifecycle-event 
      product-id 
      u"STATUS_UPDATE" 
      (default-to u"Status updated" notes)
      location
      (some (concat u"Status changed to: " status-name))
    ))
    
    (ok true)
  )
)

;; Add maintenance record
(define-public (add-maintenance-record
  (product-id (string-ascii 64))
  (description (string-utf8 200))
  (location (optional (string-utf8 100)))
  (cost uint)
  (technician (string-utf8 100))
)
  (let
    (
      (product (unwrap! (get-product product-id) ERR-PRODUCT-NOT-FOUND))
      (maintenance-data (concat 
        (concat u"Cost: " (uint-to-string cost))
        (concat u" STX, Technician: " technician)
      ))
    )
    (asserts! (is-eq tx-sender (get current-owner product)) ERR-NOT-AUTHORIZED)
    
    ;; Record maintenance event
    (unwrap-panic (add-lifecycle-event 
      product-id 
      u"MAINTENANCE" 
      description
      location
      (some maintenance-data)
    ))
    
    (ok true)
  )
)

;; Private functions

;; Add lifecycle event
(define-private (add-lifecycle-event
  (product-id (string-ascii 64))
  (event-type (string-utf8 50))
  (description (string-utf8 200))
  (location (optional (string-utf8 100)))
  (additional-data (optional (string-utf8 500)))
)
  (let
    (
      (current-count (get-event-count product-id))
      (new-count (+ current-count u1))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    
    ;; Add event
    (map-set lifecycle-events
      { product-id: product-id, event-id: new-count }
      {
        event-type: event-type,
        description: description,
        location: location,
        timestamp: current-time,
        recorded-by: tx-sender,
        additional-data: additional-data
      }
    )
    
    ;; Update counter
    (map-set event-counters { product-id: product-id } { count: new-count })
    
    (ok new-count)
  )
)

;; Helper function to convert status to string
(define-private (get-status-name (status uint))
  (if (is-eq status STATUS-MANUFACTURED) u"MANUFACTURED"
  (if (is-eq status STATUS-IN-TRANSIT) u"IN_TRANSIT"
  (if (is-eq status STATUS-DELIVERED) u"DELIVERED"
  (if (is-eq status STATUS-MAINTENANCE) u"UNDER_MAINTENANCE"
  (if (is-eq status STATUS-RETIRED) u"RETIRED"
  u"UNKNOWN")))))
)

;; Helper function to convert uint to string (simplified)
(define-private (uint-to-string (value uint))
  ;; This is a simplified version - in practice you'd want a more robust implementation
  (if (<= value u9) 
    (if (is-eq value u0) u"0"
    (if (is-eq value u1) u"1" 
    (if (is-eq value u2) u"2"
    (if (is-eq value u3) u"3"
    (if (is-eq value u4) u"4"
    (if (is-eq value u5) u"5"
    (if (is-eq value u6) u"6"
    (if (is-eq value u7) u"7"
    (if (is-eq value u8) u"8"
    u"9")))))))))
    u"10+"
  )
)

;; Helper function to convert principal to string (placeholder)
(define-private (principal-to-string (p principal))
  u"[Principal Address]" ;; In practice, you'd implement proper conversion
)
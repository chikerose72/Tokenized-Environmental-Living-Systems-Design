;; Adaptive Management Contract
;; Enables responsive system evolution

(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_STRATEGY_NOT_FOUND (err u401))
(define-constant ERR_INVALID_THRESHOLD (err u402))

;; Management strategy structure
(define-map strategies
  { strategy-id: uint }
  {
    name: (string-ascii 50),
    system-id: uint,
    trigger-threshold: uint,
    response-action: (string-ascii 100),
    created-by: principal,
    active: bool,
    execution-count: uint,
    last-executed: (optional uint)
  }
)

;; System monitoring data
(define-map system-metrics
  { system-id: uint, metric-type: (string-ascii 30) }
  {
    current-value: uint,
    trend: (string-ascii 20),
    last-updated: uint,
    alert-level: (string-ascii 10)
  }
)

(define-data-var strategy-counter uint u0)

;; Create adaptive management strategy
(define-public (create-strategy
  (name (string-ascii 50))
  (system-id uint)
  (trigger-threshold uint)
  (response-action (string-ascii 100)))
  (begin
    (asserts! (> trigger-threshold u0) ERR_INVALID_THRESHOLD)
    (let ((strategy-id (+ (var-get strategy-counter) u1)))
      (map-set strategies
        { strategy-id: strategy-id }
        {
          name: name,
          system-id: system-id,
          trigger-threshold: trigger-threshold,
          response-action: response-action,
          created-by: tx-sender,
          active: true,
          execution-count: u0,
          last-executed: none
        }
      )
      (var-set strategy-counter strategy-id)
      (ok strategy-id)
    )
  )
)

;; Update system metrics
(define-public (update-system-metric
  (system-id uint)
  (metric-type (string-ascii 30))
  (current-value uint)
  (trend (string-ascii 20)))
  (let ((alert-level (if (< current-value u30) "high"
                        (if (< current-value u60) "medium" "low"))))
    (map-set system-metrics
      { system-id: system-id, metric-type: metric-type }
      {
        current-value: current-value,
        trend: trend,
        last-updated: block-height,
        alert-level: alert-level
      }
    )
    (ok true)
  )
)

;; Execute adaptive response
(define-public (execute-adaptive-response (strategy-id uint))
  (let ((strategy (unwrap! (map-get? strategies { strategy-id: strategy-id }) ERR_STRATEGY_NOT_FOUND)))
    (asserts! (get active strategy) ERR_UNAUTHORIZED)
    (map-set strategies
      { strategy-id: strategy-id }
      (merge strategy {
        execution-count: (+ (get execution-count strategy) u1),
        last-executed: (some block-height)
      })
    )
    (ok true)
  )
)

;; Check if strategy should trigger
(define-read-only (should-trigger-strategy (strategy-id uint) (current-metric-value uint))
  (let ((strategy (unwrap! (map-get? strategies { strategy-id: strategy-id }) ERR_STRATEGY_NOT_FOUND)))
    (ok (< current-metric-value (get trigger-threshold strategy)))
  )
)

;; Get strategy details
(define-read-only (get-strategy (strategy-id uint))
  (map-get? strategies { strategy-id: strategy-id })
)

;; Get system metrics
(define-read-only (get-system-metric (system-id uint) (metric-type (string-ascii 30)))
  (map-get? system-metrics { system-id: system-id, metric-type: metric-type })
)

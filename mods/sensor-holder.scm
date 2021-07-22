(set-bounds! [-30 -30 -1] [30 30 60])
(set-quality! 10)
(set-resolution! 8)

(define fan-holder-space -0.5)
(define plate-thickness 1.5)
(define screw-distance 35)
(define fan-length 41)
(define fan-height 12)
(define fan-plus-half  (/ fan-length 2))
(define fan-minus-half  (/ fan-length -2))
(define sensor-r (/ 19 2))
(define sensor-ext-r (/ 30 2))


(define blower-plate
  (extrude-z
    (difference
      (rectangle-centered-exact [fan-length fan-length])
      (symmetric-y
        (symmetric-x
          (move (circle 1.2) [(/ screw-distance 2) (/ screw-distance 2)]))))
  0 plate-thickness))

(define sensor-holder
  (extrude-z
    (difference
      (circle sensor-ext-r)
      (circle sensor-r))
  0 5))

blower-plate
(move
  (rotate-y sensor-holder (/ pi 2))
  [fan-plus-half 0 (+ sensor-ext-r plate-thickness fan-height fan-holder-space)])

(box
  [fan-minus-half fan-plus-half 0]
  [fan-plus-half (+ fan-plus-half plate-thickness plate-thickness) fan-height])
(box
  [fan-minus-half (- fan-minus-half plate-thickness plate-thickness) 0]
  [fan-plus-half fan-minus-half fan-height])

(let (
  (base-v (+ fan-plus-half (* 2 plate-thickness)))
  (base-h (+ fan-plus-half))
  (sz 0.2)
  ) (difference
      (loft
        (rectangle [(- 0) (- base-v)] [(- base-h 0) base-v])
        (rectangle [(- base-h 5) -15] [base-h 15]) fan-height (+ sensor-ext-r plate-thickness fan-height fan-holder-space))
      
      (box [(- base-h) (- base-v) 0] [base-h base-v 10])
      
      (extrude-z (scale-xyz (circle fan-plus-half) [0.9 1 1]) 0 40)
      
      (scale-xyz
        (move
          (rotate-y
            (extrude-z (circle fan-plus-half) fan-minus-half fan-plus-half)
          (/ pi 2))
        [0 0 (/ fan-height sz)]) [1 1 sz])
      
      (move
        (rotate-y
          (extrude-z (circle sensor-r) -5 10)
          (/ pi 2))
        [fan-plus-half 0 (+ sensor-ext-r plate-thickness fan-height fan-holder-space)])
      
      (symmetric-y
        (symmetric-x
          (move (circle 1.8) [(/ screw-distance 1.8) (/ screw-distance 2)])))
      
      (move
        (rotate-y sensor-holder (/ pi 2))
        [(- fan-plus-half 5) 0 (+ sensor-ext-r plate-thickness fan-height fan-holder-space)])
      )
  )

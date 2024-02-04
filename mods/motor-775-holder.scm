(set-bounds! [-10 -10 -10] [10 10 10])
(set-quality! 10)
(set-resolution! 25)


(define wall-thickness 0.4)
(define motor-dia 4.5)
(define motor-ring-dia 1.8)

(define holder-dia (+ motor-dia wall-thickness wall-thickness))
(define holder-hegiht 3)
(define backplate-height 6.2)

(define plate-thickness 0.4)
(define plate-groove 0.5)
(define plate-lenght 2.5)

(define 90deg (/ pi 2))


(define backplate (difference
  (move
    (box-centered [holder-dia (/ holder-dia 2) backplate-height])
    [0 (- (/ holder-dia -4) wall-thickness) (/ backplate-height 2)])
  (extrude-z
    (ring (/ holder-dia 2) 0) 0 backplate-height)))

(define back-clip (let*
  (
    (clip-y (+ plate-thickness wall-thickness))
    (clip-z (+ wall-thickness plate-groove))
  )
  (move
    (difference
      (box-centered [holder-dia clip-y clip-z] [0 (/ clip-y 2) (/ clip-z 2)])
      (box-centered [plate-lenght plate-thickness plate-groove] [0 (- clip-y (/ plate-thickness 2)) (- clip-z (/ plate-groove 2))])
)
  [0 (- (/ holder-dia -2) clip-y wall-thickness) 0])))

(define motor-cup (union
  (extrude-z
    (ring (/ holder-dia 2) (/ motor-dia 2)) 0 holder-hegiht)
  (extrude-z
    (ring (/ holder-dia 2) (/ motor-ring-dia 2)) 0 plate-thickness)
))

(define motor-holes (cylinder-z 0.21 2 [0 0 -1]))
(define cup-screw-holes (union
  (cylinder-z 0.3 1 [0 0 0])
  (cylinder-z 0.15 1 [0 0 -1])))

(difference (move (union backplate motor-cup back-clip) [0 0 (/ plate-groove -2)])
  (symmetric-x (move motor-holes [1.4 0 0]))
  (symmetric-x (move (rotate-x cup-screw-holes (- 90deg)) [1 (/ holder-dia -2) 5.4]))
  (move (rotate-x (cylinder-z 0.5 1 [0 0 -0.5]) 90deg) [0 (- (/ holder-dia -2) plate-thickness) 1.5])                                                                          
  (symmetric-x (move (rotate-x (cylinder-z 1 4 [0 0 -2]) 90deg) [2.5 -2 5.4])))

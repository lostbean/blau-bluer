(set-bounds! [-10 -10 -10] [10 10 10])
(set-quality! 8)
(set-resolution! 10)

(define thickness 0.02)

(extrude-z (ring 9 8.5) 0 thickness)
(extrude-z (ring 7 6.5) 0 thickness)
(extrude-z (ring 5 4.5) 0 thickness)
(extrude-z (ring 3 2.5) 0 thickness)
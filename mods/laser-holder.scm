;; Holder for Laser Tree - LT-40W-AA
;; for 3D printer Two Trees
(set-bounds! [-10 -10 -10] [10 10 10])
(set-quality! 10)
(set-resolution! 25)


(define wall-thickness 0.4)
(define back-wall-thickness (* wall-thickness 2))

(define motor-dia 4.5)
(define motor-ring-dia 1.8)

(define holder-dia (+ motor-dia wall-thickness wall-thickness))
(define holder-hegiht back-wall-thickness)
(define backplate-height 6.2)

(define plate-thickness 0.41)
(define plate-groove 0.5)
(define plate-lenght 2.5)

(define laser-xy 4.03)
(define laser-cover-z 3.8)
(define laser-base-screew-z (+ 4.0 laser-cover-z))
(define laser-screew-x (/ 2.4 2))

(define sensor-r (/ 1.9 2))
(define sensor-outer-r (/ 3.2 2))

(define 90deg (/ pi 2))
(define 45deg (/ pi 5))

(define clip-y (+ plate-thickness wall-thickness))
(define laser-holder-outer-len (+ laser-xy wall-thickness))



(define sensor-holder
  (move
    (extrude-z
      (difference
        (union
          (circle sensor-outer-r)
          (rectangle-centered-exact [(* 1 sensor-outer-r) (* 2 sensor-outer-r) ] [(/ sensor-outer-r 2) 0]))
        (circle sensor-r)
    ) 0 back-wall-thickness)
  [(- (+ sensor-outer-r (/ laser-holder-outer-len 2))) (+ sensor-outer-r clip-y back-wall-thickness) laser-cover-z]))

(define back-clip (let*
  ((clip-z (+ wall-thickness plate-groove)))
  (difference
    (box-centered [holder-dia clip-y clip-z] [0 (/ clip-y 2) (/ clip-z 2)])
    (box-centered [plate-lenght plate-thickness plate-groove] [0 (- clip-y (/ plate-thickness 2)) (- clip-z (/ plate-groove 2))]))))

(define backplate (let*
  ((total-z (+ laser-base-screew-z 1)))                        
  (union
    (move
      (box-centered [holder-dia back-wall-thickness total-z])
      [0 (+ clip-y (/ back-wall-thickness 2)) (/ total-z 2)]))))

(define motor-cup (let*
  (
    (inner laser-xy)
    (inner-base (+ inner 1))
    (outter-base holder-dia)
    (outter (- outter-base wall-thickness))
    (cup-z (+ back-wall-thickness laser-cover-z)))
  (move
    (intersection
      (difference
        (loft
          (rectangle-centered-exact [outter-base outter-base])
          (rectangle-centered-exact [outter outter])
          0 cup-z)
        (loft
          (rectangle-centered-exact [inner-base inner-base])
          (rectangle-centered-exact [inner inner])
          0 cup-z))
      (move
        (extrude-z
          (rotate-x (rectangle-centered-exact [outter-base outter-base]) (- 45deg))
        (- cup-z) 0)
      [0 (/ (- (/ laser-holder-outer-len 2) back-wall-thickness) -6) cup-z])
  )                                                                                                                                                         
  [0 (+ back-wall-thickness clip-y (/ inner 2)) ])))



(define motor-holes (cylinder-z 0.2505 2 [0 0 -1]))
(define cup-screw-holes (union
  (cylinder-z 0.3 1 [0 0 0])
  (cylinder-z 0.15 1 [0 0 -1])))

(difference (move (union backplate motor-cup back-clip sensor-holder) [0 0 (/ plate-groove -2)])
  (symmetric-x (move (rotate-x motor-holes (- 90deg)) [laser-screew-x 1 (+ laser-base-screew-z (/ plate-groove -2))]))
  (symmetric-x (move (rotate-x cup-screw-holes (- 90deg)) [1 (+ clip-y (/ back-wall-thickness 2)) 5.4]))
  (move (rotate-x (cylinder-z 0.5 1) 90deg) [0 (+ clip-y 0.6) 1.5])                                                                          
  (symmetric-x (move (rotate-y (scale-z (rotate-x (cylinder-z 1.2 4) 90deg) 1.4) -0.3) [2.8 3 6.1])))

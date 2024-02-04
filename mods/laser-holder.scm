;; Holder for Laser Tree - LT-40W-AA
;; for 3D printer Two Trees
(set-bounds! [-10 -10 -10] [10 10 10])
(set-quality! 10)
(set-resolution! 25)


(define wall-thickness 0.4)
(define back-wall-thickness (* wall-thickness 2))

(define laser-cover-xy 4.03)
(define laser-cover-xy-base 4.16)
(define laser-cover-z 3.8)
(define laser-base-screew-z (+ 4.0 laser-cover-z))
(define laser-screew-x (/ 2.4 2))

(define holder-dia (+ laser-cover-xy-base wall-thickness))
(define holder-hegiht back-wall-thickness)
(define backplate-height 6.2)

(define plate-thickness 0.41)
(define plate-groove 0.5)
(define plate-lenght 2.5)


(define sensor-r (/ 1.9 2))
(define sensor-outer-r (/ 3.2 2))

(define exhaust-inlet-r 1.2)
(define exhaust-outlet-r 0.95)
(define exhaust-insertion-y wall-thickness)
(define exhaust-cone-z 4)
(define exhaust-outlet-z 2)
(define dute-thickness 0.2)

(define blast-outlet-r 0.3)
(define blast-inlet-r 0.95)
(define blast-cone-z 2)
(define blast-inlet-z 1.5)
(define blast-outlet-z 0.615)
(define blast-wall-to-tube 1.08)

(define 90deg (/ pi 2))
(define 45deg (/ pi 5))

(define clip-y (+ plate-thickness wall-thickness))
(define laser-holder-outer-len (+ laser-cover-xy wall-thickness))
(define laser-holder-outer-len (+ laser-cover-xy wall-thickness))



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
    back-clip
    (move
      (box-centered [holder-dia back-wall-thickness total-z])
      [0 (+ clip-y (/ back-wall-thickness 2)) (/ total-z 2)]))))


(define motor-cup (let*
  (
    (inner laser-cover-xy)
    (inner-base laser-cover-xy-base)
    (outter (+ inner wall-thickness))
    (outter-base (+ inner-base wall-thickness))
    (cup-z (+ back-wall-thickness laser-cover-z))
    (mask
      (move
        (extrude-z
            (rotate-x (rectangle-centered-exact [outter-base outter-base]) (- 45deg))
        (- cup-z) 0)
      [0 (/ (- (/ laser-holder-outer-len 2) back-wall-thickness) -6) cup-z]))

    (inlet (intersection
      (circle exhaust-inlet-r)
      (rectangle-centered-exact [exhaust-inlet-r (* exhaust-inlet-r 2)] [(/ exhaust-inlet-r 2) 0])))
    (outlet (circle exhaust-outlet-r))
    (exhaust-dute
        (shell
            (union
              (extrude-z outlet exhaust-cone-z (+ exhaust-cone-z exhaust-outlet-z))
              (loft (circle exhaust-inlet-r) outlet 0 exhaust-cone-z)
              (rotate-y (extrude-z inlet 0 (+ exhaust-inlet-r exhaust-insertion-y)) 90deg)
          ) dute-thickness)
    )
    (inlet-cutout (rotate-y (extrude-z (offset inlet (- dute-thickness)) 0 (+ 1 exhaust-inlet-r exhaust-insertion-y)) 90deg))
    (outlet-cutout (extrude-z (offset outlet (- dute-thickness)) (- exhaust-cone-z 1) (+ 1 exhaust-cone-z exhaust-outlet-z)))
    (dute-move [(+ (/ outter-base 2) exhaust-outlet-r dute-thickness) 0 0])
    (cup-move [0 (+ back-wall-thickness clip-y (/ inner 2)) ])
    (cover-cutout
      (loft
        (rectangle-centered-exact [inner-base inner-base])
        (rectangle-centered-exact [inner inner])
        0 cup-z))
    
    (blast-inlet-outer-r blast-inlet-r)
    (blast-inlet-inner-r (- blast-inlet-r dute-thickness))
    (blast-outlet-outer-r (+ blast-outlet-r dute-thickness))
    (blast-outlet-inner-r blast-outlet-r)
    (blast-outlet-shift [0 (- blast-outlet-outer-r blast-inlet-outer-r)])
    (blast-wall-to-inner-tube (- blast-wall-to-tube (* blast-outlet-inner-r 2)))
    
    (blast
      (union
        (extrude-z (ring blast-inlet-outer-r blast-inlet-inner-r) blast-cone-z (+ blast-cone-z blast-inlet-z))
        (difference
          (loft
            (move (circle blast-outlet-outer-r) blast-outlet-shift)
            (circle blast-inlet-outer-r)
            0 blast-cone-z) 
          (loft
            (move (circle blast-outlet-inner-r) blast-outlet-shift)
            (circle blast-inlet-inner-r)
            0 blast-cone-z))      
        (move (extrude-z (ring blast-outlet-outer-r blast-outlet-inner-r) (- 0 blast-outlet-z) 0) blast-outlet-shift)
        (move 
          (extrude-z
            (rectangle-centered-exact [(* wall-thickness 2) blast-wall-to-inner-tube])
            (- blast-outlet-z) (+ blast-cone-z))
        [0 (- (+ blast-inlet-inner-r (/ blast-wall-to-inner-tube 2)))])
      )
    )
    
  )

  (difference
    (union
      (move blast [0 (+ blast-wall-to-inner-tube inner blast-inlet-outer-r clip-y back-wall-thickness (/ wall-thickness -2)) laser-cover-z])
      backplate
      sensor-holder
      (move (move exhaust-dute dute-move) cup-move)
      (move (intersection
        mask
        (loft
          (rectangle-centered-exact [outter-base outter-base])
          (rectangle-centered-exact [outter outter])
          0 cup-z)) cup-move))
  (move cover-cutout cup-move)
  (move (move inlet-cutout dute-move) cup-move)
  (move (move outlet-cutout dute-move) cup-move))))

(define motor-holes (cylinder-z 0.2505 2 [0 0 -1]))
(define cup-screw-holes (union
  (cylinder-z 0.3 1 [0 0 0])
  (cylinder-z 0.15 1 [0 0 -1])))

(difference (move motor-cup [0 0 (/ plate-groove -2)])
  (symmetric-x (move (rotate-x motor-holes (- 90deg)) [laser-screew-x 1 (+ laser-base-screew-z (/ plate-groove -2))]))
  (symmetric-x (move (rotate-x cup-screw-holes (- 90deg)) [1 (+ clip-y (/ back-wall-thickness 2)) 5.4]))
  (move (rotate-x (cylinder-z 0.5 1) 90deg) [0 (+ clip-y 0.6) 1.5])                                                                          
  (symmetric-x (move (rotate-y (scale-z (rotate-x (cylinder-z 1.2 2) 90deg) 1.4) -0.3) [2.8 2 6.1])))

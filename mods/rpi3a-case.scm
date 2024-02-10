(set-bounds! [-100 -100 -100] [100 150 100])
(set-quality! 8)
(set-resolution! 10)

(define board-x 65)
(define board-y 56)
(define board-holes-x 58)
(define board-holes-y 49)

(define board-holes-r 1.2)
(define board-hole-base-r 5)
(define board-support-z 38)
(define board-support-inset-base-r 2.5)
(define board-support-inset-base-z 11)
(define board-support-inset-z 2)

(define box-height (+ board-support-z 10))

(define wall-th 2)

(define box-inner-x (+ board-x (* 1 wall-th)))
(define box-inner-y (+ board-y (* 1 wall-th)))
(define box-x (+ board-x (* 2 wall-th)))
(define box-y (+ board-y (* 2 wall-th)))

(define support-sq-base-x (- box-inner-x board-holes-x))
(define support-sq-base-y (- box-inner-y board-holes-y))

(define flat-cable-gap-z 1)
(define flat-cable-width 16)
(define flat-cable-lenght 45)

(define cam-holder-xy 32)
(define cam-holder- 32)

(define bar-xy 20)

(define 90deg (* 90 (/ pi 180)))

(let* (
  (support-rect (rectangle-centered-exact [support-sq-base-x support-sq-base-y]))
  
  (support (union
    (extrude-z support-rect 0 (- board-support-z board-support-inset-base-z))
    (move (cylinder-z board-support-inset-base-r board-support-inset-base-z) [0 0 (- board-support-z board-support-inset-base-z)])
    (move (cylinder-z board-holes-r board-support-inset-z) [0 0 board-support-z])
   ))
  
  (supports
    (symmetric-x
      (symmetric-y
        (move support [(/ board-holes-x 2) (/ board-holes-y 2)]))))
  
  (base-rect (rounded-rectangle [(/ box-x -2) (/ box-y -2)] [(/ box-x 2) (/ box-y 2)] 1))
  
  (inner-rect (rectangle [(/ box-inner-x -2) (/ box-inner-y -2)] [(/ box-inner-x 2) (/ box-inner-y 2)]))
  
  (box-side
    (extrude-z (difference base-rect inner-rect) 0 box-height))
  
  (box-base
    (extrude-z base-rect 0 wall-th))

  (box-tube
    (move (rotate-y (extrude-z (rectangle-centered-exact [(+ bar-xy wall-th wall-th) (+ bar-xy wall-th wall-th)]) (/ box-x -2) (/ box-x 2)) 90deg) [0 0 (/ (+ bar-xy wall-th wall-th) 2)]))
  
  (cover
    (union
      (extrude-z base-rect box-height (+ box-height wall-th))
      (extrude-z (shell inner-rect wall-th) (- box-height wall-th) (+ box-height wall-th))
      (symmetric-x
        (symmetric-y
          (move
            (extrude-z support-rect (+ board-support-z board-support-inset-z) box-height)
            [(/ board-holes-x 2) (/ board-holes-y 2)])))
    ))

    (cam-arm
      (union
        (rectangle-centered-exact [flat-cable-width flat-cable-lenght])
        (rectangle-centered-exact [cam-holder-xy cam-holder-xy] [0 (/ (+ flat-cable-lenght cam-holder-xy) 2)])))

    (flat-cable
      (move
         (difference
          (extrude-z (offset cam-arm wall-th) 0 (* 2 wall-th))
          (extrude-z cam-arm wall-th (* 2 wall-th))
         )
      [0 (/(+ flat-cable-lenght box-y) 2) 0]))
    
    (flat-cable-cover
      (move
         (difference
          (extrude-z (offset cam-arm (* 2 wall-th)) 0 (* 3 wall-th))
          (extrude-z (offset cam-arm wall-th) 0 (* 2 wall-th))
         )
      [0 (/(+ flat-cable-lenght box-y) 2) 0]))

    (cuts
      (union
        ;; flat cable hole
        (extrude-z
          (rectangle-centered-exact [flat-cable-width 10] [0 (/(+ box-y) 2) wall-th]) wall-th (* 2 wall-th))
        ;;cam hole
        (extrude-z
          (rectangle-centered-exact [24 17.5] [0 (/ (+ box-y flat-cable-lenght flat-cable-lenght cam-holder-xy) 2)]) 0 wall-th)
        ;; hdmi hole
        (move (rotate-x (extrude-z (rectangle-centered-exact [16 8]) (- wall-th) wall-th) 90deg) [-0.5 (/ box-y -2) (- board-support-z 4)])
        ;; micro usb hole
        (move (rotate-x (extrude-z (rectangle-centered-exact [9 4]) (- wall-th) wall-th) 90deg) [22 (/ box-y -2) (- board-support-z 2)])
        ;; audio jack hole
        (move (rotate-x (extrude-z (circle 3.5) (- wall-th) wall-th) 90deg) [-21 (/ box-y -2) (- board-support-z 3.5)])
        ;; USB hole
        (move (rotate-y (extrude-z (rectangle-centered-exact [9 15]) (- wall-th) wall-th) 90deg) [(/ box-x -2) 3.45 (- board-support-z 4.5)])
        ;; sd card hole
        (move (rotate-y (extrude-z (rectangle-centered-exact [3 12]) (- wall-th) wall-th) 90deg) [(/ box-x 2) 0 (+ board-support-z 1)])
        ;; bar groove 
        (move (rotate-y (extrude-z (rectangle-centered-exact [(* bar-xy 2) bar-xy]) (- box-x) box-x) 90deg) [0 0 0])
    ))
    
  ) 
  
  (difference
    (union
      flat-cable
      box-base
      box-side
      box-tube
      supports
      (move flat-cable-cover [0 5 15])
      (move cover [0 0 30])
    )
  cuts))



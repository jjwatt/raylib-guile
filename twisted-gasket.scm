(use-modules (raylib))
(use-modules (srfi srfi-9))

(define screen-width 800)
(define screen-height 450)

(define-macro (inc! x . rest)
  `(set! ,x (+ ,x ,(if (null? rest) 1 (car rest)))))

(define (norm value low high)
  "Normalize value to between 0.0 and 1.0."
  (/ (- value low) (- high low)))

(define (lerp low high amt)
  "Linear interpolation of amt (normalized) to low-high."
  (+ low (* amt (- high low))))

(define (mapvalue value low1 high1 low2 high2)
  "Map from one set of values to the other."
  (let ((n (norm value low1 high1)))
    (lerp low2 high2 n)))

(define pi (* 4 (atan 1.0)))

(define (deg->rad degrees)
  (* degrees (/ pi 180)))

(define-record-type <point>
  (make-point x y)
  point?
  (x point-x)
  (y point-y))

(define (midpoint p1 p2)
  (make-point (/ (+ (point-x p1) (point-x p2)) 2.0)
	      (/ (+ (point-y p1) (point-y p2)) 2.0)))

(define (draw-rotated-line p1 p2 cx cy angle)
  "Rotates two points and draws a line between them in one go."
  (let* ((tx1 (- (point-x p1) cx))
	 (ty1 (- (point-y p1) cy))
	 (dist1 (sqrt (+ (* tx1 tx1) (* ty1 ty1))))
	 (angle1 (+ angle (/ dist1 40)))
	 (cos-a1 (cos angle1))
	 (sin-a1 (sin angle1))
	 (rx1 (+ (- (* tx1 cos-a1) (* ty1 sin-a1)) cx))
	 (ry1 (+ (- (* tx1 sin-a1) (* ty1 cos-a1)) cy))
	 (sx1 (inexact->exact (round (+ (- rx1) screen-width))))
	 (sy1 (inexact->exact (round (+ (- ry1) screen-height))))

	 (tx2 (- (point-x p2) cx))
	 (ty2 (- (point-y p2) cy))
	 (dist2 (sqrt (+ (* tx2 tx2) (* ty2 ty2))))
	 (angle2 (+ angle (/ dist2 40)))
	 (cos-a2 (cos angle2))
	 (sin-a2 (sin angle2))
	 (rx2 (+ (- (* tx2 cos-a2) (* ty2 sin-a2)) cx))
	 (ry2 (+ (- (* tx2 sin-a2) (* ty2 cos-a2)) cy))
	 (sx2 (inexact->exact (round (+ (- rx2) screen-width))))
	 (sy2 (inexact->exact (round (+ (- ry2) screen-height))))
	 (hue (* (modulo (round (+ (/ angle 30.0) (/ t 8.0))) 6.0) 60.0))
	 (dynamic-color (ColorFromHSV hue 0.8 1.0)))
    (DrawLine sx1 sy1 sx2 sy2 dynamic-color)))

(define (draw-gasket p1 p2 p3 depth cx cy angle)
  "Recursively draw the triangle outlines."
  (if (= depth 0)
      ;; base case: draw outer edges.
      (begin
	(draw-rotated-line p1 p2 cx cy angle)
	(draw-rotated-line p2 p3 cx cy angle)
	(draw-rotated-line p3 p1 cx cy angle))
      ;; recursive case: subdivide.
      (let* ((m12 (midpoint p1 p2))
	     (m23 (midpoint p2 p3))
	     (m31 (midpoint p3 p1))
	     (next-depth (- depth 1)))
	(draw-gasket p1 m12 m31 next-depth cx cy angle)
	(draw-gasket m12 p2 m23 next-depth cx cy angle)
	(draw-gasket m31 m23 p3 next-depth cx cy angle))))

(InitWindow screen-width screen-height "raylib twisted gasket")
(SetTargetFPS 60)
(define t 0)

(define (main-loop)
  (unless (WindowShouldClose)
    (inc! t 1)
    (BeginDrawing)

    (ClearBackground BLACK)

    (let* ((cx (/ screen-width 2))
	   (cy (/ screen-height 2))
	   (angle (* t (deg->rad 0.25)))
	   (p1 (make-point 0 screen-height))
	   (p2 (make-point (/ screen-width 2) 0))
	   (p3 (make-point screen-width screen-height)))
    (draw-gasket p1 p2 p3 5 cx cy angle))

    (EndDrawing)
    (main-loop)))

(main-loop)
(CloseWindow)

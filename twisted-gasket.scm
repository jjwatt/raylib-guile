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

(define (rotate-point p cx cy base-angle)
  "Twist a single point relative to the center."
  (let* ((tx (- (point-x p) cx))
	 (ty (- (point-y p) cy))
	 (dist (sqrt (+ (* tx tx) (* ty ty))))
	 (twist-angle (+ base-angle (/ dist 40.0)))
	 (cos-a (cos twist-angle))
	 (sin-a (sin twist-angle))
	 (rx (+ (- (* tx cos-a) (* ty sin-a)) cx))
	 (ry (+ (- (* tx sin-a) (* ty cos-a)) cy)))
    (make-point rx ry)))

(define (draw-twisted-line p1 p2 cx cy base-angle t)
  "Transforms points p1 and p2 with the warp and draws a thick line."
  (let* ((rp1 (rotate-point p1 cx cy base-angle))
	 (rp2 (rotate-point p2 cx cy base-angle))
	 (mid-x (/ (+ (point-x rp1) (point-x rp2)) 2.0))
	 (mid-y (/ (+ (point-y rp1) (point-y rp2)) 2.0))
	 (distance-from-center (sqrt (+ (expt (- mid-x cx) 2) (expt (- mid-y cy) 2))))
	 (hue (modulo (round (+ (* distance-from-center 0.5) (* t 2.0))) 360.0))
	 (dynamic-color (ColorFromHSV hue 0.85 1.0)))
    (DrawLineEx (make-Vector2 (point-x rp1) (point-y rp1))
		(make-Vector2 (point-x rp2) (point-y rp2))
		2.5
		dynamic-color)))

(define (draw-gasket p1 p2 p3 depth cx cy angle t)
  "Recursively draw the triangle outlines."
  (if (= depth 0)
      ;; base case: draw outer edges.
      (begin
	(draw-twisted-line p1 p2 cx cy angle t)
	(draw-twisted-line p2 p3 cx cy angle t)
	(draw-twisted-line p3 p1 cx cy angle t))
      ;; recursive case: subdivide.
      (let* ((m12 (midpoint p1 p2))
	     (m23 (midpoint p2 p3))
	     (m31 (midpoint p3 p1))
	     (next-depth (- depth 1)))
	(draw-gasket p1 m12 m31 next-depth cx cy angle t)
	(draw-gasket m12 p2 m23 next-depth cx cy angle t)
	(draw-gasket m31 m23 p3 next-depth cx cy angle t))))

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
	   (p1 (make-point cx (- cy 200)))
	   (p2 (make-point (- cx 230) (+ cy 170)))
	   (p3 (make-point (+ cx 230) (+ cy 170))))
    (draw-gasket p1 p2 p3 5 cx cy angle t))

    (EndDrawing)
    (main-loop)))

(main-loop)
(CloseWindow)

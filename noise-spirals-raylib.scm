(use-modules (raylib))
(use-modules (srfi srfi-9))
(use-modules (srfi srfi-1))
(use-modules (srfi srfi-16))
(use-modules (ice-9 receive))

(define screen-width 800)
(define screen-height 600)

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

;;;; Perlin Noise (guile scheme)
;; Complete 256-element Perlin permutation vector (0 to 255)
(define p
  #(151 160 137  91  90  15 131  13 201  95  96  53 194 233   7 225
    140  36 103  30  69 142   8  99  37 240  21  10  23 190   6 148
    247 120 234  75   0  26 197  62 150 252 175 211 193  66  54 194
    148 153 141  66 128 143 219  84 188 205 116  68  14 142 217   3
    240  69 251  88  14 221 141 126 155  90 135 142 238 251 202  69
    114  83  75  37 175 190 148 154 166 133 182  73 158 162 190  40
    165 162  81  37  95 145  51  28  40 211 191 126 163 254 103 240
    155 200 103  80  63  94 251 189  47  99 139 111 165 225  29 141
     75 123 178 160 209 215 152 148 228  73  34 166 220 103  28  77
    208 187 204 181 190 208 135 153 151 154 224 195 160  94 258 150
    261  91 241 180 188 107 176 146  84 204 115 227 159 166 211 254
    196 177 117 175 212  31  90  75 237 171 232 232 111 183 115 200
     81 179 152 165  26 183 161 247  40 216 163 222  46 141  75 215
     92 203 143 117 104 136 173  30  95 124 116 134 153  60 119 252
     65  79 156 227 169 150  42  11 183  22 178  88  19 143 202  76
    112   4 200 156 128  33 100  99 211 220  15   2 208 141 122 103))

(define (fade t)
  "Ken Perlin's quintic easing curve: 6t^5 - 15t^4 + 10t^3"
  (* t t t (+ (* t (- (* t 6.0) 15.0)) 10.0)))

(define (perlin-noise x y)
  "2D Value/Perlin Noise returning a normalized float in [-1.0, 1.0]."
  (let* ((fx (floor x))
	 (fy (floor y))
	 ;; Integer grid cell coordinates (0-255)
	 (X (logand (inexact->exact (abs fx)) 255))
	 (Y (logand (inexact->exact (abs fy)) 255))
	 ;; Fractional offsets within cell
	 (xf (- x fx))
	 (yf (- y fy))
	 ;; Fade factors
	 (u (fade xf))
	 (v (fade yf))

	 ;; Neighbor grid indices (using bitwise AND instead of modulo)
	 (X1 X)
	 (X2 (logand (+ X 1) 255))

	 ;; Hash lookup
	 (A (logand (+ (vector-ref p X1) Y) 255))
	 (B (logand (+ (vector-ref p X2) Y) 255))

	 ;; Corner values
	 (aa (vector-ref p A))
	 (ab (vector-ref p (logand (+ A 1) 255)))
	 (ba (vector-ref p B))
	 (bb (vector-ref p (logand (+ B 1) 255))))

    ;; Bilinear interpolation mapped to [-1.0, 1.0]
    (- (/ (lerp (lerp aa ab u)
		(lerp ba bb u)
		v)
	  128.0)
       1.0)))

(define (perlin-noise-1d x)
  "1D noise evaluated along y = 0.5."
  (perlin-noise x 0.5))

(define (perlin-noise-3d x y z)
  "3D Value/Perlin Noise returning a normalized float in [-1.0, 1.0]."
  (let* ((fx (floor x))
	 (fy (floor y))
	 (fz (floor z))

	 (X (logand (inexact->exact (abs fx)) 255))
	 (Y (logand (inexact->exact (abs fy)) 255))
	 (Z (logand (inexact->exact (abs fz)) 255))

	 (xf (- x fx))
	 (yf (- y fy))
	 (zf (- z fz))

	 (u (fade xf))
	 (v (fade yf))
	 (w (fade zf))

	 ;; Hash X -> Y
	 (A (logand (+ (vector-ref p X) Y) 255))
	 (B (logand (+ (vector-ref p (logand (+ X 1) 255)) Y) 255))

	 ;; Hash XY -> Z
	 (AA (logand (+ (vector-ref p A) Z) 255))
	 (AB (logand (+ (vector-ref p (logand (+ A 1) 255)) Z) 255))
	 (BA (logand (+ (vector-ref p B) Z) 255))
	 (BB (logand (+ (vector-ref p (logand (+ B 1) 255)) Z) 255))

	 ;; 8 cube corners
	 (aaa (vector-ref p AA))
	 (aab (vector-ref p (logand (+ AA 1) 255)))
	 (aba (vector-ref p AB))
	 (abb (vector-ref p (logand (+ AB 1) 255)))
	 (baa (vector-ref p BA))
	 (bab (vector-ref p (logand (+ BA 1) 255)))
	 (bba (vector-ref p BB))
	 (bbb (vector-ref p (logand (+ BB 1) 255))))

    ;; Trilinear interpolation across X, Y, and Z axes mapped to [-1.0, 1.0]
    (- (/ (lerp (lerp (lerp aaa baa u)
		      (lerp aba bba u)
		      v)
		(lerp (lerp aab bab u)
		      (lerp abb bbb u)
		      v)
		w)
	  128.0)
       1.0)))

(define noise
  (case-lambda
    ((x)     (perlin-noise-1d x))
    ((x y)   (perlin-noise x y))
    ((x y z) (perlin-noise-3d x y z))))

(define (get-palette-color t)
  "Generate a cycling cyberpunk palette (cyans, magentas, deep purples)."
  (let* ((phase (* t 2.0))
	  (r (+ 0.5 (* 0.5 (cos phase))))
	  (g (+ 0.2 (* 0.2 (sin phase))))
	  (b (+ 0.5 (* 0.5 (cos (+ phase pi))))))
    (values r g b 1.0)))

(define (next-radius random-fn base-radius radius-noise spikes angle t)
  "Calculate the explicit radial distance for a single coordinate step."
  (let ((path-shredder (* 6.0 (random-fn) (cos (+ angle t))))
	(noise-factor (+ 0.1 (* 0.9 spikes))))
    (+ base-radius (* radius-noise noise-factor) path-shredder)))

(define (draw-spiral opts cfg center-x center-y max-radius t)
  "Iterates from 0 to max-angle, drawing line segments to form a generative spiral."
  (let* ((noise-fn (assoc-ref cfg 'noise-fn))
	 (random-fn (assoc-ref cfg 'random-fn))
	 (set-color (assoc-ref cfg 'set-color))
	 (draw-line (assoc-ref cfg 'draw-line))
	 (smooth-state (or (assoc-ref cfg 'smooth-noise-state) 0.0))
	 (noise-strategy (assoc-ref opts 'noise-strategy))
	 (color-scale (assoc-ref opts 'color-scale))
	 (color-speed (assoc-ref opts 'color-speed))
	 (radius-noise (assoc-ref opts 'radius-noise))
	 (angle-jitter-scale (assoc-ref opts 'angle-jitter-scale))
	 (needs-smooth-state (assoc-ref opts 'needs-smooth-state))
	 (radius-scale-fn (or (assoc-ref opts 'radius-scale-fn) (lambda (t nfn) 1)))

	 (radius-scale (radius-scale-fn t noise-fn))
	 (dynamic-max-radius (* max-radius radius-scale))
	 (total-loops 10)
	 (max-angle (* 360.0 total-loops))
	 (step-size 5)
	 (growth-rate (/ dynamic-max-radius max-angle)))
      (let loop ((angle 0)
	     (smooth (if needs-smooth-state smooth-state 0.0))
	     (base-radius 0.0)
	     (radius-noise-val radius-noise)
	     (prev-x #f)
	     (prev-y #f))
    (if (<= max-angle angle)
	smooth
	(let* ((color-phase (+ (/ angle color-scale) (* t color-speed))))
	  (receive (r g b a) (get-palette-color color-phase)
	    (set-color r g b a)
	    (receive (next-smooth spikes combined)
		(noise-strategy noise-fn random-fn t angle base-radius smooth)
	      (let* ((this-radius (next-radius random-fn base-radius radius-noise-val spikes angle t))
		     (angle-jitter (* angle-jitter-scale combined))
		     (radians (deg->rad (+ angle angle-jitter)))
		     (x (+ center-x (* this-radius (cos radians))))
		     (y (+ center-y (* this-radius (sin radians)))))
		(when prev-x
		  (draw-line x y prev-x prev-y))
		(loop (+ angle step-size)
		      next-smooth
		      (+ base-radius (* growth-rate step-size))
		      (+ radius-noise-val 0.09)
		      x
		      y)))))))))

(define (spiral-noise12 noise-fn random-fn t angle start-radius prev-smooth)
  "Noise strategy 12: Generate aggressive, heavily modulated noise profile."
  (let* ((glitch-time (+ t (* 0.2 (random-fn))))
	 (noise-angle (+ angle (* start-radius 0.5)))
	 (wave-speed (+ 3.0 (* 4.0 (noise-fn t))))
	 (moving-wave (sin (+ (* noise-angle wave-speed) (* glitch-time 10.0))))
	 (glitch-trigger (random-fn))
	 (glitch-factor (if (< 0.85 glitch-trigger)
			    (* 15.0 (random-fn))
			    0.0))
	 (noise-x (+ (* angle 0.02) glitch-factor))
	 (noise-y (* t 0.8))
	 (raw-noise (noise-fn noise-x noise-y))
	 (smooth (lerp prev-smooth raw-noise 0.05))
	 (combined (+ (* 0.4 moving-wave) (* 0.6 smooth)))
	 (dynamic-power (+ 2.0 (* 5.0 (noise-fn (* t 1.5)))))
	 (spikes (expt (abs combined) dynamic-power)))
    (values smooth spikes combined)))

(define (make-spiral options)
  "Factory returning a runner function with spiral options injected."
  (lambda (cfg center-x center-y max-radius t)
    (draw-spiral options cfg center-x center-y max-radius t)))

(define draw-noise-spiral12
  (make-spiral
   `((name . "noise-spiral12")
     (noise-strategy . ,spiral-noise12)
     (color-speed . 1.5)
     (color-scale . 45.0)
     (radius-noise . 10.0)
     (radius-scale-fn . ,(lambda (t noise-fn)
			   (+ 0.6 (* 0.4 (noise-fn (sin (* t 1.5)))))))
     (angle-jitter-scale . 1.0)
     (needs-smooth-state . #t))))

(define (raylib-draw-line x1 y1 x2 y2)
  (DrawLineEx (make-Vector2 x1 y1)
	      (make-Vector2 x2 y2)
	      2.5
	      *current-color*))

(define (raylib-set-color r g b a)
  (let ((c (make-Color (inexact->exact (round (* r 255)))
		       (inexact->exact (round (* g 255)))
		       (inexact->exact (round (* b 255)))
		       (inexact->exact (round (* a 255))))))
    (set! *current-color* c)))

(define raylib-config
  `((draw-line . ,raylib-draw-line)
    (set-color . ,raylib-set-color)
    (noise-fn . ,noise)
    (random-fn . ,(lambda () (random 1.0)))
    (smooth-noise-state . 0.0)))

(define (stateful-runner draw-fn)
  "Creates a clean state enclosure keeping smoothing state."
  (let ((state 0.0))
    (lambda (center-x center-y max-radius t)
      (set-cdr! (assoc 'smooth-noise-state raylib-config) state)
      (set! state (draw-fn raylib-config center-x center-y max-radius t)))))

(define draw-12 (stateful-runner draw-noise-spiral12))

(InitWindow screen-width screen-height "raylib noise spirals")
(SetTargetFPS 60)
(define t 0)
(define *current-color* (make-Color 255 255 255 255))

(define (main-loop)
  (unless (WindowShouldClose)
    (inc! t 1)
    (BeginDrawing)

    (ClearBackground BLACK)

    (let ((center-x (/ screen-width 2))
	  (center-y (/ screen-height 2))
	  (startradius (/ screen-width 2.5)))
      (draw-12 center-x center-y startradius t))
    (EndDrawing)
    (main-loop)))

(main-loop)
(CloseWindow)

(use-modules (raylib))

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

;;;; Perlin Noise (s7 Scheme for TIC-80)
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

(define (my-noise-spiral center-x center-y color intensity rotations)
  "Renders a perlin noise perturbed spiral."
  (let* ((start-radius 0.0)
	 (noise-scale 0.9)
	 (time-step (* t 0.12))
	 (init-last-x center-x)
	 (init-last-y center-y)
	 (max-angle (* 360 rotations)))
    (let loop ((angle 0.0)
	       (last-x init-last-x)
	       (last-y init-last-y))
      (if (<= angle max-angle)
	  (let* ((radians (deg->rad angle))
		 (cos-r (cos radians))
		 (sin-r (sin radians))
		 (spatial-scale (* noise-scale (+ 1.0 (* angle 0.002))))
		 (base-growth (* 0.06 angle))
		 (n-val (perlin-noise-3d (* cos-r spatial-scale)
					 (+ (* sin-r spatial-scale) time-step)
					 angle))
		 (noise-offset (* n-val 6.0 intensity (min 1.0 (/ angle 360.0))))
		 (this-radius (+ start-radius base-growth noise-offset))
		 (x (+ center-x (* this-radius cos-r)))
		 (y (+ center-y (* this-radius sin-r)))
		 (hue (* (modulo (round (+ (/ angle 30.0) (/ t 4.0))) 6.0) 60.0))
		 (dynamic-color (ColorFromHSV hue 0.8 1.0)))
	    (DrawLine (inexact->exact (round x))
		      (inexact->exact (round y))
		      (inexact->exact (round last-x))
		      (inexact->exact (round last-y))
		      dynamic-color)
	    (loop (+ angle 5.0) x y))))))

(InitWindow screen-width screen-height "raylib noisy-spiral")
(SetTargetFPS 60)
(define t 0)

(define (main-loop)
  (unless (WindowShouldClose)
    (inc! t 1)
    (BeginDrawing)

    (ClearBackground BLACK)
    (let* ((spiral-intensity (if (< t 30)
				 0.0
				 (let* ((active-time (- t 60))
					(sine-wave (sin (- (* active-time 0.2) 1.5708))))
				   (/ (+ sine-wave 1.0) 2.0))))
	   (growth-sine (sin (- (* t 0.015) 1.5708)))
	   (normalized-growth (/ (+ growth-sine 1.0) 2.0))
	   (current-rotations (* normalized-growth 10.0))
	   (center-x (/ screen-width 2))
	   (center-y (/ screen-height 2)))
      (my-noise-spiral center-x center-y 4 spiral-intensity current-rotations))

    (EndDrawing)
    (main-loop)))

(main-loop)
(CloseWindow)

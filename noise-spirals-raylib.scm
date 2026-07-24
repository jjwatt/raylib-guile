(use-modules (raylib))
(use-modules (srfi srfi-9))
(use-modules (srfi srfi-1))
(use-module (ice-9 receive))

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

(define (get-palette-color t)
  "Generate a cycling cyberpunk palette (cyans, magentas, deep purples)."
  (let * ((phase (* t 2.0))
	  (r (+ 0.5 (* 0.5 (cos phase))))
	  (g (+ 0.2 (* 0.2 (sin phase))))
	  (b (+ 0.5 (* 0.5 (cos (+ phase pi)))))))
  (values r g b 1.0))

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
	 (growth-rate (/ dynamic-max-radius max-angle))))
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
		      y))))))))

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
     (noise-strategy . ,sprial-noise12)
     (color-speed . 1.5)
     (color-scale . 45.0)
     (radius-noise . 10.0)
     (radius-scale-fn . ,(lambda (t noise-fn)
			   (+ 0.6 (* 0.4 (noise-fn (sin (* t 1.5)))))))
     (angle-jitter-scale . 1.0)
     (needs-smooth-state . #t))))


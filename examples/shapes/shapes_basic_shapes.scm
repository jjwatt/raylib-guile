(use-modules (raylib))

(define screen-width 800)
(define screen-height 450)

(InitWindow screen-width screen-height "raylib [shapes] example - basic shapes")
(SetTargetFPS 60)
(define rotation 0.0)

(define (main-loop)
  (unless (WindowShouldClose)
    (set! rotation (+ rotation 0.2))
    (BeginDrawing)

    (ClearBackground RAYWHITE)
    (DrawText "some basic shapes available on raylib" 20 20 20 DARKGRAY)

    ;; Circle shapes and lines
    (DrawCircle (/ screen-width 5) 120 35 DARKBLUE)
    (DrawCircleGradient (make-Vector2 (/ screen-width 5.0) 220.0) 60 GREEN SKYBLUE)
    (DrawCircleLines (/ screen-width 5) 340 80 DARKBLUE)
    (DrawEllipse (/ screen-width 5) 120 25 20 YELLOW)
    (DrawEllipseLines (/ screen-width 5) 120 30 25 YELLOW)

    ;; Rectangle shapes and lines
    (DrawRectangle (- (* 2 (/ screen-width 4)) 60) 100 120 60 RED)
    (DrawRectangleGradientH (- (* 2 (/ screen-width 4)) 90) 170 180 130 MAROON GOLD)
    (DrawRectangleLines (- (* 2 (/ screen-width 4)) 40) 320 80 60 ORANGE)

    ;; Triangle shapes and lines
    (DrawTriangle (make-Vector2 (* 3.0 (/ screen-width 4)) 80.0)
		  (make-Vector2 (- (* 3.0 (/ screen-width 4)) 60.0) 150.0)
		  (make-Vector2 (+ (* 3.0 (/ screen-width 4)) 60.0) 150.0)
		  VIOLET)
    (DrawTriangleLines (make-Vector2 (* 3.0 (/ screen-width 4)) 160.0)
		       (make-Vector2 (- (* 3.0 (/ screen-width 4)) 20.0) 230.0)
		       (make-Vector2 (+ (* 3.0 (/ screen-width 4)) 20.0) 230.0)
		       DARKBLUE)

    ;; Polygon shapes and lines
    (DrawPoly (make-Vector2 (* 3 (/ screen-width 4)) 330) 6 80 rotation BROWN)
    (DrawPolyLines (make-Vector2 (* 3 (/ screen-width 4)) 330) 6 90 rotation BROWN)
    (DrawPolyLinesEx (make-Vector2 (* 3 (/ screen-width 4)) 330) 6 85 rotation 6 BEIGE)

    (DrawLine 18 42 (- screen-width 18) 42 BLACK)
    (EndDrawing)
    (main-loop)))

(main-loop)
(CloseWindow)

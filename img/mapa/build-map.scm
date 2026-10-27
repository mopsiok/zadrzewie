; Build informational map layers over img/mapa/baza.png
; Output: mapa.xcf (layered, editable) + mapa.png (merged export)

(define (build-map)
  (let* ((img (car (gimp-file-load RUN-NONINTERACTIVE
                      "C:/git/zadrzewie/img/mapa/baza.png" "baza.png")))
         (w (car (gimp-image-width img)))
         (h (car (gimp-image-height img)))
         (baza (car (gimp-image-get-active-drawable img)))
         (FONT "DejaVu Sans Bold")
         (c-red    '(224 48 32))
         (c-white  '(255 255 255))
         (c-dark   '(38 42 46))
         (c-purple '(178 62 190))
         (c-fillA  '(232 130 58))
         (c-fillB  '(240 196 60))
         (c-textA  '(74 38 10))
         (c-textB  '(96 74 10))
         (c-nred   '(198 40 40))
         (gr-l #f) (pd-l #f))

    (gimp-item-set-name baza "baza")

    ;; ---------- helpers ----------
    (define (new-layer name)
      (let ((l (car (gimp-layer-new img w h RGBA-IMAGE name 100 LAYER-MODE-NORMAL))))
        (gimp-image-insert-layer img l 0 0)
        l))

    (define (fill-ellipse layer cx cy r color opacity)
      (gimp-image-select-ellipse img CHANNEL-OP-REPLACE (- cx r) (- cy r) (* 2 r) (* 2 r))
      (gimp-context-set-foreground color)
      (gimp-context-set-opacity opacity)
      (gimp-drawable-edit-fill layer FILL-FOREGROUND)
      (gimp-selection-none img))

    (define (fill-rect layer x y rw rh color opacity)
      (gimp-image-select-rectangle img CHANNEL-OP-REPLACE x y rw rh)
      (gimp-context-set-foreground color)
      (gimp-context-set-opacity opacity)
      (gimp-drawable-edit-fill layer FILL-FOREGROUND)
      (gimp-selection-none img))

    (define (fill-poly layer pts color opacity)
      (gimp-image-select-polygon img CHANNEL-OP-REPLACE (length pts) (list->vector pts))
      (gimp-context-set-foreground color)
      (gimp-context-set-opacity opacity)
      (gimp-drawable-edit-fill layer FILL-FOREGROUND)
      (gimp-selection-none img))

    (define (line-x layer x1 y1 x2 y2 width color opacity)
      (let* ((dx (- x2 x1)) (dy (- y2 y1))
             (len (max 0.001 (sqrt (+ (* dx dx) (* dy dy)))))
             (hw (/ width 2.0))
             (ux (/ dx len)) (uy (/ dy len))
             (nx (* hw (- uy))) (ny (* hw ux)))
        (fill-poly layer
                   (list (+ x1 nx) (+ y1 ny) (+ x2 nx) (+ y2 ny)
                         (- x2 nx) (- y2 ny) (- x1 nx) (- y1 ny))
                   color opacity)))

    ;; one wrapped label (halo below, main text above), both merged into `layer`.
    ;; returns the merged layer id - callers must rebind!
    (define (label-into layer txt cx cy size color halo-color)
      (let* ((ext (gimp-text-get-extents-fontname txt size PIXELS FONT))
             (tw (car ext)) (th (cadr ext))
             (x0 (- cx (/ tw 2.0))) (y0 (- cy (/ th 2.0))))
        (gimp-context-set-foreground halo-color)
        (let ((halo (car (gimp-text-fontname img -1 (+ x0 1.0) (+ y0 1.0) txt 0 TRUE size PIXELS FONT))))
          (display "CHK halo=")(display halo)(display "\n")
          (gimp-image-merge-down img halo EXPAND-AS-NECESSARY))
        (gimp-context-set-foreground color)
        (let* ((main (car (gimp-text-fontname img -1 x0 y0 txt 0 TRUE size PIXELS FONT)))
               (merged (car (gimp-image-merge-down img main EXPAND-AS-NECESSARY))))
          merged)))

    ;; ---------- granica działki (red outline + vertex dots) ----------
    (set! gr-l (new-layer "granica działki"))
    (line-x gr-l 421 85 788 345 3 c-red 100)
    (line-x gr-l 788 345 575 669 3 c-red 100)
    (line-x gr-l 575 669 168 381 3 c-red 100)
    (line-x gr-l 168 381 421 85 3 c-red 100)
    (for-each
      (lambda (v)
        (fill-ellipse gr-l (car v) (cadr v) 8 c-white 100)
        (fill-ellipse gr-l (car v) (cadr v) 5 c-red 100))
      '((421.4 85.3) (787.5 345.0) (575.4 668.8) (167.6 380.8)))

    ;; ---------- podział A/B (purple divider) ----------
    (set! pd-l (new-layer "podział A/B"))
    (line-x pd-l 294.5 233.1 681.5 506.9 5 c-purple 100)

    ;; ---------- strefa A - część społeczna ----------
    (let ((za #f))
      (set! za (new-layer "strefa A - część społeczna"))
      (fill-poly za '(294.5 233.1 168 381 575 669 681.5 506.9) c-fillA 45)
      (set! za (label-into za "część społeczna" 429.7 447.4 16 c-textA c-white)))

    ;; ---------- strefa B - część ogrodnicza ----------
    (let ((zb #f))
      (set! zb (new-layer "strefa B - część ogrodnicza"))
      (fill-poly zb '(294.5 233.1 421 85 788 345 681.5 506.9) c-fillB 38)
      (set! zb (label-into zb "część ogrodnicza" 546.2 292.6 16 c-textB c-white)))

    ;; ---------- wymiary (4 white dimension lines + labels) ----------
    (let ((wm #f))
      (set! wm (new-layer "wymiary"))
      ;; front (119 m)
      (line-x wm 410.8 76.2 157.0 371.7 2 c-white 100)
      (line-x wm 415.0 71.2 406.5 81.1 2 c-white 100)
      (line-x wm 161.2 366.7 152.7 376.6 2 c-white 100)
      (set! wm (label-into wm "119 m" 274.0 215.5 13 c-white c-dark))
      ;; NE (137 m)
      (line-x wm 429.5 73.9 795.6 333.6 2 c-white 100)
      (line-x wm 424.2 70.1 434.8 77.6 2 c-white 100)
      (line-x wm 790.3 329.8 800.9 337.3 2 c-white 100)
      (set! wm (label-into wm "137 m" 620.1 193.1 13 c-white c-dark))
      ;; back (118 m)
      (line-x wm 799.2 352.7 587.1 676.5 2 c-white 100)
      (line-x wm 802.8 347.2 795.6 358.1 2 c-white 100)
      (line-x wm 590.7 671.0 583.5 681.9 2 c-white 100)
      (set! wm (label-into wm "118 m" 704.0 521.7 13 c-white c-dark))
      ;; SW (152 m)
      (line-x wm 567.3 680.2 159.5 392.2 2 c-white 100)
      (line-x wm 572.6 684.0 562.0 676.5 2 c-white 100)
      (line-x wm 164.8 396.0 154.2 388.5 2 c-white 100)
      (set! wm (label-into wm "152 m" 355.9 546.9 13 c-white c-dark)))

    ;; ---------- róża wiatrów (compass, bottom-left) ----------
    (let ((rz #f))
      (set! rz (new-layer "róża wiatrów"))
      (fill-ellipse rz 91 679 46 c-dark 30)          ; shadow
      (fill-ellipse rz 88 675 47 c-dark 100)         ; outer ring
      (fill-ellipse rz 88 675 44 c-white 100)        ; face
      (fill-poly rz '(80 676 96 676 88 714) '(90 94 98) 100) ; south tail
      (fill-poly rz '(80 676 96 676 88 638) c-nred 100)      ; north needle
      (fill-ellipse rz 88.5 675.5 3.5 c-dark 100)    ; pivot
      (fill-rect rz 72 599 32 25 c-dark 100)         ; N badge
      (fill-rect rz 74 601 28 21 c-white 100)
      (set! rz (label-into rz "N" 88 611.5 14 c-dark c-white)))

    ;; put red outline & purple divider on top of the stack
    (gimp-image-raise-item-to-top img pd-l)
    (gimp-image-raise-item-to-top img gr-l)

    ;; ---------- save outputs ----------
    (gimp-image-set-active-layer img baza)
    (gimp-xcf-save RUN-NONINTERACTIVE img (car (gimp-image-get-active-drawable img))
                   "C:/git/zadrzewie/img/mapa/mapa.xcf" "mapa.xcf")
    (let* ((dup (car (gimp-image-duplicate img))))
      (gimp-image-flatten dup)
      (file-png-save RUN-NONINTERACTIVE dup
                     (car (gimp-image-get-active-drawable dup))
                     "C:/git/zadrzewie/img/mapa/mapa.png" "mapa.png"
                     0 9 1 1 1 1 1)
      (gimp-image-delete dup))))

(build-map)
(gimp-quit 0)

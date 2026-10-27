; Build informational map layers over img/mapa/baza.png
; Output: mapa.xcf (layered, editable) + mapa.png (merged export)

(define (build-map)
  (let* ((img (car (gimp-file-load RUN-NONINTERACTIVE
                      "C:/git/zadrzewie/img/mapa/baza.png" "baza.png")))
         (w (car (gimp-image-width img)))
         (h (car (gimp-image-height img)))
         (baza (car (gimp-image-get-active-drawable img)))
         (FONT "DejaVu Sans Bold")
         ;; plot geometry (px from top-left of baza.png) per user's survey
         ;; a = top-left, b = top-right, c = bottom-right, d = bottom-left
         (c-white  '(255 255 255))
         (c-dark   '(38 42 46))
         (c-purple '(178 62 190))
         (c-zoneA  '(85 170 69))     ; #55aa45 - część społeczna
         (c-zoneB  '(240 196 60))
         (c-textA  '(35 74 30))
         (c-textB  '(96 74 10))
         (c-nred-l '(196 118 108))
         (c-nred-d '(138 72 62))
         (c-needle-l '(78 82 90))
         (c-needle-d '(22 24 28))
         (c-ntxt   '(230 230 230))
         (gr-l #f))

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

    ;; merged label (halo below, main above) - returns merged layer id
    (define (label-into layer txt cx cy size color halo-color)
      (let* ((ext (gimp-text-get-extents-fontname txt size PIXELS FONT))
             (tw (car ext)) (th (cadr ext))
             (x0 (- cx (/ tw 2.0))) (y0 (- cy (/ th 2.0))))
        (gimp-context-set-foreground halo-color)
        (let ((halo (car (gimp-text-fontname img -1 (+ x0 1.0) (+ y0 1.0) txt 0 TRUE size PIXELS FONT))))
          (gimp-image-merge-down img halo EXPAND-AS-NECESSARY))
        (gimp-context-set-foreground color)
        (let* ((main (car (gimp-text-fontname img -1 x0 y0 txt 0 TRUE size PIXELS FONT)))
               (merged (car (gimp-image-merge-down img main EXPAND-AS-NECESSARY))))
          merged)))

    ;; dimension caption as two live text layers (editable):
    ;; x-position (cx cy) = text center on canvas, value = caption text
    (define (dim-text name cx cy value)
      (let* ((ext (gimp-text-get-extents-fontname value 17 PIXELS FONT))
             (x0 (- cx (/ (car ext) 2.0))) (y0 (- cy (/ (cadr ext) 2.0))))
        (gimp-context-set-foreground c-dark)
        (let ((sha (car (gimp-text-fontname img -1 (+ x0 1.0) (+ y0 1.0) value 0 TRUE 17 PIXELS FONT))))
          (gimp-item-set-name sha (string-append name " - cień")))
        (gimp-context-set-foreground c-white)
        (let ((main (car (gimp-text-fontname img -1 x0 y0 value 0 TRUE 17 PIXELS FONT))))
          (gimp-item-set-name main (string-append name ": " value)))))

    ;; ---------- krawędzie działek (biała linia + białe punkty) ----------
    (set! gr-l (new-layer "granica działki"))
    (line-x gr-l 402 71 782 341 2 c-white 100)   ; a-b
    (line-x gr-l 782 341 571 666 2 c-white 100)  ; b-c
    (line-x gr-l 571 666 180 389 2 c-white 100)  ; c-d
    (line-x gr-l 180 389 402 71 2 c-white 100)   ; d-a
    (for-each
      (lambda (v) (fill-ellipse gr-l (car v) (cadr v) 4 c-white 100))
      '((402 71) (782 341) (571 666) (180 389)))

    ;; ---------- strefa A - część społeczna ----------
    (let ((za #f))
      (set! za (new-layer "strefa A - część społeczna"))
      (fill-poly za '(291 230 180 389 571 666 678.5 505) c-zoneA 31)
      (set! za (label-into za "strefa społeczna" 429.7 447.4 25 c-textA c-white)))

    ;; ---------- strefa B - część ogrodnicza ----------
    (let ((zb #f))
      (set! zb (new-layer "strefa B - część ogrodnicza"))
      (fill-poly zb '(291 230 402 71 782 341 678.5 505) c-zoneB 27)
      (set! zb (label-into zb "strefa ogrodnicza" 546.2 292.6 25 c-textB c-white)))

    ;; ---------- wymiary (4 osobne warstwy tekstowe + cienie) ----------
    (dim-text "wymiar d-a" 253.0 201.0 "25,6 m")
    (dim-text "wymiar a-b" 620.1 193.1 "30,8 m")
    (dim-text "wymiar b-c" 704.0 521.7 "25,4 m")
    (dim-text "wymiar c-d" 355.9 546.9 "31,8 m")

    ;; ---------- róża wiatrów (bottom-left, x1.25 wzgl. poprzedniej) ----------
    (let ((rz #f))
      (set! rz (new-layer "róża wiatrów"))
      (fill-ellipse rz 93 681 72 c-dark 20)          ; miękki cień
      ;; tarcza + plakietka N jako jedna półprzezroczysta sylwetka (bez szwu)
      (gimp-image-select-rectangle img CHANNEL-OP-REPLACE 63 572 50 39)
      (gimp-image-select-ellipse img CHANNEL-OP-ADD 14 601 148 148)
      (gimp-context-set-foreground c-dark)
      (gimp-context-set-opacity 50)
      (gimp-drawable-edit-fill rz FILL-FOREGROUND)
      (gimp-selection-none img)
      ;; delikatna obwódka: pierścień 2 px wokół sylwetki (lekko jaśniejszy od tła)
      (gimp-image-select-rectangle img CHANNEL-OP-REPLACE 61 570 54 43)
      (gimp-image-select-ellipse img CHANNEL-OP-ADD 12 599 152 152)
      (gimp-image-select-rectangle img CHANNEL-OP-SUBTRACT 63 572 50 39)
      (gimp-image-select-ellipse img CHANNEL-OP-SUBTRACT 14 601 148 148)
      (gimp-context-set-foreground c-white)
      (gimp-context-set-opacity 12)
      (gimp-drawable-edit-fill rz FILL-FOREGROUND)
      (gimp-selection-none img)
      ;; igły: każda podzielona wzdłuż na jaśniejszą i ciemniejszą połowę
      (fill-poly rz '(76 676 88 676 88 615) c-nred-l 100)    ; N: zachodnia jasna
      (fill-poly rz '(88 676 100 676 88 615) c-nred-d 100)   ; N: wschodnia ciemna
      (fill-poly rz '(88 663 88 675 154 675) c-needle-l 100) ; E: północna jasna
      (fill-poly rz '(88 675 88 687 154 675) c-needle-d 100) ; E: południowa ciemna
      (fill-poly rz '(88 676 100 676 88 735) c-needle-l 100) ; S: wschodnia jasna
      (fill-poly rz '(76 676 88 676 88 735) c-needle-d 100)  ; S: zachodnia ciemna
      (fill-poly rz '(88 675 88 687 22 675) c-needle-l 100)  ; W: południowa jasna
      (fill-poly rz '(88 663 88 675 22 675) c-needle-d 100)  ; W: północna ciemna
      (fill-ellipse rz 88 675 5.5 '(20 22 25) 100)   ; oś
      (let* ((ext (gimp-text-get-extents-fontname "N" 21 PIXELS FONT))
             (x0 (- 88 (/ (car ext) 2.0))) (y0 (- 591.5 (/ (cadr ext) 2.0))))
        (gimp-context-set-foreground c-ntxt)
        (let ((nt (car (gimp-text-fontname img -1 x0 y0 "N" 0 TRUE 21 PIXELS FONT))))
          (set! rz (car (gimp-image-merge-down img nt EXPAND-AS-NECESSARY))))))

    ;;linia działek na wierzchu stosu
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


(mapclass Almacenamiento)
(mapclass Fuente)
(mapclass PlacaBase)
(mapclass Procesador)
(mapclass Ram)
(mapclass TarjetaGrafica)
(mapclass Equipo)
(mapclass Marca)
(mapclass Usuario)

(defrule MAIN::r-init-pc 
   (initial-fact) 
   (not (equipo)) 
   => 
   (printout t "equipo" crlf) 
   (assert (MAIN::equipo hayequipo)) 
   (assert (MAIN::placa no)) 
   (assert (MAIN::completo no)) 
   (assert (MAIN::pres no)) 
   (make-instance of Equipo))


(defrule MAIN::r-min-cpu-dise-game 
   ?eq <- (object (is-a Equipo) (precio_total ?precio) (cpu nil)) 
   (and ?us <- (object (is-a Usuario) (tipo_usuario ?tipo)) 
        (test (or (eq ?tipo disenador) (eq ?tipo gamer)))) 
   (and ?cpu <- (object (is-a Procesador) (precio ?precioCPU) (cores ?cores)) 
        (test (> ?cores 3))) 
   => 
   (slot-set ?eq cpu ?cpu) 
   (slot-set ?eq precio_total (+ ?precio ?precioCPU)) 
   (assert (MAIN::socket (slot-get ?cpu conexion_socket))))

(defrule MAIN::r-sobra-pres 
   (completo si) 
   (pres no) 
   ?eq <- (object (is-a Equipo) (precio_total ?precio)) 
   (and ?us <- (object (is-a Usuario) (presupuesto ?pres)) 
        (test (> ?pres ?precio))) 
   => 
   (assert (MAIN::pres sobra)))

(defrule MAIN::r-falta-pres 
   (completo si) 
   (pres no) 
   ?eq <- (object (is-a Equipo) (precio_total ?precio)) 
   (and ?us <- (object (is-a Usuario) (presupuesto ?pres)) 
        (test (< ?pres ?precio))) 
   => 
   (assert (MAIN::pres falta)))

(defrule MAIN::r-bajar-fuente 
   ?h1 <- (pres falta) 
   ?eq <- (object (is-a Equipo) (fuente ?f) (precio_total ?precio)) 
   (and ?fuente <- (object (is-a Fuente) (precio ?precioF)) 
        (test (< ?precioF (slot-get ?f precio)))) 
   => 
   (retract ?h1) 
   (assert (MAIN::pres no)) 
   (slot-set ?eq fuente ?fuente) 
   (slot-set ?eq precio_total (- ?precio (- (slot-get ?f precio) ?precioF))))

(defrule MAIN::r-bajar-gpu 
   ?h1 <- (pres falta) 
   (and ?us <- (object (is-a Usuario) (tipo_usuario ?tipo)) 
        (test (or (eq ?tipo disenador) (eq ?tipo multimedia)))) 
   ?eq <- (object (is-a Equipo) (gpu ?g) (placa ?p) (precio_total ?precio)) 
   (and ?gpu <- (object (is-a TarjetaGrafica) (precio ?precioGPU) (conexion_grafica ?c)) 
        (test (< ?precioGPU (slot-get ?g precio))) 
        (test (eq ?c (slot-get ?p conexion_grafica)))) 
   => 
   (retract ?h1) 
   (assert (MAIN::pres no)) 
   (slot-set ?eq gpu ?gpu) 
   (slot-set ?eq precio_total (- ?precio (- (slot-get ?g precio) ?precioGPU))))

(defrule MAIN::r-min-resto-dise 
   ?us <- (object (is-a Usuario) (tipo_usuario disenador)) 
   (and ?eq <- (object (is-a Equipo) (cpu ?cpu) (fuente nil) (precio_total ?precio)) 
        (test (neq ?cpu nil))) 
   ?fuente <- (object (is-a Fuente) (precio ?precioF)) 
   ?gpu <- (object (is-a TarjetaGrafica) (precio ?precioGPU) (conexion_grafica ?c_gpu)) 
   ?hdd <- (object (is-a Almacenamiento) (precio ?precioHDD) (conexion_hdd ?c_hdd)) 
   ?placa <- (object (is-a PlacaBase) (precio ?precioPB) (conexion_hdd ?c_hddp) (conexion_socket ?sock) (conexion_grafica ?c_gpup)) 
   (and (socket ?sock) 
        (test (eq ?c_gpu ?c_gpup)) 
        (test (eq ?c_hdd ?c_hddp))) 
   => 
   (printout t "resto" crlf) 
   (slot-set ?eq fuente ?fuente) 
   (slot-set ?eq gpu ?gpu) 
   (slot-set ?eq hdd ?hdd) 
   (slot-set ?eq placa ?placa) 
   (slot-set ?eq precio_total (+ ?precio ?precioF ?precioGPU ?precioHDD ?precioPB)) 
   (slot-set ?eq slots_usados 0) 
   (slot-set ?eq slots_libres (slot-get ?placa slots)) 
   (assert (MAIN::placa si)))

(defrule MAIN::r-min-ram-dise 
   (placa si) 
   ?us <- (object (is-a Usuario) (tipo_usuario disenador)) 
   ?eq <- (object (is-a Equipo) (mem ?mem) (slots_usados ?usados) (placa ?p) (ram nil) (slots_libres ?libres) (precio_total ?precio)) 
   (and ?ram <- (object (is-a Ram) (precio ?precioR) (conexion_ram ?c) (dram ?memr)) 
        (test (> (* ?memr ?libres) 12)) 
        (test (eq ?c (slot-get ?p conexion_ram)))) 
   => 
   (printout t "min ram" crlf) 
   (slot-set ?eq slots_usados ?libres) 
   (slot-set ?eq ram ?ram) 
   (slot-set ?eq precio_total (+ ?precio (* ?precioR ?libres))) 
   (slot-set ?eq mem (* ?memr ?libres)) 
   (slot-set ?eq slots_libres 0) 
   (assert (MAIN::completo si)))

(defrule MAIN::r-opt-ram 
   ?h1 <- (pres sobra) 
   ?us <- (object (is-a Usuario) (tipo_usuario disenador) (presupuesto ?pres)) 
   ?eq <- (object (is-a Equipo) (mem ?mem) (slots_usados ?usados) (placa ?p) (ram ?r) (slots_libres ?libres) (precio_total ?precio)) 
   (and ?ram <- (object (is-a Ram) (precio ?precioR) (conexion_ram ?c) (dram ?memr)) 
        (test (> (* ?memr ?usados) ?mem)) 
        (test (eq ?c (slot-get ?p conexion_ram))) 
        (test (<= (+ (- ?precio (* (slot-get ?r precio) ?usados)) (* ?usados ?precioR)) ?pres))) 
   => 
   (retract ?h1) 
   (assert (MAIN::pres no)) 
   (slot-set ?eq ram ?ram) 
   (slot-set ?eq precio_total (+ (- ?precio (* (slot-get ?r precio) ?usados)) (* ?precioR ?usados))) 
   (slot-set ?eq mem (* ?memr ?usados)))

(defrule MAIN::r-min-resto-gamer 
   ?us <- (object (is-a Usuario) (tipo_usuario gamer)) 
   (and ?eq <- (object (is-a Equipo) (cpu ?cpu) (fuente nil) (precio_total ?precio)) 
        (test (neq ?cpu nil))) 
   ?fuente <- (object (is-a Fuente) (precio ?precioF)) 
   ?hdd <- (object (is-a Almacenamiento) (precio ?precioHDD) (conexion_hdd ?c_hdd)) 
   ?placa <- (object (is-a PlacaBase) (precio ?precioPB) (conexion_hdd ?c_hddp) (conexion_grafica ?c_gpup) (conexion_socket ?sock)) 
   (and (socket ?sock) 
        (test (eq ?c_hdd ?c_hddp))) 
   => 
   (printout t "resto" crlf) 
   (slot-set ?eq fuente ?fuente) 
   (slot-set ?eq hdd ?hdd) 
   (slot-set ?eq placa ?placa) 
   (slot-set ?eq precio_total (+ ?precio ?precioF ?precioHDD ?precioPB)) 
   (slot-set ?eq slots_usados 0) 
   (slot-set ?eq slots_libres (slot-get ?placa slots)) 
   (assert (MAIN::placa si)))

(defrule MAIN::r-min-ram-gamer 
   (placa si) 
   ?us <- (object (is-a Usuario) (tipo_usuario gamer)) 
   ?eq <- (object (is-a Equipo) (mem ?mem) (slots_usados ?usados) (placa ?p) (ram nil) (slots_libres ?libres) (precio_total ?precio)) 
   (and ?ram <- (object (is-a Ram) (precio ?precioR) (conexion_ram ?c) (dram ?memr)) 
        (test (> (* ?memr ?libres) 7)) 
        (test (eq ?c (slot-get ?p conexion_ram)))) 
   => 
   (printout t "min ram" crlf) 
   (slot-set ?eq slots_usados ?libres) 
   (slot-set ?eq ram ?ram) 
   (slot-set ?eq precio_total (+ ?precio (* ?precioR ?libres))) 
   (slot-set ?eq mem (* ?memr ?libres)) 
   (slot-set ?eq slots_libres 0) 
   (assert (MAIN::completo si)))

(defrule MAIN::r-min-gpu 
   (placa si) 
   ?us <- (object (is-a Usuario) (tipo_usuario gamer)) 
   ?eq <- (object (is-a Equipo) (gpu nil) (placa ?p) (slots_libres 0) (precio_total ?precio)) 
   (and ?gpu <- (object (is-a TarjetaGrafica) (precio ?precioGPU) (conexion_grafica ?c) (vram ?ram)) 
        (test (>= ?ram 2)) 
        (test (eq ?c (slot-get ?p conexion_grafica)))) 
   => 
   (slot-set ?eq gpu ?gpu) 
   (slot-set ?eq precio_total (+ ?precio ?precioGPU)))

(defrule MAIN::r-bajar-hdd 
   ?h1 <- (pres falta) 
   (and ?us <- (object (is-a Usuario) (tipo_usuario ?tipo)) 
        (test (or (eq ?tipo gamer) (eq ?tipo multimedia)))) 
   ?eq <- (object (is-a Equipo) (placa ?p) (hdd ?h) (precio_total ?precio)) 
   (and ?hdd <- (object (is-a Almacenamiento) (precio ?precioHDD) (conexion_hdd ?c)) 
        (test (< ?precioHDD (slot-get ?h precio))) 
        (test (eq ?c (slot-get ?p conexion_hdd)))) 
   => 
   (retract ?h1) 
   (assert (MAIN::pres no)) 
   (slot-set ?eq hdd ?hdd) 
   (slot-set ?eq precio_total (- ?precio (- (slot-get ?h precio) ?precioHDD))))

(defrule MAIN::r-opt-gpu 
   ?h1 <- (pres sobra) 
   ?us <- (object (is-a Usuario) (tipo_usuario gamer) (presupuesto ?pres)) 
   ?eq <- (object (is-a Equipo) (gpu ?g) (precio_total ?precio)) 
   (object (OBJECT ?g) (precio ?precioG2) (conexion_grafica ?c2)) 
   (and ?gpu <- (object (is-a TarjetaGrafica) (precio ?precioGPU) (conexion_grafica ?c) (vram ?vram)) 
        (test (>= ?vram 2)) 
        (test (eq ?c ?c2)) 
        (test (> ?precioGPU ?precioG2)) 
        (test (<= (+ ?precio (- ?precioGPU ?precioG2)) ?pres))) 
   => 
   (retract ?h1) 
   (assert (MAIN::pres no)) 
   (slot-set ?eq precio_total (+ ?precio (- ?precioGPU ?precioG2))) 
   (slot-set ?eq gpu ?gpu))

(defrule MAIN::r-min-resto-multi 
   ?us <- (object (is-a Usuario) (tipo_usuario multimedia)) 
   ?eq <- (object (is-a Equipo) (cpu nil) (fuente nil) (precio_total ?precio)) 
   ?cpu <- (object (is-a Procesador) (precio ?precioCPU) (conexion_socket ?sock)) 
   ?fuente <- (object (is-a Fuente) (precio ?precioF)) 
   ?gpu <- (object (is-a TarjetaGrafica) (precio ?precioGPU) (conexion_grafica ?c_gpu)) 
   ?hdd <- (object (is-a Almacenamiento) (precio ?precioHDD) (conexion_hdd ?c_hdd)) 
   ?placa <- (object (is-a PlacaBase) (precio ?precioPB) (conexion_hdd ?c_hdd) (conexion_socket ?sock) (conexion_ram ?c_ram) (conexion_grafica ?c_gpu)) 
   ?ram <- (object (is-a Ram) (precio ?precioR) (conexion_ram ?c_ram) (dram ?memr)) 
   => 
   (printout t "resto" crlf) 
   (slot-set ?eq fuente ?fuente) 
   (slot-set ?eq gpu ?gpu) 
   (slot-set ?eq hdd ?hdd) 
   (slot-set ?eq placa ?placa) 
   (slot-set ?eq cpu ?cpu) 
   (slot-set ?eq ram ?ram) 
   (slot-set ?eq precio_total (+ ?precio ?precioCPU ?precioF ?precioGPU ?precioHDD ?precioPB (* (slot-get ?placa slots) ?precioR))) 
   (slot-set ?eq slots_usados (slot-get ?placa slots)) 
   (slot-set ?eq slots_libres 0) 
   (slot-set ?eq mem (* (slot-get ?placa slots) ?memr)) 
   (assert (MAIN::completo si)))

(defrule MAIN::r-bajar-ram 
   ?h1 <- (pres falta) 
   ?us <- (object (is-a Usuario) (tipo_usuario multimedia)) 
   (and ?eq <- (object (is-a Equipo) (mem ?mem) (slots_usados ?usados) (ram ?ram) (slots_libres ?libres) (precio_total ?precio)) 
        (test (> ?usados 1))) 
   => 
   (printout t "bajar-ram" crlf) 
   (retract ?h1) 
   (assert (MAIN::pres no)) 
   (slot-set ?eq slots_usados (- ?usados 1)) 
   (slot-set ?eq slots_libres (+ ?libres 1)) 
   (slot-set ?eq mem (- ?mem (slot-get ?ram dram))) 
   (slot-set ?eq precio_total (- ?precio (slot-get ?ram precio))))

(defrule MAIN::r-bajar-tipo-ram 
   ?h1 <- (pres falta) 
   ?us <- (object (is-a Usuario) (tipo_usuario multimedia)) 
   (and ?eq <- (object (is-a Equipo) (mem ?mem) (slots_usados ?usados) (placa ?p) (ram ?ram) (slots_libres ?libres) (precio_total ?precio)) 
        (test (eq ?usados 1))) 
   (and ?r <- (object (is-a Ram) (precio ?precioR) (conexion_ram ?c) (dram ?memr)) 
        (test (eq ?c (slot-get ?p conexion_ram))) 
        (test (< ?precioR (slot-get ?ram precio)))) 
   => 
   (printout t "bajar-ram" crlf) 
   (retract ?h1) 
   (assert (MAIN::pres no)) 
   (slot-set ?eq mem ?memr) 
   (slot-set ?eq ram ?r) 
   (slot-set ?eq precio_total (- ?precio (- (slot-get ?ram precio) ?precioR))))

(defrule MAIN::r-opt-hdd 
   ?h1 <- (pres sobra) 
   (and ?us <- (object (is-a Usuario) (tipo_usuario ?user) (presupuesto ?pres)) 
        (test (or (eq ?user disenador) (eq ?user multimedia)))) 
   ?eq <- (object (is-a Equipo) (precio_total ?precio) (hdd ?h)) 
   (object (OBJECT ?h) (precio ?precioHDD2) (conexion_hdd ?c2)) 
   (and ?hdd <- (object (is-a Almacenamiento) (precio ?precioHDD) (conexion_hdd ?c) (tipo_almacenamiento ?tipo)) 
        (test (neq ?h ?hdd)) 
        (test (eq ?tipo SSD)) 
        (test (eq ?c2 ?c)) 
        (test (> ?precioHDD ?precioHDD2)) 
        (test (<= (+ ?precio (- ?precioHDD ?precioHDD2)) ?pres))) 
   => 
   (printout t "opt hdd" crlf) 
   (retract ?h1) 
   (assert (MAIN::pres no)) 
   (slot-set ?eq precio_total (+ ?precio (- ?precioHDD ?precioHDD2))) 
   (slot-set ?eq hdd ?hdd))

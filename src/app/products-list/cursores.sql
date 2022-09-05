INTENTO NUMERO 1:

DROP PROCEDURE IF EXISTS sp_obtener_prefacturas_no_facturadas;

DELIMITER $$
CREATE PROCEDURE sp_obtener_prefacturas_no_facturadas(IN filtros VARCHAR(700))
BEGIN
	# Tabla que retorna
    CREATE TEMPORARY TABLE resultados(liq_tipo VARCHAR(50), fecha_confirmacion DATE, prefactura_id INT(11), empleador_cuit VARCHAR(13), empleador_nombre VARCHAR(150), prefactura_estado VARCHAR(60), prefactura_fecha DATE, prefactura_anio INT(11), prefactura_mes INT(11), prefactura_subtotal DECIMAL(10,2), prefactura_iva DECIMAL(10,2), prefactura_total DECIMAL(10,2), usuario_nombre VARCHAR(30), def_emp_nombre VARCHAR(500), def_emp_solicita_hes VARCHAR(2), facturadora_nombre VARCHAR(500), nombre_comercial VARCHAR(100));

BLOQUE_PRINCIPAL: BEGIN
	# Declaro los finales de cada cursor.
	DECLARE fin_liquidaciones INTEGER DEFAULT 0;
    DECLARE fin_prefactura_principal INTEGER DEFAULT 0;
    DECLARE fin_prefactura_secundaria INTEGER DEFAULT 0;
    DECLARE fin_prefactura_terciaria INTEGER DEFAULT 0;
    # Variable auxiliar para saber si cargo una prefactura o no
    DECLARE cargo_prefactura INTEGER DEFAULT 1;
    # Query liquidaciones.
	DECLARE cursor_liquidaciones CURSOR FOR SELECT Liquidacion.tipo, Liquidacion.prefactura_id, CambioDetalle.fecha_confirmacion FROM liquidaciones Liquidacion JOIN cambio_detalles CambioDetalle ON Liquidacion.cambio_detalle_id = CambioDetalle.id WHERE filtros;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin_liquidaciones = 1;
    
    OPEN cursor_liquidaciones;
 	BLOCK1: BEGIN
    	CREATE TEMPORARY TABLE var_liquidaciones(liq_tipo VARCHAR(50), prefactura_id INT(11), fecha_confirmacion datetime);
    	SET fin_liquidaciones = 0;
        liquidaciones:
        LOOP
            FETCH cursor_liquidaciones INTO var_liquidaciones;
            IF fin_liquidaciones = 1 THEN 
                LEAVE liquidaciones;
            END IF;
            SET cargo_prefactura = 1;
            BLOCK2: BEGIN
            # Traemos la prefactura asociada a la liquidacion.
                DECLARE cursor_prefactura_principal CURSOR FOR SELECT Prefactura.id, Empleador.cuit, Empleador.nombre, Prefactura.estado, Prefactura.fecha, Prefactura.anio, Prefactura.mes, 							Prefactura.subtotal, Prefactura.iva, Prefactura.total, Usuario.nombre, DefinicionEmpleador.nombre, DefinicionEmpleador.solicita_hes, Facturadora.nombre, (SELECT 
                    COALESCE((SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Principal' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Secundario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Terciario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Ninguna' AND u.estado != 'Bloqueado'), '-')) AS nombre_comercial FROM prefacturas Prefactura JOIN empleadores Empleador ON Prefactura.empleador_id = Empleador.id JOIN definicion_empleadores DefinicionEmpleador ON Prefactura.definicion_empleador_id = DefinicionEmpleador.id JOIN facturadoras Facturadora ON Prefactura.facturadora_id = Facturadora.id WHERE Prefactura.id = var_liquidaciones.prefactura_id LIMIT 1;

				# Variables para la prefactura principal
                DROP TABLE IF EXISTS var_prefactura_principal;
                CREATE TEMPORARY TABLE var_prefactura_principal(prefactura_id INT(11), empleador_cuit VARCHAR(13), empleador_nombre VARCHAR(150), prefactura_estado VARCHAR(60), prefactura_fecha DATE, prefactura_anio INT(11), prefactura_mes INT(11), prefactura_subtotal DECIMAL(10,2), prefactura_iva DECIMAL(10,2), prefactura_total DECIMAL(10,2), usuario_nombre VARCHAR(30), def_emp_nombre VARCHAR(500), def_emp_solicita_hes VARCHAR(2), facturadora_nombre VARCHAR(500), nombre_comercial VARCHAR(100));
                SET fin_prefactura_principal = 0;
                DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin_prefactura_principal = 1;
                OPEN cursor_prefactura_principal;
                
                pre_principal:
                LOOP
                	FETCH cursor_prefactura_principal INTO var_prefactura_principal;
                    IF fin_prefactura_principal = 1 THEN
                    	LEAVE pre_principal;
                    END IF;
                    IF(var_prefactura_principal.reemplazada_por != NULL, 
                     #Guardo porque fue reemplazada, es la definitiva
                     SET cargo_prefactura = 0;                      
                     INSERT INTO resultados(var_liquidaciones.liq_tipo , var_liquidaciones.fecha_confirmacion , var_liquidaciones.prefactura_id , var_prefactura_principal.empleador_cuit , var_prefactura_principal.empleador_nombre, var_prefactura_principal.prefactura_estado, var_prefactura_principal.prefactura_fecha, var_prefactura_principal.prefactura_anio, var_prefactura_principal.prefactura_mes, var_prefactura_principal.prefactura_subtotal, var_prefactura_principal.prefactura_iva, var_prefactura_principal.prefactura_total, var_prefactura_principal.usuario_nombre, var_prefactura_principal.def_emp_nombre, var_prefactura_principal.def_emp_solicita_hes, var_prefactura_principal.facturadora_nombre, var_prefactura_principal.nombre_comercial);
                       , # Veo si fue agrupada unicamente o agrupada y luego reemplazada
                       IF var_prefactura_principal.prefactura_id != NULL THEN
                          SET cargo_prefactura = 0;
                          # Busco la prefactura agrupada y veo si fue reemplazada o no.
                          DECLARE cursor_prefactura_secundaria CURSOR FOR SELECT Prefactura.id, Empleador.cuit, Empleador.nombre, Prefactura.estado, Prefactura.fecha, Prefactura.anio, Prefactura.mes, 							Prefactura.subtotal, Prefactura.iva, Prefactura.total, Usuario.nombre, DefinicionEmpleador.nombre, DefinicionEmpleador.solicita_hes, Facturadora.nombre, (SELECT 
                    COALESCE((SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Principal' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Secundario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Terciario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Ninguna' AND u.estado != 'Bloqueado'), '-')) AS nombre_comercial FROM prefacturas Prefactura JOIN empleadores Empleador ON Prefactura.empleador_id = Empleador.id JOIN definicion_empleadores DefinicionEmpleador ON Prefactura.definicion_empleador_id = DefinicionEmpleador.id JOIN facturadoras Facturadora ON Prefactura.facturadora_id = Facturadora.id WHERE Prefactura.id = var_prefactura_principal.prefactura_id LIMIT 1;
                       		# Tabla temporal prefactura secundaria.
                          	DROP TABLE IF EXISTS var_prefactura_secundaria;
                           CREATE TEMPORARY TABLE var_prefactura_secundaria(prefactura_id INT(11), empleador_cuit VARCHAR(13), empleador_nombre VARCHAR(150), prefactura_estado VARCHAR(60), prefactura_fecha DATE, prefactura_anio INT(11), prefactura_mes INT(11), prefactura_subtotal DECIMAL(10,2), prefactura_iva DECIMAL(10,2), prefactura_total DECIMAL(10,2), usuario_nombre VARCHAR(30), def_emp_nombre VARCHAR(500), def_emp_solicita_hes VARCHAR(2), facturadora_nombre VARCHAR(500), nombre_comercial VARCHAR(100));
                            SET  fin_prefactura_secundaria = 0;
                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin_prefactura_secundaria = 1;
                            OPEN cursor_prefactura_secundaria;
                          
                           pre_secundaria:
                            LOOP
                                FETCH cursor_prefactura_secundaria INTO var_prefactura_secundaria;
                                IF fin_prefactura_secundaria = 1 THEN
                                    LEAVE pre_secundaria;
                                END IF;
                          		IF(var_prefactura_secundaria.reemplazada_por IS NULL ,
                                   # No fue reemplazada, entonces la guardo.
                                   INSERT INTO resultados(var_liquidaciones.liq_tipo , var_liquidaciones.fecha_confirmacion , var_liquidaciones.prefactura_id , var_prefactura_secundaria.empleador_cuit , var_prefactura_secundaria.empleador_nombre, var_prefactura_secundaria.prefactura_estado, var_prefactura_secundaria.prefactura_fecha, var_prefactura_secundaria.prefactura_anio, var_prefactura_secundaria.prefactura_mes, var_prefactura_secundaria.prefactura_subtotal, var_prefactura_secundaria.prefactura_iva, var_prefactura_secundaria.prefactura_total, var_prefactura_secundaria.usuario_nombre, var_prefactura_secundaria.def_emp_nombre, var_prefactura_secundaria.def_emp_solicita_hes, var_prefactura_secundaria.facturadora_nombre, var_prefactura_secundaria.nombre_comercial);
                                   ,
                                   # Fue reemplazada, busco la prefactura y la guardo.
                                   DECLARE cursor_prefactura_terciaria CURSOR FOR SELECT Prefactura.id, Empleador.cuit, Empleador.nombre, Prefactura.estado, Prefactura.fecha, Prefactura.anio, Prefactura.mes, 							Prefactura.subtotal, Prefactura.iva, Prefactura.total, Usuario.nombre, DefinicionEmpleador.nombre, DefinicionEmpleador.solicita_hes, Facturadora.nombre, (SELECT 
                    COALESCE((SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Principal' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Secundario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Terciario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Ninguna' AND u.estado != 'Bloqueado'), '-')) AS nombre_comercial FROM prefacturas Prefactura JOIN empleadores Empleador ON Prefactura.empleador_id = Empleador.id JOIN definicion_empleadores DefinicionEmpleador ON Prefactura.definicion_empleador_id = DefinicionEmpleador.id JOIN facturadoras Facturadora ON Prefactura.facturadora_id = Facturadora.id WHERE Prefactura.id = var_prefactura_secundaria.reemplazada_por LIMIT 1;
                                    DROP TABLE IF EXISTS var_prefactura_terciaria;
                                    CREATE TEMPORARY TABLE var_prefactura_terciaria(prefactura_id INT(11), empleador_cuit VARCHAR(13), empleador_nombre VARCHAR(150), prefactura_estado VARCHAR(60), prefactura_fecha DATE, prefactura_anio INT(11), prefactura_mes INT(11), prefactura_subtotal DECIMAL(10,2), prefactura_iva DECIMAL(10,2), prefactura_total DECIMAL(10,2), usuario_nombre VARCHAR(30), def_emp_nombre VARCHAR(500), def_emp_solicita_hes VARCHAR(2), facturadora_nombre VARCHAR(500), nombre_comercial VARCHAR(100));
                                    SET fin_prefactura_terciaria = 0;
                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin_prefactura_terciaria = 1;
                                    OPEN cursor_prefactura_terciaria;
                                   
                                   pre_terciaria:
                                   LOOP 
                                   	FETCH cursor_prefactura_terciaria INTO var_prefactura_terciaria;
                                    IF fin_prefactura_terciaria = 1 THEN
                                        LEAVE pre_terciaria;
                                    END IF;
                                    # Procedo a guardar la prefactura terciaria
                                   INSERT INTO resultados(var_liquidaciones.liq_tipo , var_liquidaciones.fecha_confirmacion , var_liquidaciones.prefactura_id , var_prefactura_terciaria.empleador_cuit , var_prefactura_terciaria.empleador_nombre, var_prefactura_terciaria.prefactura_estado, var_prefactura_terciaria.prefactura_fecha, var_prefactura_terciaria.prefactura_anio, var_prefactura_terciaria.prefactura_mes, var_prefactura_terciaria.prefactura_subtotal, var_prefactura_terciaria.prefactura_iva, var_prefactura_terciaria.prefactura_total, var_prefactura_terciaria.usuario_nombre, var_prefactura_terciaria.def_emp_nombre, var_prefactura_terciaria.def_emp_solicita_hes, var_prefactura_terciaria.facturadora_nombre, var_prefactura_terciaria.nombre_comercial);
                                   END LOOP pre_terciaria;
                                   CLOSE cursor_prefactura_terciaria;
                                  )# Parentesis del if de var_prefactura_secundaria.reemplazada_por;
                         		END IF;
                         	END LOOP pre_secundaria;
                       		CLOSE cursor_prefactura_secundaria;
                       END IF;
                       ) #Parentesis del if de var_prefactura_principal.reemplazada_por
                	END IF;
                    # En caso de que no haya sido ni reemplazada ni agrupada la cargo
                     IF cargo_prefactura = 1 THEN
						INSERT INTO resultados (var_liquidaciones.liq_tipo , var_liquidaciones.fecha_confirmacion , var_liquidaciones.prefactura_id , var_prefactura_principal.empleador_cuit , var_prefactura_principal.empleador_nombre, var_prefactura_principal.prefactura_estado, var_prefactura_principal.prefactura_fecha, var_prefactura_principal.prefactura_anio, var_prefactura_principal.prefactura_mes, var_prefactura_principal.prefactura_subtotal, var_prefactura_principal.prefactura_iva, var_prefactura_principal.prefactura_total, var_prefactura_principal.usuario_nombre, var_prefactura_principal.def_emp_nombre, var_prefactura_principal.def_emp_solicita_hes, var_prefactura_principal.facturadora_nombre, var_prefactura_principal.nombre_comercial);
                     END IF;
                END LOOP pre_principal;
                CLOSE cursor_prefactura_principal;
            END BLOCK2;
        END LOOP liquidaciones;
        CLOSE cursor_liquidaciones;
    END BLOCK1;
END BLOQUE_PRINCIPAL;
END$$
DELIMITER ;

call sp_obtener_prefacturas_no_facturadas("Liquidacion.estado = 'Confirmada'");

INTENTO NUMERO 2:

DROP PROCEDURE IF EXISTS sp_obtener_prefacturas_no_facturadas;

DELIMITER $$
CREATE PROCEDURE sp_obtener_prefacturas_no_facturadas(IN filtros VARCHAR(700))
BEGIN
	# Tabla que retorna
    CREATE TEMPORARY TABLE resultados(liq_tipo VARCHAR(50), fecha_confirmacion DATE, prefactura_id INT(11), empleador_cuit VARCHAR(13), empleador_nombre VARCHAR(150), prefactura_estado VARCHAR(60), prefactura_fecha DATE, prefactura_anio INT(11), prefactura_mes INT(11), prefactura_subtotal DECIMAL(10,2), prefactura_iva DECIMAL(10,2), prefactura_total DECIMAL(10,2), usuario_nombre VARCHAR(30), def_emp_nombre VARCHAR(500), def_emp_solicita_hes VARCHAR(2), facturadora_nombre VARCHAR(500), nombre_comercial VARCHAR(100));

BLOQUE_PRINCIPAL: BEGIN
	# Declaro los finales de cada cursor.
	DECLARE fin_liquidaciones INTEGER DEFAULT 0;
    DECLARE fin_prefactura_principal INTEGER DEFAULT 0;
    DECLARE fin_prefactura_secundaria INTEGER DEFAULT 0;
    DECLARE fin_prefactura_terciaria INTEGER DEFAULT 0;
    # Variable auxiliar para saber si cargo una prefactura o no
    DECLARE cargo_prefactura INTEGER DEFAULT 1;
    # Variables que tendran los campos de los resultados de los cursores.
    DECLARE var_reemplazada_por_principal INT(11) DEFAULT NULL;
    DECLARE var_prefactura_id_principal INT(11) DEFAULT NULL;
    DECLARE var_reemplazada_por_secundaria INT(11) DEFAULT NULL;
    DECLARE var_prefactura_id_secundaria INT(11) DEFAULT NULL;    
    DECLARE var_liq_tipo VARCHAR(50) DEFAULT '';
    DECLARE var_fecha_confirmacion DATE DEFAULT '0000-00-00';
    DECLARE var_prefactura_id INT(11) DEFAULT 0;
    DECLARE var_empleador_cuit VARCHAR(13) DEFAULT '0-0-0';
    DECLARE var_empleador_nombre VARCHAR(150) DEFAULT '';
    DECLARE var_prefactura_estado VARCHAR(60) DEFAULT '';
    DECLARE var_prefactura_fecha DATE DEFAULT '0000-00-00';
    DECLARE var_prefactura_anio INT(11) DEFAULT 0;
    DECLARE var_prefactura_mes INT(11) DEFAULT 0;
    DECLARE var_prefactura_subtotal DECIMAL(10,2) DEFAULT 0.0;
    DECLARE var_prefactura_iva DECIMAL(10,2) DEFAULT 0.0;
    DECLARE var_prefactura_total DECIMAL(10,2) DEFAULT 0.0;
    DECLARE var_usuario_nombre VARCHAR(30) DEFAULT '';
    DECLARE var_def_emp_nombre VARCHAR(500) DEFAULT '';
    DECLARE var_def_emp_solicita_hes VARCHAR(2) DEFAULT '';
    DECLARE var_facturadora_nombre VARCHAR(500) DEFAULT '';
    DECLARE var_nombre_comercial VARCHAR(100) DEFAULT '';
    # Query liquidaciones.
	DECLARE cursor_liquidaciones CURSOR FOR SELECT Liquidacion.tipo, Liquidacion.prefactura_id, CambioDetalle.fecha_confirmacion FROM liquidaciones Liquidacion JOIN cambio_detalles CambioDetalle ON Liquidacion.cambio_detalle_id = CambioDetalle.id WHERE filtros;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin_liquidaciones = 1;
    
    OPEN cursor_liquidaciones;
 	BLOCK1: BEGIN
    	SET fin_liquidaciones = 0;
        liquidaciones:
        LOOP
            FETCH cursor_liquidaciones INTO var_liq_tipo, var_prefactura_id, var_fecha_confirmacion;
            IF fin_liquidaciones = 1 THEN 
                LEAVE liquidaciones;
            END IF;
            SET cargo_prefactura = 1;
            BLOCK2: BEGIN
            # Traemos la prefactura asociada a la liquidacion.
                DECLARE cursor_prefactura_principal CURSOR FOR SELECT Prefactura.reemplazada_por, Prefactura.prefactura_id,Prefactura.id, Empleador.cuit, Empleador.nombre, Prefactura.estado, Prefactura.fecha, Prefactura.anio, Prefactura.mes, Prefactura.subtotal, Prefactura.iva, Prefactura.total, Usuario.nombre, DefinicionEmpleador.nombre, DefinicionEmpleador.solicita_hes, Facturadora.nombre, (SELECT 
                    COALESCE((SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Principal' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Secundario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Terciario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Ninguna' AND u.estado != 'Bloqueado'), '-')) AS nombre_comercial FROM prefacturas Prefactura JOIN empleadores Empleador ON Prefactura.empleador_id = Empleador.id JOIN definicion_empleadores DefinicionEmpleador ON Prefactura.definicion_empleador_id = DefinicionEmpleador.id JOIN facturadoras Facturadora ON Prefactura.facturadora_id = Facturadora.id WHERE Prefactura.id = var_liquidaciones.prefactura_id LIMIT 1;

				# Variables para la prefactura principal
                DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin_prefactura_principal = 1;
                SET fin_prefactura_principal = 0;
                OPEN cursor_prefactura_principal;
                
                pre_principal:
                LOOP
                	FETCH cursor_prefactura_principal INTO var_reemplazada_por_principal, var_prefactura_id_principal, var_prefactura_id , var_empleador_cuit, var_empleador_nombre, var_prefactura_estado, var_prefactura_fecha, var_prefactura_anio, var_prefactura_mes, var_prefactura_subtotal, var_prefactura_iva, var_prefactura_total, var_usuario_nombre, var_def_emp_nombre, var_def_emp_solicita_hes, var_facturadora_nombre, var_nombre_comercial;
                    IF fin_prefactura_principal = 1 THEN
                    	LEAVE pre_principal;
                    END IF;
                    IF var_reemplazada_por_principal != NULL THEN
                     #Guardo porque fue reemplazada, es la definitiva
                     SET cargo_prefactura = 0;                      
                     INSERT INTO resultados VALUES (var_liq_tipo , var_fecha_confirmacion , var_prefactura_id , var_empleador_cuit , var_empleador_nombre, var_prefactura_estado, var_prefactura_fecha, var_prefactura_anio, var_prefactura_mes, var_prefactura_subtotal, var_prefactura_iva, var_prefactura_total, var_usuario_nombre, var_def_emp_nombre, var_def_emp_solicita_hes, var_facturadora_nombre, var_nombre_comercial);
                     ELSE # Veo si fue agrupada unicamente o agrupada y luego reemplazada
                       IF var_prefactura_id_principal != NULL THEN
                       BLOQUE3: BEGIN
                       # Busco la prefactura agrupada y veo si fue reemplazada o no.
                          DECLARE cursor_prefactura_secundaria CURSOR FOR SELECT Prefactura.reemplazada_por, Prefactura.prefactura_id, Prefactura.id, Empleador.cuit, Empleador.nombre, Prefactura.estado, Prefactura.fecha, Prefactura.anio, Prefactura.mes, 							Prefactura.subtotal, Prefactura.iva, Prefactura.total, Usuario.nombre, DefinicionEmpleador.nombre, DefinicionEmpleador.solicita_hes, Facturadora.nombre, (SELECT 
                    COALESCE((SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Principal' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Secundario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Terciario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Ninguna' AND u.estado != 'Bloqueado'), '-')) AS nombre_comercial FROM prefacturas Prefactura JOIN empleadores Empleador ON Prefactura.empleador_id = Empleador.id JOIN definicion_empleadores DefinicionEmpleador ON Prefactura.definicion_empleador_id = DefinicionEmpleador.id JOIN facturadoras Facturadora ON Prefactura.facturadora_id = Facturadora.id WHERE Prefactura.id = var_prefactura_id_principal LIMIT 1;
                       		# Variables prefactura secundaria.                       
                       		DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin_prefactura_secundaria = 1;
                          	SET cargo_prefactura = 0;
                            SET  fin_prefactura_secundaria = 0;
                            OPEN cursor_prefactura_secundaria;
                          
                           pre_secundaria:
                            LOOP
                                FETCH cursor_prefactura_secundaria INTO var_reemplazada_por_secundaria, var_prefactura_id_secundaria, var_prefactura_id , var_empleador_cuit, var_empleador_nombre, var_prefactura_estado, var_prefactura_fecha, var_prefactura_anio, var_prefactura_mes, var_prefactura_subtotal, var_prefactura_iva, var_prefactura_total, var_usuario_nombre, var_def_emp_nombre, var_def_emp_solicita_hes, var_facturadora_nombre, var_nombre_comercial;
                                IF fin_prefactura_secundaria = 1 THEN
                                    LEAVE pre_secundaria;
                                END IF;
                          		IF var_reemplazada_por_secundaria IS NULL THEN
                                   # No fue reemplazada, entonces la guardo.
                                   INSERT INTO resultados VALUES (var_liq_tipo , var_fecha_confirmacion , var_prefactura_id , var_empleador_cuit , var_empleador_nombre, var_prefactura_estado, var_prefactura_fecha, var_prefactura_anio, var_prefactura_mes, var_prefactura_subtotal, var_prefactura_iva, var_prefactura_total, var_usuario_nombre, var_def_emp_nombre, var_def_emp_solicita_hes, var_facturadora_nombre, var_nombre_comercial);
                                ELSE
                                   BLOQUE4: BEGIN
                                   # Fue reemplazada, busco la prefactura y la guardo.
                                   DECLARE cursor_prefactura_terciaria CURSOR FOR SELECT Prefactura.id, Empleador.cuit, Empleador.nombre, Prefactura.estado, Prefactura.fecha, Prefactura.anio, Prefactura.mes, 							Prefactura.subtotal, Prefactura.iva, Prefactura.total, Usuario.nombre, DefinicionEmpleador.nombre, DefinicionEmpleador.solicita_hes, Facturadora.nombre, (SELECT 
                    COALESCE((SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Principal' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Secundario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Terciario' AND u.estado != 'Bloqueado'),
                    (SELECT u.nombre_completo FROM crm_eecc_empresas cee 
                    JOIN usuarios u  ON cee.usuario_id  = u.id WHERE cee.empresa_id = Empleador.id
                    AND cee.prioridad = 'Ninguna' AND u.estado != 'Bloqueado'), '-')) AS nombre_comercial FROM prefacturas Prefactura JOIN empleadores Empleador ON Prefactura.empleador_id = Empleador.id JOIN definicion_empleadores DefinicionEmpleador ON Prefactura.definicion_empleador_id = DefinicionEmpleador.id JOIN facturadoras Facturadora ON Prefactura.facturadora_id = Facturadora.id WHERE Prefactura.id = var_reemplazada_por_secundaria LIMIT 1;
                                    # Variables prefactura terciaria.
                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin_prefactura_terciaria = 1;
                                    SET fin_prefactura_terciaria = 0;
                                    OPEN cursor_prefactura_terciaria;
                                   
                                   pre_terciaria:
                                   LOOP 
                                   	FETCH cursor_prefactura_terciaria INTO var_prefactura_id , var_empleador_cuit, var_empleador_nombre, var_prefactura_estado, var_prefactura_fecha, var_prefactura_anio, var_prefactura_mes, var_prefactura_subtotal, var_prefactura_iva, var_prefactura_total, var_usuario_nombre, var_def_emp_nombre, var_def_emp_solicita_hes, var_facturadora_nombre, var_nombre_comercial;
                                    IF fin_prefactura_terciaria = 1 THEN
                                        LEAVE pre_terciaria;
                                    END IF;
                                    # Procedo a guardar la prefactura terciaria
                                   INSERT INTO resultados VALUES (var_liq_tipo , var_fecha_confirmacion , var_prefactura_id , var_empleador_cuit , var_empleador_nombre, var_prefactura_estado, var_prefactura_fecha, var_prefactura_anio, var_prefactura_mes, var_prefactura_subtotal, var_prefactura_iva, var_prefactura_total, var_usuario_nombre, var_def_emp_nombre, var_def_emp_solicita_hes, var_facturadora_nombre, var_nombre_comercial);
                                   END LOOP pre_terciaria;
                                   CLOSE cursor_prefactura_terciaria;
                                   END BLOQUE4;
                         		END IF; # IF var_reemplazada_por_secundaria
                         	END LOOP pre_secundaria;
                       		CLOSE cursor_prefactura_secundaria;
                       END BLOQUE3;
                       END IF; # IF la principal fue agrupada.
                	END IF; # IF var_reemplazada_por_principal
                    # En caso de que no haya sido ni reemplazada ni agrupada la cargo
                     IF cargo_prefactura = 1 THEN
						INSERT INTO resultados VALUES (var_liq_tipo , var_fecha_confirmacion , var_prefactura_id , var_empleador_cuit , var_empleador_nombre, var_prefactura_estado, var_prefactura_fecha, var_prefactura_anio, var_prefactura_mes, var_prefactura_subtotal, var_prefactura_iva, var_prefactura_total, var_usuario_nombre, var_def_emp_nombre, var_def_emp_solicita_hes, var_facturadora_nombre, var_nombre_comercial);
                     END IF;
                END LOOP pre_principal;
                CLOSE cursor_prefactura_principal;
            END BLOCK2;
        END LOOP liquidaciones;
        CLOSE cursor_liquidaciones;
    END BLOCK1;
END BLOQUE_PRINCIPAL;
END$$
DELIMITER ;

call sp_obtener_prefacturas_no_facturadas("Liquidacion.estado = 'Confirmada'");

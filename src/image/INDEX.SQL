VAR V_CARGA_FAMILIAR NUMBER(9);
VAR V_MOVILIZACION_ADICIONAL NUMBER(9);
VAR V_COLACION NUMBER(9);
VAR V_FECHA_PROCESO DATE;

DECLARE
    V_MES NUMBER(2);
    V_ANNO NUMBER(4);
    V_FAMILIA_CARGA NUMBER(10);
    V_MOVILIZACION NUMBER(11);
    V_ASIG_ESCOLARIDAD NUMBER(10);
    V_PORC_BONIFICACION_TRABAJO NUMBER(10);
    V_MOVILIZACION_ADICIONAL NUMBER(10);
BEGIN
:V_COLACION := 40000;
:V_FECHA_PROCESO := ADD_MONTHS(SYSDATE,-2);
:V_CARGA_FAMILIAR := 4500;

    V_MES:= EXTRACT(MONTH FROM (TO_DATE(:V_FECHA_PROCESO)));
    V_ANNO:= EXTRACT(YEAR FROM (TO_DATE(:V_FECHA_PROCESO)));


    FOR I IN (SELECT emp.cod_emp, emp.numrut_emp,porc_b.porc_bonif, 
    carga_emp.cantidad, comu.nombre_comuna, emp.sueldo_base_emp, catemp.desc_categoria_emp,
    comi.valor, esco.porc_asig_escolaridad, emp.cod_salud, emp.cod_afp
        FROM empleado  emp
    INNER JOIN asig_escolaridad esco ON esco.id_escolaridad = emp.id_escolaridad
    LEFT JOIN (SELECT cod_emp ,COUNT(cod_emp) cantidad FROM carga_familiar
                GROUP BY cod_emp) carga_emp ON emp.cod_emp = carga_emp.cod_emp
    LEFT JOIN porc_bonif_annos_contrato porc_b ON ( EXTRACT(YEAR FROM(SYSDATE))- EXTRACT(YEAR FROM(fecing_emp))) BETWEEN porc_b.ANNOS_CONT_INF AND porc_b.ANNOS_CONT_SUP
    LEFT JOIN  comuna COMU ON comu.id_comuna = emp.id_comuna
    LEFT JOIN categoria_empleado catemp ON  catemp.id_categoria_emp = emp.id_categoria_emp
    LEFT JOIN (     SELECT bol.cod_emp, SUM(com_v.valor_comision) COM_VENTAS FROM BOLETA bol   
    INNER JOIN comision_venta COM_V ON bol.nro_boleta = com_v.nro_boleta
    WHERE EXTRACT(MONTH FROM(bol.fecha_boleta))  = V_MES AND EXTRACT(YEAR FROM(bol.fecha_boleta)) = V_ANNO
    GROUP BY bol.cod_emp) COMI ON COMI.cod_emp = emp.cod_emp
    ORDER BY EMP.COD_EMP)
        LOOP
        --SE CREA PORQUE EL DOC LO SOLICITA.
        V_FAMILIA_CARGA:= :V_CARGA_FAMILIAR*NVL(i.cantidad,0);
        
        FOR POC_MOVILIZACION IN (SELECT * FROM porc_movilizacion) 
        LOOP
            IF  i.sueldo_base_emp >= poc_movilizacion.sueldo_base_inf  AND  I.sueldo_base_emp <= POC_MOVILIZACION.sueldo_base_sup  THEN
                V_MOVILIZACION:= POC_MOVILIZACION.PORC_MOV;
            END IF;
        END LOOP;
        

        V_ASIG_ESCOLARIDAD:= ROUND((i.sueldo_base_emp* i.porc_asig_escolaridad)/100);
        i.valor;
        V_PORC_BONIFICACION_TRABAJO:=  (i.sueldo_base_emp* NVL(i.porc_bonif,0)/100);
        V_MOVILIZACION_ADICIONAL:= ROUND((i.sueldo_base_emp* v_movilizacion)/100);


    
            BEGIN
            INSERT INTO haber_calc_mes VALUES(i.cod_emp, i.numrut_emp,v_mes,v_anno,i.sueldo_base_emp, V_PORC_BONIFICACION_TRABAJO,
            V_FAMILIA_CARGA, V_MOVILIZACION_ADICIONAL, :V_COLACION, v_com_ventas, V_ASIG_ESCOLARIDAD);
            
            END;
                    
     
           DECLARE
           
           V_TOTAL_AFP NUMBER(9):= i.sueldo_base_emp+v_familia_carga+v_asig_escolaridad;
           V_PORC_AFP NUMBER(4);
           AFP_EMP NUMBER(9);
           
           V_TOTAL_SALUD NUMBER(8):=  i.sueldo_base_emp+v_porc_bonificacion_trabajo+V_MOVILIZACION_ADICIONAL;
           V_PORC_SALUD NUMBER(4);
           SALUD_EMP NUMBER(9);
           BEGIN 
           
            FOR SALUD IN (SELECT * FROM salud)
            LOOP
                IF i.cod_salud = salud.cod_salud 
                THEN 
                    V_PORC_SALUD:= salud.porc_descto_salud;
                ELSE 
                V_PORC_SALUD:=0;
                END IF;
            END LOOP;
            
            SALUD_EMP:= ROUND((V_TOTAL_SALUD*V_PORC_SALUD)/100);
            
            FOR afp IN (SELECT * FROM afp)
            LOOP
              IF afp.cod_afp = i.cod_afp THEN
                V_PORC_SALUD:= afp.porc_descto_afp;
            ELSE 
            V_PORC_SALUD:= 0;
              END IF;
            
            END LOOP;
            
         SALUD_EMP:= ROUND((V_TOTAL_SALUD*V_PORC_SALUD)/100);
         AFP_EMP:= V_TOTAL_AFP;
         
         DBMS_OUTPUT.PUT_LINE(AFP_EMP);


           END;
            

        END LOOP;



END;




 
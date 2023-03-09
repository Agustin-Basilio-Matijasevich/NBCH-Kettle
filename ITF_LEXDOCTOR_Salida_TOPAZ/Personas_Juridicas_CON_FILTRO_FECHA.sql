--== Personas Juridicas CON FILTRO DE FECHA ==--

DECLARE @fecha DATE;
SET @fecha = CAST('${fecha}' AS DATE); --Setear fecha filtro como variable para ahorrar recursos y codigo.

SELECT  PJF.* , 
		bpj.TIPO_TRAZA AS BPTraza , 
		bpj.ESTADO AS BPEstado , 
		ROW_NUMBER () OVER (PARTITION BY [ID_Cliente] ORDER BY bpj.HORA) AS BO 

FROM

		(SELECT * --La seleccion de campos se hace en la SubQuery 
		
		FROM 
				--SubQuery que trae tabla personas fisicas con repetidos enumerados para filtrar 
				(SELECT --Seleccion de Campos
					cp.NUMEROPERSONAJURIDICA AS ID_Cliente, 
					cp.RAZONSOCIAL AS Nombre, 
					' ' AS Apellido, 
					'1' AS Tipo_Persona, 
					cdp.TIPODOCUMENTO AS Tipo_ID, 
					cdp.NUMERODOCUMENTO AS Nro_ID, 
					CONCAT(cd.CALLE,' ',cd.NUMERO,' ',cd.PISO,' ',cd.OBSERVACIONES,' ',cd.APARTAMENTO,' ',cd.BARRIO,' ',cd.MANZANA,' ',cd.PARCELA,' ',cd.CASA,' ',cd.MONOBLOCK,' ',cd.TIRA,' ',cd.CHACRA) AS Domicilio, 
					cl.DESCRIPCION_DIM3 AS Localidad, 
					cl.CODIGO_POSTAL AS Codigo_Postal, 
					cp2.DESCRIPCION AS Provincia, --Procesar en Spoon
					' ' AS Conyugue, 
					ct.NUMERO AS Telefono, 
					ce.EMAIL AS E_Mail, 
					cp.IVA AS Condicion_IVA, --Procesar en Spoon 
					cp.SUC_ALTA AS Sucursal, 
					--Generar Campo 'Nota' en Spoon 
					'1' AS Marca_Empleado, --Procesar en Spoon 
					cp.ESTADO as Estado, --Procesar en Spoon 
					ROW_NUMBER () OVER (PARTITION BY cp.NUMEROPERSONAJURIDICA ORDER BY cp.NUMEROPERSONAJURIDICA) AS RN, --Enumera los repetidos en un campo llamado RN 
					cp.FECHAALTA AS Fecha_Alta 
				 
				FROM CLI_PERSONASJURIDICAS cp 
				
				LEFT JOIN CLI_DIRECCIONES cd ON cp.NUMEROPERSONAJURIDICA = cd.ID AND cd.TIPODIRECCION LIKE 'L' AND cd.FORMATO LIKE 'PJ' --Uso de clave primaria parcial (Provoca Repetidos). Filtra Domicilios Reales de personas fisicas.lalolanda 
				LEFT JOIN CLI_PROVINCIAS cp2 ON cd.PROVINCIA = cp2.DIM1 AND cd.PAIS = cp2.CODIGOPAIS --Usa Clave Primaria Completa 
				LEFT JOIN CLI_LOCALIDADES cl ON cd.PROVINCIA = cl.DIM1 AND cd.DEPARTAMENTO = cl.DIM2 AND cd.LOCALIDAD = cl.DIM3 AND cd.PAIS = cl.CODIGOPAIS AND cd.CPA_VIEJO = cl.CODIGO_POSTAL --Usa Clave Primaria Completa 
				LEFT JOIN CLI_DocumentosPFPJ cdp ON cp.NUMEROPERSONAJURIDICA = cdp.NUMEROPERSONAFJ --Uso de clave primaria parcial (Provoca Repetidos). 
				LEFT JOIN CLI_TELEFONOS ct ON cp.NUMEROPERSONAJURIDICA = ct.ID AND ct.TIPO LIKE 'LE' AND ct.FORMATO LIKE 'PJ' --Uso de clave parcial 
				LEFT JOIN CLI_EMAILS ce ON cp.NUMEROPERSONAJURIDICA = ce.ID AND ce.TIPO LIKE 'LE' AND ce.FORMATO LIKE 'PJ' --Uso de Clave Parcial 
				) 
				PF --Nombre de la tabla nueva es PF 
				--FIN SubQuery 

		WHERE RN = 1
		) 
		PJF --Filtramos y eliminamos los repetidos quedandonos con el primer registro de cada bloque de repetidos. 
		
		LEFT JOIN BITACORA_PERSONAS_JURIDICAS bpj ON bpj.NUMEROPERSONAJURIDICA = [ID_Cliente] AND bpj.FECHA = @fecha AND PJF.Fecha_Alta <= @fecha 
		LEFT JOIN BITACORA_DIRECCIONES bd ON bd.ID = [ID_Cliente] AND bd.TIPODIRECCION LIKE 'PR' AND bd.FORMATO LIKE 'PF' AND bd.FECHA = @fecha AND bpj.FECHA IS NULL
		LEFT JOIN BITACORA_TELEFONOS bt ON bt.ID = [ID_Cliente] AND bt.TIPO LIKE 'PE' AND bt.FORMATO LIKE 'PF' AND bt.FECHA = @fecha AND bpj.FECHA IS NULL 
		LEFT JOIN BITACORA_CORREOELECTRONICO bc ON bc.ID = [ID_Cliente] AND bc.TIPO LIKE 'PE' AND bc.FORMATO LIKE 'PF' AND bc.FECHA = @fecha AND bpj.FECHA IS NULL 

WHERE PJF.Fecha_Alta <= @fecha 
	  AND ((bpj.TIPO_TRAZA IS NOT NULL AND bpj.ESTADO IS NOT NULL) 
	  OR bd.TIPO_TRAZA IS NOT NULL 
	  OR bt.TIPO_TRAZA IS NOT NULL
	  OR bc.TIPO_TRAZA IS NOT NULL)
; 
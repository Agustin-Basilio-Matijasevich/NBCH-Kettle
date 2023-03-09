--== Personas Fisicas CON FILTRO DE FECHA ==--

DECLARE @fecha DATE;
SET @fecha = CAST('${fecha}' AS DATE); --Setear fecha filtro como variable para ahorrar recursos y codigo.

SELECT 		PFF.* , 
			bpf.TIPO_TRAZA AS BPTraza , 
			bpf.ESTADO AS BPEstado , 
			ROW_NUMBER () OVER (PARTITION BY [ID_Cliente] ORDER BY bpf.HORA) AS BO 

FROM  

	(SELECT * --La seleccion de campos se hace en la SubQuery 
	FROM 
		--SubQuery que trae tabla personas fisicas con id_cliente repetidos enumerados para filtrar 
		(SELECT
		cp.NUMEROPERSONAFISICA AS ID_Cliente, 
		CONCAT(CONVERT(VARCHAR(15),cp.PRIMERNOMBRE),' ',CONVERT(VARCHAR(15),cp.SEGUNDONOMBRE)) AS Nombre, 
		CONCAT(CONVERT(VARCHAR(15),cp.APELLIDOPATERNO),' ',CONVERT(VARCHAR(15),cp.APELLIDOMATERNO)) AS Apellido, 
		'0' AS Tipo_Persona, 
		cdp.TIPODOCUMENTO AS Tipo_ID, 
		cdp.NUMERODOCUMENTO AS Nro_ID, 
		concat(cd.CALLE,' ',cd.NUMERO,' ',cd.PISO,' ',cd.OBSERVACIONES,' ',cd.APARTAMENTO,' ',cd.BARRIO,' ',cd.MANZANA,' ',cd.PARCELA,' ',cd.CASA,' ',cd.MONOBLOCK,' ',cd.TIRA,' ',cd.CHACRA) AS Domicilio, 
		cl.DESCRIPCION_DIM3 AS Localidad, 
		cl.CODIGO_POSTAL AS Codigo_Postal, 
		cp2.DESCRIPCION AS Provincia, --Procesar en Spoon con las abreviaciones
		concat(CONVERT(VARCHAR(8),cp3.APELLIDOPATERNO),' ',CONVERT(VARCHAR(8),cp3.APELLIDOMATERNO),' ',CONVERT(VARCHAR(7),cp3.PRIMERNOMBRE),' ',CONVERT(VARCHAR(7),cp3.SEGUNDONOMBRE)) AS Conyugue, 
		ct.NUMERO AS Telefono, 
		ce.EMAIL AS E_Mail, 
		cp.IVA AS Condicion_IVA, --Se procesa en Spoon 
		cp.SUC_ALTA AS Sucursal, 
		--Generar Campo 'Nota' en Spoon 
		cp.EMPLEADO_BC_BANCO AS Marca_Empleado, --Procesar en Spoon 
		cp.ESTADO AS Estado, --Procesar en Spoon 
		ROW_NUMBER () OVER (PARTITION BY cp.NUMEROPERSONAFISICA ORDER BY cp.NUMEROPERSONAFISICA) AS RN, --Enumera los repetidos en un campo llamado RN 
		cp.FECHAALTA AS Fecha_Alta 
		--JOINS 
		FROM CLI_PERSONASFISICAS cp 
		LEFT JOIN CLI_DIRECCIONES cd ON cp.NUMEROPERSONAFISICA = cd.ID AND cd.TIPODIRECCION LIKE 'PR' AND cd.FORMATO LIKE 'PF' --Uso de clave primaria parcial (Provoca Repetidos). Filtra Domicilios Reales de personas fisicas. lalolanda 
		LEFT JOIN CLI_PROVINCIAS cp2 ON cd.PROVINCIA = cp2.DIM1 AND cd.PAIS = cp2.CODIGOPAIS --Usa Clave Primaria Completa 
		LEFT JOIN CLI_LOCALIDADES cl ON cd.PROVINCIA = cl.DIM1 AND cd.DEPARTAMENTO = cl.DIM2 AND cd.LOCALIDAD = cl.DIM3 AND cd.PAIS = cl.CODIGOPAIS AND cd.CPA_VIEJO = cl.CODIGO_POSTAL --Usa Clave Primaria Completa 
		LEFT JOIN CLI_DocumentosPFPJ cdp ON cp.NUMEROPERSONAFISICA = cdp.NUMEROPERSONAFJ --Uso de clave primaria parcial (Provoca Repetidos). 
		LEFT JOIN CLI_TELEFONOS ct ON cp.NUMEROPERSONAFISICA = ct.ID AND ct.TIPO LIKE 'PE' AND ct.FORMATO LIKE 'PF' --Uso de clave parcial 
		LEFT JOIN CLI_EMAILS ce ON cp.NUMEROPERSONAFISICA = ce.ID AND ce.TIPO LIKE 'PE' AND ce.FORMATO LIKE 'PF' --Uso de Clave Parcial 
		LEFT JOIN CLI_VINCULACIONES VI ON cp.NUMEROPERSONAFISICA = VI.PERSONA_VINCULANTE AND VI.ROL = 71 AND VI.FECHA_FIN IS NULL --Uso clave Parcial
		LEFT JOIN CLI_PERSONASFISICAS cp3 ON cp3.NUMEROPERSONAFISICA = VI.PERSONA_VINCULADA --Uso clave completa
		) 
		PF --Nombre de la tabla nueva es PF 
		--FIN SubQuery 
		
WHERE RN = 1) PFF --Filtramos y eliminamos los repetidos quedandonos con el primer registro de cada bloque de repetidos. 

LEFT JOIN BITACORA_PERSONAS_FISICAS bpf ON bpf.NUMEROPERSONAFISICA = [ID_Cliente] AND bpf.FECHA = @fecha AND PFF.Fecha_Alta <= @fecha 
LEFT JOIN BITACORA_DIRECCIONES bd ON bd.ID = [ID_Cliente] AND bd.TIPODIRECCION LIKE 'PR' AND bd.FORMATO LIKE 'PF' AND bd.FECHA = @fecha AND bpf.FECHA IS NULL
LEFT JOIN BITACORA_TELEFONOS bt ON bt.ID = [ID_Cliente] AND bt.TIPO = 'PE' AND bt.FORMATO = 'PF' AND bt.FECHA = @fecha AND bpf.FECHA IS NULL
LEFT JOIN BITACORA_CORREOELECTRONICO bc ON bc.ID = [ID_Cliente] AND bc.TIPO LIKE 'PE' AND bc.FORMATO LIKE 'PF' AND bc.FECHA = @fecha AND bpf.FECHA IS NULL
LEFT JOIN BITACORA_CONYUGUES bc2 ON bc2.NUMEROPERSONAFISICA = [ID_Cliente] AND bc2.FECHA = @fecha AND bpf.FECHA IS NULL

WHERE PFF.Fecha_Alta <= @fecha 
	  AND ((bpf.TIPO_TRAZA IS NOT NULL AND bpf.ESTADO IS NOT NULL) 
	  OR bd.TIPO_TRAZA IS NOT NULL 
	  OR bt.TIPO_TRAZA IS NOT NULL 
	  OR bc.TIPO_TRAZA IS NOT NULL 
	  OR bc2.TIPO_TRAZA IS NOT NULL) 
;
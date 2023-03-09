--== Personas Fisicas - parametro = 0 ==--

SELECT * --La seleccion de campos se hace en la SubQuery 

FROM 
		--SubQuery que trae tabla personas fisicas con repetidos enumerados para filtrar 
		(SELECT --Seleccion de Campos
		cp.NUMEROPERSONAFISICA AS ID_Cliente, 
		CONCAT(CONVERT(VARCHAR(15),cp.PRIMERNOMBRE),' ',CONVERT(VARCHAR(15),cp.SEGUNDONOMBRE)) AS Nombre, 
		CONCAT(CONVERT(VARCHAR(15),cp.APELLIDOPATERNO),' ',CONVERT(VARCHAR(15),cp.APELLIDOMATERNO)) AS Apellido, 
		'0' AS Tipo_Persona, 
		cdp.TIPODOCUMENTO AS Tipo_ID, 
		cdp.NUMERODOCUMENTO AS Nro_ID, 
		concat(cd.CALLE,' ',cd.NUMERO,' ',cd.PISO,' ',cd.OBSERVACIONES,' ',cd.APARTAMENTO,' ',cd.BARRIO,' ',cd.MANZANA,' ',cd.PARCELA,' ',cd.CASA,' ',cd.MONOBLOCK,' ',cd.TIRA,' ',cd.CHACRA) AS Domicilio, 
		cl.DESCRIPCION_DIM3 AS Localidad, 
		cl.CODIGO_POSTAL AS Codigo_Postal, 
		cp2.DESCRIPCION AS Provincia, --Procesar en Spoon
		concat(CONVERT(VARCHAR(8),cp3.APELLIDOPATERNO),' ',CONVERT(VARCHAR(8),cp3.APELLIDOMATERNO),' ',CONVERT(VARCHAR(7),cp3.PRIMERNOMBRE),' ',CONVERT(VARCHAR(7),cp3.SEGUNDONOMBRE)) AS Conyugue, 
		ct.NUMERO AS Telefono, 
		ce.EMAIL AS E_Mail, 
		cp.IVA AS Condicion_IVA, --Procesar en Spoon 
		cp.SUC_ALTA AS Sucursal, 
		--Generar Campo 'Nota' en Spoon 
		cp.EMPLEADO_BC_BANCO AS Marca_Empleado, --Procesar en Spoon 
		cp.ESTADO AS Estado, --Procesar en Spoon 
		ROW_NUMBER () OVER (PARTITION BY cp.NUMEROPERSONAFISICA ORDER BY cp.NUMEROPERSONAFISICA) AS RN --Enumera los repetidos en un campo llamado RN 
		 
		from CLI_PERSONASFISICAS cp 
		
		left join CLI_DIRECCIONES cd ON cp.NUMEROPERSONAFISICA = cd.ID AND cd.TIPODIRECCION LIKE 'PR' AND cd.FORMATO LIKE 'PF' --Uso de clave primaria parcial (Provoca Repetidos). Filtra Domicilios Reales de personas fisicas. lalolanda 
		left join CLI_PROVINCIAS cp2 ON cd.PROVINCIA = cp2.DIM1 AND cd.PAIS = cp2.CODIGOPAIS --Usa Clave Primaria Completa 
		left join CLI_LOCALIDADES cl ON cd.PROVINCIA = cl.DIM1 AND cd.DEPARTAMENTO = cl.DIM2 AND cd.LOCALIDAD = cl.DIM3 AND cd.PAIS = cl.CODIGOPAIS AND cd.CPA_VIEJO = cl.CODIGO_POSTAL --Usa Clave Primaria Completa 
		left join CLI_DocumentosPFPJ cdp ON cp.NUMEROPERSONAFISICA = cdp.NUMEROPERSONAFJ --Uso de clave primaria parcial (Provoca Repetidos). 
		left join CLI_TELEFONOS ct ON cp.NUMEROPERSONAFISICA = ct.ID AND ct.TIPO LIKE 'PE' AND ct.FORMATO LIKE 'PF' --Uso de clave parcial 
		left join CLI_EMAILS ce ON cp.NUMEROPERSONAFISICA = ce.ID AND ce.TIPO LIKE 'PE' AND ce.FORMATO LIKE 'PF' --Uso de Clave Parcial 
		left join CLI_VINCULACIONES VI ON cp.NUMEROPERSONAFISICA = VI.PERSONA_VINCULANTE AND VI.ROL = 71 AND VI.FECHA_FIN IS NULL --Uso clave Parcial
		left join CLI_PERSONASFISICAS cp3 ON cp3.NUMEROPERSONAFISICA = VI.PERSONA_VINCULADA --Uso clave completa
		) 
		PF --Nombre de la tabla nueva es PF 
		--FIN SubQuery 

WHERE RN = 1; --Filtramos y eliminamos los repetidos quedandonos con el primer registro de cada bloque de repetidos.
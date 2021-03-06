module recocido_simulado
include("base_datos.jl")
include("visualizador.jl")
using StatsBase
using Random
using Dates

__precompile__()
#Parte de la CONFIGURACION

ciudades_del_problema = [1,2,3,4,5,6,7,8,9,11,12,14,16,17,19,20,22,23,25,26,27,28,74,75,151,163,164,165,166,167,168,169,171,172,173,174,176,179,181,182,183,184,185,186,187,297,326,327,328,329,330,331,332,333,334,336,339,340,343,344,345,346,347,349,350,351,352,444,483,489,490,491,492,493,494,495,496,499,500,501,502,504,505,507,508,509,510,511,512,520,652,653,654,655,656,657,658,660,661,662,663,665,666,667,668,670,671,673,674,675,676,678,814,815,816,817,818,819,820,821,822,823,825,826,828,829,832,837,839,840,978,979,980,981,982,984,985,986,988,990,991,995,999,1001,1003,1004,1037,1038,1073,1075]
 T_0 = 50
 L = 3000
 iter_max = 5000
 epsilon = 0.0001
 phi = 0.9
 veces = 1000
 epsilon_p = 0.04
 P = 0.9

#############################
Norm = Base_Datos.normalizador(ciudades_del_problema)
grafica = Base_Datos.crea_matriz_adyacencias(ciudades_del_problema)


"Funcion que calcula el costo de una ruta
#Arguments
- ruta:: Array{Int64,1}: Ruta a la que le obtendremos el costo"
function costo(ruta)
    length = size(ruta)[1]
    suma = 0
    for i in 1:(length-1)
        ciudad_1 = ruta[i]
        ciudad_2 = ruta[i+1]
        cost = grafica[ciudad_1,ciudad_2]
        suma = suma + cost
    end
    suma = suma/Norm
    return suma
end

"Funcion que calcula el nuevo costo dada una permutacion
#Arguments
- costo_actual:: Double: Representa el costo de la ruta sin la costo_permutacion
- ruta::Array{Float64,1}: Representa la ruta sin costo_permutacion
- v_1::Integer: El primer vertice que se va a permutar
- v_2::Integer: El segundo vertice a permutar
- norm::Float: El normalizador"
function costo_permutacion(costo_actual, ruta_1, v_1, v_2)
    suma = costo_actual*Norm
    length = size(ruta_1)[1]
    ruta = permuta(copy(ruta_1),v_1,v_2)
    indice_v_1 = Base_Datos.find_id(ruta_1,v_1)
    indice_v_2 = Base_Datos.find_id(ruta_1,v_2)
    if indice_v_1 == length #v_1 esta en el extremo
        suma = suma - grafica[v_1,ruta[indice_v_1-1]] + grafica[v_2,ruta[indice_v_1-1]] #permutamos el extremo
        if indice_v_2 == 1
            suma = suma - grafica[v_2,ruta[indice_v_2+1]] + grafica[v_1,ruta[indice_v_2+1]] #permutamos el extremo
        else
            suma = suma - grafica[v_2,ruta[indice_v_2+1]] - grafica[v_2,ruta[indice_v_2-1]]
            suma = suma + grafica[v_1,ruta[indice_v_2+1]] + grafica[v_1,ruta[indice_v_2-1]]
        end
        return suma/Norm
    end
    if indice_v_2 == length #v_2 esta en el extremo
        suma = suma - grafica[v_2,ruta[indice_v_2-1]] + grafica[v_1,ruta[indice_v_2-1]] #permutamos el extremo
        if indice_v_1 == 1
            suma = suma - grafica[v_1,ruta[indice_v_1+1]] + grafica[v_2,ruta[indice_v_1+1]] #permutamos el extremo
        else
            suma = suma - grafica[v_1,ruta[indice_v_1+1]] - grafica[v_1,ruta[indice_v_1-1]]
            suma = suma + grafica[v_2,ruta[indice_v_1+1]] + grafica[v_2,ruta[indice_v_1-1]]
        end
        return suma/Norm
    end
    if indice_v_1 == 1 #Un indice esta al inicio y el otro no esta al final
        suma = suma - grafica[v_1,ruta[indice_v_1+1]] +  grafica[v_2,ruta[indice_v_1+1]]
        suma = suma - grafica[v_2,ruta[indice_v_2+1]] - grafica[v_2,ruta[indice_v_2-1]]
        suma = suma + grafica[v_1,ruta[indice_v_2+1]] + grafica[v_1,ruta[indice_v_2-1]]
        return suma/Norm
    end
    if indice_v_2 == 1 #Un indice esta al inicio y el otro no esta al final
        suma = suma - grafica[v_2,ruta[indice_v_2+1]] +  grafica[v_1,ruta[indice_v_2+1]]
        suma = suma - grafica[v_1,ruta[indice_v_1+1]] - grafica[v_1,ruta[indice_v_1-1]]
        suma = suma + grafica[v_2,ruta[indice_v_1+1]] + grafica[v_2,ruta[indice_v_1-1]]#REVISAAAR, no funciona porque se suman consigo mismos, dado que no cambio de posicion, si son contiguos se suman con su vecino que son ellos mismos
        return suma/Norm
    end
    suma = suma - grafica[v_1,ruta[indice_v_1+1]] - grafica[v_1,ruta[indice_v_1-1]]
    suma = suma - grafica[v_2,ruta[indice_v_2+1]] - grafica[v_2,ruta[indice_v_2-1]]
    suma = suma + grafica[v_1,ruta[indice_v_2+1]] + grafica[v_1,ruta[indice_v_2-1]]
    suma = suma + grafica[v_2,ruta[indice_v_1+1]] + grafica[v_2,ruta[indice_v_1-1]]#REVISAAAR
    suma = suma/Norm
    return suma
end

"Funcion que permuta dos ciudades en una ruta, modifica la ruta original
#Arguments
- ruta:: Array{Int64,1}: Ruta original para permutar
- v_1:: Int64: Primer vertice a permutar
- v_2:: Int64: Segundo vertice a permutar"
function permuta(ruta, v_1, v_2)
    indice_v_1 = Base_Datos.find_id(ruta,v_1)
    indice_v_2 = Base_Datos.find_id(ruta,v_2)
    ruta[indice_v_1] = v_2
    ruta[indice_v_2] = v_1
    return ruta
end

"Funcion que obtiene una permutacion aleatoria usando la grafica
para esto usamos los id's en graica para luego despues hacer la correspondencia con
los verdaderos id's localizados en la base de datos
#Arguments
- longitud:: Int64: Longitud de la ruta"
function obten_permutacion_aleatoria(longitud,semilla)
    Random.seed!(semilla)
    ruta = sample(1:longitud, longitud, replace=false)#Obtenemos dos indices aleatorios
    return ruta
end

"Funcion que calcula el lote (soluciones aceptadas)
#Arguments
- T:: Float64: Temperatura inicial
- S:: Ruta inicial"
function calcula_lote(T, S, s_best)
    c = 0
    i = 0
    r = 0.0
    costo_i = costo(S)
    indice_metodo2 = 0
    longitud = size(ciudades_del_problema)[1]
    while c < L
        #Obtenemos una permutacion
        id_s = sample(1:longitud, 2, replace=false) #obtenemos 2 id's
        id_1 = id_s[1]
        id_2 = id_s[2]
        s_1 = permuta(copy(S),id_1,id_2)
        costo_aux = costo(s_1)
	if costo_aux < costo_i + T
            S = s_1
            c = c+1
            r = r + costo_aux
            if costo_aux < costo(s_best)#Costo de la solucion actual
                s_best = S
            end
            costo_i = costo_aux #Para no recalcular
	    i = 0
        end
        if i >= iter_max -1
    		return [-1,S, s_best]
    	end
        i += 1
    end
    return [r/L,S, s_best]
end

"Funcion que se encarga del recocido simulado
#Arguments
- T:: Float64: Temperatura inicial
- S:: Ruta inicial"
function aceptacion_por_umbrales(T,S)
    p = 0
    s_best = S
    while T > epsilon

        q = Inf
        while p <= q
            q = p
            a = calcula_lote(T, S, s_best)
            p = a[1]
            S = a[2]
            if costo(a[3]) < costo(s_best)
                s_best = a[3]
            end
        	if p < 0
        		return s_best
        	end
        end
        T = phi*T
    end
    return s_best #Regresamos la mejor solucion
end

"Funcion que calcula el porcentaje de soluciones aceptadas
#Arguments
- T:: Float64: Temperatura inicial
- S:: Ruta actual"
function porcentaje_aceptados(S,T)
    c = 0
    costo_i = costo(S)
    for i in 1:veces
        #Obtenemos una permutacion
        id_s = sample(1:size(ciudades_del_problema)[1], 2, replace=false) #obtenemos 2 id's
        id_1 = id_s[1]
        id_2 = id_s[2]
        s_1 = permuta(copy(S),id_1,id_2)
        #costo_aux = costo_permutacion(costo_i,S,id_1,id_2, normalIzador)
        costo_aux = costo(s_1)
        if costo_aux < costo_i + T
            c = c+1
            S = permuta(S,id_1,id_2)
        end
    end
    return c/veces
end

"Funcion que realiza la busqueda binaria
#Arguments
- T_1:: Float64: Temperatura inferior de la busqueda
- T_2:: Float64: Limite superior de la busqueda
- s:: Ruta actual"
function busqueda_binaria(s, T_1, T_2, P)
    T_m = (T_1 + T_2) / 2
    if T_2 - T_1 < epsilon
        return T_m
    end
    p = porcentaje_aceptados(s, T_m)
    if abs(P-p) < epsilon_p
        return T_m
    end
    if p > P
        return busqueda_binaria(s, T_1, T_m,P)
    else
        return busqueda_binaria(s, T_m, T_2,P)
    end
end

"Funcion que calcula la temperatura inicial
#Arguments
- s:: Ruta inicial
- T:: Float64: Temperatura inicial de la configuracion
- P:: Float64: Probabilidad de aceptacion"
function  temperatura_inicial(s, T, P)
    p = porcentaje_aceptados(s, T)
    if abs(P - p) <= epsilon_p
        return T
    end
    if p < P
        while p < P
            T = 2*T
            p = porcentaje_aceptados(s, T)
        end
        T_1 = T/2
        T_2 = T
    else
        while p > P
            T = T/2
            p = porcentaje_aceptados(s, T)
        end
        T_1 = T
        T_2 = 2*T
    end
    return busqueda_binaria(s, T_1, T_2, P)
end

"Funcion que nos dice si una solucion es factible
#Arguments
- costo:: Float64: Costo de la ruta obtenida"
function es_factible(costo)
    return costo < 1
end

"Funcion que toma los id's en la matriz de adyacencias y regresa los de las ciudades
#Arguments
- ciudades_del_problema:: Array{Int64,1}: Lista con las ciudades que participan en el TSP
- solucion:: Array{Int64,1}: Ruta obtenida por el algoritmo"
function pasa_a_ids_reales(ciudades_del_problema, solucion)
    length = size(solucion)[1]
    respuesta = ones(length)
    for i in 1:length
        indice = solucion[i]
        ciudad = ciudades_del_problema[indice]
        respuesta[i] = ciudad
    end
    return respuesta
end

function pasa_a_ids_fic(ciudades_del_problema, solucion)
    length = size(ciudades_del_problema)[1]
    respuesta = ones(length)
    for i in 1:length
        elemento = solucion[i]
        indice_en_lista = Base_Datos.find_id(ciudades_del_problema,elemento)
        respuesta[i] = indice_en_lista
    end
    return map(x -> trunc(Int,x),respuesta)
end

"Funcion que corre todo el algoritmo"
function haz_todo(semilla)
    #Tomando instancia
    length = size(ciudades_del_problema)[1]
    s_0 = obten_permutacion_aleatoria(length,semilla)#permutacion aleatoria
    T = temperatura_inicial(copy(s_0),T_0,P)
    solucion = aceptacion_por_umbrales(T,s_0)
    costo_f = costo(solucion)
    solucion2 = pasa_a_ids_reales(ciudades_del_problema,solucion)
    solucion2 = map(x -> trunc(Int,x),solucion2)
    return[solucion2,costo_f,es_factible(costo_f),s_0]
end

function corre_varias_veces(veces_1, random_b)
    escritura = ""
    minimo_g = Inf
    s_minima = []
    for i in 1:veces_1
        if random_b
            semilla = abs(rand(Int))
        else
            semilla = i
        end
        resp = haz_todo(semilla)
        minimo = resp[2]
        s = resp[1]
        if minimo < minimo_g
            s_minima = s
            minimo_g = minimo
        end
        if resp[3]
            escritura = string(escritura, string("costo = ",minimo," solucion = ", s, " es factible ",resp[3], " semilla = ",semilla, "\n"))
        end
        println(i)
end
    escritura = string(escritura, minimo_g)
    fecha = string("Salidas_",Dates.now(),size(ciudades_del_problema)[1],"_",veces_1)
    visualizador.grafica_ruta(s_minima,fecha)
    write(string(fecha,".txt"),escritura)
end

if size(ARGS)[1] >= 2
	if Meta.parse(ARGS[2]) == "r"
	    corre_varias_veces(Meta.parse(ARGS[1]), true) #Corre con semillas aleatorias
	else
	    if Meta.parse(ARGS[2]) == "s" && size(ARGS)[1] >=3
		haz_todo(Meta.parse(ARGS[3]))
	    else
		corre_varias_veces(Meta.parse(ARGS[1]), false)#Corre con semillas consecutivas
	    end
	end
end

end

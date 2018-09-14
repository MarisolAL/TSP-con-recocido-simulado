include("base_datos.jl")
using Base_Datos
using StatsBase

#Parte de la CONFIGURACION
ciudades_del_problema = [1,2,3,28,74,163,164,165,166,167,169,326,327,328,329,330,489,490,491,492,493,494,495,653,654,655,658,666,814,815,816,817,818,819,978,979,980,981,1037,1073]
T_0 = 100
L = 500
iter_max = 5000
epsilon = 0.1
phi = 0.5
veces = 5000
epsilon_p = 0.1
P = 0.9
#############################
N = Base_Datos.normalizador(ciudades_del_problema)
grafica = Base_Datos.crea_matriz_adyacencias(ciudades_del_problema)


"Funcion que calcula el costo de una ruta
#Arguments
- ruta:: Array{Int64,1}: Ruta a la que le obtendremos el costo
- norm:: Float64: Normalizador del problema"
function costo(ruta,norm)
    length = size(ruta)[1]
    suma = 0
    for i in 1:(length-1)
        ciudad_1 = ruta[i]
        ciudad_2 = ruta[i+1]
        cost = grafica[ciudad_1,ciudad_2]
        suma = suma + cost
    end
    suma = suma/norm
    return suma
end

"Funcion que calcula el nuevo costo dada una permutacion
#Arguments
- costo_actual:: Double: Representa el costo de la ruta sin la costo_permutacion
- ruta::Array{Float64,1}: Representa la ruta sin costo_permutacion
- v_1::Integer: El primer vertice que se va a permutar
- v_2::Integer: El segundo vertice a permutar
- norm::Float: El normalizador"
function costo_permutacion(costo_actual, ruta, v_1, v_2,norm)
    suma = costo_actual*norm
    length = size(ruta)[1]
    indice_v_1 = Base_Datos.find_id(ruta,v_1)
    indice_v_2 = Base_Datos.find_id(ruta,v_2)
    if indice_v_1 == length #v_1 esta en el extremo
        suma = suma - grafica[v_1,ruta[indice_v_1-1]] + grafica[v_2,ruta[indice_v_1-1]] #permutamos el extremo
        if indice_v_2 == 1
            suma = suma - grafica[v_2,ruta[indice_v_2+1]] + grafica[v_1,ruta[indice_v_2+1]] #permutamos el extremo
        else
            suma = suma - grafica[v_2,ruta[indice_v_2+1]] - grafica[v_2,ruta[indice_v_2-1]]
            suma = suma + grafica[v_1,ruta[indice_v_2+1]] + grafica[v_1,ruta[indice_v_2-1]]
        end
        return suma/norm
    end
    if indice_v_2 == length #v_2 esta en el extremo
        suma = suma - grafica[v_2,ruta[indice_v_2-1]] + grafica[v_1,ruta[indice_v_2-1]] #permutamos el extremo
        if indice_v_1 == 1
            suma = suma - grafica[v_1,ruta[indice_v_1+1]] + grafica[v_2,ruta[indice_v_1+1]] #permutamos el extremo
        else
            suma = suma - grafica[v_1,ruta[indice_v_1+1]] - grafica[v_1,ruta[indice_v_1-1]]
            suma = suma + grafica[v_2,ruta[indice_v_1+1]] + grafica[v_2,ruta[indice_v_1-1]]
        end
        return suma/norm
    end
    if indice_v_1 == 1 #Un indice esta al inicio y el otro no esta al final
        suma = suma - grafica[v_1,ruta[indice_v_1+1]] +  grafica[v_2,ruta[indice_v_1+1]]
        suma = suma - grafica[v_2,ruta[indice_v_2+1]] - grafica[v_2,ruta[indice_v_2-1]]
        suma = suma + grafica[v_1,ruta[indice_v_2+1]] + grafica[v_1,ruta[indice_v_2-1]]
        return suma/norm
    end
    if indice_v_2 == 1 #Un indice esta al inicio y el otro no esta al final
        suma = suma - grafica[v_2,ruta[indice_v_2+1]] +  grafica[v_1,ruta[indice_v_2+1]]
        suma = suma - grafica[v_1,ruta[indice_v_1+1]] - grafica[v_1,ruta[indice_v_1-1]]
        suma = suma + grafica[v_2,ruta[indice_v_1+1]] + grafica[v_2,ruta[indice_v_1-1]]#REVISAAAR, no funciona porque se suman consigo mismos, dado que no cambio de posicion, si son contiguos se suman con su vecino que son ellos mismos
        return suma/norm
    end
    suma = suma - grafica[v_1,ruta[indice_v_1+1]] - grafica[v_1,ruta[indice_v_1-1]]
    suma = suma - grafica[v_2,ruta[indice_v_2+1]] - grafica[v_2,ruta[indice_v_2-1]]
    suma = suma + grafica[v_1,ruta[indice_v_2+1]] + grafica[v_1,ruta[indice_v_2-1]]
    suma = suma + grafica[v_2,ruta[indice_v_1+1]] + grafica[v_2,ruta[indice_v_1-1]]#REVISAAAR
    suma = suma/norm
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
function obten_permutacion_aleatoria(longitud)
    ruta = sample(1:longitud, longitud, replace=false)#Obtenemos dos indices aleatorios
    return ruta
end

"Funcion que calcula el lote (soluciones aceptadas)
#Arguments
- T:: Float64: Temperatura inicial
- S:: Ruta inicial
- normalIzador:: Normalizador del sistema"
function calcula_lote(T, S,normalIzador)
    c = 0
    i = 0
    r = 0.0
    costo_i = costo(S,normalIzador)
    while c < L || i < iter_max
        #Obtenemos una permutacion
        id_s = sample(1:size(ciudades_del_problema)[1], 2, replace=false) #obtenemos 2 id's
        id_1 = id_s[1]
        id_2 = id_s[2]
        s_1 = permuta(copy(S),id_1,id_2)
        costo_aux = costo(s_1, normalIzador)
        if costo_aux < costo_i + T
            S = permuta(S,id_1,id_2)
            c = c+1
            r = r + costo_aux
            costo_i = costo_aux #Para no recalcular
        end
        i += 1
    end
    return [r/L,S]
end

"Funcion que se encarga del recocido simulado
#Arguments
- T:: Float64: Temperatura inicial
- S:: Ruta inicial
- normalIzador:: Normalizador del sistema"
function aceptacion_por_umbrales(T,S,normalIzador)
    p = 0
    while T > epsilon
        q = Inf
        while p <= q
            q = p
            a = calcula_lote(T, S,normalIzador)
            p = a[1]
            S = a[2]
        end
        T = phi*T
    end
    return S
end

"Funcion que calcula el porcentaje de soluciones aceptadas
#Arguments
- T:: Float64: Temperatura inicial
- S:: Ruta actual
- normalIzador:: Normalizador del sistema"
function porcentaje_aceptados(S,T,normalIzador)
    c = 0
    costo_i = costo(S,normalIzador)
    for i in 1:veces
        #Obtenemos una permutacion
        id_s = sample(1:size(ciudades_del_problema)[1], 2, replace=false) #obtenemos 2 id's
        id_1 = id_s[1]
        id_2 = id_s[2]
        s_1 = permuta(copy(S),id_1,id_2)
        costo_aux = costo(s_1, normalIzador)
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
- s:: Ruta actual
- normalIzador:: Normalizador del sistema"
function busqueda_binaria(s, T_1, T_2, P,normalIzador)
    T_m = (T_1 + T_2) / 2
    if T_2 - T_1 < epsilon
        return T_m
    end
    p = porcentaje_aceptados(s, T_m,normalIzador)
    if abs(P-p) < epsilon_p
        return T_m
    end
    if p > P
        return busqueda_binaria(s, T_1, T_m,P,normalIzador)
    else
        return busqueda_binaria(s, T_m, T_2,P,normalIzador)
    end
end

"Funcion que calcula la temperatura inicial
#Arguments
- s:: Ruta inicial
- T:: Float64: Temperatura inicial de la configuracion
- P:: Float64: Probabilidad de aceptacion
- normalIzador:: Normalizador del sistema"
function  temperatura_inicial(s, T, P,normalIzador)
    p = porcentaje_aceptados(s, T,normalIzador)
    if abs(P - p) <= epsilon_p
        return T
    end
    if p < P
        while p < P
            T = 2*T
            p = porcentaje_aceptados(s, T,normalIzador)
        end
        T_1 = T/2
        T_2 = T
    else
        while p > P
            T = T/2
            p = porcentaje_aceptados(s, T,normalIzador)
        end
        T_1 = T
        T_2 = 2*T
    end
    return busqueda_binaria(s, T_1, T_2, P,normalIzador)
end

"Funcion que nos dice si una solucion es factible
#Arguments
- costo:: Float64: Costo de la ruta obtenida
- normalIzador:: Float64: Normalizador del sistema"
function es_factible(costo, normalIzador)
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

"Funcion que corre todo el algoritmo"
function haz_todo(normalIzador)
    #Tomando instancia
    length = size(ciudades_del_problema)[1]
    s_0 = obten_permutacion_aleatoria(length)#permutacion aleatoria
    T = temperatura_inicial(copy(s_0),T_0,P,normalIzador)
    solucion = aceptacion_por_umbrales(T,s_0,normalIzador)
    solucion2 = pasa_a_ids_reales(ciudades_del_problema,solucion)
    costo_f = costo(solucion, normalIzador)
    return[solucion2,costo_f,es_factible(costo_f,normalIzador)]
end

resp = haz_todo(N)
minimo = resp[2]
s = resp[1]
println(minimo)
println(s)
println(resp[3])

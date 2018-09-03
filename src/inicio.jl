using SQLite
using StatsBase

base_datos = SQLite.DB("ciudades.db")
ciudadesdb = SQLite.query(base_datos, "SELECT * FROM cities")

#Para hacer el normalizador
#Primero obtenemos las n ciudades iniciales
no_ciudades = 40 #Este es parte de la configuracion
total_ciudades = SQLite.query(base_datos, "SELECT COUNT(*) FROM cities")
no_total_ciudades = first(convert(Array,total_ciudades))

"Funcion que regresa un arreglo con los id's de las ciudades
propuestas para el tsp
#Arguments
- no_ciudades:: Integer: El numero de ciudades que participaran en el algoritmo
- no_total_ciudades::Integer: El numero total de ciudades que tenemos en la base de datos"
function get_ciudades(no_ciudades, no_total_ciudades)
    id_s = sample(1:no_total_ciudades, no_ciudades, replace=false)
    return id_s
end

ciudades_del_problema = get_ciudades(no_ciudades, no_total_ciudades)

#Funcion que regresa una tabla con las ciudades que utilizaremos
#esta es una subtabla de la tabla original de connections
#Recibe la lista con los id's de las ciudades
function get_tabla_min(lista_ciudades)
    id_s = strip(string(lista_ciudades), ['[',']','(',')','{','}'])
    consulta  = string("SELECT * FROM connections where id_city_1 in (", id_s , ") and id_city_2 in (" , id_s,")")
    conexiones_db = SQLite.query(base_datos, consulta)
    return conexiones_db
end

"Funcion que obtiene el normalizador dados los id's de las ciudades."
function normalizador(ciudades_del_problema)
    id_s = strip(string(ciudades_del_problema), ['[',']','(',')','{','}'])
    n = size(ciudades_del_problema,1)
    consulta = string(" SELECT sum(distance) FROM connections where id_city_1 in (",id_s,") and id_city_2 in (",id_s,") order by distance desc limit ",n)
    suma_c = SQLite.query(base_datos,consulta)
    suma = first(convert(Array,suma_c))
    return suma
end

"Funcion que devuelve el indice en la lista"
function find_id(lista, id)
    n = size(lista,1)
    for i in 1:n
        if lista[i] == id
            return i
        end
    end
    return -1
end

"Funcion que calcula la distancia natural entre dos ciudades usando sus id's"
function distancia_natural(citi_1, citi_2)
    #Obtenemos las latitudes y longitudes
    consulta_lat = string("SELECT latitude  FROM cities  where id == ",citi_1,";")
    consulta_long = string("SELECT longitude  FROM cities  where id == ",citi_1,";")
    lat_1 = first(convert(Array, SQLite.query(base_datos,consulta_lat)))
    long_1 = first(convert(Array, SQLite.query(base_datos,consulta_long)))
    consulta_lat = string("SELECT latitude  FROM cities  where id == ",citi_2,";")
    consulta_long = string("SELECT longitude  FROM cities  where id == ",citi_2,";")
    lat_2 = first(convert(Array, SQLite.query(base_datos,consulta_lat)))
    long_2 = first(convert(Array, SQLite.query(base_datos,consulta_long)))
    #Pasando las coordenadas a radianes
    lat_1 = (lat_1*pi)/180
    lat_2 = (lat_2*pi)/180
    long_1 = (long_1*pi)/180
    long_2 = (long_2*pi)/180
    #Obtenemos la distancia distancia natural
    A = sin((lat_2-lat_1)/2)^2 + (cos(lat_1)*cos(lat_2)*(sin((long_2-long_1)/2)^2))
    C = 2*atan2(A^0.5,(1-A)^0.5)#REVISAAAR
    distancia = 6373000*C
    return distancia
end

#println(distancia_natural(2,9))

"Funcion que crea la matriz de adyacencias con los pesos entre las ciudades, en caso de no haber arista la funcion
calcula la distancia natural y multiplica por el normalizador, a la arista con el mismo vertice se le asigna un 0"
function crea_matriz_adyacencias(ciudades_del_problema)
        norm = normalizador(ciudades_del_problema)
        entorno = get_tabla_min(ciudades_del_problema)
        m = size(entorno)[1]
        n = size(ciudades_del_problema,1)
        matriz = ones(n,n)
        fill!(matriz,0.1)
        for i in 1:m
            id1 = find_id(ciudades_del_problema, entorno[1][i])
            id2 = find_id(ciudades_del_problema, entorno[2][i])
            distancia = entorno[3][i]
            matriz[id1, id2] = distancia
            matriz[id2, id1] = distancia
        end
        #Matriz llena con distancias de la bd
        for i in 1:n
            for j in 1:n
                if matriz[i,j] == 0.1
                    matriz[i,j] = distancia_natural(ciudades_del_problema[i],ciudades_del_problema[j])*norm
                end
                if i == j
                    matriz[i,j] = 0
                end
            end
        end
        return matriz
end
ciudades_del_problema = [1,2,3,4,5,6,7,8,9,10,11,12]
grafica = crea_matriz_adyacencias(ciudades_del_problema)
ruta_1 = [1,3,6,9,2,12]

"Funcion que calcula el costo de una ruta"
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
    indice_v_1 = find_id(ruta,v_1)
    indice_v_2 = find_id(ruta,v_2)
    if indice_v_1 < length && indice_v_2 < length && indice_v_1 > 0 && indice_v_2 > 0  #Caso facil
        suma = suma - grafica[v_1,ruta[indice_v_1+1]] - grafica[v_1,ruta[indice_v_1-1]]
        suma = suma - grafica[v_2,ruta[indice_v_2+1]] - grafica[v_2,ruta[indice_v_2-1]]
        suma = suma + grafica[v_1,ruta[indice_v_2+1]] + grafica[v_1,ruta[indice_v_2-1]]
        suma = suma + grafica[v_2,ruta[indice_v_1+1]] + grafica[v_2,ruta[indice_v_1-1]]
    end
    if indice_v_1 == length #v_1 esta en el extremo
        suma = suma - grafica[v_1,ruta[indice_v_1-1]] + grafica[v_2,ruta[indice_v_1-1]] #permutamos el extremo
        if indice_v_2 == 0
            suma = suma - grafica[v_2,ruta[indice_v_2+1]] + grafica[v_1,ruta[indice_v_2+1]] #permutamos el extremo
        else
            suma = suma - grafica[v_2,ruta[indice_v_2+1]] - grafica[v_2,ruta[indice_v_2-1]]
            suma = suma + grafica[v_1,ruta[indice_v_2+1]] + grafica[v_1,ruta[indice_v_2-1]]
        end
    end
    if indice_v_2 == length #v_2 esta en el extremo
        suma = suma - grafica[v_2,ruta[indice_v_2-1]] + grafica[v_1,ruta[indice_v_2-1]] #permutamos el extremo
        if indice_v_1 == 0
            suma = suma - grafica[v_1,ruta[indice_v_1+1]] + grafica[v_2,ruta[indice_v_1+1]] #permutamos el extremo
        else
            suma = suma - grafica[v_1,ruta[indice_v_1+1]] - grafica[v_1,ruta[indice_v_1-1]]
            suma = suma + grafica[v_2,ruta[indice_v_1+1]] + grafica[v_2,ruta[indice_v_1-1]]
        end
    end
    suma = suma/norm
    return suma
end

#--------------------------------------------
#Empezando recocido simulado

T_0 = 50 #Esto pertenece a la configuracion
num = rand(1:size(ciudades_del_problema)[1])
S_0 = ciudades_del_problema[num] #Esta es la solucion inicial (puede pertenecer a la configuracion)
L = 50 #Esto pertenece a la configuracion
iter_max = 5000 #Esto pertenece a la configuracion
normalIzador = normalizador(ciudades_del_problema)#####
epsilon = 0.1 #Pertenece a archivo de configuracion
phi = 0.5 #Pertenece a archivo de configuracion
N = 500 #configuracion
epsilon_p = 0.1 #configuracion
epsilon_t = 0.1 #configuracion

"Funcion que permuta dos ciudades en una ruta"
function permuta(ruta, v_1, v_2)
    ruta_nva = ruta
    indice_v_1 = find_id(ruta_nva,v_1)
    indice_v_2 = find_id(ruta_nva,v_2)
    ruta_nva[indice_v_1] = v_2
    ruta_nva[indice_v_2] = v_1
    return ruta_nva
end

"Funcion que calcula el lote (soluciones aceptadas)"
function calcula_lote(T, S)
    c = 0
    i = 0
    r = 0.0
    costo_i = costo(S)
    while c < L or i < iter_max
        #Obtenemos una permutacion
        id_s = sample(1:size(ciudades_del_problema)[1], 2, replace=false) #obtenemos 2 id's
        id_1 = id_s[1]
        id_2 = id_s[2]
        costo_aux = costo_permutacion(costo_i ,S, id_1, id_2, normalIzador)
        if costo_aux < costo_i + T
            S = permuta(S,id_1,id_2)
            c = c+1
            r = r + costo_aux
            costo_i = costo_aux #Para no recalcular
        end
    end
    return [r/L,S]
end



"Funcion que se encarga del recocido simulado"
function aceptacion_por_umbrales(T,S)
    p = 0
    while T > epsilon
        q = Inf
        while p <= q
            q = p
            a = calcula_lote(T, S)
            p = a[1]
            s = a[2]
        end
        T = phi*T
    end
end

#-------------------------


"Funcion que calcula el porcentaje de soluciones aceptadas"
function porcentaje_aceptados(s,T)
    c = 0
    costo_i = costo(s)
    for i in 1:N
        #Obtenemos una permutacion
        id_s = sample(1:size(ciudades_del_problema)[1], 2, replace=false) #obtenemos 2 id's
        id_1 = id_s[1]
        id_2 = id_s[2]
        costo_aux = costo_permutacion(costo_i ,s, id_1, id_2, normalIzador)
        if costo_aux < costo_i + T
            c = c+1
            s = permuta(s,id_1,id_2)
        end
    end
    return c/N
end

"Funcion que realiza la busqueda binaria"
function busqueda_binaria(s, T_1, T_2, P)
    T_m = (T_1 + T_2) / 2
    if T_2 - T_1 < epsilon_t
        return T_m
    end
    p = porcentaje_aceptados(s, T_m)
    if abs(P-p) < epsilon_p
        return T_m
    end
    if p > P
        return busqueda_binaria(s, T_1, T_m)
    else
        return busqueda_binaria(s, T_m, T_2)
    end
end

"Funcion que calcula la temperatura inicial"
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

"Funcion que nos dice si una solucion es factible"
function es_factible(costo, normalizador)
    return costo > normalizador
end

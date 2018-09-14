#Modulo que se encargara del manejo con la base de datos
module Base_Datos

using SQLite
using StatsBase

base_datos = SQLite.DB("ciudades.db")

"Funcion que regresa una tabla con las ciudades que utilizaremos esta es
una subtabla de la tabla original de connections
#Arguments
- lista_ciudades:: Array{Int64,1}: Lista con los id's de las ciudades"
function get_tabla_min(lista_ciudades)
    id_s = strip(string(lista_ciudades), ['[',']','(',')','{','}'])
    consulta  = string("SELECT * FROM connections where id_city_1 in (", id_s , ") and id_city_2 in (" , id_s,")")
    conexiones_db = SQLite.query(base_datos, consulta)
    return conexiones_db
end

"Funcion que obtiene el normalizador dados los id's de las ciudades.
#Arguments
- ciudades_del_problema:: Array{Int64,1}: Lista con los id's de las ciudades que participaran en el TSP"
function normalizador(ciudades_del_problema)
    id_s = strip(string(ciudades_del_problema), ['[',']','(',')','{','}'])
    n = size(ciudades_del_problema,1)
    consulta = string("select sum(distance) from (select * from connections where id_city_1 in (",id_s,") and id_city_2 in (",id_s,") order by distance desc limit ", n-1, ")")
    suma_c = SQLite.query(base_datos,consulta)
    suma = first(convert(Array,suma_c))
    return suma
end

"Funcion que calcula la distancia natural entre dos ciudades usando sus id's en la base de datos
#Arguments
- citi_1:: Int64: Id de la primera ciudad
- citi_2:: Int64: Id de la segunda ciudad"
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

"Funcion que devuelve el indice en la lista del objeto obj
#Arguments
- lista:: Array{Any, 1}: Lista sobre la cual buscaremos el objeto
- obj:: Any: Objeto que buscamos en la lista"
function find_id(lista, obj)
    n = size(lista,1)
    for i in 1:n
        if lista[i] == obj
            return i
        end
    end
    return -1
end

"Funcion que crea la matriz de adyacencias con los pesos entre las ciudades, en caso de no haber arista la funcion
calcula la distancia natural y multiplica por el normalizador, a la arista con el mismo vertice se le asigna un 0
#Arguments
- ciudades_del_problema:: Array{Int64,1}: Lista con los id's de las ciudades que participan en el TSP"
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


end

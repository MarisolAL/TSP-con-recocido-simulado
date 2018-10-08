module visualizador

include("base_datos.jl")
using PyPlot
"Funcion que dada una lista de id's grafica los puntos
usando la latitud y longitud obtenidas de la base de datos
# Arguments
- id_s:: Array{Int64,1}: Arreglo con los id's de las ciudades que
queremos graficar"
function grafica_ruta(id_s)
    PyPlot.svg(true)
    len = size(id_s)[1]
    x = ones(len)
    y = ones(len)
    for i in 1:len
        coordenadas = Base_Datos.get_lat_longitud(id_s[i])
        x[i] = coordenadas[2][1]
        y[i] = coordenadas[1][1]
    end
    #fig = figure(string("Grafica de la ruta ",id_s),figsize=(300,300))
    plot(x, y, color="blue", linewidth=1.1, linestyle="-")
    title(string("Grafica de la ruta ",id_s))
    savefig(string("Grafica de la ruta ",id_s))
end

end

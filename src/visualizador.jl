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
    coordenadas = Base_Datos.get_lat_longitud(id_s)
    x = coordenadas[2]
    y = coordenadas[1]
    #fig = figure(string("Grafica de la ruta ",id_s),figsize=(300,300))
    plot(x, y, color="blue", linewidth=1.2, linestyle="--")
    title(string("Grafica de la ruta ",id_s))
    savefig(string("Grafica de la ruta ",id_s))
end

end

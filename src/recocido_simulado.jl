include("base_datos.jl")
using Base_Datos

#Parte de la configuracion
ciudades_del_problema = [1,2,3,28,74,163,164,165,166,167,169,326,327,328,329,330,489,490,491,492,493,494,495,653,654,655,658,666,814,815,816,817,818,819,978,979,980,981,1037,1073]
N = Base_Datos.normalizador(ciudades_del_problema)

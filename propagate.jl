include("leer_eof.jl")


if(length(ARGS) == 0)
	println(" Error... requiere input de archivo. ")
	exit(-1)
end

archivo_de_entrada = ARGS[1]
println("archivo de entrada: $(archivo_de_entrada)")
archivo_de_salida = replace(archivo_de_entrada, ".EOF" => ".PRED")

println("archivo de salida : $(archivo_de_salida)")


t, Z = leer_eof(archivo_de_entrada)

println("t = $(t)")
println("Z = $(Z)")



Mt = 5.972e24  # kg
G = 6.67408e-11 #m3 kg-1 s-2
ω_T = -7.2921150e-5  # radians/s

z0 = Z[:,1]
Nt = 9000
dt = 10.

# println("dt = $(archivo_de_salida = replace(archivo_de_entrada, ".EOF" => ".PRED")dt)")
archivo_de_salida = replace(archivo_de_entrada, ".EOF" => ".PRED")
function zpunto(t,z)
	#Calculo FgTierra
	x = z[1:3]
	xp = z[4:6]
	coseno = cos.(ωt*t[1])
	seno = sin.(ωt*t[1])

	T = [coseno seno 0; -seno coseno 0; 0 0 1]
	Tp = ωt*[-seno coseno 0; -coseno -seno 0; 0 0 0]
	Tpp = ωt^2*[-coseno seno 0; seno -coseno 0; 0 0 0]

	r = sqrt(x'*x)
	rnorm = T*x / r

	Fg = -T'*(G*Mt/r^2 *rnorm + Tpp*x + 2*Tp*xp)
	#Calculo Fgsol
	s = [150000000000.,0.,0.]
	xs = x-s
	rs = sqrt(xs'*xs)
	rsnorm = x/rs
        Fsol = G*Ms/rs^2*rsnorm
	
	zp = zeros(6)
	zp[1:3] = xp
	zp[4:6] = Fg+Fsol
	return zp
end



tiempo = zeros(Nt)

z = zeros(6,Nt)
z[:,1] = z0
tiempo[1] = t[1]

NSubSteps = 200

dt_sub = dt / NSubSteps


#Metodo de Ralston

for i in 2:(Nt)
	zsub = z[:,i-1]
	for substep in 1: NSubSteps
		k1 = zpunto(t[i],zsub)
		k2 = zpunto(t[i] + dt_sub*0.75, zsub +dt_sub*0.75*k1)
		zsub = zsub + dt_sub*(k1/3+2*k2/3)
	end
	z[:,i] = zsub
	
end




# Escribir el XML de salida

using LightXML 
import Dates

# create an empty XML document
xdoc = XMLDocument()

# create & attach a root node
xroot = create_root(xdoc, "Earth_Explorer_File")

# create the first child
xs1 = new_child(xroot, "Data_Block")
set_attribute(xs1, "type", "xml")


xs2 = new_child(xs1, "List_of_OSVs")
set_attribute(xs2, "count", "$(Nt)")


for i in 1:Nt

	t_datetime = Dates.unix2datetime(tiempo[i])
	t_utc = Dates.format(t_datetime, "yyyy-mm-ddTHH:MM:SS.ssssss")
	
	# println("t_utc = $(t_utc)")

	# utc_string = content(XMLElement(osv)["UTC"][1])
	# println(utc_string[5:end])
	# utc_time = Dates.DateTime(utc_string[5:end], "yyyy-mm-ddTHH:MM:SS.ssssss")
	# t[po/s] = Dates.datetime2unix(utc_time)

	xs3 = new_child(xs2, "OSV")
	xs4 = new_child(xs3, "UTC")
	add_text(xs4, "UTC=$(t_utc)")

    xs4 = new_child(xs3, "X")
	set_attribute(xs4, "unit", "m")
	add_text(xs4, "$(z[1,i])")

    xs4 = new_child(xs3, "Y")
	set_attribute(xs4, "unit", "m")
	add_text(xs4, "$(z[2,i])")

	xs4 = new_child(xs3, "Z")
	set_attribute(xs4, "unit", "m")
	add_text(xs4, "$(z[3,i])")

	xs4 = new_child(xs3, "VX")
	set_attribute(xs4, "unit", "m/s")
	add_text(xs4, "$(z[4,i])")

    xs4 = new_child(xs3, "VY")
	set_attribute(xs4, "unit", "m/s")
	add_text(xs4, "$(z[5,i])")

	xs4 = new_child(xs3, "VZ")
	set_attribute(xs4, "unit", "m/s")
	add_text(xs4, "$(z[6,i])")

end



# save to an XML file
save_file(xdoc, archivo_de_salida)
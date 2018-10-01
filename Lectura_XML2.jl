using LightXML
using Dates


#Lectura de archivo XML
filename =  "/home/joaquin/Documents/MCO/S1B_OPER_AUX_POEORB_OPOD_20180904T110615_V20180814T225942_20180816T005942.EOF"
xdoc_in = parse_file(filename)

Earth_Explorer_File = root(xdoc_in) #El archivo completo
println(name(Earth_Explorer_File)) 

#LAS 2 MAYORES
Earth_Explorer_Header = Earth_Explorer_File["Earth_Explorer_Header"][1]
Data_Block = Earth_Explorer_File["Data_Block"][1]

List_of_OSVs = Data_Block["List_of_OSVs"][1]
println(name(Earth_Explorer_Header))
println(name(List_of_OSVs))

Nt_texto = attribute(List_of_OSVs, "count")
Nt = parse(Int32, Nt_texto)

println("Nt  = $(Nt)")

Z = zeros(6,Nt)
t = zeros(Nt)      
i = 1

for hijo in child_nodes(List_of_OSVs)
	global i 

	if is_elementnode(hijo)
		nombre = name(hijo)
 
		if nombre == "OSV"
			utc_texto = content(XMLElement(hijo)["UTC"][1])
			utc_time = Dates.DateTime(utc_texto[5:end], "yyyy-mm-ddTHH:MM:SS.ssssss")
			UnixTime = Dates.datetime2unix(DateTime(utc_time))
			#println("i = $(i) utc_texto = $(utc_texto) UnixTime = $(UnixTime)")
			t[i] = UnixTime
			Z[1,i] = parse(Float64,content(XMLElement(hijo)["X"][1]))
			Z[2,i] = parse(Float64,content(XMLElement(hijo)["Y"][1]))
			Z[3,i] = parse(Float64,content(XMLElement(hijo)["Z"][1]))
			Z[4,i] = parse(Float64,content(XMLElement(hijo)["VX"][1]))
			Z[5,i] = parse(Float64,content(XMLElement(hijo)["VY"][1]))
			Z[6,i] = parse(Float64,content(XMLElement(hijo)["VZ"][1]))
			i += 1
		end
	end
end

#println(Z)

#Aqui comienza la simulacion de la orbita
Mt = 5.97219e24 # Masa tierra en Kg

G = 6.67408e-11 # Constante de gravitacion en m3 kg-1 s-2
ωt = -7.2921159e-5 # Velocidad angular de la tierra en rad s-1
Ml = 7.349e22 #Kg luna
mt = 5.972e24 #kg tierra
Ms = 1.989e30 #Kg sol
dt = 10

z0 = [Z[1,1],Z[1,2],Z[1,3],Z[1,4],Z[1,5],Z[1,6]]
println([Z[1,end],Z[2,end],Z[3,end],Z[4,end],Z[5,end],Z[6,end]])
z =zeros(6,Nt)
z1 =zeros(6,Nt)
z2 =zeros(6,Nt)
#Ecuacion de movimiento
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

z[:,1] = z0
NSubSteps = 100 #Mientras mayor, es mas preciso
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
println("runge kutta prden 2: $(z[:,end])")

##=#
xdoc_in = XMLDocument()
xroot = create_root(xdoc_in,"Earth_Explorer_File")


xs1 = new_child(xroot, "Data_Block")
set_attribute(xs1, "type", "XML")


xs2 = new_child(xs1, "List_of_OSVs")
set_attribute(xs2, "count", "$(Nt)")


for i in 1:Nt 

	t_datetime = Dates.unix2datetime(t[i])
	t_utc = Dates.format(t_datetime, "yyyy-mm-ddTHH:MM:SS.ssssss")

	xs3 = new_child(xs2, "OSV")
	xs4 = new_child(xs3, "UTC")
	add_text(xs4,"UTC = $(t_utc)") 

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
save_file(xdoc_in, "orbitafinal.xml")

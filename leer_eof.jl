using LightXML
using Dates
filename="S1A_OPER_AUX_POEORB_OPOD_20180904T120748_V20180814T225942_20180816T005942.EOF"

function leer_eof(file_name)

    xdoc_in=parse_file(file_name)

    # parse ex1.xml:
    # xdoc is an instance of XMLDocument, which maintains a tree structure


    # get the root element
    xroot = root(xdoc_in)  # an instance of XMLElement
    # print its name
    # println(name(xroot))  # this should print: bookstore
    dataBlock=xroot["Data_Block"]
    listOSV=dataBlock[1]["List_of_OSVs"]
    Count=parse(Int32,attribute(listOSV[1],"count"))
    t=zeros(Count)
    Z=zeros(6,Count)
    println("Count = $(Count)")

    i=1
    for el in child_nodes(listOSV[1])
        if is_elementnode(el)
            utc=content(XMLElement(el)["UTC"][1])
            # println(utc)
            utcTiempo=Dates.DateTime(utc[5:end], "yyyy-mm-ddTHH:MM:SS.ssssss")
            t[i]=Dates.datetime2unix(utcTiempo)
            Z[1,i] = parse(Float64,content(XMLElement(el)["X"][1]))
            Z[2,i] = parse(Float64,content(XMLElement(el)["Y"][1]))
            Z[3,i] = parse(Float64,content(XMLElement(el)["Z"][1]))
            Z[4,i] = parse(Float64,content(XMLElement(el)["VX"][1]))
            Z[5,i] = parse(Float64,content(XMLElement(el)["VY"][1]))
            Z[6,i] = parse(Float64,content(XMLElement(el)["VZ"][1]))
            i+=1
        end
    end
    free(xdoc_in) 
    println("Listo")
    return t,Z
end
display(leer_eof(filename))
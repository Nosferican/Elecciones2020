using WebDriver
using WebDriver: HTTP.request, URI
using Base64: base64decode
using CSV, DataFrames
using Cascadia: parsehtml, Selector, nodeText, Gumbo.HTMLDocument, getattr
using Unicode: normalize

navigate!(session, "https://wikipedia.org")
# url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es")
url = URI(scheme = "http", host = "elecciones2020.ceepur.org")
# url = URI(scheme = "http", host = "elecciones2020.ceepur.org")
wd = RemoteWebDriver(Capabilities("chrome"))
session = Session(wd)
navigate!(session, string(url))
element = Element(session, "xpath", "/html/body/table[2]/tbody/tr[3]/td[2]/a")
click!(element)
current_url(session)

# GOBERNADOR

url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es/default/GOBERNADOR_Precintos.xml")
navigate!(session, string(url))
# By precinct
element = Element(session, "css selector", "#container > nav > ul > li:nth-child(1) > ul > li:nth-child(7) > a")
click!(element)
# Order by ballot order
element = Element(session, "css selector", "#sortOptions")
click!(element)
element = Element(session, "css selector", "#sortOptions > option:nth-child(2)")
click!(element)
# Get source
write(joinpath("data", "byprecinct", "GOBERNADOR.html"), source(session))

# Comisionado Residente
url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es/default_list/COMISIONADO_RESIDENTE_Precintos.xml")
navigate!(session, string(url))
# By precinct
element = Element(session, "css selector", "#container > nav > ul > li:nth-child(1) > ul > li:nth-child(7) > a")
click!(element)
# Order by ballot order
element = Element(session, "css selector", "#sortOptions")
click!(element)
element = Element(session, "css selector", "#sortOptions > option:nth-child(2)")
click!(element)
# Get source
write(joinpath("data", "byprecinct", "COMISIONADO_RESIDENTE.html"), source(session))

# REPRESENTANTES_POR_DISTRITO
url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es/default_list/REPRESENTANTES_POR_DISTRITO_Precintos.xml")
navigate!(session, string(url))
# Order by ballot order
element = Element(session, "css selector", "#sortOptions")
click!(element)
element = Element(session, "css selector", "#sortOptions > option:nth-child(2)")
click!(element)
# Get source
write(joinpath("data", "byprecinct", "REPRESENTANTES_POR_DISTRITO.html"), source(session))

# SENADORES_POR_DISTRITO
url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es/default_list/SENADORES_POR_DISTRITO_Precintos.xml")
navigate!(session, string(url))
# Order by ballot order
element = Element(session, "css selector", "#sortOptions")
click!(element)
element = Element(session, "css selector", "#sortOptions > option:nth-child(2)")
click!(element)
# Get source
write(joinpath("data", "byprecinct", "SENADORES_POR_DISTRITO.html"), source(session))

# REPRESENTANTES_POR_ACUMULACION
url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es/default_list/REPRESENTANTES_POR_ACUMULACION_Precintos.xml")
navigate!(session, string(url))
# Order by ballot order
element = Element(session, "css selector", "#sortOptions")
click!(element)
element = Element(session, "css selector", "#sortOptions > option:nth-child(2)")
click!(element)
# Get source
write(joinpath("data", "byprecinct", "REPRESENTANTES_POR_ACUMULACION.html"), source(session))

# SENADORES_POR_ACUMULACION
url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es/default_list/SENADORES_POR_ACUMULACION_Precintos.xml")
navigate!(session, string(url))
# Order by ballot order
element = Element(session, "css selector", "#sortOptions")
click!(element)
element = Element(session, "css selector", "#sortOptions > option:nth-child(2)")
click!(element)
# Get source
write(joinpath("data", "byprecinct", "SENADORES_POR_ACUMULACION.html"), source(session))

# ALCALDES
url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es/default_list/ALCALDES_Precintos.xml")
navigate!(session, string(url))
# Order by ballot order
element = Element(session, "css selector", "#sortOptions")
click!(element)
element = Element(session, "css selector", "#sortOptions > option:nth-child(2)")
click!(element)
# Get source
write(joinpath("data", "byprecinct", "ALCALDES.html"), source(session))

# LEGISLADORES_MUNICIPALES
url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es/default_list/LEGISLADORES_MUNICIPALES_Municipios.xml")
navigate!(session, string(url))
# Order by ballot order
element = Element(session, "css selector", "#sortOptions")
click!(element)
element = Element(session, "css selector", "#sortOptions > option:nth-child(2)")
click!(element)
# Get source
write(joinpath("data", "byprecinct", "LEGISLADORES_MUNICIPALES.html"), source(session))

files = filter!(x -> endswith(x, ".html"), readdir(joinpath("data", "byprecinct")))

# GOBERNADOR
html = parsehtml(String(read(joinpath("data", "byprecinct", "GOBERNADOR.html"))))
html = @view(eachmatch(Selector(".default-list > table"), html.root)[2:end])


"""
    parse_precinct(report::AbstractString)
"""
function parse_precinct(report::AbstractString)
    html = parsehtml(String(read(joinpath("data", "byprecinct", report))))
    html = @view(eachmatch(Selector(".default-list > table"), html.root)[2:end])
    data = DataFrame(contienda = String[], precinto = Int[],
                     partido = String[], posición_en_papeleta = Int[], candidato = String[], votos = Int[])
    for elem in html
        elem = elem[1]
        metadata = getattr(elem[1][1][1], "data-xml", nothing)
        contienda = match(r"[\p{Lu}_]+(?=_\p{Lu}\p{L})", metadata).match
        precinto = parse(Int, match(r"\d+(?=\.xml)", metadata).match)
        posición_en_papeleta = 0
        partido = ""
        for elem in @view(elem.children[2:end - 1])
            partido_de_candidato = nodeText(elem[1])
            if partido_de_candidato ≠ partido
                posición_en_papeleta = 1
                partido = partido_de_candidato
            else
                posición_en_papeleta += 1
            end
            partido = partido_de_candidato
            candidato = nodeText(elem[2])
            votos = parse(Int, replace(nodeText(elem[3]), "," => ""))
            push!(data, (;contienda, precinto, partido, posición_en_papeleta, candidato, votos))
        end
    end
    data
end
resultados_por_precinto = DataFrame(contienda = String[], precinto = Int[],
                                    partido = String[], posición_en_papeleta = Int[], candidato = String[], votos = Int[])
for report in filter(!isequal("LEGISLADORES_MUNICIPALES.html"), files)
    append!(resultados_por_precinto, parse_precinct(report))
end

resultados_por_precinto[(resultados_por_precinto[!,:contienda] .== "ALCALDES"),:]

# chk = parse_precinct(files[4])

unique(resultados_por_precinto[!,:contienda])

"""
    parse_councilperson(report::AbstractString)
"""
function parse_councilperson(report::AbstractString)
    # report = files[4]
    html = parsehtml(String(read(joinpath("data", "byprecinct", report))))
    html = @view(eachmatch(Selector(".default-list > table"), html.root)[2:end])
    data = DataFrame(contienda = String[], municipio = String[],
                     partido = String[], posición_en_papeleta = Int[], candidato = String[], votos = Int[])
    for elem in html
        # elem = html[1]
        elem = elem[1]
        metadata = getattr(elem[1][1][1], "data-xml", nothing)
        contienda = match(r"[\p{Lu}_]+(?=_\p{Lu}\p{L})", metadata).match
        municipio = match(r"(?<=LEGISLADORES_MUNICIPALES_).*(?=\.xml)", metadata).match
        posición_en_papeleta = 0
        partido = ""
        for elem in @view(elem.children[2:end - 1])
            partido_de_candidato = nodeText(elem[1])
            if partido_de_candidato ≠ partido
                posición_en_papeleta = 1
                partido = partido_de_candidato
            else
                posición_en_papeleta += 1
            end
            partido = partido_de_candidato
            candidato = nodeText(elem[2])
            votos = parse(Int, replace(nodeText(elem[3]), "," => ""))
            push!(data, (;contienda, municipio, partido, posición_en_papeleta, candidato, votos))
        end
    end
    data
end
precintos = CSV.read(joinpath("data", "precintos.csv"), DataFrame)
precintos[!,:municipio] .= normalize.(precintos[!,:municipio], stripmark = true)
councilperson_results = parse_councilperson("LEGISLADORES_MUNICIPALES.html")
councilperson_results[!,:municipio] .= replace.(councilperson_results[!,:municipio], "_" => " ")
councilperson = leftjoin(councilperson_results[!,[:contienda,:municipio,:partido,:posición_en_papeleta,:candidato]],
                         precintos[!,[:municipio,:precinto]],
                         on = [:municipio])[!,[:contienda,:precinto,:partido,:posición_en_papeleta,:candidato]]
for_name_match = vcat(resultados_por_precinto[!,[:contienda, :precinto, :partido, :posición_en_papeleta, :candidato]],
                      councilperson)
for_name_match[!,:contienda] .= replace.(for_name_match[!,:contienda], "_" => " ")
for_name_match[!,:contienda] .= replace.(for_name_match[!,:contienda], "ACUMULACION" => "ACUMULACIÓN")
rename!(for_name_match, :candidato => :nombre_de_candidato)

councilperson_results[councilperson_results[!,:candidato] .== "Aida Ivette Rivera Torres",:]

resultados_por_precinto[(resultados_por_precinto[!,:contienda] .== "REPRESENTANTES POR ACUMULACIÓN") .&
                        (resultados_por_precinto[!,:precinto] .== 1),:]

x = html[1][1]

html[1]
html[2]
html[3]
html[4]
html[5]
html[6]
html.children[end]

votos = CSV.read(joinpath("data", "votos.csv"), DataFrame)
# names(votos)

votos_candidato = leftjoin(votos,
                           for_name_match,
                           on = [:contienda, :precinto, :partido, :posición_en_papeleta],
                           )[!,[:precinto,:unidad,:colegio,:contienda,:partido,:posición_en_papeleta,:nombre_de_candidato,:votos]]
rename!(votos_candidato, :nombre_de_candidato => :candidato)
# any(ismissing, votos_candidato.candidato)

# chk = votos_candidato[ismissing.(votos_candidato[!,:nombre_de_candidato]),:]
votos_candidato[!,:candidato] .= ifelse.(votos_candidato[!,:posición_en_papeleta] .< 1, "", votos_candidato[!,:candidato])
votos_candidato[!,:candidato] .= ifelse.(votos_candidato[!,:partido] .∈ Ref(("OTROS", "NO", "SI")), "", votos_candidato[!,:candidato])

sort!(unique!(length.(votos_candidato[!,:candidato])))

disallowmissing!(votos_candidato)

tmp = votos[,:]
tmp[(tmp[!,:posición_en_papeleta] .< 1) .& (tmp[!,:contienda] .== "GOBERNADOR"),:]

votos_candidato = vcat(votos_candidato, tmp)
replace!(votos_candidato[!,:candidato], "OTROS" => missing)
votos_candidato[!,:partido] .= ifelse.(votos_candidato[!,:posición_en_papeleta] .< 1, "", votos_candidato[!,:partido])

votos_candidato[votos_candidato[!,:partido] .== "",:]
sort!(votos_candidato)
CSV.write(joinpath("data", "votos_clean.csv"), votos_candidato)
votos = CSV.read(joinpath("data", "votos_clean.csv"), DataFrame)
votos[!,:partido] .= coalesce.(votos[!,:partido], "")

execute(conn, "BEGIN;")

execute(conn, "COMMIT;")

# Ahora con los asambleistas
votos_candidato

conn = 

unique(votos_candidato[!,[:candidato,:nombre_de_candidato]])


candidatos = votos[occursin.(r"^\p{Lu}{3}$", coalesce.(votos[!,:candidato], "")),
                   [:precinto,:contienda,:partido,:posición_en_papeleta,:candidato]]
disallowmissing!(candidatos)
unique(candidatos[!,:contienda])

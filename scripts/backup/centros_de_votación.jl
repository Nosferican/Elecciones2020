using WebDriver: URI
using PDFIO
using DataFrames
using CSV: CSV
using JSON3: JSON3

if !isfile(joinpath("data", "centros_de_votación.pdf"))
    download(string(URI(scheme = "https", host = "ceepur.org", path = "/Elecciones/docs/centrosvotacion.pdf")),
             joinpath("data", "centros_de_votación.pdf"))
end
if !isfile(joinpath("data", "centros_de_votación-adelantado.pdf"))
    download(string(URI(scheme = "https", host = "ceepur.org", path = "/Elecciones/docs/centrosvotacion-adelantado.pdf")),
             joinpath("data", "centros_de_votación.pdf"))
end
doc = pdDocOpen(joinpath("data", "centros_de_votación.pdf"))
doc = pdDocOpen(joinpath("data", "centrosvotacion-adelantado.pdf"))
docinfo = pdDocGetInfo(doc)
npage = pdDocGetPageCount(doc)
records = String[]
empty!(records)
io = IOBuffer(write = true)
for i in 1:npage
    page = pdDocGetPage(doc, i)
    pdPageExtractText(io, page)
    text = String(take!(io))
    lns = split(text, '\n')
    append!(records, @view(lns[3:end]))
end
close(io)
pdDocClose(doc)
records = strip.(records)
filter!(!isempty, records)
filter!(!isequal("630"), records) # Last total on adelantado
function parse_record(ln::AbstractString)
    # Handle issue on page 6
    county = match(r"\p{Lu}\p{Ll}+(\s\p{Lu}\p{Ll}+)?", ln).match
    precinct = parse(Int, match(r"\d{3}", ln).match)
    pollingstation_regex = match(r"(?<=\d{3} )\d{2}", ln)
    pollingstation = parse(Int, pollingstation_regex.match)
    regular_added_total = match(r"\d+\s+\d+\s+\d+$", rstrip(ln))
    regular, added = parse.(Int, @view(split(regular_added_total.match, r"\s+")[1:2]))
    stationtype_idx = match(r"(Acad\.|Ant\. Esc\.|C\. Com|Cncha|Col\.|Ctro\.|Esc\.|H\. S\.|Igl\.|Loc\.|Rcia\.|Univ\.)",
                            ln)
    stationtype = stationtype_idx.match
    name_address = strip(SubString(ln, stationtype_idx.offset + length(stationtype), regular_added_total.offset - 1))
    name, address = try
        x = split(name_address, r"\s{2,}")
        if length(x) == 2
            x
        elseif length(x) == 3
            x[1], join(x[2:end], " ")
        else
            @assert length(x) == 2
        end
    catch err
        strip.(split(name_address, r"(?=(6 Paseo|Carr\.|Cll\.))"))
    end
    (;county, precinct, pollingstation, stationtype, name, address, regular, added)
end
ln = records[1]
function parse_adelantado(ln::AbstractString)
    # Handle issue on page 6
    county = match(r"\p{Lu}+(\s\p{Lu}+)?", ln).match
    precinct = parse(Int, match(r"\d{3}", ln).match)
    pollingstation_regex = match(r"(?<= )\d{2}(?= )", ln)
    pollingstation = parse(Int, pollingstation_regex.match)
    regular = match(r"\d+$", rstrip(ln))
    colegios = parse(Int, regular.match)
    stationtype_idx = match(r"(Acad\.|Ant\. Esc\.|C\. Com|Cncha|Col\.|Ctro\.|Esc\.|H\. S\.|Igl\.|Loc\.|Rcia\.|Univ\.)",
                            ln)
    stationtype = stationtype_idx.match
    name_address = strip(SubString(ln, stationtype_idx.offset + length(stationtype), regular.offset - 1))
    name, address = try
        x = split(name_address, r"\s{2,}")
        if length(x) == 2
            x
        elseif length(x) == 3
            x[1], join(x[2:end], " ")
        else
            @assert length(x) == 2
        end
    catch err
        strip.(split(name_address, r"(?=(6 Paseo|Carr\.|Cll\.))"))
    end
    (;county, precinct, pollingstation, stationtype, name, address, regular)
end
for i in eachindex(records)
    println(i)
    parse_adelantado(records[i])
end
records[358]
data = DataFrame(parse_adelantado(record) for record in records)
centros = CSV.read(joinpath("data", "final", "centros_de_votación.csv"), DataFrame)
data[!,:añadido_a_mano] .= missing



centros[!,:adelantado] .= false
data[!,:adelantado] .= true
names(data)
names(centros)
rename!(data, :precinct => :precinto)
rename!(data, :pollingstation => :unidad)
rename!(data, :stationtype => :tipo)
rename!(data, :name => :centrodevotación)
rename!(data, :address => :dirección)

data = data[!,names(centros)]
chk = vcat(centros, data, cols = :setequal)
chk = sort!(chk[!,union(["precinto", "unidad", "adelantado"], names(chk))])
CSV.write(joinpath("data", "final", "centros_de_votación.csv"), chk)

data = DataFrame(parse_record(record) for record in records)
CSV.write(joinpath("data", "centros_de_votación.tsv"), data, delim = '\t')
CSV.write(joinpath("data", "centros_de_votación.csv"), data)

# Add GIS data for public schools

response = request("GET",
                   URI(scheme = "https",
                       host = "data.pr.gov",
                       path = "/resource/gb92-58gc.csv",
                       query = ["\$select" => "escuela,direccion_municipio,direccion_zipcode,geolocalizacion.longitude as lon,geolocalizacion.latitude as lat"]))
io = IOBuffer(write = true)
write(io, String(response.body))
schools = CSV.read(take!(io), DataFrame)
response = request("GET",
                   URI(scheme = "https",
                       host = "data.pr.gov",
                       path = "/resource/gb92-58gc.csv",
                       query = ["\$select" => "escuela,direccion_municipio,direccion_zipcode,geolocalizacion.longitude as lon,geolocalizacion.latitude as lat",
                                "\$offset" => 999]))
write(io, String(response.body))
append!(schools, CSV.read(take!(io), DataFrame))
filter!(row -> !(ismissing(row.escuela) | ismissing(row.lon) | ismissing(row.lat)), schools)
findall(ismissing, schools[!,:direccion_municipio])
schools[13:16,:]
schools[!,:direccion_municipio] .= replace.(schools[!,:direccion_municipio], r".*,\s+" => "")
unique(schools[!,:direccion_municipio])
download(string(URI(scheme = "https",
                    host = "data.pr.gov",
                    path = "/resource/gb92-58gc.csv",
                    query = ["\$select" => "region,geolocalizacion.longitude as lon,geolocalizacion.latitude as lat",
                             "\$order" => "geolocalizacion.longitude != null and geolocalizacion.latitude != null"])),
         joinpath("data", "escuelas_públicas.csv"))
request("GET",
        "https://data.pr.gov/resource/gb92-58gc.json?%24select=region%2Cgeolocalizacion__longitude__c%2Cgeolocalizacion__latitude__c")
escuelas_públicas = JSON3.read(String(read(joinpath("data", "escuelas_públicas.json"))))
function parse_public_school(node)
    (name = titlecase(node.escuela),
     county = titlecase(node.distrito),
     address = haskey(node, :direccio_fisica) ? node.direccio_fisica : missing,
     zipcode = haskey(node, :direccion_zipcode) ? node.direccion_zipcode : missing,
     lon = haskey(node, :geolocalization) ? node.geolocalization.longitude : missing,
     lat = haskey(node, :geolocalization) ? node.geolocalization.longitude : missing,
     )
end
escuelas_públicas_tabla = DataFrame(parse_public_school(escuela) for escuela in escuelas_públicas)

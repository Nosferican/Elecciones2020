"""
    procesar_acta(acta::AbstractString)

Procesa la acta y devuelve la información sobre los votos, papeletas, papeletas_adicional y electores.

Una `posición_en_papeleta = -1` indica los `MAL VOTADO` y `posición_en_papeleta = 0` indica `NO VOTADO`.

# Examples

```julia-repl
julia> votos, papeletas, papeletas_adicional, electores = procesar_acta("001_01_01.html");

julia> votos
157×8 DataFrame
│ Row │ contienda                │ partido │ posición_en_papeleta │ candidato │ votos │ precinto │ unidad │ colegio │
│     │ String                   │ String  │ Int64                │ String    │ Int64 │ Int64    │ Int64  │ Int64   │
├─────┼──────────────────────────┼─────────┼──────────────────────┼───────────┼───────┼──────────┼────────┼─────────┤
│ 1   │ GOBERNADOR               │ PNP     │ 1                    │ PPU       │ 85    │ 1        │ 1      │ 1       │
│ 2   │ GOBERNADOR               │ PPD     │ 1                    │ CDA       │ 49    │ 1        │ 1      │ 1       │
│ 3   │ GOBERNADOR               │ PIP     │ 1                    │ JDR       │ 16    │ 1        │ 1      │ 1       │
│ 4   │ GOBERNADOR               │ MVC     │ 1                    │ ALA       │ 38    │ 1        │ 1      │ 1       │
│ 5   │ GOBERNADOR               │ PD      │ 1                    │ CVM       │ 21    │ 1        │ 1      │ 1       │
│ 6   │ GOBERNADOR               │ INDPT   │ 1                    │ EMP       │ 3     │ 1        │ 1      │ 1       │
│ 7   │ GOBERNADOR               │ OTROS   │ 1                    │ OTROS     │ 0     │ 1        │ 1      │ 1       │
│ 8   │ GOBERNADOR               │         │ -1                   │           │ 0     │ 1        │ 1      │ 1       │
⋮
│ 149 │ LEGISLADORES MUNICIPALES │ PD      │ 11                   │ LBV       │ 20    │ 1        │ 1      │ 1       │
│ 150 │ LEGISLADORES MUNICIPALES │ PD      │ 12                   │ RRG       │ 20    │ 1        │ 1      │ 1       │
│ 151 │ LEGISLADORES MUNICIPALES │ OTROS   │ 1                    │ OTROS     │ 0     │ 1        │ 1      │ 1       │
│ 152 │ LEGISLADORES MUNICIPALES │         │ -1                   │           │ 0     │ 1        │ 1      │ 1       │
│ 153 │ LEGISLADORES MUNICIPALES │         │ 0                    │           │ 200   │ 1        │ 1      │ 1       │
│ 154 │ PLEBISCITO               │ NO      │ 1                    │ NO        │ 81    │ 1        │ 1      │ 1       │
│ 155 │ PLEBISCITO               │ SI      │ 2                    │ SI        │ 131   │ 1        │ 1      │ 1       │
│ 156 │ PLEBISCITO               │         │ -1                   │           │ 0     │ 1        │ 1      │ 1       │
│ 157 │ PLEBISCITO               │         │ 0                    │           │ 0     │ 1        │ 1      │ 1       │

julia> papeletas
30×7 DataFrame
│ Row │ papeleta  │ modo    │ partido │ votos │ precinto │ unidad │ colegio │
│     │ String    │ String  │ String  │ Int64 │ Int64    │ Int64  │ Int64   │
├─────┼───────────┼─────────┼─────────┼───────┼──────────┼────────┼─────────┤
│ 1   │ ESTATAL   │ INTEGRO │ PNP     │ 78    │ 1        │ 1      │ 1       │
│ 2   │ ESTATAL   │ INTEGRO │ PPD     │ 38    │ 1        │ 1      │ 1       │
│ 3   │ ESTATAL   │ INTEGRO │ PIP     │ 8     │ 1        │ 1      │ 1       │
│ 4   │ ESTATAL   │ INTEGRO │ MVC     │ 28    │ 1        │ 1      │ 1       │
│ 5   │ ESTATAL   │ INTEGRO │ PD      │ 14    │ 1        │ 1      │ 1       │
│ 6   │ ESTATAL   │ MIXTO   │ PNP     │ 0     │ 1        │ 1      │ 1       │
│ 7   │ ESTATAL   │ MIXTO   │ PPD     │ 1     │ 1        │ 1      │ 1       │
│ 8   │ ESTATAL   │ MIXTO   │ PIP     │ 0     │ 1        │ 1      │ 1       │
⋮
│ 22  │ MUNICIPAL │ INTEGRO │ PPD     │ 41    │ 1        │ 1      │ 1       │
│ 23  │ MUNICIPAL │ INTEGRO │ PIP     │ 3     │ 1        │ 1      │ 1       │
│ 24  │ MUNICIPAL │ INTEGRO │ MVC     │ 47    │ 1        │ 1      │ 1       │
│ 25  │ MUNICIPAL │ INTEGRO │ PD      │ 12    │ 1        │ 1      │ 1       │
│ 26  │ MUNICIPAL │ MIXTO   │ PNP     │ 1     │ 1        │ 1      │ 1       │
│ 27  │ MUNICIPAL │ MIXTO   │ PPD     │ 0     │ 1        │ 1      │ 1       │
│ 28  │ MUNICIPAL │ MIXTO   │ PIP     │ 0     │ 1        │ 1      │ 1       │
│ 29  │ MUNICIPAL │ MIXTO   │ MVC     │ 1     │ 1        │ 1      │ 1       │
│ 30  │ MUNICIPAL │ MIXTO   │ PD      │ 5     │ 1        │ 1      │ 1       │

julia> papeletas_adicional
11×6 DataFrame
│ Row │ papeleta    │ modo                      │ votos │ precinto │ unidad │ colegio │
│     │ String      │ String                    │ Int64 │ Int64    │ Int64  │ Int64   │
├─────┼─────────────┼───────────────────────────┼───────┼──────────┼────────┼─────────┤
│ 1   │ ESTATAL     │ EN BLANCO                 │ 0     │ 1        │ 1      │ 1       │
│ 2   │ ESTATAL     │ NULAS                     │ 0     │ 1        │ 1      │ 1       │
│ 3   │ ESTATAL     │ PAPELETAS POR CANDIDATURA │ 45    │ 1        │ 1      │ 1       │
│ 4   │ LEGISLATIVA │ EN BLANCO                 │ 0     │ 1        │ 1      │ 1       │
│ 5   │ LEGISLATIVA │ NULAS                     │ 0     │ 1        │ 1      │ 1       │
│ 6   │ LEGISLATIVA │ PAPELETAS POR CANDIDATURA │ 39    │ 1        │ 1      │ 1       │
│ 7   │ MUNICIPAL   │ EN BLANCO                 │ 0     │ 1        │ 1      │ 1       │
│ 8   │ MUNICIPAL   │ NULAS                     │ 0     │ 1        │ 1      │ 1       │
│ 9   │ MUNICIPAL   │ PAPELETAS POR CANDIDATURA │ 18    │ 1        │ 1      │ 1       │
│ 10  │ PLEBISCITO  │ EN BLANCO                 │ 0     │ 1        │ 1      │ 1       │
│ 11  │ PLEBISCITO  │ NULAS                     │ 0     │ 1        │ 1      │ 1       │

julia> electores
1×4 DataFrame
│ Row │ precinto │ unidad │ colegio │ registrados │
│     │ Int64    │ Int64  │ Int64   │ Int64       │
├─────┼──────────┼────────┼─────────┼─────────────┤
│ 1   │ 1        │ 1      │ 1       │ 554         │

```
"""
function procesar_acta(acta::AbstractString)
    html = parsehtml(String(read(joinpath("data", "actas", acta))))
    warp = only(eachmatch(Selector("#reportDiv > .tabular-report > .wrap"), html.root))
    votos = DataFrame(contienda = String[], partido = String[], posición_en_papeleta = Int[], candidato = String[], votos = Int[])
    papeletas = DataFrame(papeleta = String[], modo = String[], partido = String[], votos = Int[])
    papeletas_adicional = DataFrame(papeleta = String[], modo = String[], votos = Int[])
    electores = DataFrame(precinto = Int[], unidad = Int[], colegio = Int[], registrados = Int[])
    precinto, unidad, colegio = 0, 0, 0
    papeleta = ""
    contienda = ""
    for elem in warp.children
        elem_tag = tag(elem)
        class = getattr(elem, "class", "")
        if elem_tag == :h2
            h2 = nodeText(elem)
            if startswith(h2, "PRECINTO")
                precinto = parse(Int, match(r"\d+", h2).match)
            elseif startswith(h2, "UNIDAD")
                unidad = parse(Int, match(r"\d+", h2).match)
            elseif startswith(h2, "COLEGIO")
                colegio = parse(Int, match(r"\d+", h2).match)
            end
        elseif elem_tag == :h4
            papeleta = match(r"(?<=PAPELETA ).*", nodeText(elem)).match
        elseif elem_tag == :h5
            contienda = nodeText(elem)
        elseif class == "columns"
            elements = @view(elem.children[1].children[2:end])
            for elem in elements
                subelems = elem.children
                partido = nodeText(subelems[1])
                posición_en_papeleta, candidato = split(nodeText(subelems[2]), "-")
                posición_en_papeleta = parse(Int, posición_en_papeleta)
                apoyo = parse(Int, replace(nodeText(subelems[3]), "," => ""))
                push!(votos, (;contienda, partido, posición_en_papeleta, candidato, votos = apoyo))
            end
        elseif (class == "ballot-votes") && (contienda ≠ "CAMPOS DE PAPELETA")
            for subelem in elem[1].children
                push!(votos,
                      (;contienda,
                        partido = "",
                        posición_en_papeleta = nodeText(subelem[1]) == "MAL VOTADO" ? -1 : 0,
                        candidato = "",
                        votos = parse(Int, replace(nodeText(subelem[2]), "," => ""))))
            end
        elseif class == "votes"
            elem = elem[1].children
            modo = match(r"(?<=VOTO ).*", nodeText(elem[1])).match
            for subelem in @view(elem[2:end - 1])
                push!(papeletas,
                      (;papeleta, modo, partido = nodeText(subelem[1]), votos = parse(Int, replace(nodeText(subelem[2]), "," => ""))))
            end
        elseif (class == "ballot-votes") && (contienda == "CAMPOS DE PAPELETA")
            elem = @view(elem.children[1].children[1:3])
            for subelem in elem
                modo = nodeText(subelem[1])
                if modo ∈ ["EN BLANCO", "NULAS", "PAPELETAS POR CANDIDATURA"]
                    push!(papeletas_adicional, (;papeleta, modo, votos = parse(Int, replace(nodeText(subelem[2]), "," => ""))))
                end
            end
        elseif class == "special-votes"
            push!(electores, (;precinto, unidad, colegio, registrados = parse(Int, replace(nodeText(elem[1][1][2]), "," => ""))))
        end
    end
    votos[!,:precinto] .= precinto
    votos[!,:unidad] .= unidad
    votos[!,:colegio] .= colegio
    papeletas[!,:precinto] .= precinto
    papeletas[!,:unidad] .= unidad
    papeletas[!,:colegio] .= colegio
    papeletas_adicional[!,:precinto] .= precinto
    papeletas_adicional[!,:unidad] .= unidad
    papeletas_adicional[!,:colegio] .= colegio
    (votos, papeletas, papeletas_adicional, electores)
end
"""
    acceder_acta(sesión::Session, precinto::Integer, unidad::Integer, colegio::Integer)

Descarga la acta para el precinto, unidad y colegio a `data/actas/precinto_unidad_colegio.html`.

# Examples

```julia-repl
julia> wd = RemoteWebDriver(Capabilities("chrome"))
Remote WebDriver

julia> sesión = Session(wd)
Session

julia> url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es/reportdefault/Actas.xml")
HTTP.URI("http://elecciones2020.ceepur.org/Escrutinio_General_93/index.html#es/reportdefault/Actas.xml")

julia> navigate!(sesión, string(url))

julia> acceder_acta(sesión, 1, 1, 1)
97215

```
"""
function acceder_acta(sesión::Session, precinto::Integer, unidad::Integer, colegio::Integer)
    precinto = lpad(precinto, 3, '0')
    unidad = lpad(unidad, 2, '0')
    colegio = lpad(colegio, 2, '0')
    precinto_idx = Element(sesión, "xpath", "//*[@id='precinctOptions']//option[@value='AXU_$(precint_muni[precinto])_$precinto.xml']")
    click!(precinto_idx)
    sleep(0.1)
    unidad_idx = Element(sesión, "xpath",
                         string("//*[@id='pollingStationOptions']//option[",
                                "@value='AXU_$(PRECINTO_MUNICIPIO[precinto])_$(precinto)_$(parse(Int, unidad)).xml']"))
    click!(unidad_idx)
    sleep(0.1)
    colegio_idx = Element(sesión, "xpath",
                          string("//*[@id='votingPlaceOptions']//option[",
                                 "@value='AXU_$(PRECINTO_MUNICIPIO[precinto])_$(precinto)_$(parse(Int, unidad))_$(parse(Int, colegio)).xml']"))
    click!(colegio_idx)
    sleep(0.1)
    generar_acta = Element(sesión, "xpath", "//*[@id='btnShowReport']")
    click!(generar_acta)
    sleep(0.3)
    archivo = "$(precinto)_$(unidad)_$colegio.html"
    write(joinpath("data", "actas", archivo), source(sesión))
end

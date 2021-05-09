using Cascadia: parsehtml, Selector, nodeText, Gumbo.HTMLDocument, tag, attrs, getattr
using CSV, DataFrames

reports = filter!(filename -> endswith(filename, ".html"), readdir(joinpath("data", "reports")))

report = reports[1]

"""
    parse_report(report::AbstractString)
"""
function parse_report(report::AbstractString)
    html = parsehtml(String(read(joinpath("data", "reports", report))))
    warp = only(eachmatch(Selector("#reportDiv > .tabular-report > .wrap"), html.root))
    votos = DataFrame(contienda = String[], partido = String[], posición_en_papeleta = Int[], candidato = String[], votos = Int[])
    papeletas = DataFrame(papeleta = String[], modo = String[], partido = String[], votos = Int[])
    papeletas_adicional = DataFrame(papeleta = String[], modo = String[], votos = Int[])
    electores = DataFrame(precinto = Int[], unidad = Int[], colegio = Int[], registrados = Int[])
    precinto, unidad, colegio = 0, 0, 0
    papeleta = ""
    contienda = ""

    for elem in warp.children
        # (idx, elem) in enumerate(warp.children)
        # println(idx)
        # elem = warp.children[3]
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
            # println(ballottype)
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
            # println(string("$contienda: ",
            #         join((x.match for x in eachmatch(r"\d+", nodeText(elem))), ',')))
            # elem = warp.children[9][1].children
            for subelem in elem[1].children
                push!(votos,
                      (;contienda,
                        partido = "",
                        posición_en_papeleta = nodeText(subelem[1]) == "MAL VOTADO" ? -1 : 0,
                        candidato = "",
                        votos = parse(Int, replace(nodeText(subelem[2]), "," => ""))))
            end
        elseif class == "votes"
            # elem = warp.children[13]
            elem = elem[1].children
            modo = match(r"(?<=VOTO ).*", nodeText(elem[1])).match
            for subelem in @view(elem[2:end - 1])
                push!(papeletas,
                      (;papeleta, modo, partido = nodeText(subelem[1]), votos = parse(Int, replace(nodeText(subelem[2]), "," => ""))))
            end
        elseif (class == "ballot-votes") && (contienda == "CAMPOS DE PAPELETA")
            # elem = warp.children[16]
            elem = @view(elem.children[1].children[1:3])
            for subelem in elem
                modo = nodeText(subelem[1])
                if modo ∈ ["EN BLANCO", "NULAS", "PAPELETAS POR CANDIDATURA"]
                    push!(papeletas_adicional, (;papeleta, modo, votos = parse(Int, replace(nodeText(subelem[2]), "," => ""))))
                end
            end
        elseif class == "special-votes"
            # elem = warp.children[54]
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
# x = parse_report(report)
votos, papeletas, papeletas_adicional, electores = parse_report(reports[1]);

votos = DataFrame(contienda = String[], partido = String[], posición_en_papeleta = Int[], candidato = String[], votos = Int[],
                  precinto = Int[], unidad = Int[], colegio = Int[])
papeletas = DataFrame(papeleta = String[], modo = String[], partido = String[], votos = Int[],
                      precinto = Int[], unidad = Int[], colegio = Int[])
papeletas_adicionales = DataFrame(papeleta = String[], modo = String[], votos = Int[],
                                  precinto = Int[], unidad = Int[], colegio = Int[])
electores = DataFrame(precinto = Int[], unidad = Int[], colegio = Int[], registrados = Int[])
empty!(votos)
empty!(papeletas)
empty!(papeletas_adicionales)
empty!(electores)

verifier = DataFrame(filename = String[], precinto = Int[], unidad = Int[], colegio = Int[])
for report in reports
    txt = String(read(joinpath("data", "reports", report)))
    html = parsehtml(txt)
    warp = [ match(r"\d+$", nodeText(node)).match
             for node in eachmatch(Selector("#reportDiv > .tabular-report > .wrap > h2"), html.root) ]
    write(joinpath("data", "reports_clean", string(join(warp, '_'), ".html")), txt)
    println(report)
end

error_files = String[]
empty!(error_files)
bad_files = String[]
empty!(bad_files)
chk = copy(bad_files)
function fixer(report::AbstractString)

end
reports = 
report = reports[1]
for report in chk
    try
        voto, papeleta, papeleta_adicional, registrados = parse_report(report)
        precinto = parse(Int, SubString(report, 1, 3))
        unidad = parse(Int, SubString(report, 5, 6))
        colegio = parse(Int, SubString(report, 8, 9))
        if (precinto ≠ voto[1,:precinto]) || (unidad ≠ voto[1,:unidad]) || (colegio ≠ voto[1,:colegio])
            push!(bad_files, report)
        end
    catch err
        push!(error_files, report)
    end
end
for report in reports
    voto, papeleta, papeleta_adicional, registrados = parse_report(report)
    # println("$report: $(voto[1,:unidad]) $(voto[1,:colegio])")
    append!(votos, voto)
    append!(papeletas, papeleta)
    append!(papeletas_adicionales, papeleta_adicional)
    append!(electores, registrados)
    println(report)
end
votos = votos[!,union([:precinto,:unidad,:colegio], propertynames(votos))]
papeletas = papeletas[!,union([:precinto,:unidad,:colegio], propertynames(papeletas))]
papeletas_adicionales = papeletas_adicionales[!,union([:precinto,:unidad,:colegio], propertynames(papeletas_adicionales))]

votos[(votos[!,:posición_en_papeleta] .== 1) .&
      (votos[!,:contienda] .== "COMISIONADO RESIDENTE") .&
      (votos[!,:partido] .== "PPD") .&
      (votos[!,:precinto] .== 2)]
      # .&
    #   (votos[!,:unidad] .== 1),:]

nrow(votos)
nrow(unique(votos))

nrow(papeletas)
nrow(unique(papeletas))

nrow(papeletas_adicionales)
nrow(unique(papeletas_adicionales))
length(reports)

votos[!,[]]

CSV.write(joinpath("data", "votos.csv"), votos)
CSV.write(joinpath("data", "papeletas.csv"), papeletas)
CSV.write(joinpath("data", "papeletas_adicionales.csv"), papeletas_adicionales)
CSV.write(joinpath("data", "electores.csv"), electores)

candidatos = unique(votos[!,[:contienda,:partido,:candidato]])
candidacies = CSV.read(joinpath("data", "candidacies.csv"), DataFrame)
candidacies_map = Dict("GOBERNADOR" => "governor",
                       "COMISIONADO RESIDENTE" => "resident_commissioner",
                       "REPRESENTANTES POR DISTRITO" => "lower",
                       "SENADORES POR DISTRITO" => "upper",
                       "REPRESENTANTES POR ACUMULACIÓN" => "lower",
                       "SENADORES POR ACUMULACIÓN" => "upper",
                       "ALCALDES" => "mayor",
                       "LEGISLADORES MUNICIPALES" => "councilperson")
candidacies[!,:contest] .= get.(Ref(candidacies_map), candidacies[!,:contest], candidacies[!,:contest])

candidatos[]

unique(candidacies[!,:contest])
unique(candidatos[!,:contienda])



findfirst(isequal("001_77_04.html"), reports)
report = reports[114]

    precinct, pollingplace, pollingstation =
        [ parse(Int, match(r"\d+", nodeText(node)).match)
          for node in eachmatch(Selector("#reportDiv > .tabular-report > .wrap > h2"), html.root) ]
    contests = eachmatch(Selector("#reportDiv > .tabular-report > .wrap > h5"), html.root)
    tbls = eachmatch(Selector("#reportDiv > .tabular-report > .wrap > .columns > tbody > tr"), html.root)
    eachmatch(Selector("""h5:matches("GOVERNADOR")"""), html.root)
    p:matches([\d])
end

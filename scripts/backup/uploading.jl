using LibPQ: Connection, load!, execute, prepare, CopyIn
using CSV, DataFrames
using CSV: CSV, RowWriter
using Cascadia: parsehtml, Selector, nodeText, Gumbo.HTMLDocument
conn = Connection("")
const SCHEMA = "elecciones_generales_2020"
execute(conn, String(read(joinpath("src", "assets", "sql", "schema.sql"))))

candidacies = CSV.read(joinpath("data", "candidacies.csv"), DataFrame)
execute(conn, "TRUNCATE $SCHEMA.candidacies;")
execute(conn, "BEGIN;")
load!(candidacies, conn, "insert into $SCHEMA.candidacies values(\$1,\$2,\$3,\$4);")
execute(conn, "COMMIT;")

pollingstations = CSV.read(joinpath("data", "centros_de_votación.csv"), DataFrame)
pollingstations = pollingstations[!,[:precinct,:pollingstation,:stationtype,:name,:address,:regular,:added]]
execute(conn, "TRUNCATE $SCHEMA.pollingstations;")
execute(conn, "BEGIN;")
load!(pollingstations, conn, "insert into $SCHEMA.pollingstations values(\$1,\$2,\$3,\$4,\$5,\$6,\$7);")
execute(conn, "COMMIT;")

# Candidatura
x = parsehtml(String(read(joinpath("data", "reports", "001_01_01.html"))))
precinct = parse(Int, match(r"\d{3}$", nodeText(only(eachmatch(Selector("#reportDiv > div > div > h2:nth-child(2)"), x.root)))).match)
pollingstation = parse(Int, match(r"\d{2}$", nodeText(only(eachmatch(Selector("#reportDiv > div > div > h2:nth-child(3)"), x.root)))).match)
pollingplace = parse(Int, match(r"\d{2}$", nodeText(only(eachmatch(Selector("#reportDiv > div > div > h2:nth-child(4)"), x.root)))).match)

candidacies = ["governor", "resident_commissioner", "lower_regional", "upper_regional", "lower_atlarge", "upper_atlarge", "mayor", "councilperson"]

data = DataFrame(precinct = Int[],
                 pollingstation = Int[],
                 pollingplace = Int[],
                 candidacy = String[],
                 party = Union{String,Missing}[],
                 position = Union{Int,Missing}[],
                 candidate = Union{String,Missing}[],
                 votes = Int[],
                 )

# Votes
function parse_votes(report::HTMLDocument, candidacy::AbstractString)
    candidacy = candidacies[1]
    candidacy = candidacies[7]
    idx = if candidacy == "governor"
        8
    elseif candidacy == "resident_commissioner"
        11
    elseif candidacy == "lower_regional"
        20
    elseif candidacy == "upper_regional"
        23
    elseif candidacy == "lower_atlarge"
        26
    elseif candidacy == "upper_atlarge"
        29
    elseif candidacy == "mayor"
        38
    elseif candidacy == "councilperson"
        41
    end
    eachmatch(Selector("#reportDiv"), report.root)
    votos = @view(eachmatch(Selector("#reportDiv > .tabular-report > .wrap > .columns:nth-child($idx) > tbody > tr"), report.root)[2:end])
    null_count, empty_count = parse.(Int, nodeText.(node[2] for node in eachmatch(Selector("#reportDiv > .tabular-report > .wrap > .ballot-votes:nth-child($(idx + 3))"), report.root)[1][1].children))
    chk = eachmatch(Selector("#reportDiv > .tabular-report > .wrap > .ballot-votes"), report.root)
    chk[5]
    chk2 = DataFrame(id = 1:13, val = nodeText.(chk))


    [ nodeText(node[1][2]) for node in eachmatch(Selector("#reportDiv > .tabular-report > .wrap > .ballot-votes:nth-child($(idx + 1))"), report.root)[1][1] ]
    eachmatch(Selector("#reportDiv > .tabular-report > .wrap > .ballot-votes"), report.root)[2]
    eachmatch(Selector("#reportDiv > .tabular-report > .wrap > .ballot-votes"), report.root)[3]
    eachmatch(Selector("#reportDiv > .tabular-report > .wrap > .ballot-votes"), report.root)[4]
    null_count, empty_count = parse.(Int, nodeText.(eachmatch(Selector("#reportDiv > .tabular-report > .wrap > .ballot-votes:nth-child($(idx + 1)) > tbody:nth-child(1)"), report.root)[1]))
    data = DataFrame(candidacy = String[], party = Union{String,Missing}[], position = Union{Int,Missing}[], candidate = Union{String,Missing}[], votes = Int[])
    for voto in votos
        party, candidate, votes = nodeText.(eachmatch(Selector("td"), voto))
        position, candidate = split(candidate, "-", limit = 2)
        push!(data, (;candidacy = candidacy, party, position = parse(Int, position), candidate, votes = parse(Int, votes)))
    end
    push!(data, (;candidacy = candidacy, party = missing, position = missing, candidate = "voided", votes = null_count))
    push!(data, (;candidacy = candidacy, party = missing, position = missing, candidate = "blank", votes = empty_count))
    data
end
function process_report(filename::AbstractString)
    report = parsehtml(String(read(joinpath("data", "reports", filename))))
    data = reduce(vcat, parse_votes(report, candidacy) for candidacy in candidacies)
    data[!,:precinct] .= parse(Int, match(r"^\d{3}", filename).match)
    data[!,:pollingstation] .= parse(Int, match(r"(?<=^\d{3}_)\d{2}", filename).match)
    data[!,:pollingplace] .= parse(Int, match(r"(?<=^\d{3}_\d{2}_)\d{2}(?=\.html)", filename).match)
    data
end
# empty!(bad)
bad = String[]
filename = "001_01_01.html"
xx = process_report("020_77_05.html")
xx[]

reports = filter!(filename -> endswith(filename, ".html"), readdir(joinpath("data", "reports")))

for report in reports
    try
        x = process_report(report)
        append!(data, x)
    catch err
        push!(bad, report)
    end
    println(report)
end

data = process_report(reports[1])


report = x
data = reduce(vcat, parse_votes(x, candidacy) for candidacy in candidacies)
data[!,:precinct] .= precinct
data[!,:pollingstation] .= pollingstation
data[!,:pollingplace] .= pollingplace
data = data[!,union([:precinct, :pollingstation, :pollingplace], propertynames(data))]
replace!(data[!,:party], "INDPT" => missing)
replace!(data[!,:party], "OTROS" => missing)
replace!(data[!,:candidate], "OTROS" => missing)
unique(data[!,:party])

data = CSV.read(joinpath("data", "votes_backup.csv"), DataFrame)

data[!,:position] .= ifelse.(data[!,:candidate] .== "voided", -1, data[!,:position])
data[!,:position] .= ifelse.(data[!,:candidate] .== "blank", 0, data[!,:position])
data[!,:party] .= ifelse.(ismissing.(data[!,:party]) .& (data[!,:position] .== 1), "INDPT", data[!,:party])
data[!,:party] .= ifelse.(data[!,:position] .∈ Ref((-1, 0)), "", data[!,:party])
replace!(data[!,:party], "INDPT" => "")
replace!(data[!,:candidate], "voided" => "")
replace!(data[!,:candidate], "black" => "")
replace!(data[!,:candidate], "OTROS" => "")


data[coalesce.(data[!,:party] .== "INDPT", false),:]

execute(conn, "TRUNCATE $SCHEMA.votes;")
execute(conn, "BEGIN;")
load!(data, conn, "insert into $SCHEMA.votes values(\$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8);")
execute(conn, "COMMIT;")

candidacies = CSV.read(joinpath("data", "candidacies.csv"), DataFrame)
candidatos = unique(candidacies.name)

Juan Ramón ''Chiki'' Torres Rivera

candidato = "Ángel Luis \"Coolie\" Cedeño Jr."
suffix = ifelse(occursin(r" Jr\.(\s|$)", candidato), "Jr.", missing)
candidato = replace(candidato, r"Jr\." => "")
candidato = replace(candidato, r"\s+" => " ")
candidato = strip(candidato)
candidato = replace(candidato, "()" => "")
candidato = replace(candidato, " De Los " => " De_Los_")
candidato = replace(candidato, " De La " => " De_La_")
candidato = replace(candidato, " De " => " De_")
first_name = getproperty(match(r"\p{Lu}[\p{Ll}_']+", candidato), :match)
nickname = match(r"[\(\'{2}].*[\)\'{2}]", candidato)
nickname = (x -> isnothing(x) ? missing : replace(x.match, "(" => "") |> (x -> replace(x, ")" => "")))(nickname)
candidato = strip(replace(candidato, r"[\(\"].*[\)\"]" => ""))
candidato = strip(replace(candidato, first_name => ""))
candidato
match(r"[\w+", "O'Neil")
surname = getproperty(match(r"\p{Lu}[\p{Ll}(_\p{Lu})']+( \p{Lu}[\p{Ll}(_\p{Lu})'])?$", candidato), :match)
middlename = getproperty.(match.(r"(\p{Lu}\.|\p{Lu}(?= )|\p{Lu}[\p{Ll}'_]+)", candidatos), :match)
chk = DataFrame(candidatos = unique(candidacies.name), firstname = first_name, middlename = middlename, surname = surname, nickname = nickname)
chk[!,:middlename] = ifelse.(startswith.(chk[!,:surname], chk[!,:middlename]), "", chk[!,:middlename])

suffix = ifelse.(occursin.("Jr.", candidatos), "Jr.", missing)
candidatos = replace.(candidatos, "Jr." => "")
candidatos = replace.(candidatos, r"\s+" => " ")
candidato = strip.(candidatos)
candidatos = replace.(candidatos, r"[\(][\)\'{2}]" => "")
candidatos = replace.(candidatos, " Del " => " Del_")
candidatos = replace.(candidatos, " De Los " => " De_Los_")
candidatos = replace.(candidatos, " De La " => " De_La_")
candidatos = replace.(candidatos, " De " => " De_")
findall(x -> occursin("De", x), candidatos)

first_name = getproperty.(match.(r"\p{Lu}[\p{Ll}(_\p{Lu})']+", candidatos), :match)
nickname = match.(r"[\(\'{2}].*[\)\'{2}]", candidatos)
nickname = (x -> isnothing(x) ? missing : replace(x.match, r"[\(\'{2}]" => "") |> (x -> replace(x, r"[\)\'{2}]" => ""))).(nickname)
candidatos = strip.(replace.(candidatos, r"[\'{2}\(].*[\)\'{2}]" => ""))
candidatos = strip.(replace.(candidatos, r"^\p{Lu}\p{Ll}+" => ""))

surname = getproperty.(match.(r"\p{Lu}[\p{Ll}(_\p{Lu})']+( \p{Lu}[\p{Ll}(_\p{Lu})']+\.?)?$", candidatos), :match)
middlename = getproperty.(match.(r"(\p{Lu}\.|\p{Lu}(?= )|\p{Lu}[\p{Ll}(_\p{Lu})']+)", candidatos), :match)
chk = DataFrame(candidatos = unique(candidacies.name), firstname = first_name, middlename = middlename, surname = surname, suffix = suffix, nickname = nickname)
chk[!,:middlename] = ifelse.(startswith.(chk[!,:surname], chk[!,:middlename]), "", chk[!,:middlename])
chk[!,:middlename] = replace.(chk[!,:middlename], "_" => " ")
chk[!,:middlename] = ifelse.(occursin.(r"\p{Lu}$", chk[!,:middlename]), string.(chk[!,:middlename], "."), chk[!,:middlename])
chk[!,:surname] = replace.(chk[!,:surname], "_" => " ")
# Manual fix
chk[chk[!,:surname] .== "Luis Cedeño",:middlename] = "Luis"
chk[chk[!,:surname] .== "Luis Cedeño",:surname] = "Cedeño"

findfirst(x -> occursin("''", x), chk[!,:candidatos])
chk[386,:]

CSV.write(joinpath("data", "clean_names.csv"), chk)
for i in eachindex(candidatos)
    try
        match(r"\p{Lu}[\p{Ll}']+( \p{Lu}[\p{Ll}']+\.?)?$", candidatos[i]).match
    catch
        println(i)
    end
end
candidatos[954]
candidatos[2870]

match(r"\p{Lu}\p{Ll}+( \p{Lu}[\p{Ll}']+)?$", "Juan J. Rivera O'farell").match

cool = CSV.read(joinpath("data", "candidatos_cleaned_checked.csv"), DataFrame)

z = join(candidacies, cool, on = :name => :candidato)

execute(conn, "BEGIN;")
load!(z, conn, string("INSERT INTO $SCHEMA.candidacies VALUES(", join(("\$$i" for i in 1:size(z, 2)), ','),")"))
execute(conn, "COMMIT;")
candidacies

contest       │ district │ party  │ name                        │ firstname │ middlename │ surname          │ suffix  │ nickname

votos = DataFrame(execute(conn,
                          """
                          SELECT distinct contest, party, ballotposition, candidate
                          from $SCHEMA.votes
                          where length(candidate) = 3
                          order by 1, 2
                          """, not_null = true))

chk = unique(votos[!,:candidate])

files = filter!(x -> endswith(x, ".html"), readdir(joinpath("data", "reports")))

cp = CopyIn(string("INSERT INTO $SCHEMA.votos values(",
                   join(("\$$i" for i in 1:size(votos, 2)), ','),
                   ")"),
            votos)
votos[!,:partido] .= replace.(votos[!,:partido], missing => "")
votos[!,:partido] = disallowmissing(votos[!,:partido])
votos[!,:partido] .= replace.(votos[!,:partido], "" => ".")
any(ismissing, votos[!,:partido])

execute(conn, "TRUNCATE TABLE $SCHEMA.votos")
function load_by_copy!(table, conn::Connection, table_name::AbstractString)
    iter = RowWriter(table)
    column_names = first(iter)
    copyin = CopyIn("COPY $table_name ($column_names) FROM STDIN WITH null as E'\\'\\'' CSV HEADER;", iter)
    execute(conn, copyin)
end
load_by_copy!(votos, conn, "$SCHEMA.votos")

execute(conn, "BEGIN;")
execute(conn, cp)
execute(conn, "COMMIT;")

for x in 1:4
    x = lpad(x, 3, '0')
    to_zip = filter!(filename -> startswith(filename, x) && endswith(filename, ".html"), readdir(joinpath("data", "reports")))
    to_zip = joinpath.("data", "reports", to_zip)
    destfile = "$x.zip"
    run(`zip -r $destfile $to_zip`)
end

papeletas = CSV.read(joinpath("data", "papeletas.csv"), DataFrame)
papeletas_ = CSV.read(joinpath("data", "papeletas_adicionales.csv"), DataFrame)
papeletas_[!,:partido] .= ""

data = vcat(papeletas, papeletas_, cols = :setequal)
data = data[!,[:precinto, :unidad, :colegio, :papeleta, :modo, :partido, :votos]]
sort!(data)
load_by_copy!(data, conn, "$SCHEMA.papeletas")

electores = CSV.read(joinpath("data", "electores.csv"), DataFrame)
load_by_copy!(electores, conn, "$SCHEMA.electores")

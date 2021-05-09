using WebDriver
using WebDriver: HTTP.request, URI, screenshot
using Base64: base64decode
using Cascadia: Gumbo.getattr


url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es/reportdefault/Actas.xml")
url = URI(scheme = "http", host = "elecciones2020.ceepur.org")
wd = RemoteWebDriver(Capabilities("chrome"))
session = Session(wd)
navigate!(session, "https://wikipedia.org")
navigate!(session, string(url))

tracker = 
empty!(tracker)
# Precincts
function precintos_unidades_colegios(sesión::Session)
    data = DataFrame(precinto = Int[], unidad = Int[], colegio = Int[])
    precintos = Elements(sesión, "xpath", "//*[@id='precinctOptions']//option")
    sc
    precintos_vals = element_attr.(precintos, "value")
    for precinto_val in precintos_vals
        # precinto_val = precintos_vals[2]
        precinto = parse(Int, match(r"(?<=_)\d+(?=\.xml)", precinto_val).match)
        precinto_idx = precintos[findfirst(isequal(precinto_val), precintos_vals)]
        click!(precinto_idx)
        unidades = Elements(sesión, "xpath", "//*[@id='pollingStationOptions']//option")
        unidades_vals = element_attr.(unidades, "value")
        for unidad_val in unidades_vals
            unidad = parse(Int, match(r"(?<=_)\d+(?=\.xml)", unidad_val).match)
            unidades = Elements(sesión, "xpath", "//*[@id='pollingStationOptions']//option")
            unidad_idx = unidades[findfirst(isequal(unidad_val), unidades_vals)]
            click!(unidad_idx)
            colegios = Elements(sesión, "xpath", "//*[@id='votingPlaceOptions']//option")
            colegios_vals = element_attr.(colegios, "value")
            for colegio in colegios_vals
                colegio = parse(Int, match(r"(?<=_)\d+(?=\.xml)", colegio).match)
                push!(data, (;precinto, unidad, colegio))
            end
        end
        precintos = Elements(sesión, "xpath", "//*[@id='precinctOptions']//option")
    end
    data
end

data = precintos_unidades_colegios(session)

xxx!(tracker, session)
CSV.write(joinpath("data", "precinto_unidad_colegio.csv"), tracker)
allfiles = string.(lpad.(tracker[!,:precinto], 3, '0'),
                   "_",
                   lpad.(tracker[!,:unidad], 2, '0'),
                   "_",
                   lpad.(tracker[!,:colegio], 2, '0'),
                   ".html")
setdiff(filter!(x -> endswith(x, ".html"), readdir(joinpath("data", "reports"))),
        allfiles)
to_collect = setdiff(allfiles,
                     filter!(x -> endswith(x, ".html"), readdir(joinpath("data", "reports"))))
session = sesión
precintos = Elements(session, "xpath", "//*[@id='precinctOptions']//option")
precintos_vals = element_attr.(precintos, "value")
precintos_vals = replace.(precintos_vals, "AXU_" => "")
precintos_vals = replace.(precintos_vals, ".xml" => "")
filter!(!isempty, precintos_vals)
munis = getproperty.(match.(r"[\w_]+(?=_\d)", precintos_vals), :match)
precinct = getproperty.(match.(r"\d+", precintos_vals), :match)

precint_muni = Dict(precinct .=> munis)
println(string(precint_muni))

function scrape_this_report(report)
    # report = "001_15_04.html"
    precinto = SubString(report, 1, 3)
    unidad = SubString(report, 5, 6)
    colegio = SubString(report, 8, 9)
    precinto_idx = Element(session, "xpath", "//*[@id='precinctOptions']//option[@value='AXU_$(precint_muni[precinto])_$precinto.xml']")
    click!(precinto_idx)
    sleep(0.1)
    unidad_idx = Element(session, "xpath",
                         string("//*[@id='pollingStationOptions']//option[",
                                "@value='AXU_$(precint_muni[precinto])_$(precinto)_$(parse(Int, unidad)).xml']"))
    click!(unidad_idx)
    sleep(0.1)
    colegio_idx = Element(session, "xpath",
                          string("//*[@id='votingPlaceOptions']//option[",
                                 "@value='AXU_$(precint_muni[precinto])_$(precinto)_$(parse(Int, unidad))_$(parse(Int, colegio)).xml']"))
    click!(colegio_idx)
    sleep(0.1)
    showreport = Element(session, "xpath", "//*[@id='btnShowReport']")
    click!(showreport)
    sleep(0.3)
    destfile = "$(precinto)_$(unidad)_$colegio.html"
    write(joinpath("data", "reports", destfile), source(session))
end

# for report in to_collect
# for report in error_files
for report in bad_files
    scrape_this_report(report)
    println(report)
end

write("img.png", base64decode(screenshot(session)))

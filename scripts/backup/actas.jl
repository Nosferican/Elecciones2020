using WebDriver
using WebDriver: HTTP.request, URI
using Base64: base64decode

navigate!(session, "https://wikipedia.org")
url = URI(scheme = "http", host = "elecciones2020.ceepur.org", path = "/Escrutinio_General_93/index.html#es/reportdefault/Actas.xml")
url = URI(scheme = "http", host = "elecciones2020.ceepur.org")
wd = RemoteWebDriver(Capabilities("chrome"))
session = Session(wd)
navigate!(session, string(url))

write("img.png", base64decode(screenshot(session)))
element = Element(session, "xpath", "/html/body/table[2]/tbody/tr[3]/td[2]/a")
click!(element)
element = Element(session, "xpath", """//*[@id="container"]/nav/ul/li[10]/ul/li/a""")
click!(element)

# Optionsk
element = Element(session, "css selector", "#precinctOptions")
click!(element)
# Precincts
precinctOptions = Elements(session, "xpath", "//*[@id='precinctOptions']//option")
for precinctoption_idx in 2:lastindex(precinctOptions)
    precinctoption = precinctOptions[precinctoption_idx]
    click!(precinctoption)
    # Polling Station
    pollingStationOptions = Elements(session, "xpath", "//*[@id='pollingStationOptions']//option")
    for pollingstationoption_idx in 2:lastindex(pollingStationOptions)
        pollingstationoption = pollingStationOptions[pollingstationoption_idx]
        click!(pollingstationoption)
        # Voting Place
        votingPlaceOptions = Elements(session, "xpath", "//*[@id='votingPlaceOptions']//option")
        for votingplaceoption_idx in 2:lastindex(votingPlaceOptions)
            # Precinct
            precinctOptions = Elements(session, "xpath", "//*[@id='precinctOptions']//option")
            precinctoption = precinctOptions[precinctoption_idx]
            precinct = match(r"\d+$", element_text(precinctoption)).match
            click!(precinctoption)
            # Polling Station
            pollingStationOptions = Elements(session, "xpath", "//*[@id='pollingStationOptions']//option")
            pollingstationoption = pollingStationOptions[pollingstationoption_idx]
            pollingstation = match(r"\d+$", element_text(pollingstationoption)).match
            click!(pollingstationoption)
            
            # Voting Place
            votingPlaceOptions = Elements(session, "xpath", "//*[@id='votingPlaceOptions']//option")
            votingplaceoption = votingPlaceOptions[votingplaceoption_idx]
            votingplace = match(r"\d+$", element_text(votingplaceoption)).match
            click!(votingplaceoption)

            # Report
            showreport = Element(session, "xpath", "//*[@id='btnShowReport']")
            click!(showreport)
            destfile = "$(precinct)_$(pollingstation)_$votingplace.html"
            write(joinpath("data", "reports", destfile), source(session))
        end
    end
end
filename = "001_01_01.html"
filename = "002_01_01.html"
function isfilevalid(filename)    
    report = parsehtml(String(read(joinpath("data", "reports", filename))))
    !isempty(eachmatch(Selector("#reportDiv > .tabular-report > .date"), report.root))
end
isfilevalid(filename)

reports = filter!(filename -> endswith(filename, ".html"), readdir(joinpath("data", "reports")))
bad_files = String[]
empty!(bad_files)
filename = nothing
for filename in reports
    if !isfilevalid(filename)
        push!(bad_files, filename)
    end
    println(filename)
end

CSV.write("data/bad_files.txt", DataFrame(file = bad_files))

for filename in bad_files
    # Voting Place
    # filename = bad_files[3]
    # filename = "005_06_01.html"
    precinctoption_idx = SubString(filename, 1, 3)
    pollingstationoption_idx = parse(Int, SubString(filename, 5, 6))
    votingplaceoption_idx = parse(Int, SubString(filename, 8, 9))
    # Precinct
    precinctOptions = Elements(session, "xpath", "//*[@id='precinctOptions']//option")
    option_values = element_attr.(precinctOptions, "value")
    precinctoption = precinctOptions[findfirst(x -> endswith(x, "$precinctoption_idx.xml"), option_values)]
    precinct = match(r"\d+$", element_text(precinctoption)).match
    click!(precinctoption)

    # Polling Station
    pollingStationOptions = Elements(session, "xpath", "//*[@id='pollingStationOptions']//option")
    option_values = element_attr.(pollingStationOptions, "value")
    pollingstationoption = pollingStationOptions[findfirst(x -> endswith(x, "_$pollingstationoption_idx.xml"), option_values)]
    pollingstation = match(r"\d+$", element_text(pollingstationoption)).match
    click!(pollingstationoption)

    # Voting Place
    votingPlaceOptions = Elements(session, "xpath", "//*[@id='votingPlaceOptions']//option")
    option_values = element_attr.(votingPlaceOptions, "value")
    votingplaceoption = votingPlaceOptions[findfirst(x -> endswith(x, "_$votingplaceoption_idx.xml"), option_values)]
    votingplace = match(r"\d+$", element_text(votingplaceoption)).match
    click!(votingplaceoption)

    # Report
    showreport = Element(session, "xpath", "//*[@id='btnShowReport']")
    click!(showreport)
    destfile = "$(precinct)_$(pollingstation)_$votingplace.html"
    sleep(0.35)
    write(joinpath("data", "reports", destfile), source(session))
    println(destfile)
end

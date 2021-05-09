using WebDriver
using WebDriver: HTTP.request, URI
using Base64: base64decode
using CSV, DataFrames
# WebDriver
wd = RemoteWebDriver(Capabilities("chrome"))
# Session
session = Session(wd)
# Escrutinio_General
url = URI(scheme = "http",
          host = "elecciones2020.ceepur.org")
navigate!(session, string(url))
element = Element(session, "xpath", "/html/body/table[2]/tbody/tr[3]/td[2]/a")
click!(element)

# Gobernador
url = URI(scheme = "http",
          host = "elecciones2020.ceepur.org")
navigate!(session, string(url))
gobernador = Element(session, "css selector", "#container > nav > ul > li:nth-child(1) > span")


write("img.png", base64decode(screenshot(session)))

data = CSV.read(joinpath("data", "candidacies.csv"), DataFrame)
data = data[!,[:contest,:district,:party,:name]]
sort!(data)
CSV.write(joinpath("data", "candidacies.csv"), data)

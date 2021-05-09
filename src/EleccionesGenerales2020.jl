"""
    EleccionesGenerales2020 :: Module

Módulo para hacer más accesible la información del evento electoral Elecciones Generales 2020 de Puerto Rico.
"""
module EleccionesGenerales2020

using Cascadia: Cascadia, Selector, parsehtml, nodeText, tag, attrs, getattr,
      # Gumbo
      Gumbo, Gumbo.HTMLDocument
using CSV: CSV
using DataFrames: DataFrames, DataFrame
using WebDriver
using WebDriver: RemoteWebDriver, Capabilities, Session, navigate!, Elements, Element, element_attr, click!, source,
    # HTTP
    HTTP, URI, HTTP.request
using Base64: Base64, base64decode
using Unicode: Unicode, normalize
using LibPQ: LibPQ, Connection, load!, execute, prepare, CopyIn
using PDFIO: PDFIO, pdDocOpen, pdDocGetPageCount, pdPageExtractText

const PRECINTO_MUNICIPIO = Dict("001" => "SAN_JUAN", "002" => "SAN_JUAN", "003" => "SAN_JUAN", "004" => "SAN_JUAN", "005" => "SAN_JUAN", "006" => "GUAYNABO", "007" => "GUAYNABO", "008" => "CATANO", "009" => "BAYAMON", "010" => "BAYAMON", "011" => "BAYAMON", "012" => "BAYAMON", "013" => "TOA_ALTA", "014" => "TOA_BAJA", "015" => "DORADO", "016" => "VEGA_ALTA", "017" => "VEGA_ALTA", "018" => "VEGA_BAJA", "019" => "VEGA_BAJA", "020" => "MOROVIS", "021" => "MANATI", "022" => "MANATI", "023" => "CIALES", "024" => "FLORIDA", "025" => "BARCELONETA", "026" => "ARECIBO", "027" => "ARECIBO", "028" => "HATILLO", "029" => "HATILLO", "030" => "CAMUY", "031" => "QUEBRADILLAS", "032" => "ISABELA", "033" => "SAN_SEBASTIAN", "034" => "LAS_MARIAS", "035" => "AGUADILLA", "036" => "MOCA", "037" => "MOCA", "038" => "AGUADA", "039" => "RINCON", "040" => "ANASCO", "041" => "MAYAGUEZ", "042" => "MAYAGUEZ", "043" => "SAN_GERMAN", "044" => "SAN_GERMAN", "045" => "HORMIGUEROS", "046" => "CABO_ROJO", "047" => "LAJAS", "048" => "GUANICA", "049" => "SABANA_GRANDE", "050" => "MARICAO", "051" => "YAUCO", "052" => "YAUCO", "053" => "LARES", "054" => "UTUADO", "055" => "ADJUNTAS", "056" => "JAYUYA", "057" => "JAYUYA", "058" => "GUAYANILLA", "059" => "PENUELAS", "060" => "PONCE", "061" => "PONCE", "062" => "PONCE", "063" => "JUANA_DIAZ", "064" => "JUANA_DIAZ", "065" => "VILLALBA", "066" => "OROCOVIS", "067" => "SANTA_ISABEL", "068" => "COAMO", "069" => "AIBONITO", "070" => "BARRANQUITAS", "071" => "BARRANQUITAS", "072" => "COROZAL", "073" => "NARANJITO", "074" => "COMERIO", "075" => "COAMO", "076" => "CIDRA", "077" => "CAYEY", "078" => "SALINAS", "079" => "GUAYAMA", "080" => "ARROYO", "081" => "AGUAS_BUENAS", "082" => "CAGUAS", "083" => "CAGUAS", "084" => "GURABO", "085" => "SALINAS", "086" => "SAN_LORENZO", "087" => "SAN_LORENZO", "088" => "JUNCOS", "089" => "LAS_PIEDRAS", "090" => "LAS_PIEDRAS", "091" => "PATILLAS", "092" => "MAUNABO", "093" => "YABUCOA", "094" => "HUMACAO", "095" => "NAGUABO", "096" => "VIEQUES", "097" => "CULEBRA", "098" => "CEIBA", "099" => "FAJARDO", "100" => "LUQUILLO", "101" => "RIO_GRANDE", "102" => "RIO_GRANDE", "103" => "LOIZA", "104" => "CANOVANAS", "105" => "CANOVANAS", "106" => "CAROLINA", "107" => "CAROLINA", "108" => "CAROLINA", "109" => "TRUJILLO_ALTO", "110" => "TRUJILLO_ALTO")
include(joinpath("src", "actas.jl"))

end # module

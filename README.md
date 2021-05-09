# Elecciones Generales 2020

## Propósito del proyecto

1. Hacer más accesible la información provista por la Comisión Estatal de Elecciones de Puerto Rico sobre los resultados del proceso electoral: [Elecciones Generales 2020](http://elecciones2020.ceepur.org). En particular, la información recolectada será a base del Escrutinio General.

2. La información será a base de las [actas por precinto, unidad y colegio](http://elecciones2020.ceepur.org/Escrutinio_General_93/index.html#es/reportdefault/Actas.xml).

3. La información en las actas incluye:

    A nivel de contienda,

    - Contienda
    - Partido
    - Candidato
    - Posición en la papeleta
    - Votos
    - Papeletas mal votadas
    - Papeletas sin voto

    A nivel de papeleta (i.e., estatal, legislativa, municipal, plebiscito),

    - Modalidad de voto (e.g., integro por partido, mixto por partido, por candidatura, en blanco, nulas)

    A nivel de precinto/unidad/colegio,

    - Votantes registrados

## Estrategia

Crear una base de datos en un servidor PostgreSQL. El esquema de `elecciones_generales_2020` tendrá las siguientes tablas:

- `votos`
    - `precinto :: smallint`
    - `unidad :: smallint`
    - `colegio :: smallint`
    - `candidatura :: text` (Nombre según la papeleta)
    - `partido :: text`

| Abreviación |                 Partido                |
|:-----------:|:--------------------------------------:|
|     PNP     |        Partido Nuevo Progresista       |
|     PPD     |       Partido Popular Democrático      |
|     PIP     | Partido Independentista Puertorriqueño |
|     MVC     |      Movimiento Victoria Ciudadana     |
|      PD     |            Proyecto Dignidad           |
|             |             Independientes             |
|    OTROS    |           Nominación Directa           |

    - `posición_en_papela :: smallint`

| Abreviación |       Partido      |
|:-----------:|:------------------:|
|     -1     |        Mal Votado   |
|      0     |       No votado     |

        - `-1`: Mal votado
        - ` 0`: No votado

    - `candidato :: text`
    - `votos :: smallint`
- 

### Web scraping

El programa usa [WebDriver.jl](https://github.com/Nosferican/WebDriver.jl) junto a [Selenium/Standalone-Chrome](https://hub.docker.com/r/selenium/standalone-chrome) (e.g., `selenium/standalone-chrome:4`) para acceder al portal de la CEE y acceder a cada una de las actas. Una vez se genera la acta, el programa descarga la página con el código. El archivo se guarda bajo `precinto_unidad_colegio.html`. Se coteja que cada acta esté grabada, se refiera a la acta correcta y que el contenido sea el correcto.

Las actas contienen las iniciales de los candidatos, pero no los nombres. El proceso descrito en el paso anterior se replica para los resumenes por precinto que sí contienen el nombre de los candidatos. Se junta la información utilizando el precinto, candidatura, partido y posición en la papeleta.

### Procesamiento de actas y resúmenes

El programa utiliza [Gumbo.jl](https://github.com/JuliaWeb/Gumbo.jl) / [Cascadia.jl](https://github.com/Algocircle/Cascadia.jl) para procesar el HTML a información tabular que se importa a la base de datos.

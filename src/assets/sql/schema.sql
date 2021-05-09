CREATE SCHEMA IF NOT EXISTS elecciones_generales_2020;
COMMENT ON SCHEMA elecciones_generales_2020 IS 'Información sobre las elecciones generales de Puerto Rico en el 2020.';
CREATE TABLE IF NOT EXISTS elecciones_generales_2020.candidacies (
    contest text NOT NULL,
    district text NOT NULL,
    party text NOT NULL,
    candidate text NOT NULL,
    firstname text NOT NULL,
    middlename text,
    surname text NOT NULL,
    suffix text,
    nickname text
);
CREATE TABLE IF NOT EXISTS elecciones_generales_2020.pollingstations (
    precinct smallint,
    station smallint,
    stationtype text NOT NULL,
    stationname text NOT NULL,
    stationaddress text NOT NULL,
    regular smallint NOT NULL,
    added smallint NOT NULL,
    PRIMARY KEY (precinct, station)
);
CREATE TABLE IF NOT EXISTS elecciones_generales_2020.votos (
    precinto smallint,
    unidad smallint,
    colegio smallint,
    contienda text,
    partido text,
    posición_en_papeleta smallint,
    candidato text,
    votos smallint NOT NULL,
    PRIMARY KEY (precinto, unidad, colegio, contienda, partido, posición_en_papeleta)
);
CREATE TABLE IF NOT EXISTS elecciones_generales_2020.papeletas (
    precinto smallint,
    unidad smallint,
    colegio smallint,
    papeleta text,
    modo text,
    partido text,
    votos smallint NOT NULL,
    PRIMARY KEY (precinto, unidad, colegio, papeleta, modo, partido)
);
CREATE TABLE IF NOT EXISTS elecciones_generales_2020.electores (
    precinto smallint,
    unidad smallint,
    colegio smallint,
    registrados smallint NOT NULL,
    PRIMARY KEY (precinto, unidad, colegio)
);

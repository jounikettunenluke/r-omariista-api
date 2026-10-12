# Oma riista -rajapinnan käyttö R:ssä

Tämä tutkijaohje kuvaa, miten Oma riista -rajapinnasta haetaan hirvieläinten lupahakemusten aluekarttoja R-ympäristöön analysointia varten.

## Mitä ohjeen avulla voi tehdä?

- hakea yksittäisen hakemusalueen karttana
- hakea useita hakemusalueita
- visualisoida aluegeometriat R:ssä
- tehdä paikkatietoanalyysejä, kuten laskea pinta-aloja
- tallentaa aineiston paikkatietotiedostoksi

## Edellytykset

Tarvitset:

- R:n ja halutessasi RStudion
- `sf`-paketin paikkatietoaineiston käsittelyyn
- tiedoston `omariista_api.R`, joka sisältää funktion `get_application_area()`
- Oma riista -rajapinnan `client_id`- ja `client_secret`-tunnukset Riistakeskukselta
- yhden tai useamman hakemusnumeron

Asenna `sf` tarvittaessa:

```r
install.packages("sf")
```

## Hakemusnumero

Rajapinta käyttää hakemusnumeroa (*application number*). Hakemusnumero sisältyy lupanumeroon.

Esimerkki:

```text
Lupanumero:     2025-1-000-10306-6
Hakemusnumero:  10306
```

Hakemusnumerot saadaan Riistakeskukselta tai muusta käytettävästä aineistosta.

## Rajapintatunnusten turvallinen tallentaminen

Tallenna tunnukset käyttäjän kotihakemiston `.Renviron`-tiedostoon. Tämä tehdään vain kerran.

Avaa tiedosto R:ssä:

```r
file.edit("~/.Renviron")
```

Lisää tiedostoon seuraavat rivit ja korvaa arvot omilla tunnuksillasi:

```text
OMARIISTA_CLIENT_ID=oma_client_id
OMARIISTA_CLIENT_SECRET=oma_client_secret
```

Tallenna tiedosto ja käynnistä R tai RStudio uudelleen. Tarkista tämän jälkeen tunnusten löytyminen tulostamatta niiden arvoja:

```r
stopifnot(
  nzchar(Sys.getenv("OMARIISTA_CLIENT_ID")),
  nzchar(Sys.getenv("OMARIISTA_CLIENT_SECRET"))
)
```

> [!IMPORTANT]
> Älä kirjoita tunnuksia R-skriptiin, README-tiedostoon tai versionhallintaan. `.Renviron` luetaan automaattisesti R:n käynnistyessä, joten sitä ei tarvitse ladata erikseen.

Jos projektihakemistossa käytetään paikallista `.Renviron`-tiedostoa, lisää se `.gitignore`-tiedostoon:

```gitignore
.Renviron
```

## Käyttö

### 1. Lataa funktiot

Suorita jokaisen uuden R-istunnon alussa:

```r
source("omariista_api.R")
```

### 2. Hae yksi hakemusalue

```r
hakemusnumero <- 10306
areas_sf <- get_application_area(hakemusnumero)
```

Tarkista tulos:

```r
stopifnot(inherits(areas_sf, "sf"))
print(areas_sf)
```

### 3. Visualisoi alue

```r
plot(sf::st_geometry(areas_sf))
```

### 4. Hae useita hakemusalueita

```r
hakemusnumerot <- c(10306, 45678)
areas_list <- lapply(hakemusnumerot, get_application_area)
```

Jos tulokset halutaan yhdistää yhdeksi `sf`-objektiksi ja niiden sarakerakenne on sama:

```r
areas_sf_all <- do.call(rbind, areas_list)
```

### 5. Tallenna aineisto GeoPackage-tiedostoksi

Yhden hakemuksen tulos:

```r
sf::st_write(
  areas_sf,
  "areas.gpkg",
  delete_dsn = TRUE
)
```

Useiden hakemusten yhdistetty tulos:

```r
sf::st_write(
  areas_sf_all,
  "areas_all.gpkg",
  delete_dsn = TRUE
)
```

`delete_dsn = TRUE` korvaa samannimisen olemassa olevan GeoPackage-tiedoston. Poista asetus tai muuta tiedostonimeä, jos vanha tiedosto pitää säilyttää.

## Tyypillinen työnkulku

1. Tallenna rajapintatunnukset `.Renviron`-tiedostoon.
2. Käynnistä R tai RStudio uudelleen.
3. Lataa funktiot komennolla `source("omariista_api.R")`.
4. Anna hakemusnumero tai hakemusnumerot.
5. Hae alueet funktiolla `get_application_area()`.
6. Tarkista, visualisoi ja tallenna tulokset tarpeen mukaan.

## Tiedostot

```text
.
├── README.md
├── omariista_api.R
└── .gitignore
```

`.Renviron` sijaitsee ensisijaisesti käyttäjän kotihakemistossa eikä kuulu projektin versionhallintaan.

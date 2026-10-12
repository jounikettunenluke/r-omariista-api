###################
# PERUSKÄYTTÖ
###################

# lataa funktiot
source("omariista_api.R")

# hae yksi hakemus
areas_sf <- get_application_area(10306)

# tulosta
print(areas_sf)

# piirrä
plot(st_geometry(areas_sf))


###################
# Usean alueen hakeminen
###################

###########################################################
# 1–10 ovat esimerkkihakemusnumeroita (kuvitteellisia)
# Näitä vaihdetaan oikeaan dataan myöhemmin
###########################################################

hakemusnumerot <- c(1,2,3,4,5,6,7,8,9,10)


###########################################################
# Funktio: turvallinen haku
#
# Yrittää hakea hakemusalueen.
# Jos haku epäonnistuu (esim. numero ei ole olemassa),
# ei kaada koko prosessia, vaan palauttaa NULL.
###########################################################

safe_get_application_area <- function(id) {
  tryCatch(
    get_application_area(id),
    error = function(e) {
      message("Ei onnistunut: ", id)
      return(NULL)
    }
  )
}


###########################################################
# Haetaan kaikki hakemusalueet
#
# lapply käy jokaisen hakemusnumeron läpi
# ja hakee alueen yksi kerrallaan
###########################################################

areas_list <- lapply(hakemusnumerot, safe_get_application_area)


###########################################################
# Poistetaan epäonnistuneet haut (NULL-arvot)
###########################################################

areas_list <- Filter(Negate(is.null), areas_list)


###########################################################
# Yhdistetään kaikki alueet yhdeksi sf-aineistoksi
###########################################################

all_areas <- do.call(rbind, areas_list)


###########################################################
# VISUALISOINTI
#
# Piirretään kaikki alueet kartalle
###########################################################

plot(st_geometry(all_areas))


###########################################################
# (Valinnainen) Lisävisualisointi värityksellä
###########################################################

plot(
  st_geometry(all_areas),
  col = rainbow(length(all_areas)),  # eri väri per kohde
  main = "Hakemusalueet (esimerkkidata)"
)
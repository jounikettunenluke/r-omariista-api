############################################################
# omariista_api.R
#
# Oma riista API helper-funktiot
#
# Tämä skripti:
#   1. hakee access tokenin Keycloakista
#   2. hallitsee tokenin uusimisen
#   3. hakee hirvieläinten hakemusalueet
#
# Käyttö:
#   source("omariista_api.R")
#
############################################################


############################
# TARVITTAVAT PAKETIT
############################

library(httr2)
library(jsonlite)
library(sf)


############################
# YMPÄRISTÖ
############################
# Vaihda tarvittaessa:
#   environment <- "staging"
#   environment <- "production"
############################

environment <- "production"


############################
# ENDPOINTIT
############################

if (environment == "staging") {
  
  KEYCLOAK_TOKEN_URL <-
    "https://keycloak-test-env.omariista.eu/realms/staging/protocol/openid-connect/token"
  
  OMARIISTA_API_BASE <-
    "https://staging-eu-west-1.omariista.eu/api/v1/export/luke"
  
} else {
  
  KEYCLOAK_TOKEN_URL <-
    "https://sso.oma.riista.fi/realms/omariista/protocol/openid-connect/token"
  
  OMARIISTA_API_BASE <-
    "https://oma.riista.fi/api/v1/export/luke"
}


############################
# TOKENIN HAKU
############################
# Hakee uuden access tokenin Keycloakista.
# Tunnukset luetaan suoraan .Renvironista.
############################

get_token <- function() {
  
  # haetaan tunnukset turvallisesti (ei globaaleja muuttujia)
  client_id <- Sys.getenv("OMARIISTA_CLIENT_ID")
  client_secret <- Sys.getenv("OMARIISTA_CLIENT_SECRET")
  
  # tarkistus
  if (client_id == "" || client_secret == "") {
    stop("Client ID tai Client Secret puuttuu (.Renviron)")
  }
  
  req <- request(KEYCLOAK_TOKEN_URL) |>
    req_method("POST") |>
    req_body_form(
      grant_type = "client_credentials",
      client_id = client_id,
      client_secret = client_secret
    )
  
  resp <- req_perform(req)
  
  token <- resp_body_json(resp)
  
  # tallennetaan hakuaika (tarvitaan voimassaolon laskemiseen)
  token$obtained_at <- Sys.time()
  
  return(token)
}


############################
# TOKENIN VOIMASSAOLON TARKISTUS
############################

token_valid <- function(token_info, margin_seconds = 60) {
  
  if (is.null(token_info)) {
    return(FALSE)
  }
  
  expiry_time <-
    token_info$obtained_at + token_info$expires_in
  
  Sys.time() < (expiry_time - margin_seconds)
}


############################
# TOKENIN HALLINTA
############################
# Käytetään tokenia niin kauan kuin voimassa.
############################

.omariista_token <- NULL

get_valid_token <- function() {
  
  if (!token_valid(.omariista_token)) {
    
    message("Haetaan uusi access token...")
    
    .omariista_token <<- get_token()
  }
  
  return(.omariista_token$access_token)
}


############################
# HAKEMUSALUEEN HAKU
############################
#
# Parametri:
#   application_number
#
# Esimerkki:
#   Lupanumero:
#   2020-1-123-45678-1
#
#   Hakemusnumero:
#   45678
#
############################

get_application_area <- function(application_number) {
  
  token <- get_valid_token()
  
  url <- paste0(
    OMARIISTA_API_BASE,
    "/mooselike-permit-application-area/",
    application_number
  )
  
  req <- request(url) |>
    req_headers(
      Authorization = paste("Bearer", token)
    )
  
  resp <- req_perform(req)
  
  geojson <- resp_body_string(resp)
  
  sf_object <- st_read(
    geojson,
    quiet = TRUE
  )
  
  return(sf_object)
}

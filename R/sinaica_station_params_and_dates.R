#' Parameters supported by a station
#'
#' List of air quality parameters of a measuring station for which SINAICA has data
#'
#' @param station_id the numeric code corresponding to each station. See
#' \code{\link{stations_sinaica}} for a list of stations and their ids.
#' @param type The type of data to download. One of the following:
#' \itemize{
#'  \item Crude - Crude data that has not been validated
#'  \item Validated - Validated data (may not be the most up-to-date)
#'  \item Manual - Manual data
#' }
#'
#' @return a data.frame with the parameters supported by the station
#' @importFrom httr POST http_error http_type content status_code
#' @importFrom jsonlite fromJSON
#' @export
#'
#' @examples
#' ## id 271 is Xalostoc. See `stations_sinaica`
#' df <- sinaica_station_params(271, "Crude")
#' head(df)
sinaica_station_params <- function(station_id,
                                   type = "Crude") {
  if (missing(station_id))
    stop(paste0("argument station_id is missing, please provide it. The",
                " data.frame",
                " `stations_sinaica` contains a list of all station ids",
                " and names"), call. = FALSE)
  if (!is.integer2(station_id))
    stop(paste0("argument station_id must be an integer. The",
                " data.frame",
                " `stations_sinaica` contains a list of all station ids",
                " and names"), call. = FALSE)
  check_arguments(type,
                  valid = c("Crude", "Validated", "Manual"),
                  "type")

  type <- switch(type,
                 "Crude"     = "",
                 "Validated" = "V",
                 "Manual"    = "M"
  )
  # curl 'https://sinaica.inecc.gob.mx/lib/libd/cnxn.php'
  # estId=33&metodo=getParamsPorEstAjax&tipoDatos=''
  url <- "https://sinaica.inecc.gob.mx/lib/libd/cnxn.php"
  fd <- list(
    estId     = station_id,
    metodo    = "getParamsPorEstAjax",
    tipoDatos = type
  )
  tryCatch(
    {
      result <- httr::with_config(httr::config(ssl_verifypeer = 0L), {
        POST(url,
                     body = fd,
                     encode = "form")
      })
      if (http_error(result))
        stop(sprintf("The request to <%s> failed [%s]",
                     url,
                     status_code(result)
        ), call. = FALSE)
      if (http_type(result) != "text/html")
        stop(paste0(url, " did not return text/html", call. = FALSE))
      json_text <- content(result, "text", encoding = "UTF-8")
      df <- fromJSON(json_text)
      if (!length(df))
        return(data.frame(parameter_code = character(0),
                          parameter_name = character(0),
                          stringsAsFactors = FALSE)
        )
      names(df) <- c("param_code", "param_name")
      return(df)
    },
    error = function(cond) {
      message("An error occurred downloading data from SINAICA:")
      message(cond)
      return(NULL)
    }
  )
}

#' Dates supported by a station
#'
#' Start date and end date of the range for which SINAICA has data for an air quality station
#'
#' @param station_id the numeric code corresponding to each station. See
#' \code{\link{stations_sinaica}} for a list of stations and their ids.
#' @param type The type of data to download. One of the following:
#' \itemize{
#'  \item Crude - Crude data that has not been validated
#'  \item Validated - Validated data (may not be the most up-to-date)
#'  \item Manual - Manual data
#' }
#'
#' @return a vector containing the date the station started reporting
#' and end reporting date
#' @importFrom httr POST http_error http_type content status_code with_config config
#' @importFrom jsonlite fromJSON
#' @export
#'
#' @examples
#' ## id 271 is Xalostoc. See `stations_sinaica`
#' df <- sinaica_station_dates(271, "Manual")
#' head(df)
sinaica_station_dates <- function(station_id,
                              type = "Crude") {
  if (missing(station_id))
    stop(paste0("argument station_id is missing, please provide it. The",
                " data.frame",
                " `stations_sinaica` contains a list of all station ids",
                " and names"), call. = FALSE)
  if (!is.integer2(station_id))
    stop(paste0("argument station_id must be an integer. The",
                " data.frame",
                " `stations_sinaica` contains a list of all station ids",
                " and names"), call. = FALSE)
  check_arguments(type,
                  valid = c("Crude", "Validated", "Manual"),
                  "type")

  type <- switch(type,
                 "Crude"     = "",
                 "Validated" = "V",
                 "Manual"    = "M"
  )
  #curl 'https://sinaica.inecc.gob.mx/lib/libd/cnxn.php'
  # id=31&metodo=getFechasLimiteEstacionAjax&tipoDatos=
  url <- "https://sinaica.inecc.gob.mx/lib/libd/cnxn.php"
  fd <- list(
    id        = station_id,
    metodo    = "getFechasLimiteEstacionAjax",
    tipoDatos = type
  )

  tryCatch(
    {
      result <- httr::with_config(httr::config(ssl_verifypeer = 0L), {
        POST(url,
             body = fd,
             encode = "form")
      })
      if (http_error(result))
        stop(sprintf("The request to <%s> failed [%s]",
                     url,
                     status_code(result)
        ), call. = FALSE)
      if (http_type(result) != "text/html")
        stop(paste0(url, " did not return text/html", call. = FALSE))
      json_text <- content(result, "text", encoding = "UTF-8")
      df <- fromJSON(json_text)
      if (is.na(df[[1]]))
        df <- c(NA, NA)
      return(df)
    },
    error = function(cond) {
      message("An error occurred downloading data from SINAICA:")
      message(cond)
      return(NULL)
    }
  )

}

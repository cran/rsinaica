#' Get air quality data from all stations by parameter
#'
#' Download data from all stations for a single parameter by specifying a date range
#'
#' @param parameter type of parameter to download
#' \itemize{
#'  \item BEN - Benceno
#'  \item CH4 - Metano
#'  \item CN - Carbono negro
#'  \item CO - Monóxido de carbono
#'  \item CO2 - Dióxido de carbono
#'  \item DV - Dirección del viento
#'  \item H2S - Acido Sulfhídrico
#'  \item HCNM - Hidrocarburos no metánicos
#'  \item HCT - Hidrocarburos Totales
#'  \item HR - Humedad relativa
#'  \item HRI - Humedad relativa interior
#'  \item IUV - Índice de radiación ultravioleta
#'  \item NO - Óxido nítrico
#'  \item NO2 - Dióxido de nitrógeno
#'  \item NOx - Óxidos de nitrógeno
#'  \item O3 - Ozono
#'  \item PB - Presión Barométrica
#'  \item PM10 - Partículas menores a 10 micras
#'  \item PM2.5 - Partículas menores a 2.5 micras
#'  \item PP - Precipitación pluvial
#'  \item PST - Partículas Suspendidas totales
#'  \item RS - Radiación solar
#'  \item SO2 - Dióxido de azufre
#'  \item TMP - Temperatura
#'  \item TMPI - Temperatura interior
#'  \item UVA - Radiación ultravioleta A
#'  \item VV - Radiación ultravioleta B
#'  \item XIL - Xileno
#' }
#' @param start_date start of range in YYYY-MM-DD format
#' @param end_date end of range from which to download data in YYYY-MM-DD format
#' @param remove_extremes whether to remove extreme values. For O3 all values above .2 are set to NA,
#' for PM10 those above 600, for PM2.5 above 175, for NO2 above .21, for SO2 above .2, and for CO
#' above 15. This is done so that the values match exactly those of the SINAICA website, but it is
#' recommended that you use a more complicated statistical procedure to remove outliers.
#' @param type The type of data to download. One of the following:
#' \itemize{
#'  \item Crude - Crude data that has not been validated
#'  \item Manual - Manually collected data that is sent to an external
#'  lab for analysis (may no be collected daily). Mostly used for suspend particles collected by
#'  pushing air through a filter which is later sent to a lab to be weighted
#'  }
#'
#' @return data.frame with a column named \emph{value} containing the air quality parameter values.
#' If the data was validated the column named \emph{date_validated} will contain the validation
#' date. Care should be taken when working with hourly data since
#' each station has their own timezone (available in the \code{\link{stations_sinaica}} data.frame)
#' and some stations reported the timezome in which they are located erroneously.
#' @importFrom httr POST http_error content add_headers with_config config
#' @importFrom jsonlite fromJSON
#' @importFrom dplyr left_join
#' @importFrom utils data
#' @importFrom stats runif
#' @export
#' @examples
#' \dontrun{
#' ## May take several seconds
#' df <- sinaica_param_data("O3", "2015-10-14", "2015-10-14")
#' head(df)
#' }
sinaica_param_data <- function(parameter,
                               start_date,
                               end_date,
                               type = "Crude",
                               remove_extremes = FALSE) {
  ## Argument Checking
  if (missing(start_date))
    stop("You need to specify a start date in YYYY-MM-DD format", call. = FALSE)
  if (missing(end_date))
    stop("You need to specify an end date in YYYY-MM-DD format", call. = FALSE)
  if (!is.Date(start_date))
    stop("start_date should be in YYYY-MM-DD format", call. = FALSE)
  if (!is.Date(end_date))
    stop("end_date should be in YYYY-MM-DD format", call. = FALSE)
  check_arguments(parameter,
                  valid = c("BEN", "CH4", "CN", "CO", "CO2", "DV",
                            "H2S", "HCNM", "HCT",
                            "HR", "HRI", "IUV", "NO", "NO2",
                            "NOx",
                            "O3", "PB", "PM10",
                            "PM2.5", "PP", "PST", "RS", "SO2",
                            "TMP", "TMPI", "UVA", "UVB",
                            "VV", "XIL"),
                  "parameter")
  if (start_date > end_date)
    stop("start_date should be less than or equal to end_date")

  check_arguments(type,
                  valid = c("Crude", "Manual"),
                  "type")

  if (as.Date(end_date) > .increase_month(start_date))
    stop("The maximum amount of data you can download is 1 month",
         call. = FALSE)

  ## Query the SINAICA server for the data
  url <-  "https://sinaica.inecc.gob.mx/lib/j/php/getData.php"
  fd <- list(
    tabla  = if (type == "Crude") "Datos" else "DatosManuales",
    fields = "",
    where  = paste0("parametro = '", parameter, "' and fecha >= '", start_date,
                    "' and fecha <= '", end_date, "'")
  )
  result <- httr::with_config(httr::config(ssl_verifypeer = 0L), {
    POST(url,
         add_headers("user-agent" =
                       "https://github.com/diegovalle/rsinaica"),
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

  ## As not to overload the server wait a random value before the next call
  Sys.sleep(runif(1, max = 1.5))

  ## Clean the data
  if (type == "Crude")
    parameter_clean_crude(df, remove_extremes, parameter)
  else
    parameter_clean_manual(df, remove_extremes, parameter)
}

parameter_clean_manual <- function(df, remove_extremes, parameter){
  if (!length(df)) {
    return(data.frame(id = character(0), station_id = integer(0),
                      station_name = character(0),
                      station_code = character(0), network_name = character(0),
                      network_code = character(0),
                      network_id = integer(0), date = character(0),
                      hour = integer(0), parameter = character(0),
                      value_actual = character(0),
                      valid_actual = character(0),
                      validation_level = character(0),
                      unit = character(0),
                      value = numeric(0),
                      stringsAsFactors = FALSE)
    )
  }

  lim_perm <- switch(parameter, PM10 = 600, PM2.5 = 175, NO2 = .21,
                     SO2 = .2, CO = 15,
                     O3 = .2, 10000000000)
  df$value <- df$valorAct
  df$value <- as.numeric(df$value)
  df$value[which(!is.finite(df$value))] <- NA_real_
  df$value[which(df$validoAct == 0)] <- NA_real_
  df$value[which(df$value < 0)] <- NA_real_
  if (identical(remove_extremes, TRUE)) {
    ## Values above this are suppossed to be invalid
    df$value[which(df$value > lim_perm)] <- NA_real_
  }

  names(df) <- c("id", "station_id", "date",
                 "parameter", "value_actual",
                 "valid_actual",
                 "validation_level", "arichive_id",
                 "hour", "value")

  df$hour <- as.integer(df$hour)
  df$station_id <- as.integer(df$station_id)
  df <- left_join(df, stations_sinaica[, c("station_id",
                                           "station_name",
                                           "station_code",
                                           "network_name",
                                           "network_code",
                                           "network_id")],
                  by = c("station_id" = "station_id"))
  df$unit <- .recode_sinaica_units(parameter)
  df <- df[, c("id", "station_id", "station_name",  "station_code",
               "network_name",
               "network_code",
               "network_id", "date", "hour",
               "parameter",  "value_actual",
               "valid_actual",
               "validation_level", "unit", "value")]
  return(df)
}

parameter_clean_crude <- function(df, remove_extremes, parameter) {
  if (!length(df)) {
    return(data.frame(id = character(0), station_id = integer(0),
                      station_name = character(0), station_code = character(0),
                      network_name = character(0),
                      network_code = character(0),
                      network_id = integer(0), date = character(0),
                      hour = integer(0), parameter = character(0),
                      value_original = character(0),
                      flag_original = character(0),
                      valid_original = character(0),
                      value_actual = character(0),
                      valid_actual = character(0),
                      date_validated = character(0),
                      validation_level = character(0),
                      unit = character(0),
                      value = numeric(0),
                      stringsAsFactors = FALSE)
    )
  }

  df$estacionesId <- as.integer(df$estacionesId)
  df$fechaValidoAct <- as.character(df$fechaValidoAct)



  lim_perm <- switch(parameter, PM10 = 600, PM2.5 = 175, NO2 = .21,
                     SO2 = .2, CO = 15,
                     O3 = .2, 10000000000)
  df$value <- df$valorAct
  df$value <- as.numeric(df$value)
  df$value[which(!is.finite(df$value))] <- NA_real_
  df$value[which(df$validoAct == 0)] <- NA_real_
  df$value[which(df$value < 0)] <- NA_real_
  if (identical(remove_extremes, TRUE)) {
    ## Values above this are suppossed to be invalid
    df$value[which(df$value > lim_perm)] <- NA_real_
  }
  names(df) <- c("id", "station_id", "date", "hour",
                 "parameter", "value_original",
                 "flag_original", "valid_original", "value_actual",
                 "valid_actual", "date_validated",
                 "validation_level", "value")

  df$hour <- as.integer(df$hour)
  df$date_validated <- as.character(df$date_validated)
  data("stations_sinaica", package = "rsinaica", envir = environment())
  df <- left_join(df, stations_sinaica[, c("station_id",
                                           "station_name",
                                           "station_code",
                                           "network_name",
                                           "network_code",
                                           "network_id")],
                  by = c("station_id" = "station_id"))
  df$unit <- .recode_sinaica_units(parameter)
  df <- df[, c("id", "station_id", "station_name",  "station_code",
               "network_name",
               "network_code",
               "network_id", "date", "hour",
               "parameter", "value_original",
               "flag_original", "valid_original", "value_actual",
               "valid_actual", "date_validated",
               "validation_level", "unit", "value")]
  return(df)
}

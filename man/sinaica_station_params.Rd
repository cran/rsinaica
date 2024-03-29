% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sinaica_station_params_and_dates.R
\name{sinaica_station_params}
\alias{sinaica_station_params}
\title{Parameters supported by a station}
\usage{
sinaica_station_params(station_id, type = "Crude")
}
\arguments{
\item{station_id}{the numeric code corresponding to each station. See
\code{\link{stations_sinaica}} for a list of stations and their ids.}

\item{type}{The type of data to download. One of the following:
\itemize{
\item Crude - Crude data that has not been validated
\item Validated - Validated data (may not be the most up-to-date)
\item Manual - Manual data
}}
}
\value{
a data.frame with the parameters supported by the station
}
\description{
List of air quality parameters of a measuring station for which SINAICA has data
}
\examples{
## id 271 is Xalostoc. See `stations_sinaica`
df <- sinaica_station_params(271, "Crude")
head(df)
}

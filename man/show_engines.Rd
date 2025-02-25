% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/engines.R
\name{show_engines}
\alias{show_engines}
\title{Display currently available engines for a model}
\usage{
show_engines(x)
}
\arguments{
\item{x}{The name of a \code{parsnip} model (e.g., "linear_reg", "mars", etc.)}
}
\value{
A tibble.
}
\description{
The possible engines for a model can depend on what packages are loaded.
Some \pkg{parsnip} extension add engines to existing models. For example,
the \pkg{poissonreg} package adds additional engines for the \code{\link[=poisson_reg]{poisson_reg()}}
model and these are not available unless \pkg{poissonreg} is loaded.
}
\examples{
show_engines("linear_reg")
}

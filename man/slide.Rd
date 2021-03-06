% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/window.R
\name{slide}
\alias{slide}
\alias{slide_lst}
\alias{slide_dfr}
\alias{slider}
\title{Sliding window calculation}
\usage{
slide(x, .f, ..., size = 1, fill = NA_real_)

slide_lst(x, .f, ..., size = 1, fill = NA)

slide_dfr(x, .f, ..., size = 1, fill = NA, .id = NULL)

slider(x, size = 1)
}
\arguments{
\item{x}{A vector of numerics, or data frame. If a data frame, row-wise rolling
window is performed.}

\item{.f}{A function or one-sided formula using purrr-like syntax. If a
formula, it is converted to a function.}

\item{...}{Additional arguments passed on to \code{.f}.}

\item{size}{An integer for window size.}

\item{fill}{A single value or data frame to replace \code{NA}.}

\item{.id}{If not \code{NULL} a variable with this name will be created giving
either the name or the index of the data frame, which is passed to
\link[dplyr:bind_rows]{dplyr::bind_rows}.}
}
\description{
Rolling window with overlapping observations:
\itemize{
\item \code{slide()} always returns a vector of numerics
\item \code{slide_lst()} returns a list
\item \code{slide_dfr()} return data frame using row-binding
\item \code{slider()} splits the input \code{x} to a list according to the window size.
}
}
\details{
The \code{slide()} function attempts to tackle more general problems using
the purrr-like syntax. For some specialist functions like \code{mean} and \code{sum},
you may like to check out for
\href{https://CRAN.R-project.org/package=RcppRoll}{RcppRoll} for faster performance.
}
\examples{
# sliding through a vector ----
x <- 1:10
slide(x, mean, size = 3)
slide(x, ~ mean(.), size = 3)
slide(x, mean, size = 3, fill = 0)

# slider ----
slider(x, size = 3)

\dontrun{
# takes a little longer for cran check
# sliding a 2-day window for a data frame ----
jan <- pedestrian \%>\% 
  filter(Date <= as.Date("2015-01-31")) \%>\% 
  split_by(Sensor)
# returns a data frame of fitted values and residuals for each sensor,
# and then combines
diag_jan <- jan \%>\%
  purrr::map_dfr(
    ~ slide_dfr(., function(x) {
      fit <- lm(Count ~ Time, data = x)
      data.frame(fitted = fitted(fit), resid = residuals(fit))
    }, size = 48)
  )
diag_jan[48:57, ]
# save lm models as additional columns
lm_jan <- jan \%>\% 
  purrr::map(
    ~ mutate(., lm = slide_lst(., ~ lm(Count ~ Time, data = .), size = 48)
  ))
lm_jan[[1]][48:57, ]
}
}
\seealso{
\link{tile} for tiling window without overlapping observations;
\link{stretch} for expanding more observations
}

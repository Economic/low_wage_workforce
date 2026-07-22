## library() calls go here
library(conflicted)
library(dotenv)
library(targets)
library(tarchetypes)
options(tidyverse.quiet = TRUE)
library(tidyverse)
library(epitargets)
options(epiextractr.quiet = TRUE)
library(epiextractr)
library(epidatatools)
library(haven)
library(realtalk)
library(arrow)
library(janitor)
library(scales)
library(slider)
library(MetricsWeighted)
library(assertr)
library(ipumsr)
library(fs)

## Resolve conflicts
conflicts_prefer(
  dplyr::filter,
  dplyr::lag,
  .quiet = T
)

## library() calls go here
library(conflicted)
library(dotenv)
library(targets)
library(tarchetypes)
suppressPackageStartupMessages(library(tidyverse))
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

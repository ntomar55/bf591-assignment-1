library(tibble)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
# library(purrr)


# ----------------------- Helper Functions to Implement ------------------------

#' Read the expression data "csv" file.
#'
#' Function to read microarray expression data stored in a csv file. The
#' function should return a sample x gene tibble, with an extra column named
#' "subject_id" that contains the geo accession ids for each subject.
#'
#' @param filename (str): the file to read.
#'
#' @return
#' @export
#'
#' @examples expr_mat <- read_expression_table('example_intensity_data.csv')
read_expression_table <- function(filename) {
  exp_data <- readr::read_delim(filename, " ")
  exp_data_t <- t(exp_data)
  colname = exp_data_t[1,]
  colname = c("subject_id", colname)
  exp_data_tbl <- tibble::as_tibble(cbind(names(exp_data), t(exp_data)))
  
  exp_data_tbl <- exp_data_tbl[-1,]
  names(exp_data_tbl) <- colname
  #head(exp_data_tbl[1:13])
  return (exp_data_tbl)
}

#' Replaces all '.' in a string with '_'
#'
#' @param str String to operate upon.
#'
#' @return reformatted string.
#' @export
#'
#' @examples
#' period_to_underscore("foo.bar")
#' "foo_bar"
period_to_underscore <- function(str) {
  changed_str <- str_replace_all(str, "[.]", "_")
  return (changed_str)
}
metadata <- readr::read_csv("data/proj_metadata.csv")
colnames(metadata)
lapply(colnames(metadata), period_to_underscore)

# rename variables:
# Age_at_diagnosis to Age
# SixSubtypesClassification to Subtype
# normalizationcombatbatch to Batch

#' Rename and select specified columns.
#'
#' Function to rename Age_at_diagnosis, SixSubtypesClassification, and
#' normalizationcombatbatch columns to Age, Subtype, and Batch, respectively. A
#' subset of the data should be returned, containing only the Sex, Age, TNM_Stage,
#' Tumor_Location, geo_accession, KRAS_Mutation, Subtype, and Batch columns.
#'
#' @param data (tibble) metadata information for each sample
#'
#' @return (tibble) renamed and subsetted tibble
#' @export
#'
#' @examples rename_and_select(metadata)
#' 
#' 
rename_and_select <- function(data) {
  col_renamed_data = rename(data, Age=Age_at_diagnosis, Subtype=SixSubtypesClassification, Batch=normalizationcombatbatch)
  subsetted_data = select(col_renamed_data,Sex,Age,TNM_Stage,Tumor_Location,geo_accession,KRAS_Mutation,Subtype,Batch)
  #print(dim(subsetted_data))
  #print(dim(col_renamed_data))
  #print(head(subsetted_data))
  return (subsetted_data)
}

#' Create new "Stage" column containing "stage " prefix.
#'
#' Creates a new column "Stage" with elements following a "stage x" format, where
#' `x` is the cancer stage data held in the existing TNM_Stage column. Stage
#' should have a factor data type.
#'
#' @param data  (tibble) metadata information for each sample
#'
#' @return (tibble) updated metadata with "Stage" column
#' @export
#'
#' @examples metadata <- stage_as_factor(metadata)
stage_as_factor <- function(data) {
  data$Stage <- (factor(as.character(lapply(data$TNM_Stage, function(stg){ return (paste(c("stage", stg), collapse = " ")) }))))
  return (data)
}


#' Calculate age of samples from a specified sex.
#'
#' @param data (tibble) metadata information for each sample
#' @param sex (str) which sex to calculate mean age. Possible values are "M"
#' and "F"
#'
#' @return (float) mean age of specified samples
#' @export
#'
#' @examples mean_age_by_sex(metadata, "F")
mean_age_by_sex <- function(data, sex) {
  age_by_sex_col = filter(data, Sex==sex)$Age
  return (mean(age_by_sex_col))
}


#' Calculate average age of samples within each cancer stage. Stages should be
#' from the newly created "Stage" column.
#'
#' @param data (tibble) metadata information for each sample
#'
#' @return (tibble) summarized tibble containing average age for all samples from
#' each stage.
#' @export
#'
#' @examples age_by_stage(data)
age_by_stage <- function(data) {
  #data = selected_metadata
  summary_tbl <- select(data,Stage,Age) %>%
    group_by(Stage) %>%
    summarise(mean(Age))
  return (summary_tbl)
}

#' Create a cross tabulated table for Subtype and Stage using dplyr methods.
#'
#' @param data (tibble) metadata information for each sample
#'
#' @return (tibble) table where rows are the cancer stage of each sample, and the
#' columns are each cancer subtype. Elements represent the number of samples from
#' the corresponding stage and subtype. If no instances of a specific pair are
#' observed, a zero entry is expected.
#' @export
#'
#' @examples cross_tab <- dplyr_cross_tab(metadata)
subtype_stage_cross_tab <- function(data) {
  summary_tbl <- data %>%
   group_by(Stage, Subtype) %>%
    summarise(n = n())
  return (summary_tbl)
}

#' Summarize average expression and probe variability over expression matrix.
#'
#' @param exprs An (n x p) expression matrix, where n is the number of samples,
#' and p is the number of probes.
#'
#' @return A summarized tibble containing `main_exp`, `variance`, and `probe`
#' columns documenting average expression, probe variability, and probe ids,
#' respectively.
summarize_expression <- function(exprs) {
  exprs = readr::read_delim("data/example_intensity_data.csv", " ")
  head(exprs)
  mean_exp = rowMeans(select(exprs, starts_with("GSM")), na.rm = TRUE)
  RowVar <- function(x, ...) {
    rowSums((x - rowMeans(x, ...))^2, ...)/(dim(x)[2] - 1)
  }
  variance = RowVar(exprs[,-1])
  #summarise_all(exprs, mean)
  new_tbl = select(exprs, probe)
  new_tbl$mean_exp = mean_exp
  new_tbl$variance = variance
  relocate(new_tbl, variance, .before = probe)
  new_tbl = relocate(new_tbl, mean_exp, .before = probe, variance)
  return(new_tbl)
}

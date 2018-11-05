#!/usr/bin/env Rscript

## Load library
library(rmarkdown)

## Render HTML output
render('reports/low_grade_debt_consolidation_report.Rmd', output_format='html_document')

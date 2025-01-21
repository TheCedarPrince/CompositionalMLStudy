---
jupyter:
  jupytext:
    text_representation:
      extension: .md
      format_name: markdown
      format_version: '1.3'
      jupytext_version: 1.14.7
  kernelspec:
    display_name: Julia 1.10.5
    language: julia
    name: julia-1.10
---

# Analysis Set-up

```julia
using DrWatson
@quickactivate "CompositionalMLStudy"

using CairoMakie
using Dates
using OMOPCDMCohortCreator
using CSV
using DataFrames
using IPUMS
using LibPQ
using MLJ

import DBInterface:
    connect,
    execute

import DrWatson:
  datadir

import FunSQL:
    reflect,
    render

import IPUMS:
  load_ipums_extract,
  parse_ddi

import OMOPCDMCohortCreator:
    GenerateDatabaseDetails,
    GenerateTables

import OHDSICohortExpressions:
    translate,
    Model
```

## Data Configuration

### IPUMS Data Directory

```julia
# IPUMS Data Directory
IPUMS_DIR = datadir("exp_raw", "IPUMS")

# DDI Data Dictionary
DDI_FILE = "cps_00097.xml"

# IPUMS CPS Example Data 
DAT_FILE = "cps_00097.dat"
```

### Load Data

```julia
omop_db_conn = connect(LibPQ.Connection, "user=thecedarprince dbname=synthea");
GenerateDatabaseDetails(:postgresql, "omop");
omop_tables = GenerateTables(omop_db_conn, exported = true);
```

```julia
ddi = parse_ddi(joinpath(IPUMS_DIR, DDI_FILE));
ipums = load_ipums_extract(ddi, joinpath(IPUMS_DIR, DAT_FILE));
```

```julia
weather_data = CSV.read(datadir("exp_raw", "climdiv-tmpcst-v1.0.0-20241021-filtered"), DataFrame, header = false, delim = "  ")
filter!(row -> row.Column1[5:6] == "02", weather_data)
states = [row[1:3] for row in weather_data.Column1]
years = [parse(Int, row[7:10]) for row in weather_data.Column1]
weather_data = weather_data[:, Not(:Column1, :Column14)]
rename!(weather_data, Dates.monthname.(1:12))
weather_data.Year = years
weather_data.State = states
```

# Patients with a History of Myocardial Infarction

## Finding Patients Who Have Had Myocardial Infarction

```julia
cohort_expression = read("data/myocardial_infarction.json", String)

fun_sql = translate(
    cohort_expression,
    cohort_definition_id = 1
);

catalog = reflect(
    omop_db_conn;
    schema = "omop",
    dialect=:postgresql
);

sql = render(catalog, fun_sql);

res = execute(omop_db_conn,
    """
    INSERT INTO
        omop.cohort
    SELECT
        *
    FROM
        ($sql) AS foo;
    """
)

cohort = GetCohortSubjects([1], omop_db_conn)
```

## Finding When Initial Myocardial Infarctions Took Place

```julia
cohort = GetCohortSubjectStartDate([1], cohort.subject_id, omop_db_conn)
rename!(cohort, :subject_id => :person_id)
```

## Getting Patient Demographic Information

```julia
cohort = GetPatientGender(cohort, omop_db_conn) |>
x -> GetPatientAgeGroup(x, omop_db_conn) |>
x -> GetPatientRace(x, omop_db_conn)
```

# Manually Combining Data Together

## Remarks

Inspecting the datasets, it seems like the following holds true:

- The temporal axis is the constraining feature between all these data sets.

    * The temporal limitation observed comes from the IPUMS data 

- The only reliably shared features between datasets are:

    * Year

    * Month

- Data can really only be used reliably between $2011$ and $2010$

## Filtering and Combining Datasets

```julia
filter!(row -> row.Year == 2011, weather_data)
ipums = ipums[!, Not([:CPSIDP, :ASECWT, :CPSID, :PERNUM, :ASECFLAG, :ASECWTH, :SERIAL, :YEAR])]
patients = filter!(row -> year(row.cohort_start_date) == 2011 || year(row.cohort_start_date) == 2010, cohort)
```

## Creating DataFrame for Prediction

```julia

```

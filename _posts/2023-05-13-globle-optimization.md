
You may have heard of a geography came that came out during the Great
Wordle Clone Wave of 2022, called [Globle](https://globle-game.com) — if
you haven’t, go check it out! The idea is, you guess a country, and it
gives you “hot or cold” feedback: the redder the country’s land mass is
highlighted, the closer you are to the country of the day. Their example
is, if the mystery country is **Japan**, the following countries would
appear with these colors if guessed:<!--more-->

| ![](/assets/img/france.svg) | ![](/assets/img/nepal.svg) | ![](/assets/img/mongolia.svg) | ![](/assets/img/south_korea.svg) |
|:---------------------------:|:--------------------------:|:-----------------------------:|:--------------------------------:|
|         **France**          |         **Nepal**          |         **Mongolia**          |         **South Korea**          |

## The Optimization

With my overthink-everything brain, after a few days I decided I wanted
to go and figure out the **OPTIMAL** first guess: this could be defined
in a bunch of ways, but to me it boiled down to, which country is
closest, on average, to *all* other countries in the world?

Like the definition of “optimal” here, the definition of “close” we use
could massively change the results: should we say two countries are
distance-zero from each other if their borders touch? What about
exclaves like [Kaliningrad](https://en.wikipedia.org/wiki/Kaliningrad)?
Or, even more chaotically, what about e.g. French *départements* in
entirely different continents[^1], like [French
Guiana](https://en.wikipedia.org/wiki/French_Guiana) in South America?
Should we say that Suriname and Brazil are distance-zero from France?

Long story short, I was able to bunny-hop over these complexities by

- Deciding to use the **centroid** of each country as its “official”
  location, and
- Finding a data source which determined these centroids in a way that
  avoided them being skewed by overseas regions by defining a “main”
  landmass, and computing the centroid of that mass.

The second part is really the key here, as using the centroid of *all*
the nation’s territory could lead to France’s centroid being somewhere
in the Atlantic Ocean near the equator, while Denmark’s would be
somewhere a bit south of Iceland, halfway to
[Greenland](https://en.wikipedia.org/wiki/Greenland).

## The Data

The dataset which met all of my requirements, and came in the form of a
convenient R package, was the [CEPII GeoDist
dataset](http://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=6):

> GeoDist provides several geographical variables, in particular
> bilateral distances measured using city-level data to account for the
> geographic distribution of population inside each nation. Different
> measures of bilateral distances are available for 225 countries. For
> most of them, different calculations of “intra-national distances’’
> are also available.

At first I downloaded the `.dta` files from that link and transformed
them into regular `.csv` files for use in `R`. Then I learned of their
[R package](https://cran.r-project.org/web/packages/cepiigeodist/),
`cepiigeodist`, which saved yet more time. By just loading this library
(plus `tidyverse` to enable pipe operations, and `countrycode` which
helps translate between different official ISO country codes):

``` r
library(cepiigeodist)
library(tidyverse)
library(countrycode)
```

You instantly have a variable called `dist_cepii` in your environment,
containing pairwise distances (calculated a few different ways) between
all countries[^2]:



<details>
<summary markdown="span">Code</summary>

``` r
# Keep only distance vars, plus ids
dists <- dist_cepii %>%
  select(iso_o, iso_d, smctry, dist, distcap, distw, distwces)
# Drop pairs that are the same country
dists <- dists %>%
  filter(smctry == 0) %>%
  filter(iso_o != iso_d)
# We don't need smctry anymore
dists <- dists %>%
  select(-smctry)
# Convert the weighted dists to floats
dists <- dists %>%
  mutate(distw_num = suppressWarnings(as.numeric(distw)))
dists %>% head(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| iso_o | iso_d |       dist |    distcap | distw              | distwces           |  distw_num |
|:------|:------|-----------:|-----------:|:-------------------|:-------------------|-----------:|
| ABW   | AFG   | 13257.8100 | 13257.8100 | 13168.219999999999 | 13166.370000000001 | 13168.2200 |
| ABW   | AGO   |  9516.9130 |  9516.9130 | 9587.3160000000007 | 9584.1929999999993 |  9587.3160 |
| ABW   | AIA   |   983.2682 |   983.2682 | 976.89739999999995 | 976.89160000000004 |   976.8974 |
| ABW   | ALB   |  9091.7420 |  9091.7420 | 9091.5759999999991 | 9091.4660000000003 |  9091.5760 |
| ABW   | AND   |  7572.7880 |  7572.7880 | 7570.0839999999998 | 7570.0829999999996 |  7570.0840 |

</div>

The `dist` and `distcap` columns are straightforward: the distances
between the countries’ centroids and capital cities, respectively. The
weighted variables, `distw` and `distwcec`, are called
“gravity-weighted” distances, which in this case means that the original
distances are weighted “using city-level data to assess the geographic
distribution of population (in 2004) inside each nation” (see
[here](http://www.cepii.fr/PDF_PUB/wp/2011/wp2011-25.pdf) for full
details).

After some basic cleaning—dropping some too-small countries with strange
distance values and providing custom labels for six countries not
included in the `countrycode` helper library, we get a version with
readable country names:



<details>
<summary markdown="span">Code</summary>

``` r
dists <- dists %>%
  mutate(
    country_o = countrycode(iso_o, origin='iso3c', destination='country.name'),
    country_d = countrycode(iso_d, origin='iso3c', destination='country.name')
  ) %>%
  select(country_o, country_d, everything())
code_map <- list(
  'ANT'='Netherlands Antilles',
  'PAL'='Palestine',
  'ROM'='Romania',
  'TMP'='East Timor',
  'YUG'='Yugoslavia',
  'ZAR'='Zaire'
)
#print(names(code_map))
for (code in names(code_map)) {
  #print(c(code, code_map[[code]]))
  dists[dists$iso_o == code, 'country_o'] <- code_map[[code]]
  dists[dists$iso_d == code, 'country_d'] <- code_map[[code]]
}
# Also dropping a few
dists <- dists %>%
  filter(country_o != "French Polynesia" & country_d != "French Polynesia") %>%
  filter(country_o != "Cook Islands" & country_d != "Cook Islands") %>%
  filter(country_o != "Pitcairn Islands" & country_d != "Pitcairn Islands")
dists %>% head(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country_o | country_d   | iso_o | iso_d |       dist |    distcap | distw              | distwces           |  distw_num |
|:----------|:------------|:------|:------|-----------:|-----------:|:-------------------|:-------------------|-----------:|
| Aruba     | Afghanistan | ABW   | AFG   | 13257.8100 | 13257.8100 | 13168.219999999999 | 13166.370000000001 | 13168.2200 |
| Aruba     | Angola      | ABW   | AGO   |  9516.9130 |  9516.9130 | 9587.3160000000007 | 9584.1929999999993 |  9587.3160 |
| Aruba     | Anguilla    | ABW   | AIA   |   983.2682 |   983.2682 | 976.89739999999995 | 976.89160000000004 |   976.8974 |
| Aruba     | Albania     | ABW   | ALB   |  9091.7420 |  9091.7420 | 9091.5759999999991 | 9091.4660000000003 |  9091.5760 |
| Aruba     | Andorra     | ABW   | AND   |  7572.7880 |  7572.7880 | 7570.0839999999998 | 7570.0829999999996 |  7570.0840 |

</div>

Finally, with a somewhat scary-looking single `dplyr` (piped) operation,
we get our average distances for each country, using a few different
ways of measuring “average”:



<details>
<summary markdown="span">Code</summary>

``` r
mean_dists <- dists %>%
  group_by(country_o) %>%
  summarize(
    mean_dist = mean(dist),
    median_dist = median(dist),
    max_dist = max(dist),
    argmax_dist = country_d[which.max(dist)],
    min_dist = min(dist),
    argmin_dist = country_d[which.min(dist)],
    mean_distw = mean(distw_num, na.rm=TRUE),
    median_distw = median(distw_num, na.rm=TRUE),
    max_distw = max(distw_num, na.rm=TRUE),
    argmax_distw = country_d[which.max(distw_num)],
    p90_distw = quantile(distw_num, 0.9, na.rm=TRUE),
    min_distw = min(distw_num, na.rm=TRUE),
    argmin_distw = country_d[which.min(distw_num)],
    mean_distcap = mean(distcap),
    median_distcap = median(distcap),
    max_distcap = max(distcap),
    argmax_distcap = country_d[which.max(distcap)],
    min_distcap = min(distcap),
    argmin_distcap = country_d[which.min(distcap)]
  ) %>%
  rename(country=country_o)
#%>%
#  select(country_o, everything())
mean_dists %>% head(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country     | mean_dist | median_dist | max_dist | argmax_dist | min_dist | argmin_dist     | mean_distw | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw        | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:------------|----------:|------------:|---------:|:------------|---------:|:----------------|-----------:|-------------:|----------:|:-------------|----------:|----------:|:--------------------|-------------:|---------------:|------------:|:---------------|------------:|:----------------|
| Afghanistan |  7490.292 |    6351.646 | 16353.90 | Chile       | 374.6522 | Pakistan        |   7442.843 |     6443.254 |  16262.29 | Chile        |  13290.70 |  498.4332 | Tajikistan          |     7480.183 |       6351.646 |    16353.90 | Chile          |    374.6522 | Pakistan        |
| Albania     |  6383.108 |    5795.587 | 17971.90 | New Zealand | 155.9628 | North Macedonia |   6328.318 |     5625.398 |  17853.96 | New Zealand  |  11658.82 |  168.1648 | North Macedonia     |     6370.987 |       5747.847 |    17971.90 | New Zealand    |    155.9628 | North Macedonia |
| Algeria     |  6571.217 |    6157.438 | 18953.23 | New Zealand | 643.6230 | Andorra         |   6516.543 |     5986.565 |  19107.99 | New Zealand  |  11645.69 |  781.0697 | Andorra             |     6561.525 |       6102.879 |    18953.23 | New Zealand    |    643.6230 | Andorra         |
| Andorra     |  6548.793 |    6214.106 | 19455.71 | New Zealand | 492.9274 | Spain           |   6487.443 |     6067.936 |  19278.08 | New Zealand  |  11849.80 |  519.3864 | Spain               |     6539.376 |       6214.106 |    19455.71 | New Zealand    |    492.9274 | Spain           |
| Angola      |  7636.282 |    7169.937 | 17965.46 | Tokelau     | 553.1064 | Zaire           |   7649.624 |     7230.497 |  17829.95 | Tokelau      |  12864.15 |  681.5906 | Congo - Brazzaville |     7632.548 |       7169.937 |    17965.46 | Tokelau        |    553.1064 | Zaire           |

</div>

The `mean_dist`, `median_dist`, `max_dist`, and `min_dist` columns are
self-explanatory, but `argmax_dist` tells us the country that is
*furthest away* from a given country, while `argmin_dist` tells us the
country that is *closest*. `p90_distw` tells us the 90th percentile of
the `distw` measure between this country and all other countries (this
is how I caught the strange distances for the countries we dropped in
the previous step).

## The Results

Now that we have our average distances, we can get our result: the
country that is closest, on average, to all other countries! Let’s look
at a few different ways of computing this average, starting with the
**landmass centroid-based** measures:

### Mean of Distances

**Top 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_mean <- mean_dists %>%
  arrange(mean_dist) %>%
  select(country, mean_dist, everything())
sorted_mean %>% head(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country    | mean_dist | median_dist | max_dist | argmax_dist | min_dist | argmin_dist     | mean_distw | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw    | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:-----------|----------:|------------:|---------:|:------------|---------:|:----------------|-----------:|-------------:|----------:|:-------------|----------:|----------:|:----------------|-------------:|---------------:|------------:|:---------------|------------:|:----------------|
| Albania    |  6383.108 |    5795.587 | 17971.90 | New Zealand | 155.9628 | North Macedonia |   6328.318 |     5625.398 |  17853.96 | New Zealand  |  11658.82 |  168.1648 | North Macedonia |     6370.987 |       5747.847 |    17971.90 | New Zealand    |    155.9628 | North Macedonia |
| Bulgaria   |  6395.541 |    5785.217 | 17735.26 | New Zealand | 168.0973 | North Macedonia |   6354.845 |     5548.004 |  17445.41 | New Zealand  |  11839.60 |  311.9887 | North Macedonia |     6382.957 |       5785.217 |    17735.26 | New Zealand    |    168.0973 | North Macedonia |
| Greece     |  6401.242 |    5675.844 | 17541.17 | Niue        | 485.2823 | North Macedonia |   6345.718 |     5432.146 |  17521.98 | Niue         |  11668.36 |  420.2454 | North Macedonia |     6388.844 |       5675.844 |    17541.17 | Niue           |    485.2823 | North Macedonia |
| Italy      |  6410.571 |    5996.121 | 18572.15 | New Zealand | 230.0196 | San Marino      |   6365.753 |     5680.541 |  18460.90 | New Zealand  |  11963.57 |  327.9480 | San Marino      |     6399.405 |       5884.250 |    18572.15 | New Zealand    |    230.0196 | San Marino      |
| San Marino |  6415.701 |    6079.517 | 18621.28 | New Zealand | 230.0196 | Italy           |   6358.362 |     5795.321 |  18427.01 | New Zealand  |  11910.63 |  308.0931 | Slovenia        |     6404.382 |       5971.463 |    18621.28 | New Zealand    |    230.0196 | Italy           |

</div>

**Bottom 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_mean %>% tail(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country     | mean_dist | median_dist | max_dist | argmax_dist |  min_dist | argmin_dist     | mean_distw | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw    | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:------------|----------:|------------:|---------:|:------------|----------:|:----------------|-----------:|-------------:|----------:|:-------------|----------:|----------:|:----------------|-------------:|---------------:|------------:|:---------------|------------:|:----------------|
| Vanuatu     |  13279.77 |    14298.53 | 19579.91 | Mauritania  |  538.6225 | New Caledonia   |   13326.29 |     14359.81 |  19599.64 | Mauritania   |  17325.20 |  579.1039 | New Caledonia   |     13286.01 |       14305.40 |    19579.91 | Mauritania     |    538.6225 | New Caledonia   |
| Niue        |  13368.45 |    14482.60 | 19108.23 | Chad        |  604.2923 | Tonga           |   13423.24 |     14816.30 |  19226.05 | Niger        |  17551.72 |  581.7195 | Tonga           |     13378.56 |       14589.33 |    19108.23 | Chad           |    604.2923 | Tonga           |
| New Zealand |  13444.43 |    13871.83 | 19586.18 | Spain       | 1799.7050 | Norfolk Island  |   13491.00 |     13994.94 |  19647.66 | Gibraltar    |  18046.90 | 1322.4910 | Norfolk Island  |     13453.14 |       13874.92 |    19586.18 | Spain          |   1799.7050 | Norfolk Island  |
| Fiji        |  13512.67 |    14275.24 | 19388.75 | Niger       |  788.5273 | Wallis & Futuna |   13570.82 |     14377.85 |  19384.72 | Burkina Faso |  17938.90 |  788.8261 | Wallis & Futuna |     13520.41 |       14275.24 |    19388.75 | Niger          |    788.5273 | Wallis & Futuna |
| Tonga       |  13673.66 |    14556.90 | 19139.56 | Niger       |  604.2923 | Niue            |   13732.91 |     14722.22 |  19222.06 | Niger        |  17742.83 |  581.7196 | Niue            |     13683.17 |       14556.90 |    19139.56 | Niger          |    604.2923 | Niue            |

</div>

### Median of Distances

**Top 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_median <- mean_dists %>%
  arrange(median_dist) %>%
  select(country, median_dist, everything())
sorted_median %>% head(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country | median_dist | mean_dist | max_dist | argmax_dist |  min_dist | argmin_dist       | mean_distw | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw      | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap |
|:--------|------------:|----------:|---------:|:------------|----------:|:------------------|-----------:|-------------:|----------:|:-------------|----------:|----------:|:------------------|-------------:|---------------:|------------:|:---------------|------------:|:---------------|
| Sudan   |    5018.948 |  6848.041 | 17618.83 | Niue        |  681.6393 | Eritrea           |   6830.272 |     4954.066 |  17620.83 | Niue         |  12608.62 |  818.3794 | Eritrea           |     6836.581 |       5014.771 |    17618.83 | Niue           |    681.6393 | Eritrea        |
| Egypt   |    5247.417 |  6526.851 | 17570.36 | Niue        |  346.6150 | Palestine         |   6478.056 |     5168.484 |  17581.45 | Niue         |  12184.41 |  410.3289 | Palestine         |     6513.576 |       5247.417 |    17570.36 | Niue           |    346.6150 | Palestine      |
| Eritrea |    5307.508 |  6980.465 | 16947.59 | Niue        |  574.1962 | Yemen             |   6963.982 |     5125.310 |  16893.26 | Niue         |  13184.02 |  567.4298 | Djibouti          |     6969.185 |       5184.840 |    16947.59 | Niue           |    574.1962 | Yemen          |
| Chad    |    5364.059 |  6986.228 | 19192.57 | Tokelau     | 1158.0940 | Equatorial Guinea |   6965.297 |     5450.785 |  19137.92 | Tokelau      |  12235.48 | 1232.0420 | Equatorial Guinea |     6975.912 |       5364.059 |    19192.57 | Tokelau        |    916.8266 | Nigeria        |
| Jordan  |    5390.645 |  6559.271 | 17076.25 | Niue        |  111.0933 | Israel            |   6513.777 |     5292.887 |  17082.49 | Niue         |  12443.22 |  114.6373 | Israel            |     6545.317 |       5390.645 |    17076.25 | Niue           |    111.0933 | Israel         |

</div>

**Bottom 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_median %>% tail(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country         | median_dist | mean_dist | max_dist | argmax_dist    | min_dist | argmin_dist     | mean_distw | median_distw | max_distw | argmax_distw   | p90_distw | min_distw | argmin_distw  | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:----------------|------------:|----------:|---------:|:---------------|---------:|:----------------|-----------:|-------------:|----------:|:---------------|----------:|----------:|:--------------|-------------:|---------------:|------------:|:---------------|------------:|:----------------|
| Norfolk Island  |    14329.12 |  13177.62 | 19795.78 | Western Sahara | 770.1298 | New Caledonia   |   13244.26 |     14382.40 |  19710.59 | Western Sahara |  17398.00 |  822.5537 | New Caledonia |     13185.25 |       14307.25 |    19795.78 | Western Sahara |    770.1298 | New Caledonia   |
| Tokelau         |    14367.60 |  13251.50 | 19458.98 | Nigeria        | 662.7784 | Wallis & Futuna |   13312.78 |     14598.70 |  19553.24 | Nigeria        |  17369.79 |  516.8264 | Samoa         |     13260.48 |       14367.60 |    19940.46 | Nigeria        |    662.7784 | Wallis & Futuna |
| Niue            |    14482.60 |  13368.45 | 19108.23 | Chad           | 604.2923 | Tonga           |   13423.24 |     14816.30 |  19226.05 | Niger          |  17551.72 |  581.7195 | Tonga         |     13378.56 |       14589.33 |    19108.23 | Chad           |    604.2923 | Tonga           |
| Wallis & Futuna |    14540.30 |  13207.36 | 19846.20 | Niger          | 662.7784 | Tokelau         |   13261.60 |     14538.54 |  19697.69 | Niger          |  17749.21 |  470.5988 | Samoa         |     13215.18 |       14540.30 |    19846.20 | Niger          |    662.7784 | Tokelau         |
| Tonga           |    14556.90 |  13673.66 | 19139.56 | Niger          | 604.2923 | Niue            |   13732.91 |     14722.22 |  19222.06 | Niger          |  17742.83 |  581.7196 | Niue          |     13683.17 |       14556.90 |    19139.56 | Niger          |    604.2923 | Niue            |

</div>

### Mean of Weighted Distances

(We need to drop NAs for the weighted measures)

**Top 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_mean_distw <- mean_dists %>%
  arrange(mean_distw) %>%
  select(country, mean_distw, everything()) %>%
  drop_na(mean_distw)
sorted_mean_distw %>% head(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country    | mean_distw | mean_dist | median_dist | max_dist | argmax_dist | min_dist | argmin_dist     | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw    | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:-----------|-----------:|----------:|------------:|---------:|:------------|---------:|:----------------|-------------:|----------:|:-------------|----------:|----------:|:----------------|-------------:|---------------:|------------:|:---------------|------------:|:----------------|
| Albania    |   6328.318 |  6383.108 |    5795.587 | 17971.90 | New Zealand | 155.9628 | North Macedonia |     5625.398 |  17853.96 | New Zealand  |  11658.82 |  168.1648 | North Macedonia |     6370.987 |       5747.847 |    17971.90 | New Zealand    |    155.9628 | North Macedonia |
| Greece     |   6345.718 |  6401.242 |    5675.844 | 17541.17 | Niue        | 485.2823 | North Macedonia |     5432.146 |  17521.98 | Niue         |  11668.36 |  420.2454 | North Macedonia |     6388.844 |       5675.844 |    17541.17 | Niue           |    485.2823 | North Macedonia |
| Bulgaria   |   6354.845 |  6395.541 |    5785.217 | 17735.26 | New Zealand | 168.0973 | North Macedonia |     5548.004 |  17445.41 | New Zealand  |  11839.60 |  311.9887 | North Macedonia |     6382.957 |       5785.217 |    17735.26 | New Zealand    |    168.0973 | North Macedonia |
| San Marino |   6358.362 |  6415.701 |    6079.517 | 18621.28 | New Zealand | 230.0196 | Italy           |     5795.321 |  18427.01 | New Zealand  |  11910.63 |  308.0931 | Slovenia        |     6404.382 |       5971.463 |    18621.28 | New Zealand    |    230.0196 | Italy           |
| Italy      |   6365.753 |  6410.571 |    5996.121 | 18572.15 | New Zealand | 230.0196 | San Marino      |     5680.541 |  18460.90 | New Zealand  |  11963.57 |  327.9480 | San Marino      |     6399.405 |       5884.250 |    18572.15 | New Zealand    |    230.0196 | San Marino      |

</div>

**Bottom 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_mean_distw %>% tail(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country     | mean_distw | mean_dist | median_dist | max_dist | argmax_dist |  min_dist | argmin_dist     | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw    | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:------------|-----------:|----------:|------------:|---------:|:------------|----------:|:----------------|-------------:|----------:|:-------------|----------:|----------:|:----------------|-------------:|---------------:|------------:|:---------------|------------:|:----------------|
| Vanuatu     |   13326.29 |  13279.77 |    14298.53 | 19579.91 | Mauritania  |  538.6225 | New Caledonia   |     14359.81 |  19599.64 | Mauritania   |  17325.20 |  579.1039 | New Caledonia   |     13286.01 |       14305.40 |    19579.91 | Mauritania     |    538.6225 | New Caledonia   |
| Niue        |   13423.24 |  13368.45 |    14482.60 | 19108.23 | Chad        |  604.2923 | Tonga           |     14816.30 |  19226.05 | Niger        |  17551.72 |  581.7195 | Tonga           |     13378.56 |       14589.33 |    19108.23 | Chad           |    604.2923 | Tonga           |
| New Zealand |   13491.00 |  13444.43 |    13871.83 | 19586.18 | Spain       | 1799.7050 | Norfolk Island  |     13994.94 |  19647.66 | Gibraltar    |  18046.90 | 1322.4910 | Norfolk Island  |     13453.14 |       13874.92 |    19586.18 | Spain          |   1799.7050 | Norfolk Island  |
| Fiji        |   13570.82 |  13512.67 |    14275.24 | 19388.75 | Niger       |  788.5273 | Wallis & Futuna |     14377.85 |  19384.72 | Burkina Faso |  17938.90 |  788.8261 | Wallis & Futuna |     13520.41 |       14275.24 |    19388.75 | Niger          |    788.5273 | Wallis & Futuna |
| Tonga       |   13732.91 |  13673.66 |    14556.90 | 19139.56 | Niger       |  604.2923 | Niue            |     14722.22 |  19222.06 | Niger        |  17742.83 |  581.7196 | Niue            |     13683.17 |       14556.90 |    19139.56 | Niger          |    604.2923 | Niue            |

</div>

### Median of Weighted Distances

**Top 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_median_distw <- mean_dists %>%
  arrange(median_distw) %>%
  select(country, median_distw, everything()) %>%
  drop_na(median_distw)
sorted_median_distw %>% head(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country      | median_distw | mean_dist | median_dist | max_dist | argmax_dist |  min_dist | argmin_dist | mean_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap |
|:-------------|-------------:|----------:|------------:|---------:|:------------|----------:|:------------|-----------:|----------:|:-------------|----------:|----------:|:-------------|-------------:|---------------:|------------:|:---------------|------------:|:---------------|
| Sudan        |     4954.066 |  6848.041 |    5018.948 | 17618.83 | Niue        | 681.63930 | Eritrea     |   6830.272 |  17620.83 | Niue         |  12608.62 | 818.37940 | Eritrea      |     6836.581 |       5014.771 |    17618.83 | Niue           |   681.63930 | Eritrea        |
| Eritrea      |     5125.310 |  6980.465 |    5307.508 | 16947.59 | Niue        | 574.19620 | Yemen       |   6963.982 |  16893.26 | Niue         |  13184.02 | 567.42980 | Djibouti     |     6969.185 |       5184.840 |    16947.59 | Niue           |   574.19620 | Yemen          |
| Egypt        |     5168.484 |  6526.851 |    5247.417 | 17570.36 | Niue        | 346.61500 | Palestine   |   6478.056 |  17581.45 | Niue         |  12184.41 | 410.32890 | Palestine    |     6513.576 |       5247.417 |    17570.36 | Niue           |   346.61500 | Palestine      |
| Saudi Arabia |     5199.033 |  6907.222 |    5591.434 | 16203.79 | Niue        | 425.21070 | Bahrain     |   6816.178 |  16547.74 | Niue         |  13171.91 | 804.10050 | Bahrain      |     6895.014 |       5591.434 |    16203.79 | Niue           |   425.21070 | Bahrain        |
| Israel       |     5262.949 |  6540.009 |    5464.722 | 17171.11 | Niue        |  68.90157 | Palestine   |   6496.556 |  17165.09 | Niue         |  12366.88 |  72.66324 | Palestine    |     6526.097 |       5464.722 |    17171.11 | Niue           |    68.90157 | Palestine      |

</div>

**Bottom 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_median_distw %>% tail(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country         | median_distw | mean_dist | median_dist | max_dist | argmax_dist | min_dist | argmin_dist     | mean_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw    | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:----------------|-------------:|----------:|------------:|---------:|:------------|---------:|:----------------|-----------:|----------:|:-------------|----------:|----------:|:----------------|-------------:|---------------:|------------:|:---------------|------------:|:----------------|
| Wallis & Futuna |     14538.54 |  13207.36 |    14540.30 | 19846.20 | Niger       | 662.7784 | Tokelau         |   13261.60 |  19697.69 | Niger        |  17749.21 |  470.5988 | Samoa           |     13215.18 |       14540.30 |    19846.20 | Niger          |    662.7784 | Tokelau         |
| Tokelau         |     14598.70 |  13251.50 |    14367.60 | 19458.98 | Nigeria     | 662.7784 | Wallis & Futuna |   13312.78 |  19553.24 | Nigeria      |  17369.79 |  516.8264 | Samoa           |     13260.48 |       14367.60 |    19940.46 | Nigeria        |    662.7784 | Wallis & Futuna |
| Tonga           |     14722.22 |  13673.66 |    14556.90 | 19139.56 | Niger       | 604.2923 | Niue            |   13732.91 |  19222.06 | Niger        |  17742.83 |  581.7196 | Niue            |     13683.17 |       14556.90 |    19139.56 | Niger          |    604.2923 | Niue            |
| Samoa           |     14770.88 |  12946.54 |    14204.92 | 19904.45 | Mali        | 574.2394 | Vanuatu         |   13275.58 |  19603.05 | Niger        |  17500.88 |  470.5988 | Wallis & Futuna |     12952.16 |       14225.43 |    19904.45 | Mali           |    574.2394 | Vanuatu         |
| Niue            |     14816.30 |  13368.45 |    14482.60 | 19108.23 | Chad        | 604.2923 | Tonga           |   13423.24 |  19226.05 | Niger        |  17551.72 |  581.7195 | Tonga           |     13378.56 |       14589.33 |    19108.23 | Chad           |    604.2923 | Tonga           |

</div>

### Half Weighted Mean, Half Weighted Median

I wasn’t sure what to call this, and I don’t think it should be used for
important statistical analyses, but out of curiosity I tried to
“balance” the sorted-by-weighted-mean and sorted-by-weighted-median
results by computing the arithmetic mean of the two and sorting by this
quantity.

**Top 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_meanmed_distw <- mean_dists %>%
  mutate(meanmed_distw = (mean_distw + median_distw)/2) %>%
  select(country, meanmed_distw, everything()) %>%
  drop_na(meanmed_distw) %>%
  arrange(meanmed_distw)
sorted_meanmed_distw %>% head(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country | meanmed_distw | mean_dist | median_dist | max_dist | argmax_dist |  min_dist | argmin_dist     | mean_distw | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw    | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:--------|--------------:|----------:|------------:|---------:|:------------|----------:|:----------------|-----------:|-------------:|----------:|:-------------|----------:|----------:|:----------------|-------------:|---------------:|------------:|:---------------|------------:|:----------------|
| Egypt   |      5823.270 |  6526.851 |    5247.417 | 17570.36 | Niue        | 346.61500 | Palestine       |   6478.056 |     5168.484 |  17581.45 | Niue         |  12184.41 | 410.32890 | Palestine       |     6513.576 |       5247.417 |    17570.36 | Niue           |   346.61500 | Palestine       |
| Malta   |      5831.895 |  6424.187 |    5843.668 | 18137.23 | Tonga       | 375.72340 | Libya           |   6367.751 |     5296.038 |  18205.70 | New Zealand  |  11876.93 | 401.54870 | Tunisia         |     6412.946 |       5843.668 |    18137.23 | Tonga          |   375.72340 | Libya           |
| Libya   |      5842.354 |  6469.077 |    5623.395 | 18502.82 | Tonga       | 375.72340 | Malta           |   6411.796 |     5272.912 |  18435.08 | Niue         |  11704.92 | 541.65560 | Malta           |     6458.075 |       5623.395 |    18502.82 | Tonga          |   375.72340 | Malta           |
| Israel  |      5879.752 |  6540.009 |    5464.722 | 17171.11 | Niue        |  68.90157 | Palestine       |   6496.556 |     5262.949 |  17165.09 | Niue         |  12366.88 |  72.66324 | Palestine       |     6526.097 |       5464.722 |    17171.11 | Niue           |    68.90157 | Palestine       |
| Greece  |      5888.932 |  6401.242 |    5675.844 | 17541.17 | Niue        | 485.28230 | North Macedonia |   6345.718 |     5432.146 |  17521.98 | Niue         |  11668.36 | 420.24540 | North Macedonia |     6388.844 |       5675.844 |    17541.17 | Niue           |   485.28230 | North Macedonia |

</div>

**Bottom 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_meanmed_distw %>% tail(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country | meanmed_distw | mean_dist | median_dist | max_dist | argmax_dist | min_dist | argmin_dist     | mean_distw | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw    | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:--------|--------------:|----------:|------------:|---------:|:------------|---------:|:----------------|-----------:|-------------:|----------:|:-------------|----------:|----------:|:----------------|-------------:|---------------:|------------:|:---------------|------------:|:----------------|
| Tokelau |      13955.74 |  13251.50 |    14367.60 | 19458.98 | Nigeria     | 662.7784 | Wallis & Futuna |   13312.78 |     14598.70 |  19553.24 | Nigeria      |  17369.79 |  516.8264 | Samoa           |     13260.48 |       14367.60 |    19940.46 | Nigeria        |    662.7784 | Wallis & Futuna |
| Fiji    |      13974.34 |  13512.67 |    14275.24 | 19388.75 | Niger       | 788.5273 | Wallis & Futuna |   13570.82 |     14377.85 |  19384.72 | Burkina Faso |  17938.90 |  788.8261 | Wallis & Futuna |     13520.41 |       14275.24 |    19388.75 | Niger          |    788.5273 | Wallis & Futuna |
| Samoa   |      14023.23 |  12946.54 |    14204.92 | 19904.45 | Mali        | 574.2394 | Vanuatu         |   13275.58 |     14770.88 |  19603.05 | Niger        |  17500.88 |  470.5988 | Wallis & Futuna |     12952.16 |       14225.43 |    19904.45 | Mali           |    574.2394 | Vanuatu         |
| Niue    |      14119.77 |  13368.45 |    14482.60 | 19108.23 | Chad        | 604.2923 | Tonga           |   13423.24 |     14816.30 |  19226.05 | Niger        |  17551.72 |  581.7195 | Tonga           |     13378.56 |       14589.33 |    19108.23 | Chad           |    604.2923 | Tonga           |
| Tonga   |      14227.56 |  13673.66 |    14556.90 | 19139.56 | Niger       | 604.2923 | Niue            |   13732.91 |     14722.22 |  19222.06 | Niger        |  17742.83 |  581.7196 | Niue            |     13683.17 |       14556.90 |    19139.56 | Niger          |    604.2923 | Niue            |

</div>

## Capital Cities

Globle has a companion game,
[Globle-Capitals](https://globle-capitals.com), that is just as fun! To
find the optimal first guess for this game, we repeat the analysis but
using the **location of the capital city**, rather than the centroid of
the landmass, to represent each country. In our dataset, this just means
using the `distcap` variable instead of the `dist` variable used above.
We don’t have to worry about weighted distances here, however, since the
city is just located at one specific point (at least, its centroid is).
So, using the aggregated `distcap` variables instead of the
`dist`/`distw` variables used above, we obtain the results that follow:

### Mean of Capital Distances

**Top 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_meancap <- mean_dists %>%
  arrange(mean_distcap) %>%
  select(country, mean_distcap, everything())
sorted_meancap %>% head(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country    | mean_distcap | mean_dist | median_dist | max_dist | argmax_dist | min_dist | argmin_dist     | mean_distw | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw    | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:-----------|-------------:|----------:|------------:|---------:|:------------|---------:|:----------------|-----------:|-------------:|----------:|:-------------|----------:|----------:|:----------------|---------------:|------------:|:---------------|------------:|:----------------|
| Albania    |     6370.987 |  6383.108 |    5795.587 | 17971.90 | New Zealand | 155.9628 | North Macedonia |   6328.318 |     5625.398 |  17853.96 | New Zealand  |  11658.82 |  168.1648 | North Macedonia |       5747.847 |    17971.90 | New Zealand    |    155.9628 | North Macedonia |
| Bulgaria   |     6382.957 |  6395.541 |    5785.217 | 17735.26 | New Zealand | 168.0973 | North Macedonia |   6354.845 |     5548.004 |  17445.41 | New Zealand  |  11839.60 |  311.9887 | North Macedonia |       5785.217 |    17735.26 | New Zealand    |    168.0973 | North Macedonia |
| Greece     |     6388.844 |  6401.242 |    5675.844 | 17541.17 | Niue        | 485.2823 | North Macedonia |   6345.718 |     5432.146 |  17521.98 | Niue         |  11668.36 |  420.2454 | North Macedonia |       5675.844 |    17541.17 | Niue           |    485.2823 | North Macedonia |
| Italy      |     6399.405 |  6410.571 |    5996.121 | 18572.15 | New Zealand | 230.0196 | San Marino      |   6365.753 |     5680.541 |  18460.90 | New Zealand  |  11963.57 |  327.9480 | San Marino      |       5884.250 |    18572.15 | New Zealand    |    230.0196 | San Marino      |
| San Marino |     6404.382 |  6415.701 |    6079.517 | 18621.28 | New Zealand | 230.0196 | Italy           |   6358.362 |     5795.321 |  18427.01 | New Zealand  |  11910.63 |  308.0931 | Slovenia        |       5971.463 |    18621.28 | New Zealand    |    230.0196 | Italy           |

</div>

**Bottom 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_meancap %>% tail(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country     | mean_distcap | mean_dist | median_dist | max_dist | argmax_dist |  min_dist | argmin_dist     | mean_distw | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw    | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:------------|-------------:|----------:|------------:|---------:|:------------|----------:|:----------------|-----------:|-------------:|----------:|:-------------|----------:|----------:|:----------------|---------------:|------------:|:---------------|------------:|:----------------|
| Vanuatu     |     13286.01 |  13279.77 |    14298.53 | 19579.91 | Mauritania  |  538.6225 | New Caledonia   |   13326.29 |     14359.81 |  19599.64 | Mauritania   |  17325.20 |  579.1039 | New Caledonia   |       14305.40 |    19579.91 | Mauritania     |    538.6225 | New Caledonia   |
| Niue        |     13378.56 |  13368.45 |    14482.60 | 19108.23 | Chad        |  604.2923 | Tonga           |   13423.24 |     14816.30 |  19226.05 | Niger        |  17551.72 |  581.7195 | Tonga           |       14589.33 |    19108.23 | Chad           |    604.2923 | Tonga           |
| New Zealand |     13453.14 |  13444.43 |    13871.83 | 19586.18 | Spain       | 1799.7050 | Norfolk Island  |   13491.00 |     13994.94 |  19647.66 | Gibraltar    |  18046.90 | 1322.4910 | Norfolk Island  |       13874.92 |    19586.18 | Spain          |   1799.7050 | Norfolk Island  |
| Fiji        |     13520.41 |  13512.67 |    14275.24 | 19388.75 | Niger       |  788.5273 | Wallis & Futuna |   13570.82 |     14377.85 |  19384.72 | Burkina Faso |  17938.90 |  788.8261 | Wallis & Futuna |       14275.24 |    19388.75 | Niger          |    788.5273 | Wallis & Futuna |
| Tonga       |     13683.17 |  13673.66 |    14556.90 | 19139.56 | Niger       |  604.2923 | Niue            |   13732.91 |     14722.22 |  19222.06 | Niger        |  17742.83 |  581.7196 | Niue            |       14556.90 |    19139.56 | Niger          |    604.2923 | Niue            |

</div>

### Median of Capital Distances

**Top 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_mediancap <- mean_dists %>%
  arrange(median_distcap) %>%
  select(country, median_distcap, everything())
sorted_mediancap %>% head(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country | median_distcap | mean_dist | median_dist | max_dist | argmax_dist |  min_dist | argmin_dist       | mean_distw | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw      | mean_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap |
|:--------|---------------:|----------:|------------:|---------:|:------------|----------:|:------------------|-----------:|-------------:|----------:|:-------------|----------:|----------:|:------------------|-------------:|------------:|:---------------|------------:|:---------------|
| Sudan   |       5014.771 |  6848.041 |    5018.948 | 17618.83 | Niue        |  681.6393 | Eritrea           |   6830.272 |     4954.066 |  17620.83 | Niue         |  12608.62 |  818.3794 | Eritrea           |     6836.581 |    17618.83 | Niue           |    681.6393 | Eritrea        |
| Eritrea |       5184.840 |  6980.465 |    5307.508 | 16947.59 | Niue        |  574.1962 | Yemen             |   6963.982 |     5125.310 |  16893.26 | Niue         |  13184.02 |  567.4298 | Djibouti          |     6969.185 |    16947.59 | Niue           |    574.1962 | Yemen          |
| Egypt   |       5247.417 |  6526.851 |    5247.417 | 17570.36 | Niue        |  346.6150 | Palestine         |   6478.056 |     5168.484 |  17581.45 | Niue         |  12184.41 |  410.3289 | Palestine         |     6513.576 |    17570.36 | Niue           |    346.6150 | Palestine      |
| Chad    |       5364.059 |  6986.228 |    5364.059 | 19192.57 | Tokelau     | 1158.0940 | Equatorial Guinea |   6965.297 |     5450.785 |  19137.92 | Tokelau      |  12235.48 | 1232.0420 | Equatorial Guinea |     6975.912 |    19192.57 | Tokelau        |    916.8266 | Nigeria        |
| Jordan  |       5390.645 |  6559.271 |    5390.645 | 17076.25 | Niue        |  111.0933 | Israel            |   6513.777 |     5292.887 |  17082.49 | Niue         |  12443.22 |  114.6373 | Israel            |     6545.317 |    17076.25 | Niue           |    111.0933 | Israel         |

</div>

**Bottom 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_mediancap %>% tail(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country         | median_distcap | mean_dist | median_dist | max_dist | argmax_dist    | min_dist | argmin_dist     | mean_distw | median_distw | max_distw | argmax_distw   | p90_distw | min_distw | argmin_distw  | mean_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:----------------|---------------:|----------:|------------:|---------:|:---------------|---------:|:----------------|-----------:|-------------:|----------:|:---------------|----------:|----------:|:--------------|-------------:|------------:|:---------------|------------:|:----------------|
| Norfolk Island  |       14307.25 |  13177.62 |    14329.12 | 19795.78 | Western Sahara | 770.1298 | New Caledonia   |   13244.26 |     14382.40 |  19710.59 | Western Sahara |  17398.00 |  822.5537 | New Caledonia |     13185.25 |    19795.78 | Western Sahara |    770.1298 | New Caledonia   |
| Tokelau         |       14367.60 |  13251.50 |    14367.60 | 19458.98 | Nigeria        | 662.7784 | Wallis & Futuna |   13312.78 |     14598.70 |  19553.24 | Nigeria        |  17369.79 |  516.8264 | Samoa         |     13260.48 |    19940.46 | Nigeria        |    662.7784 | Wallis & Futuna |
| Wallis & Futuna |       14540.30 |  13207.36 |    14540.30 | 19846.20 | Niger          | 662.7784 | Tokelau         |   13261.60 |     14538.54 |  19697.69 | Niger          |  17749.21 |  470.5988 | Samoa         |     13215.18 |    19846.20 | Niger          |    662.7784 | Tokelau         |
| Tonga           |       14556.90 |  13673.66 |    14556.90 | 19139.56 | Niger          | 604.2923 | Niue            |   13732.91 |     14722.22 |  19222.06 | Niger          |  17742.83 |  581.7196 | Niue          |     13683.17 |    19139.56 | Niger          |    604.2923 | Niue            |
| Niue            |       14589.33 |  13368.45 |    14482.60 | 19108.23 | Chad           | 604.2923 | Tonga           |   13423.24 |     14816.30 |  19226.05 | Niger          |  17551.72 |  581.7195 | Tonga         |     13378.56 |    19108.23 | Chad           |    604.2923 | Tonga           |

</div>

### Half Median, Half Mean of Capital Distance

**Top 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_meanmed_distcap <- mean_dists %>%
  mutate(meanmed_capdist = (mean_distcap + median_distcap)/2) %>%
  select(country, meanmed_capdist, everything()) %>%
  drop_na(meanmed_capdist) %>%
  arrange(meanmed_capdist)
sorted_meanmed_distcap %>% head(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country   | meanmed_capdist | mean_dist | median_dist | max_dist | argmax_dist |  min_dist | argmin_dist | mean_distw | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap |
|:----------|----------------:|----------:|------------:|---------:|:------------|----------:|:------------|-----------:|-------------:|----------:|:-------------|----------:|----------:|:-------------|-------------:|---------------:|------------:|:---------------|------------:|:---------------|
| Egypt     |        5880.496 |  6526.851 |    5247.417 | 17570.36 | Niue        | 346.61500 | Palestine   |   6478.056 |     5168.484 |  17581.45 | Niue         |  12184.41 | 410.32890 | Palestine    |     6513.576 |       5247.417 |    17570.36 | Niue           |   346.61500 | Palestine      |
| Sudan     |        5925.676 |  6848.041 |    5018.948 | 17618.83 | Niue        | 681.63930 | Eritrea     |   6830.272 |     4954.066 |  17620.83 | Niue         |  12608.62 | 818.37940 | Eritrea      |     6836.581 |       5014.771 |    17618.83 | Niue           |   681.63930 | Eritrea        |
| Jordan    |        5967.981 |  6559.271 |    5390.645 | 17076.25 | Niue        | 111.09330 | Israel      |   6513.777 |     5292.887 |  17082.49 | Niue         |  12443.22 | 114.63730 | Israel       |     6545.317 |       5390.645 |    17076.25 | Niue           |   111.09330 | Israel         |
| Palestine |        5992.627 |  6542.312 |    5456.729 | 17224.54 | Niue        |  68.90157 | Israel      |   6499.195 |     5289.208 |  17196.58 | Niue         |  12347.68 |  72.66324 | Israel       |     6528.524 |       5456.729 |    17224.54 | Niue           |    68.90157 | Israel         |
| Israel    |        5995.410 |  6540.009 |    5464.722 | 17171.11 | Niue        |  68.90157 | Palestine   |   6496.556 |     5262.949 |  17165.09 | Niue         |  12366.88 |  72.66324 | Palestine    |     6526.097 |       5464.722 |    17171.11 | Niue           |    68.90157 | Palestine      |

</div>

**Bottom 5:**



<details>
<summary markdown="span">Code</summary>

``` r
sorted_meanmed_distcap %>% tail(disp_n)
```

</details>

<div class="table-wrapper" markdown="block">

| country         | meanmed_capdist | mean_dist | median_dist | max_dist | argmax_dist | min_dist | argmin_dist     | mean_distw | median_distw | max_distw | argmax_distw | p90_distw | min_distw | argmin_distw    | mean_distcap | median_distcap | max_distcap | argmax_distcap | min_distcap | argmin_distcap  |
|:----------------|----------------:|----------:|------------:|---------:|:------------|---------:|:----------------|-----------:|-------------:|----------:|:-------------|----------:|----------:|:----------------|-------------:|---------------:|------------:|:---------------|------------:|:----------------|
| Tokelau         |        13814.04 |  13251.50 |    14367.60 | 19458.98 | Nigeria     | 662.7784 | Wallis & Futuna |   13312.78 |     14598.70 |  19553.24 | Nigeria      |  17369.79 |  516.8264 | Samoa           |     13260.48 |       14367.60 |    19940.46 | Nigeria        |    662.7784 | Wallis & Futuna |
| Wallis & Futuna |        13877.74 |  13207.36 |    14540.30 | 19846.20 | Niger       | 662.7784 | Tokelau         |   13261.60 |     14538.54 |  19697.69 | Niger        |  17749.21 |  470.5988 | Samoa           |     13215.18 |       14540.30 |    19846.20 | Niger          |    662.7784 | Tokelau         |
| Fiji            |        13897.83 |  13512.67 |    14275.24 | 19388.75 | Niger       | 788.5273 | Wallis & Futuna |   13570.82 |     14377.85 |  19384.72 | Burkina Faso |  17938.90 |  788.8261 | Wallis & Futuna |     13520.41 |       14275.24 |    19388.75 | Niger          |    788.5273 | Wallis & Futuna |
| Niue            |        13983.94 |  13368.45 |    14482.60 | 19108.23 | Chad        | 604.2923 | Tonga           |   13423.24 |     14816.30 |  19226.05 | Niger        |  17551.72 |  581.7195 | Tonga           |     13378.56 |       14589.33 |    19108.23 | Chad           |    604.2923 | Tonga           |
| Tonga           |        14120.03 |  13673.66 |    14556.90 | 19139.56 | Niger       | 604.2923 | Niue            |   13732.91 |     14722.22 |  19222.06 | Niger        |  17742.83 |  581.7196 | Niue            |     13683.17 |       14556.90 |    19139.56 | Niger          |    604.2923 | Niue            |

</div>

## The Takeaway

Given the pretty large tails of the distribution of distances for most
countries (with the Pacific island nations, for example, having a few
very close-by nations followed by a ton of extremely-far-away ones), I
opted to go with the **median** distance as my determinant of the
optimal first guess, as the measure least negatively affected by
extremes in these distance distributions[^3]. And, since **Sudan** wins
on this metric—for both the landmass centroid *and* the capital city
location distances—I now use **Sudan** as my first guess when I launch
my daily play of Globle, and **Khartoum** as my first guess for
Globle-Capitals!

You can download the processed data, with the precomputed average
distances, [here](/assets/data/country_dists.csv).

<details>
<summary markdown="span">Code</summary>

``` r
library(readr)
write_csv(mean_dists, "../assets/data/country_dists.csv")
```

</details>

<div class="table-wrapper" markdown="block">

[^1]: Officially called [*départements et régions
    d’outre-mer*](https://en.wikipedia.org/wiki/Overseas_departments_and_regions_of_France)
    (DROM).

[^2]: `dist_cepii` also has a bunch of interesting indicator variables:
    `contig`, `comlang_off`, `comlang_ethno`, `colony`, `comcol`,
    `curcol`, `col45`, and `smctry`, that we won’t use here.

[^3]: For this game, since it’s solely geography-based, we don’t need to
    use the population-weighted distances—those were just for fun 🤓.

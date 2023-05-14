---
layout: post
title:  "Globle Optimization"
date:   2023-05-13 18:55:07 -0700
---

## Background

You may have heard of a geography came that came out during the Great Wordle Clone Wave of 2022, called Globle --- if you haven't, go check it out! The idea is, you guess a country, and it gives you "hot or cold" feedback: the redder the country's land mass is highlighted, the closer you are to the country of the day. Their example is, if the mystery country is **Japan**, the following countries would appear with these colors if guessed:

|![](/assets/img/france.svg)| ![](/assets/img/nepal.svg) | ![](/assets/img/mongolia.svg) | ![](/assets/img/south_korea.svg) |
|:-:|:-:|:-:|:-:|
| **France** | **Nepal** | **Mongolia** | **South Korea** |

## The Optimization

With my overthink-everything brain, after a few days I decided I wanted to go and figure out the **OPTIMAL** first guess: this could be defined in a bunch of ways, but to me it boiled down to, which country is closest, on average, to *all* other countries in the world?

Like the definition of "optimal" here, the definition of "close" we use could massively change the results: should we say two countries are distance-zero from each other if their borders touch? What about exclaves like [Kaliningrad](https://en.wikipedia.org/wiki/Kaliningrad)? Or, even more chaotically, what about e.g. French *départements* in entirely different continents[^drom], like [French Guiana](https://en.wikipedia.org/wiki/French_Guiana) in South America? Should we say that Suriname and Brazil are distance-zero from France?

Long story short, I was able to bunny-hop over these complexities by
* (a) deciding to use the **centroid** of each country as its "official" location, and
* (b) finding a data source which determined these centroids in a way that avoided them being skewed by overseas regions by defining a "main" landmass, and computing the centroid of that mass.

Point (b) is really the key here, as using the centroid of *all* the nation's territory could lead to France's centroid being somewhere in the Atlantic Ocean near the equator, while Denmark's would be somewhere a bit south of Iceland, halfway to [Greenland](https://en.wikipedia.org/wiki/Greenland).

## The Data

## The Results



[^drom]: Officially called [*départements et régions d'outre-mer*](https://en.wikipedia.org/wiki/Overseas_departments_and_regions_of_France) (DROM).
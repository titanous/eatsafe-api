# EatSafe API

A simple little app that describes the safety of Ottawa's restaurants in JSON.

## Usage

### Facility
    /facility/:id
The complete facility record including location and inspections.

[http://eatsafe-api.herokuapp.com/facility/B789A388-ED35-490D-A68F-518EA3893A88](http://eatsafe-api.herokuapp.com/facility/B789A388-ED35-490D-A68F-518EA3893A88)

### Nearby
    /facilities/nearby
A list of facilities near the location given. The location can either be
coordinates given as decimals in `lat` and `lon` or an `address`. A search term
in `q` can be used to filter the query. A `limit` can also be provided (defaults
to 25). The approximate distance in kilometers is provided for each facility.

[http://eatsafe-api.herokuapp.com/facilities/nearby?lat=45.4437&lon=75.6932&limit=10](http://eatsafe-api.herokuapp.com/facilities/nearby?lat=45.4437&lon=75.6932&limit=10)

[http://eatsafe-api.herokuapp.com/facilities/nearby?address=24%20Sussex,%20Ottawa&q=tim%20hortons](http://eatsafe-api.herokuapp.com/facilities/nearby?address=24%20Sussex,%20Ottawa)

### Search
    /facilities/search
Searches through the facility names and provides up to 100 results.

[http://eatsafe-api.herokuapp.com/facilities/search?q=subway](http://eatsafe-api.herokuapp.com/facilities/search?q=subway)

## Credits

Written by Jonathan Rudenberg

## References

[iPhone App and Scrapers](http://github.com/christaggart/EatSafeOttawaAPI)

[EatSafe Ottawa](http://www.ottawa.ca/residents/health/inspections/index_en.html)

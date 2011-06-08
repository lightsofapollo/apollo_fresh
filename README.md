# Apollo Fresh
(Because I was feeling trump-esque that day)

Freshbooks/MongoDB/API experiment from early rails 3 days.
Tools for interacting with the FreshBooks API (via api key) and
then downloading entire datasets into MongoDB as a cache.

From there I could interact with FreshBooks data with MongoDB
and leave the API itself alone.

## Motivation

To re-familiarize myself with rails / ruby / FreshBooks API (after 2 years in PHP development)

## Tools

HTTParty
MongoDB
ActiveSupport (sorry!)
WillPaginate (though I think Kaminari is better now)

## Stats?

When free-time appears I plan to cleanup the code and refactor some
things with the latest tools and remove dependencies on ActiveSupport
and HTTPParty. I may abstract out the API wrapper for FreshBooks which 
is one of the best parts of the library and does not rely (or care)
about the MongoDB portion.


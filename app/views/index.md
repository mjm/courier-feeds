# Courier Feeds

This is a microservice that tracks feeds that users have set up in Courier.
Feeds are tracked uniquely (there is a single record for each distinct feed URL).
Two users can pull from the same feed, but we will only query it once.
Courier Feeds currently only supports JSON Feed.

## How to Use

### GET `/feeds`

Lists all of the feeds the the service is tracking.
Returns a JSON array with information about all tracked feeds.

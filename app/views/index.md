# Courier Feeds

This is a microservice that tracks feeds that users have set up in Courier.
Feeds are tracked uniquely (there is a single record for each distinct feed URL).
Two users can pull from the same feed, but we will only query it once.
Courier Feeds currently only supports JSON Feed.

## How to Use

### GET `/feeds`

Lists all of the feeds the the service is tracking.
Returns a JSON array with information about all tracked feeds.

### GET `/users/:user_id/feeds`

Lists the feeds registered to a particular user.
Returns a JSON array in the same format as `/feeds`.

> **Note**: `courier-feeds` does not track information about users.
> Users are referenced by their ID exclusively.
> You can potentially register feeds for users that do not actually exist.

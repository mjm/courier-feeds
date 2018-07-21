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

### POST `/users/:user_id/feeds`

Registers a new feed on behalf of a user.
Returns a JSON object describing the registered feed.
Returns a `400 Bad Request` response if the user has already registered a feed with the same URL.

> **Note**: `courier-feeds` does not track information about users.
> Users are referenced by their ID exclusively.
> You can potentially register feeds for users that do not actually exist.

### POST `/feeds/:feed_id/refresh`

Requests that a feed be refreshed in the background.
Returns a JSON object with a payload indicating if the request was successful or not.
Returns a `404 Not Found` response if the feed is not registered.

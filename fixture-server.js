/*
This server acts like a normal web server but through the use of
*special URLs* allows the loading of fixtures for a given path,
the clearing of all currently loaded fixtures, the inspection of
all the currently loaded fixtures and the shutting down of the 
server.

*/

var express = require('express'),
	fs		= require('fs'),
	app = express.createServer(
		express.static(__dirname + '/public'),
		express.methodOverride(),
		express.bodyParser(),
		express.cookieParser(),
		express.session({ secret: "like, whatever dude" })
	);

/*
Fixtures are hashes with the URL as a key and an
array of responses as the value.

The array values are shifted and used as each request comes
in until no more are left at which point they __404__.
*/
var GET_fixtures = {},
	POST_fixtures = {},
	FIXTURE_DIR = __dirname + '/tests/fixtures/api/';

/*
## Load Fixtures

On this URL you can specify a fixture to load.
Fixtures are loaded from **FIXTURE_DIR** and
should be named: **:fixture**.json where **:filename**
comes from __/_fixtures/load/:fixture__
*/
app.get('/_fixtures/load/:fixture', function(req, res) {
	file = fs.readFileSync(FIXTURE_DIR + req.params['fixture'] + '.json', 'utf8');
	fixtures = JSON.parse(file);
	
	if(!Array.isArray(fixtures)) {
		fixtures = [fixtures];
	}

	fixtures.forEach(function(fixture) {
		var dest_hash = fixture.method === "POST" ? POST_fixtures : GET_fixtures;
		if(dest_hash.hasOwnProperty(fixture.path)) {
			dest_hash[fixture.path].push(fixture);
		} else {
			dest_hash[fixture.path] = [fixture];
		}
	});

	res.send('Loaded ' + fixtures.length + ' fixtures');
});

/*
## Clear Fixtures

Call this URL to clear all the fixtures from the server
*/
app.get('/_fixtures/clear', function(req, res) {
	GET_fixtures = {};
	POST_fixtures = {};
	res.send('Cleared fixtures');
});

/*
## Inspect Fixtures

Spits out the fixtures as JSON
*/
app.get('/_fixtures/inspect', function(req, res) {
	res.send(JSON.stringify({
		"GET_fixtures": GET_fixtures,
		"POST_fixtures": POST_fixtures		
	}));
});

/*
## Shutdown Fixtures Server

Call this URL to shutdown the fixtures server
*/
app.get('/_fixtures/shutdown', function(req, res) {
	res.send('Shutting down', 200);
	app.close();
});

/*
## Serve the fixtures

Grabs the appropriate fixture (if there is one).
Returns 404 if there isn't one.
*/
function serve_fixture(req, res, fixtures) {
	var path		= req.params[0],
		responses	= fixtures[path] || [],
		response	= responses.shift();

	if(response) {
		res.send(response.content, response.headers, response.status);
	} else {
		res.send(404);
	}
}

// This handles all GET requests
app.get('*', function(req, res){
	serve_fixture(req, res, GET_fixtures);
});

// This handles all POST requests
app.post('*', function(req, res){
	serve_fixture(req, res, POST_fixtures);
});

app.listen(7357); 

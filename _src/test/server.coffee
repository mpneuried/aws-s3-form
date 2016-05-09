path = require( "path" )
_config = require( "../config_test.json" )
_defaults = require( "lodash/defaults" )
_pick = require( "lodash/pick" )

CONFIG = _defaults _config.example or {},
	port: 3010

express = require('express')
app = express()
app.set('view engine', 'jade')
app.set('views', path.resolve( __dirname + '/../_testviews' ))


AwsS3Form = require( "../." )
utils = require( "../lib/utils" )

_config.s3.keyPrefix = "test_browser_"
redirectUrlTemplate = ( data )->
	_str = "http://#{ server.address().host or "localhost" }:#{server.address().port or 80 }/redir/" 
	if data.filename is "${filename}"
		_str += "*"
	else
		_str += _config.s3.keyPrefix + data.filename
	return _str
FormGen = new AwsS3Form( _config.s3 )

app.get '/', (req, res)->
	_key = req.query.key
	_statuscode = req.query.statuscode
	_contenttype = req.query.contenttype
	console.log _config.s3.keyPrefix, _key
	if not _key?
		_key = utils.randomString( 10 )
	_opts = _pick( req.query, [ "acl" ] )
	if _statuscode
		_opts.successActionStatus = _statuscode
	else
		_opts.redirectUrlTemplate = redirectUrlTemplate
	if _contenttype?.length
		_opts.contentType = _contenttype
	res.render( "index", { q: req.query, example: FormGen.create( _key, _opts ) } )
	return

app.get '/redir/:key', (req, res)->
	_url = "https://s3.#{ _config.s3.region }.amazonaws.com/#{ _config.s3.bucket }/#{req.query.key}"
	_data =
		q: req.query
		src: _url

	res.render( "img", _data )
	return


server = app.listen process.env.PORT or CONFIG.port, ->
	console.log('Now call http://%s:%s/ in your browser', @address().host or "localhost", @address().port)
	return

# # AwsS3Form

# ### extends [NPM:MPBasic](https://cdn.rawgit.com/mpneuried/mpbaisc/master/_docs/index.coffee.html)

#
# ### Exports: *Class*
#
# Generate a signed and reday to use formdata to put files to s3 directly from teh browser. Signing is done by using AWS Signature Version 4.
#

# **node modules**
crypto = require( "crypto" )

# **npm modules**
_ = require('lodash')
uuid = require('node-uuid')

# **internal modules**
# [Utils](./utils.coffee.html)
utils = require( "./utils" )

class AwsS3Form extends require( "mpbasic" )()

	validation:
		acl: [ "public-read", "authenticated-read" ]
		successActionStatus: [200, 201, 204]

	# ## defaults
	defaults: =>
		@extend super,
			# **AwsS3Form.accessKeyId** *String* AWS access key
			accessKeyId: "set-in-config-json"
			# **AwsS3Form.secretAccessKey** *String* AWS access secret
			secretAccessKey: "set-in-config-json"
			# **AwsS3Form.region** *String* AWS region
			region: "eu-central-1"
			# **AwsS3Form.bucket** *String* AWS bucket name
			bucket: null
			# **AwsS3Form.secure** *Boolean* Define if the action uses ssl. `true` = "https"; `false` = "http"
			secure: true
			# **AwsS3Form.redirectUrlTemplate** *String|Function* a redirect url template.
			redirectUrlTemplate: null
			# **AwsS3Form.redirectUrlTemplate** *Number* HTTP code to return when no redirectUrlTemplate is defined.
			successActionStatus: 204
			# **AwsS3Form.policyExpiration** *Date|Number* Add time in seconds to now to define the expiration of the policy. Or set a hard Date.
			policyExpiration: 60*60*12 # Default 12 hrs
			# **AwsS3Form.keyPrefix** *String* Key prefix to define a policy that the key has to start with this value
			keyPrefix: ""
			# **AwsS3Form.acl** *String* The standard acl type. Only `public-read` and `authenticated-read` are allowed
			acl: "public-read"
			# **AwsS3Form.useUuid** *Boolean* Use a uuid for better security
			useUuid: true

	###
	## create

	`basic.create( filename [, options ] )`

	create a new form object

	@param { String } filename The S3 file key/filename to use.
	@param { Object } [options] Create options
	@param { String } [options.acl] Option to overwrite the general `acl`
	@param { String } [options.secure] Option to overwrite the general `secure`
	@param { String } [options.keyPrefix] Option to overwrite the general `keyPrefix`
	@param { String } [options.redirectUrlTemplate] Option to overwrite the general `redirectUrlTemplate`
	@param { Number|Date } [options.policyExpiration] Option to overwrite the general `policyExpiration`

	@api public
	###
	create: ( filename, options = {} )=>
		#contentType = mime.lookup( filename )

		options.now = new Date()
		if @config.useUuid
			options.uuid = uuid.v4()

		_data =
			acl: @_acl( options.acl )
			credential: @_createCredential( options.now )
			amzdate: @_shortDate( options.now )

		_policyB64 = @_obj2b64( @policy( filename, options, _data ) )

		_signature = @sign( _policyB64, options )

		if options.secure?
			_secure = options.secure
		else
			_secure = @config.secure

		data =
			action: "#{ if _secure then "https" else "http" }://s3-#{@config.region}.amazonaws.com/#{ @config.bucket }"
			filefield: "file"
			fields:
				key: "#{( options.keyPrefix or @config.keyPrefix )}#{filename}"
				acl: _data.acl
				"X-Amz-Credential": _data.credential
				"X-Amz-Algorithm": "AWS4-HMAC-SHA256"
				"X-Amz-Date": _data.amzdate
				"Policy": _policyB64
				"X-Amz-Signature": _signature.toString()

		if options.redirectUrlTemplate?
			data.fields.success_action_redirect = @_redirectUrl( options.redirectUrlTemplate, filename: filename )
		else
			data.fields.success_action_status = @_successActionStatus( options.successActionStatus )

		if options.uuid?
			data.fields[ "x-amz-meta-uuid" ] = options.uuid

		return data

	###
	## policy

	`basic.policy( filename [, options ] )`

	Create a new policy object based on AWS Signature Version 4.

	@param { String } filename The S3 file key/filename to use.
	@param { Object } [options] Policy options
	@param { String } [options.now] The current date-time for this policy
	@param { String } [options.uuid] The uuid to add to the policy
	@param { String } [options.acl] Option to overwrite the general `acl`
	@param { String } [options.keyPrefix] Option to overwrite the general `keyPrefix`
	@param { String } [options.redirectUrlTemplate] Option to overwrite the general `redirectUrlTemplate`
	@param { Number|Date } [options.policyExpiration] Option to overwrite the general `policyExpiration`

	@api public
	###
	policy: ( filename, options = {}, _predef = {} )=>

		_date = options.now or new Date()

		policy =
			expiration: @_calcDate( options.policyExpiration or @config.policyExpiration, _date )
			conditions: [
				{ bucket: @config.bucket }
				[ "starts-with", "$key", ( options.keyPrefix or @config.keyPrefix ) ]
				{ acl: _predef.acl or @_acl( options.acl ) }
				{ success_action_redirect: _predef.success_action_redirect or @_redirectUrl( options.redirectUrlTemplate, filename: filename ) }
				{ "x-amz-credential": _predef.credential or @_createCredential( _date ) }
				{ "x-amz-algorithm": "AWS4-HMAC-SHA256" }
				{ "x-amz-date": _predef.amzdate or @_shortDate( _date ) }
				#[ "starts-with", "$Content-Type", contentType ]
				#["content-length-range", 0, @settings.maxFileSize ]
			]

		@debug "generated policy", policy
		if options.uuid?
			policy.conditions.push { "x-amz-meta-uuid": options.uuid }

		return policy

	###
	## sign

	`basic.sign( policyB64 [, options ] )`

	Create a AWS Signature Version 4. This is used to create the signature out of the policy.

	@param { String } policyB64 Base64 encoded policy
	@param { Object } [options] sign options
	@param { String } [options.now=`new Date()`] The current date-time for this signature
	@param { String } [options.signdate=converted options.now`] signature date
	@param { String } [options.secretAccessKey] Change the configured standard `secretAccessKey` type.
	@param { String } [options.region] Option to overwrite the general `region`

	@api public
	###
	sign: ( policyB64, options )=>
		_date = options.now or new Date()
		_signdate = options.signdate or @_shortDate( _date, true )

		_h1 = @_hmac( "AWS4" + ( options.secretAccessKey or @config.secretAccessKey ), _signdate )
		_h2 = @_hmac( _h1, ( options.region or @config.region ) )
		_h3 = @_hmac( _h2, "s3" )
		_key = @_hmac( _h3, "aws4_request" )

		return @_hmac( _key, policyB64 ).toString( "hex" )

	###
	## _acl

	`AwsS3Form._acl( [acl] )`

	validate the given acl or get the default

	@param { String } [acl=`config.acl`] the S3 acl

	@return { String } A valid acl

	@api private
	###
	_acl: ( acl = @config.acl )=>
		if acl not in @validation.acl
			return @_handleError( null, "EINVALIDACL", val: acl )
		return acl

	###
	## _redirectUrl

	`AwsS3Form._redirectUrl( tmpl, data )`

	Get the default redirect template or process the given sting as lodash template or call teh given function

	@param { String|Function } tmpl A lodash template or function to generate the redirect url. If `null` general `redirectUrlTemplate` will be used.
	@param { Object } data The data object for template or function args. Usual example: `{ "filename": "the-filename-from-create-or-policy.jpg" }`

	@return { String } A redirect url

	@api private
	###
	_redirectUrl: ( tmpl = @config.redirectUrlTemplate, data = {} )=>
		if not tmpl?
			return @_handleError( null, "ENOREDIR" )

		if _.isString( tmpl )
			return _.template( tmpl )( data )
		else if _.isFunction( tmpl )
			return tmpl( data )
		else
			return @_handleError( null, "EINVALIDREDIR" )

	_successActionStatus: ( successActionStatus = @config.successActionStatus )=>
		if successActionStatus not in @validation.successActionStatus
			return @_handleError( null, "EINVALIDSTATUS", val: successActionStatus )
		return successActionStatus

	###
	## _successActionStatus

	`AwsS3Form._successActionStatus( status )`

	Gets the HTTP status code that AWS will return if a redirectUrlTemplate is not defined.

	@param { Number } status The status code that should be set on successful upload

	@return { Number } A redirect url

	@api private
	###
	_successActionStatus: ( status = @config.successActionStatus )=>
		if status not in @validation.successActionStatus
			return @_handleError( null, "EINVALIDSTATUS", val: status )
		return status

	###
	## _calcDate

	`AwsS3Form._calcDate( addSec [, date] )`

	Calculate and validate a date

	@param { Number|Date } addSec A date to convert or a number in seconds to add to the date out of the `date` arg.
	@param { Date } [date=`new Date()`] A base date for adding if the first argument `addSec` is a number.

	@return { String } A date ISO String

	@api private
	###
	_calcDate: ( addSec, date = new Date() )=>
		_msAdd = 0
		_now = Date.now()

		if _.isNumber( addSec )
			_msAdd = addSec * 1000
			if _.isDate( date )
				_ts = date.valueOf()
			else if _.isNumber( date )
				_ts = date
			else
				return @_handleError( null, "ENOTDATE", val: date )
		else if _.isDate( addSec )
			_ts = addSec.valueOf()
		else
			return @_handleError( null, "ENOTDATE", val: addSec )

		# use a 10s time space to the past to check the date
		if ( _now - 10000 ) > _ts
			return @_handleError( null, "EOLDDATE", val: _now )

		return ( new Date( _ts + _msAdd ) ).toISOString()

	###
	## _createCredential

	`AwsS3Form._createCredential( date )`

	Generate a AWS Signature Version 4 conform credential string

	@param { Date } date the credential date

	@return { String } a valid AWS Signature Version 4 credential string

	@api private
	###
	_createCredential: ( date )=>
		shortDate = @_shortDate( date, true )
		return "#{@config.accessKeyId}/#{shortDate}/#{@config.region}/s3/aws4_request"

	###
	## _shortDate

	`AwsS3Form._shortDate( [date] [, onlyDate] )`

	Create a AWS valid date string

	@param { Date } [date=`new Date()`] The date to process
	@param { Boolean } [onlyDate=false] Return only the date and cut the time

	@return { String } a AWS valid date string

	@api private
	###
	_shortDate: ( date = new Date(), onlyDate = false )=>
		_sfull = date.toISOString().replace( /\.[0-9]{1,3}Z/g, "Z" ).replace( /[\.:-]/g, "" )
		if onlyDate
			return _sfull.substr( 0, 8 )
		return _sfull

	###
	## _hmac

	`AwsS3Form._hmac( secret, val )`

	Create a SHA256 hash

	@param { String } secret The secret to hash
	@param { String } val The value to hash

	@return { String } A SHA256 hash

	@api private
	###
	_hmac: ( secret, val )=>
		_hash = crypto.createHmac('SHA256', secret ).update( val )
		return new Buffer( _hash.digest( "base64" ), "base64" )

	###
	## _obj2b64

	`AwsS3Form._obj2b64( obj )`

	Srtingify a object and return it base64 encoded. Used to convert the policy result to the base64 string required by the `.sign()` method.

	@param { Object } obj A object to stringify

	@return { String } Base64 encoded JSON

	@api private
	###
	_obj2b64: ( obj )=>
		return new Buffer( JSON.stringify( obj ) ).toString('base64')

	ERRORS: =>
		"ENOTDATE": [ 500, "Invalid date `<%= val %>`. Please use a valid date object or number as timestamp" ]
		"EOLDDATE": [ 500, "Date `<%= val %>` to old. Only dates in the future are allowed" ]
		"EINVALIDACL": [ 500, "The given acl `<%= val %>` is not valid. Only `#{@validation.acl.join('`, `')}` is allowed." ]
		"ENOREDIR": [ 500, "You have to define a `redirectUrlTemplate` as config or `.create()` option." ]
		"EINVALIDREDIR": [ 500, "Only a string or function is valid as redirect url." ]


#export this class
module.exports = AwsS3Form

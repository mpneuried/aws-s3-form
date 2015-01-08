# # aws-s3-form

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

	# ## defaults
	defaults: =>
		@extend super, 
			# **aws-s3-form.accessKeyId** *String* AWS access key
			accessKeyId: "set-in-config-json"
			# **aws-s3-form.secretAccessKey** *String* AWS access secret
			secretAccessKey: "set-in-config-json"
			# **aws-s3-form.region** *String* AWS region
			region: "eu-central-1"
			# **aws-s3-form.bucket** *String* AWS bucket name
			bucket: null
			# **aws-s3-form.redirectUrlTemplate** *String|Function* a redirect url template.
			redirectUrlTemplate: null
			# **aws-s3-form.policyExpiration** *Date|Number* Add time in seconds to now to define the expiration of the policy. Or set a hard Date.
			policyExpiration: 60*60*12 # Default 12 hrs
			# **aws-s3-form.keyPrefix** *String* Key prefix to define a policy that the key has to start with this value
			keyPrefix: "/"
			# **aws-s3-form.acl** *String* Key prefix to define a policy that the key has to start with this value
			acl: "public-read"
			# **aws-s3-form.useUuid** *Boolean* Use a uuid for better security
			useUuid: true

	###
	## create
	
	`basic.create( filename, options )`
	
	create a new form object
	
	@param { String } prop Property name 
	@param { Object } [options] Create options
	@param { String } [options.acl] Option to overwrite the general `acl`
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
			success_action_redirect: @_redirectUrl( options.redirectUrlTemplate, filename: filename )
			credential: @_createCredential( options.now )
			amzdate: @_shortDate( options.now )
		_policyB64 = @_obj2b64( @policy( filename, options, _data ) )

		_signature = @sign( _policyB64, options )


		data =
			action: "http://#{ @config.bucket }.s3.amazonaws.com/"
			filefield: "file"
			fields:
				key: "#{( options.keyPrefix or @config.keyPrefix )}#{filename}"
				acl: _data.acl
				success_action_redirect: _data.success_action_redirect
				"X-Amz-Credential": _data.credential
				"X-Amz-Algorithm": "AWS4-HMAC-SHA256"
				"X-Amz-Date": _data.amzdate
				"Policy": _policyB64
				"X-Amz-Signature": _signature.toString()

		if options.uuid?
			data.fields[ "x-amz-meta-uuid" ] = options.uuid

		return data


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

		if options.uuid?
			policy.conditions.push { "x-amz-meta-uuid": options.uuid }

		return policy

	sign: ( policyB64, options )=>
		_date = options.now or new Date()
		_signdate = options.signdate or @_shortDate( _date, true )

		_h1 = @_hmac( "AWS4" + ( options.secretAccessKey or @config.secretAccessKey ), _signdate )
		_h2 = @_hmac( _h1, ( options.region or @config.region ) )
		_h3 = @_hmac( _h2, "s3" )
		_key = @_hmac( _h3, "aws4_request" )

		return @_hmac( _key, policyB64 ).toString( "hex" )


	_acl: ( acl = @config.acl )=>
		if acl not in @validation.acl
			return @_handleError( null, "EINVALIDACL", val: acl )
		return acl
	
	_redirectUrl: ( tmpl = @config.redirectUrlTemplate, data )=>
		if not tmpl?
			return @_handleError( null, "ENOREDIR" )
		
		if _.isString( tmpl ) 
			return _.template( tmpl, data )
		else if _.isFunction( tmpl )
			return tmpl( data )
		else 
			return @_handleError( null, "EINVALIDREDIR" )

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
			return @_handleError( null, "EOLDDATE", val: date )			
		
		return ( new Date( _ts + _msAdd ) ).toISOString()

	_createCredential: ( date )=>
		shortDate = @_shortDate( date, true )
		return "#{@config.accessKeyId}/#{shortDate}/#{@config.region}/s3/aws4_request"

	_shortDate: ( date = new Date(), onlyDate = false )=>
		_sfull = date.toISOString().replace( /\.[0-9]{1,3}Z/g, "Z" ).replace( /[\.:-]/g, "" )
		if onlyDate
			return _sfull.substr( 0, 8 )
		return _sfull


	_hmac: ( secret, val )=>
		_hash = crypto.createHmac('SHA256', secret ).update( val )
		return new Buffer( _hash.digest( "base64" ), "base64" )


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
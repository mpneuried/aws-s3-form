path = require( "path" )
fs = require( "fs" )
crypto = require( "crypto" )
url = require( "url" )

should = require('should')
request = require( "request" )
mime = require('mime')
xmlParse = require('xml2js').parseString

Module = require( "../." )
utils = require( "../lib/utils" )

_moduleInst = null
_config = null


redirPre = "://localhost:3010/redir/"
testfileStreamA = null
testfileStreamB = null
testfileName = null
testfileMime = null

describe "----- aws-s3-form TESTS -----", ->

	before ( done )->
		_config = require( "../config_test.json" )
		
		testfileStreamA = fs.createReadStream(_config.mocha.file)
		testfileStreamB = fs.createReadStream(_config.mocha.file)
		testfileName = path.basename( _config.mocha.file )
		testfileMime = mime.lookup( _config.mocha.file )

		_config.s3.keyPrefix = "test_"


		_moduleInst = new Module( _config.s3 )
		# TODO add initialisation Code
		done()
		return

	after ( done )->
		#  TODO teardown
		done()
		return

	describe 'Main Tests', ->
		
		_dataA = null
		_filenameA = null 
		_dataB = null
		_filenameB = null 

		it "test signing", ( done )->
			# Example out of http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html
			_testsecret = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
			_region = "us-east-1"
			_policy = "eyAiZXhwaXJhdGlvbiI6ICIyMDEzLTA4LTA3VDEyOjAwOjAwLjAwMFoiLA0KICAiY29uZGl0aW9ucyI6IFsNCiAgICB7ImJ1Y2tldCI6ICJleGFtcGxlYnVja2V0In0sDQogICAgWyJzdGFydHMtd2l0aCIsICIka2V5IiwgInVzZXIvdXNlcjEvIl0sDQogICAgeyJhY2wiOiAicHVibGljLXJlYWQifSwNCiAgICB7InN1Y2Nlc3NfYWN0aW9uX3JlZGlyZWN0IjogImh0dHA6Ly9leGFtcGxlYnVja2V0LnMzLmFtYXpvbmF3cy5jb20vc3VjY2Vzc2Z1bF91cGxvYWQuaHRtbCJ9LA0KICAgIFsic3RhcnRzLXdpdGgiLCAiJENvbnRlbnQtVHlwZSIsICJpbWFnZS8iXSwNCiAgICB7IngtYW16LW1ldGEtdXVpZCI6ICIxNDM2NTEyMzY1MTI3NCJ9LA0KICAgIFsic3RhcnRzLXdpdGgiLCAiJHgtYW16LW1ldGEtdGFnIiwgIiJdLA0KDQogICAgeyJ4LWFtei1jcmVkZW50aWFsIjogIkFLSUFJT1NGT0ROTjdFWEFNUExFLzIwMTMwODA2L3VzLWVhc3QtMS9zMy9hd3M0X3JlcXVlc3QifSwNCiAgICB7IngtYW16LWFsZ29yaXRobSI6ICJBV1M0LUhNQUMtU0hBMjU2In0sDQogICAgeyJ4LWFtei1kYXRlIjogIjIwMTMwODA2VDAwMDAwMFoiIH0NCiAgXQ0KfQ=="
			_signature = _moduleInst.sign _policy, 
				signdate: "20130806"
				secretAccessKey: _testsecret
				region: _region
			should.equal _signature, "21496b44de44ccb73d545f1a995c68214c9cb0d41c45a17a5daeec0b1a6db047"
			done()
			return

		# Implement tests cases here
		it "create data", ( done )->
			_filenameA = utils.randomString( 10 )
			_opt = 
				redirectUrlTemplate: "https" + redirPre + _filenameA
				secure: true

			_dataA = _moduleInst.create( _filenameA, _opt )
			done()
			return


		it "send file to s3", ( done )->
			@timeout( 30000 )

			formdata = _dataA.fields
			formdata.file =
				value: testfileStreamA
				options:
					filename: testfileName
					contentType: testfileMime
			#console.log _dataA
			request.post { url: _dataA.action, formData: formdata }, ( err, resp, body )=>
				#console.log  err, resp, body
				if err
					console.log err
					throw err
				
				
				if resp.statusCode >= 400 or resp.statusCode < 200
					xmlParse body, ( err, data )->
						if err
							console.log err
							throw err

						console.error( data )
						throw "AWS ERROR"
					return

				if resp.statusCode is 303
					_redirUrl = resp.headers.location

					_pathobj = url.parse( _redirUrl, true )
					_redirobj = url.parse( _dataA.fields.success_action_redirect )
					
					should.equal _pathobj.pathname, _redirobj.pathname
					should.equal _pathobj.query.bucket, _config.s3.bucket
					should.equal _pathobj.query.key, _config.s3.keyPrefix + _filenameA
					done()
				return
			return

		it "check if file exists in s3", ( done )->
			_url = "https://s3.#{ _config.s3.region }.amazonaws.com/#{ _config.s3.bucket }/#{_config.s3.keyPrefix + _filenameA}"
			request.head _url, ( err, resp, body )=>
				if err
					throw err
				should.equal( resp.statusCode, 200 )
				done()
				return
			return

		# Implement tests cases here
		it "create data (no ssl)", ( done )->
			_filenameB = utils.randomString( 10 )
			_opt = 
				redirectUrlTemplate: "http" + redirPre + _filenameB
				secure: false
			_dataB = _moduleInst.create( _filenameB, _opt )
			done()
			return

		it "send file to s3 (no ssl)", ( done )->
			@timeout( 30000 )

			formdata = _dataB.fields
			formdata.file =
				value: testfileStreamB
				options:
					filename: testfileName
					contentType: testfileMime
			#console.log _dataB
			request.post { url: _dataB.action, formData: formdata }, ( err, resp, body )=>
				if err
					console.log err
					throw err
				
				
				if resp.statusCode >= 400 or resp.statusCode < 200
					xmlParse body, ( err, data )->
						if err
							console.log err
							throw err

						console.error( data )
						throw "AWS ERROR"
					return

				if resp.statusCode is 303
					_redirUrl = resp.headers.location

					_pathobj = url.parse( _redirUrl, true )
					_redirobj = url.parse( _dataB.fields.success_action_redirect )
					
					should.equal _pathobj.pathname, _redirobj.pathname
					should.equal _pathobj.query.bucket, _config.s3.bucket
					should.equal _pathobj.query.key, _config.s3.keyPrefix + _filenameB
					done()
				return
			return

		it "check if file exists in s3 (no ssl)", ( done )->
			_url = "http://s3.#{ _config.s3.region }.amazonaws.com/#{ _config.s3.bucket }/#{_config.s3.keyPrefix + _filenameB}"
			request.head _url, ( err, resp, body )=>
				if err
					throw err
				should.equal( resp.statusCode, 200 )
				done()
				return
			return

		return
	return
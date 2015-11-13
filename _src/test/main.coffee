path = require( "path" )
fs = require( "fs" )
crypto = require( "crypto" )
url = require( "url" )

should = require('should')
request = require( "request" )
mime = require('mime-nofs')
xmlParse = require('xml2js').parseString

Module = require( "../." )
utils = require( "../lib/utils" )

_moduleInst = null
_config = null


redirPre = "://localhost:3010/redir/"
testfileStreamA = null
testfileStreamB = null
testfileStreamC = null
testfileStreamD = null
testfileStreamE = null
testfileStreamF = null
testfileName = null
testfileMime = null

initFileStreams = ->
	testfileStreamA = fs.createReadStream(_config.mocha.file)
	testfileStreamB = fs.createReadStream(_config.mocha.file)
	testfileStreamC = fs.createReadStream(_config.mocha.file)
	testfileStreamD = fs.createReadStream(_config.mocha.file)
	testfileStreamE = fs.createReadStream(_config.mocha.file)
	testfileStreamF = fs.createReadStream(_config.mocha.file)
	testfileStreamG = fs.createReadStream(_config.mocha.file)
	return

mimes = [ "application/pdf", "image/jpeg", "text/plain" ]

describe "----- aws-s3-form TESTS -----", ->

	before ( done )->
		_config = require( "../config_test.json" )
		
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
	
	for cryptomod in [ "crypto", "crypto-js" ]
		(( cryptomod )->
			describe "Main Tests with \"#{cryptomod}\"", ->
				
				
				
				_dataA = null
				_filenameA = null
				_dataB = null
				_filenameB = null
				_dataC = null
				_filenameC = null
				_dataD = null
				_filenameD = null
				_dataE = null
				_filenameE = null
				_dataF = null
				_filenameF = null
				_dataG = null
				_filenameG = null
				
				describe 'Signing', ->
					it 'Set cyrpto module', ->
						_moduleInst._setCryptoModule( cryptomod )
						return
					
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
					return
				
						
				describe 'SSL', ->
					it "init filestreams", ->
						initFileStreams()
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
						request.post { url: _dataA.action, formData: formdata }, ( err, resp, body )->
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
									throw new Error( "AWS ERROR" )
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
						request.head _url, ( err, resp, body )->
							if err
								throw err
							should.equal( resp.statusCode, 200 )
							done()
							return
						return
					return
					
				describe 'No SSL', ->

					# Implement tests cases here
					it "create data", ( done )->
						_filenameB = utils.randomString( 10 )
						_opt =
							redirectUrlTemplate: "http" + redirPre + _filenameB
							secure: false
						_dataB = _moduleInst.create( _filenameB, _opt )
						done()
						return

					it "send file to s3", ( done )->
						@timeout( 30000 )

						formdata = _dataB.fields
						formdata.file =
							value: testfileStreamB
							options:
								filename: testfileName
								contentType: testfileMime
						#console.log _dataB
						request.post { url: _dataB.action, formData: formdata }, ( err, resp, body )->
							if err
								console.log err
								throw err
							
							
							if resp.statusCode >= 400 or resp.statusCode < 200
								xmlParse body, ( err, data )->
									if err
										console.log err
										throw err

									console.error( data )
									throw new Error( "AWS ERROR" )
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
						request.head _url, ( err, resp, body )->
							if err
								throw err
							should.equal( resp.statusCode, 200 )
							done()
							return
						return
					return
				
				describe 'With Mime', ->
					# Implement tests cases here
					it "create data", ( done )->
						_filenameC = utils.randomString( 10 ) + "." + mime.extension(testfileMime)
						_opt =
							redirectUrlTemplate: "http" + redirPre + _filenameC
							secure: false
							contentType: testfileMime
							
						_dataC = _moduleInst.create( _filenameC, _opt )
						done()
						return
					
					it "send file to s3", ( done )->
						@timeout( 30000 )

						formdata = _dataC.fields
						formdata.file =
							value: testfileStreamC
							options:
								filename: testfileName
								contentType: testfileMime
						#console.log _dataC
						request.post { url: _dataC.action, formData: formdata }, ( err, resp, body )->
							if err
								console.log err
								throw err
							
							
							if resp.statusCode >= 400 or resp.statusCode < 200
								xmlParse body, ( err, data )->
									if err
										console.log err
										throw err

									console.error( data )
									throw new Error( "AWS ERROR" )
								return

							if resp.statusCode is 303
								_redirUrl = resp.headers.location

								_pathobj = url.parse( _redirUrl, true )
								_redirobj = url.parse( _dataC.fields.success_action_redirect )
								
								should.equal _pathobj.pathname, _redirobj.pathname
								should.equal _pathobj.query.bucket, _config.s3.bucket
								should.equal _pathobj.query.key, _config.s3.keyPrefix + _filenameC
								done()
							return
						return
					
					it "check if file exists in s3", ( done )->
						_url = "http://s3.#{ _config.s3.region }.amazonaws.com/#{ _config.s3.bucket }/#{_config.s3.keyPrefix + _filenameC}"
						request.head _url, ( err, resp, body )->
							if err
								throw err
							should.equal( resp.statusCode, 200 )
							done()
							return
						return

					return
				
				
				describe 'Auto mime', ->
					# Implement tests cases here
					it "create data", ( done )->
						_filenameD = utils.randomString( 10 ) + "." + mime.extension(testfileMime)
						_opt =
							redirectUrlTemplate: "http" + redirPre + _filenameD
							secure: false
							contentType: true
							
						_dataD = _moduleInst.create( _filenameD, _opt )
						done()
						return
					
					it "send file to s3", ( done )->
						@timeout( 30000 )

						formdata = _dataD.fields
						formdata.file =
							value: testfileStreamD
							options:
								filename: testfileName
								contentType: testfileMime
						#console.log _dataD
						request.post { url: _dataD.action, formData: formdata }, ( err, resp, body )->
							if err
								console.log err
								throw err
							
							if resp.statusCode >= 400 or resp.statusCode < 200
								xmlParse body, ( err, data )->
									if err
										console.log err
										throw err

									console.error( data )
									throw new Error( "AWS ERROR" )
								return

							if resp.statusCode is 303
								_redirUrl = resp.headers.location

								_pathobj = url.parse( _redirUrl, true )
								_redirobj = url.parse( _dataD.fields.success_action_redirect )
								
								should.equal _pathobj.pathname, _redirobj.pathname
								should.equal _pathobj.query.bucket, _config.s3.bucket
								should.equal _pathobj.query.key, _config.s3.keyPrefix + _filenameD
								done()
							return
						return
						
					it "check if file exists in s3", ( done )->
						_url = "http://s3.#{ _config.s3.region }.amazonaws.com/#{ _config.s3.bucket }/#{_config.s3.keyPrefix + _filenameD}"
						request.head _url, ( err, resp, body )->
							if err
								throw err
							should.equal( resp.statusCode, 200 )
							done()
							return
						return
					return
				
				describe 'Auto mime and valid condition', ->
					# Implement tests cases here
					it "create data", ( done )->
						_filenameE = utils.randomString( 10 ) + "." + mime.extension(testfileMime)
						_opt =
							redirectUrlTemplate: "http" + redirPre + _filenameE
							secure: false
							contentType: true
							customConditions: [
								["starts-with", "$content-type", "image/"]
							]
							
						_dataE = _moduleInst.create( _filenameE, _opt )
						done()
						return
					
					it "send file to s3", ( done )->
						@timeout( 30000 )

						formdata = _dataE.fields
						formdata.file =
							value: testfileStreamE
							options:
								filename: testfileName
								contentType: testfileMime
						#console.log _dataE
						request.post { url: _dataE.action, formData: formdata }, ( err, resp, body )->
							if err
								console.log err
								throw err
							
							if resp.statusCode >= 400 or resp.statusCode < 200
								xmlParse body, ( err, data )->
									if err
										console.log err
										throw err

									console.error( data )
									throw new Error( "AWS ERROR" )
								return

							if resp.statusCode is 303
								_redirUrl = resp.headers.location

								_pathobj = url.parse( _redirUrl, true )
								_redirobj = url.parse( _dataE.fields.success_action_redirect )
								
								should.equal _pathobj.pathname, _redirobj.pathname
								should.equal _pathobj.query.bucket, _config.s3.bucket
								should.equal _pathobj.query.key, _config.s3.keyPrefix + _filenameE
								done()
							return
						return
					it "check if file exists in s3", ( done )->
						_url = "http://s3.#{ _config.s3.region }.amazonaws.com/#{ _config.s3.bucket }/#{_config.s3.keyPrefix + _filenameE}"
						request.head _url, ( err, resp, body )->
							if err
								throw err
							should.equal( resp.statusCode, 200 )
							done()
							return
						return
					return
				
				describe 'Auto mime and invalid condition', ->
					# Implement tests cases here
					it "create data with mimetype", ( done )->
						_filenameF = utils.randomString( 10 ) + "." + mime.extension(testfileMime)
						_opt =
							redirectUrlTemplate: "http" + redirPre + _filenameF
							secure: false
							contentType: true
							customConditions: [
								["starts-with", "$content-type", "application/"]
							]
							
						_dataF = _moduleInst.create( _filenameF, _opt )
						done()
						return
					
					it "send file to s3 with mimetype", ( done )->
						@timeout( 30000 )

						formdata = _dataF.fields
						formdata.file =
							value: testfileStreamF
							options:
								filename: testfileName
								contentType: testfileMime
						#console.log _dataF
						request.post { url: _dataF.action, formData: formdata }, ( err, resp, body )->
							if err
								console.log "ERR", err
								throw err
							
							if resp.statusCode >= 400 or resp.statusCode < 200
								xmlParse body, ( err, data )->
									if err
										console.log err
										throw err

									errorCode = data?.Error?.Code?[0]
									errorMsg = data?.Error?.Message?[0]
									errorCode.should.eql( "AccessDenied" )
									errorMsg.should.startWith( "Invalid according to Policy" )
									errorMsg.should.match( /\$content-type/i )
									done()
								return
								
							throw new Error( "should fail" )
							return
						return
						
					it "check if file not exists in s3", ( done )->
						_url = "http://s3.#{ _config.s3.region }.amazonaws.com/#{ _config.s3.bucket }/#{_config.s3.keyPrefix + _filenameF}"
						request.head _url, ( err, resp, body )->
							if err
								throw err
							should.equal( resp.statusCode, 403 )
							done()
							return
						return
				
					return
				
				describe 'Custom condition', ->
					it "create data with numeric custom max length condtion", ( done )->
						_filenameG = utils.randomString( 10 ) + "." + mime.extension(testfileMime)
						
						_opt =
							contentType: 'contentType'
							customConditions: [
							  ['content-length-range', 0, 1048576],
							]
						_dataG = _moduleInst.create( _filenameF, _opt )
						done()
						return
					
					return
				return
		)( cryptomod )
	return

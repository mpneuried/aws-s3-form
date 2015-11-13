url = require( "url" )

should = require('should')
request = require( "request" )
mime = require('mime-nofs')
xmlParse = require('xml2js').parseString

Module = require( "../." )
utils = require( "../lib/utils" )

_moduleInst = null

describe "----- aws-s3-form Travis TESTS -----", ->
	console.log "Because this module requires AWS credentials it only possible to test the sigining."
	before ( done )->
		_config =
			"accessKeyId": "- - -",
			"secretAccessKey": "- - -",
			"region": "eu-central-1",
			"bucket": "- - -"
		
		_moduleInst = new Module( _config )
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
				return
		)( cryptomod )
	return

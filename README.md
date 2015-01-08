aws-s3-form
============

[![Build Status](https://secure.travis-ci.org/mpneuried/aws-s3-form.png?branch=master)](http://travis-ci.org/mpneuried/aws-s3-form)
[![Dependencies](https://david-dm.org/mpneuried/aws-s3-form.png)](https://david-dm.org/mpneuried/aws-s3-form)
[![NPM version](https://badge.fury.io/js/aws-s3-form.png)](http://badge.fury.io/js/aws-s3-form)

Generate a signed and reday to use formdata to put files to s3 directly from teh browser. Signing is done by using AWS Signature Version 4 

## Install

```sh
  npm install aws-s3-form
```

## Initialize

```js
  var AwsS3Form = require( "aws-s3-form" );

  var formGen = new AwsS3Form({
  	accessKeyId:		"your-access-key",
  	secretAccessKey:	"your-secret",
  	region:				"us-east-1",
  	bucket:				"my-bucket-name",
  	redirectUrlTemplate:"http://localhost:3010/redir/<%= filename %>"
  });
```

## Usage

```js
formdata = formGen.create( "my-s3-filename-or-key" )
/*

	{
		action: "http://my-bucket-name.s3.amazonaws.com/",
		filefield: "file",
		fields: {
			key: "my-s3-filename-or-key",
			acl: "public-read",
			success_action_redirect: "http://localhost:3010/redir/my-s3-filename-or-key",
			"X-Amz-Credential": "your-access-key/20150108/us-east-1/s3/aws4_request",
			"X-Amz-Algorithm": "AWS4-HMAC-SHA256",
			"X-Amz-Date": "20150108T103146Z",
			"Policy": "eyJleHBpcmF0aW9uIj ... generated base64 policy ... XdpdGgiLCI",
			"X-Amz-Signature": "4732d1 ... generated signature ... 1ac65d171a"
		}
	}

 */
```
**Options** 

- **foo** : *( `String` required )* TODO option description
- **bar** : *( `Number` optional: default = `123` )* TODO option description

## Todos

 * implement test cases to check for correct template generation.

## Release History
|Version|Date|Description|
|:--:|:--:|:--|
|0.0.1|2015-1-8|Initial commit|

## The MIT License (MIT)

Copyright © 2013 Mathias Peter, http://www.tcs.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

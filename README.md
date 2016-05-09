aws-s3-form
============

[![Build Status](https://secure.travis-ci.org/mpneuried/aws-s3-form.png?branch=master)](http://travis-ci.org/mpneuried/aws-s3-form)
[![Dependencies](https://david-dm.org/mpneuried/aws-s3-form.png)](https://david-dm.org/mpneuried/aws-s3-form)
[![NPM version](https://badge.fury.io/js/aws-s3-form.png)](http://badge.fury.io/js/aws-s3-form)

[![NPM](https://nodei.co/npm/aws-s3-form.png?downloads=true&downloadRank=true&stars=true)](https://nodei.co/npm/aws-s3-form/)


Generate a signed and ready to use formdata to put files to S3 directly from the browser. Signing is done by using AWS Signature Version 4 

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

## Basic Usage

```js
formdata = formGen.create( "my-s3-filename-or-key" )
/*

	{
		action: "http://my-bucket-name.s3.amazonaws.com/",		// The form action url. Make sure to add also `method="POST" enctype="multipart/form-data`
		filefield: "file",										// Name of the input field to upload a single file to S3.
		fields: {												// Hidden fields to add to the form. Object-key = form-name and object-value = form-value
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

**Config** 

- **accessKeyId** *( `String` required )* AWS access key
- **secretAccessKey** *( `String` required )* AWS access secret
- **region** *( `String` required )* AWS region
- **bucket** *( `String` required )* AWS bucket name
- **secure** *( `Boolean` optional: default = `true` )* Define if the action uses ssl. `true` = "https"; `false` = "http"
- **redirectUrlTemplate** *( `String|Function` optional )* a redirect url template.
- **successActionStatus** *( `String|Number` optional: default = `204` )* HTTP code to return when no redirectUrlTemplate is defined.
- **policyExpiration** *( `Date|Number` optional: default = `43200` )* Add time in seconds to now to define the expiration of the policy. Or set a hard Date *( `43200` = 12 hours )*.
- **keyPrefix** *( `String` optional: default = `` )* Key prefix to define a policy that the key has to start with this value
- **acl** *( `String` optional: default = `public-read` )* The standard acl type. Only `private`, `public-read`, `public-read-write`, `authenticated-read`, `bucket-owner-read` and `bucket-owner-full-control` are allowed
- **useUuid** *( `Boolean` optional: default = `true` )* Use a uuid for better security
- **cryptoModule** *( `String` optional: default = `crypto`; enum: `crypto`,`crypto-js` )* You can switch between the node internal crypo-module or the browser module [cryptojs](https://www.npmjs.com/package/crypto-js).  
  **INFO:** If you want to use `crypto-js` you have to add/install it separately with `npm install crypto-js`.

### Security Warning!

Do not hard code the `secretAccessKey` in your code if you want to open source it! ;-)

## Methods

#### `.create( filename [, options ] )`

Create new signed and ready to use formdata.

**Arguments**

* `filename` : *( `String` required )*: The S3 file key/filename to use.
* `options` : *( `Object` optional )*: Options to change the configured behavior
* `options.acl` : *( `String` optional; default = `config.acl` )*: Change the configured standard `acl` type. Only `private`, `public-read`, `public-read-write`, `authenticated-read`, `bucket-owner-read` and `bucket-owner-full-control` are allowed
* `options.keyPrefix` : *( `String` optional; default = `config.keyPrefix` )*: Change the configured standard `keyPrefix` type. Details see config object description.
* `options.contentType` : *( `String|Boolean` optional; )*:  Option to set the content type of the uploaded file. This could be a string with a fixed mime or a boolean to decide if the mime will be guessed by the filename.
* `options.customConditions` : *( `Array` optional; )*: Option to set s3 upload conditions. For details see http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-HTTPPOSTConstructPolicy.html
* `options.redirectUrlTemplate` : *( `String` optional; default = `config.redirectUrlTemplate` )*: Change the configured standard `redirectUrlTemplate` type. Details see config object description.
* `options.successActionStatus` : *( `String|Number` optional; default = `config.successActionStatus` )*: Change the configured standard `successActionStatus` type. Details see config object description.
* `options.policyExpiration` : *( `Date|Number` optional; default = `config.policyExpiration` )*: Change the configured standard `policyExpiration` type. Details see config object description.

**Return**

*( Object )*: Data needed to generate a form that can upload files directly to AWS S3.
 - **action** : *( `String` )* The form action url. Make sure to add also the attributes `method="POST" enctype="multipart/form-data`
 - **filefield** : *( `String` )* Name of the input field to upload a single file to S3.
 - **fields** : *( `Object` )* Hidden fields to add to the form. Object-key = form-name and object-value = form-value.

#### `.policy( filename [, options ] )`

Create a new AWS S3 policy object based on AWS Signature Version 4.

**Arguments**

* `filename` : *( `String` required )*: The S3 file key/filename to use.
* `options` : *( `Object` optional )*: Options to change the configured behavior
* `options.now` : *( `Date` optional; default = `new Date()` )*: The current date-time for this policy
* `options.uuid` : *( `String` optional;)*: The uuid to add to the policy
* `options.acl` : *( `String` optional; default = `config.acl` )*: Change the configured standard `acl` type. Only `private`, `public-read`, `public-read-write`, `authenticated-read`, `bucket-owner-read` and `bucket-owner-full-control` are allowed
* `options.keyPrefix` : *( `String` optional; default = `config.keyPrefix` )*: Change the configured standard `keyPrefix` type. Details see config object description.
* `options.customConditions` : *( `Array` optional; )*: Option to set s3 upload conditions. For details see http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-HTTPPOSTConstructPolicy.html
* `options.redirectUrlTemplate` : *( `String` optional; default = `config.redirectUrlTemplate` )*: Change the configured standard `redirectUrlTemplate` type. Details see config object description.
* `options.successActionStatus` : *( `Number` optional; default = `config.successActionStatus` )*: Change the configured standard `successActionStatus` type. Details see config object description.
* `options.policyExpiration` : *( `Date|Number` optional; default = `config.policyExpiration` )*: Change the configured standard `policyExpiration` type. Details see config object description.

**Return**

*( Object )*: A valid S3 POST policy.  
> Details see [AWS Docs: Creating a POST Policy](http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-HTTPPOSTConstructPolicy).

#### `.sign( policyB64 [, options ] )`

Create a AWS Signature Version 4. This is used to create the signature out of the policy.

**Arguments**

* `policyB64` : *( `String` required )*: Base64 encoded policy.
* `options` : *( `Object` optional )*: Options to change the configured behavior
* `options.now` : *( `Date` optional; default = `new Date()` )*: The current date-time for this signature
* `options.signdate` : *( `String` optional; default = converted `options.now` )*: signature date
* `options.secretAccessKey` : *( `String` optional; default = `config.secretAccessKey` )*: Change the configured standard `secretAccessKey` type. Details see config object description.
* `options.region` : *( `String` optional; default = `config.region` )*: Change the configured standard `region` type. Details see config object description.
**Return**

*( Object )*: AWS Signature Version 4.  
> Details see [AWS Docs: Authenticating Requests in Browser-Based Uploads Using POST (AWS Signature Version 4)](http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-authentication-HTTPPOST.html)

## Example Server

You can see a working example express server [here](https://github.com/mpneuried/aws-s3-form/blob/master/_src/test/server.coffee) and the corresponding jade template [here](https://github.com/mpneuried/aws-s3-form/blob/master/_testviews/index.jade). 

## Use Cases

#### use origin filename as S3 key/filename

It is a typical use case to reuse the original filename as s3 key.
To handle this correctly this is the example to do it correctly.

```js
  var AwsS3Form = require( "aws-s3-form" );

  var formGen = new AwsS3Form({
  	accessKeyId:		"your-access-key",
  	secretAccessKey:	"your-secret",
  	region:				"us-east-1",
  	bucket:				"my-bucket-name",
  	redirectUrlTemplate:"http://localhost:3010/redir/*"
  });
  
  var myForm = formGen.create( "${filename}" );
  
  / ... handle the data

``` 

The key points are, that you have to specify:

- the redirect with `*` at the end
- the filename with the placeholder `${filename}`

*This is also implemented within the example server as special case*

> Requested by [jontelm #1](https://github.com/mpneuried/aws-s3-form/issues/1)

## Todos

 * Mimetype guessing based on the given key/filename
 * Better policy generator to be able to add mimetype, filesize, ... policies.
 * get credentials by environment variables or Shared Credentials File. [Details]( http://docs.aws.amazon.com/AWSJavaScriptSDK/guide/node-configuring.html )

## Development and Testing

If you want to contribute you have to clone the git repository and init it:

```sh
npm install
grunt build
```

Then configure the tests by copy the file `_skeleton_config_test.json` to `config_test.json` and fill in the correct data.
Then you are able to run `grunt test` or start the express example in `test/server.js`.

## Play with it ...

To get your hands on the module you can start the testing server and try out some configurations.

This will look like:  
![Example view](https://raw.githubusercontent.com/mpneuried/aws-s3-form/master/_docs/testpage.png)

**Install:**

```
$ git clone https://github.com/mpneuried/aws-s3-form.git
$ cd aws-s3-form
$ npm install
$ grunt build
```

**Configure:**

Create a file called `config_test.json` with the following content and set your AWS crendentials:

```
{
	"s3": {
		"accessKeyId": " - Please define your test key - ",
		"secretAccessKey": " - Please define your test secret - ",
		"region": "eu-central-1",
		"bucket": " - Please define your test bucket - "
	}
}
```

**Start:**

```
$ node test/server.js
```

Open `http://localhost:3010/` in your browser.

## Code docs

The code docs can be found **[here](https://rawgit.com/mpneuried/aws-s3-form/master/_docs/_src/lib/aws-s3-form.coffee.html)**.


## Release History
|Version|Date|Description|
|:--:|:--:|:--|
|0.3.5|2016-05-09|Hard set of dependency `node-uuid` to >= 1.4.4 because of [security issue](https://nodesecurity.io/advisories/uuid_insecure-entropy-source-mathrandom).|
|0.3.4|2016-05-09|Updated dependencies, especially lodash to 4.x.; Optimized readme.|
|0.3.3|2015-11-13|Added a option `cryptoModule` to select `crypto` or `crypto-js` as internal crypto module. (thanks to [retorquere](https://github.com/retorquere) and [Ilya Shindyapin](https://github.com/license2e))|
|0.3.2|2015-11-06|Moved from `mime` to `mime-nofs` to use this module inside external modules like react-native or within the browser (thanks to [retorquere](https://github.com/retorquere))|
|0.3.1|2015-08-26|Added all possible acl options and fixed numeric custom conditions (thanks to [retorquere](https://github.com/retorquere));|
|0.3.0|2015-05-27|Added `contentType` to options and optional `customConditions` to define a custom aws-s3 policy |
|0.2.0|2015-04-07|Added option `successActionStatus` to make ajax form posts possible|
|0.1.4|2015-03-17|Added option `secure` to create method|
|0.1.2|2015-03-17|Added option `secure` to define the http type (http or https)|
|0.0.5|2015-01-26|Updated readme and optimized example server|
|0.0.4|2015-01-09|Initial version.|

[![NPM](https://nodei.co/npm-dl/aws-s3-form.png?months=6)](https://nodei.co/npm/aws-s3-form/)

## Other projects

|Name|Description|
|:--|:--|
|[**mime-nofs**](https://github.com/mpneuried/mime-nofs)|Comprehensive MIME type mapping API based on mime-db module. Without the filesystem dependency|
|[**node-cache**](https://github.com/tcs-de/nodecache)|Simple and fast NodeJS internal caching. Node internal in memory cache like memcached.|
|[**rsmq**](https://github.com/smrchy/rsmq)|A really simple message queue based on Redis|
|[**rsmq-cli**](https://github.com/mpneuried/rsmq-cli)|a terminal client for rsmq|
|[**rest-rsmq**](https://github.com/smrchy/rest-rsmq)|REST interface for.|
|[**redis-notifications**](https://github.com/mpneuried/redis-notifications)|A redis based notification engine. It implements the rsmq-worker to safely create notifications and recurring reports.|
|[**redis-sessions**](https://github.com/smrchy/redis-sessions)|An advanced session store for NodeJS and Redis|
|[**connect-redis-sessions**](https://github.com/mpneuried/connect-redis-sessions)|A connect or express middleware to simply use the [redis sessions](https://github.com/smrchy/redis-sessions). With [redis sessions](https://github.com/smrchy/redis-sessions) you can handle multiple sessions per user_id.|
|[**redis-heartbeat**](https://github.com/mpneuried/redis-heartbeat)|Pulse a heartbeat to redis. This can be used to detach or attach servers to nginx or similar problems.|
|[**systemhealth**](https://github.com/mpneuried/systemhealth)|Node module to run simple custom checks for your machine or it's connections. It will use [redis-heartbeat](https://github.com/mpneuried/redis-heartbeat) to send the current state to redis.|
|[**task-queue-worker**](https://github.com/smrchy/task-queue-worker)|A powerful tool for background processing of tasks that are run by making standard http requests.|
|[**soyer**](https://github.com/mpneuried/soyer)|Soyer is small lib for serverside use of Google Closure Templates with node.js.|
|[**grunt-soy-compile**](https://github.com/mpneuried/grunt-soy-compile)|Compile Goggle Closure Templates ( SOY ) templates inclding the handling of XLIFF language files.|
|[**backlunr**](https://github.com/mpneuried/backlunr)|A solution to bring Backbone Collections together with the browser fulltext search engine Lunr.js|
|[**domel**](https://github.com/mpneuried/domel)|A simple dom helper if you want to get rid of jQuery|
|[**obj-schema**](https://github.com/mpneuried/obj-schema)|Simple module to validate an object by a predefined schema|


## The MIT License (MIT)

Copyright © 2015 Mathias Peter, http://www.tcs.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

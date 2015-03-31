(function() {
  var AwsS3Form, _, crypto, utils, uuid,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  crypto = require("crypto");

  _ = require('lodash');

  uuid = require('node-uuid');

  utils = require("./utils");

  AwsS3Form = (function(superClass) {
    extend(AwsS3Form, superClass);

    function AwsS3Form() {
      this.ERRORS = bind(this.ERRORS, this);
      this._obj2b64 = bind(this._obj2b64, this);
      this._hmac = bind(this._hmac, this);
      this._shortDate = bind(this._shortDate, this);
      this._createCredential = bind(this._createCredential, this);
      this._calcDate = bind(this._calcDate, this);
      this._successActionStatus = bind(this._successActionStatus, this);
      this._successActionStatus = bind(this._successActionStatus, this);
      this._redirectUrl = bind(this._redirectUrl, this);
      this._acl = bind(this._acl, this);
      this.sign = bind(this.sign, this);
      this.policy = bind(this.policy, this);
      this.create = bind(this.create, this);
      this.defaults = bind(this.defaults, this);
      return AwsS3Form.__super__.constructor.apply(this, arguments);
    }

    AwsS3Form.prototype.validation = {
      acl: ["public-read", "authenticated-read"],
      successActionStatus: [200, 201, 204]
    };

    AwsS3Form.prototype.defaults = function() {
      return this.extend(AwsS3Form.__super__.defaults.apply(this, arguments), {
        accessKeyId: "set-in-config-json",
        secretAccessKey: "set-in-config-json",
        region: "eu-central-1",
        bucket: null,
        secure: true,
        redirectUrlTemplate: null,
        successActionStatus: 204,
        policyExpiration: 60 * 60 * 12,
        keyPrefix: "",
        acl: "public-read",
        useUuid: true
      });
    };


    /*
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
     */

    AwsS3Form.prototype.create = function(filename, options) {
      var _data, _policyB64, _secure, _signature, data;
      if (options == null) {
        options = {};
      }
      options.now = new Date();
      if (this.config.useUuid) {
        options.uuid = uuid.v4();
      }
      _data = {
        acl: this._acl(options.acl),
        credential: this._createCredential(options.now),
        amzdate: this._shortDate(options.now)
      };
      _policyB64 = this._obj2b64(this.policy(filename, options, _data));
      _signature = this.sign(_policyB64, options);
      if (options.secure != null) {
        _secure = options.secure;
      } else {
        _secure = this.config.secure;
      }
      data = {
        action: (_secure ? "https" : "http") + "://s3-" + this.config.region + ".amazonaws.com/" + this.config.bucket,
        filefield: "file",
        fields: {
          key: "" + (options.keyPrefix || this.config.keyPrefix) + filename,
          acl: _data.acl,
          "X-Amz-Credential": _data.credential,
          "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
          "X-Amz-Date": _data.amzdate,
          "Policy": _policyB64,
          "X-Amz-Signature": _signature.toString()
        }
      };
      if (options.redirectUrlTemplate != null) {
        data.fields.success_action_redirect = this._redirectUrl(options.redirectUrlTemplate, {
          filename: filename
        });
      } else {
        data.fields.success_action_status = this._successActionStatus(options.successActionStatus);
      }
      if (options.uuid != null) {
        data.fields["x-amz-meta-uuid"] = options.uuid;
      }
      return data;
    };


    /*
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
     */

    AwsS3Form.prototype.policy = function(filename, options, _predef) {
      var _date, policy;
      if (options == null) {
        options = {};
      }
      if (_predef == null) {
        _predef = {};
      }
      _date = options.now || new Date();
      policy = {
        expiration: this._calcDate(options.policyExpiration || this.config.policyExpiration, _date),
        conditions: [
          {
            bucket: this.config.bucket
          }, ["starts-with", "$key", options.keyPrefix || this.config.keyPrefix], {
            acl: _predef.acl || this._acl(options.acl)
          }, {
            success_action_redirect: _predef.success_action_redirect || this._redirectUrl(options.redirectUrlTemplate, {
              filename: filename
            })
          }, {
            "x-amz-credential": _predef.credential || this._createCredential(_date)
          }, {
            "x-amz-algorithm": "AWS4-HMAC-SHA256"
          }, {
            "x-amz-date": _predef.amzdate || this._shortDate(_date)
          }
        ]
      };
      this.debug("generated policy", policy);
      if (options.uuid != null) {
        policy.conditions.push({
          "x-amz-meta-uuid": options.uuid
        });
      }
      return policy;
    };


    /*
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
     */

    AwsS3Form.prototype.sign = function(policyB64, options) {
      var _date, _h1, _h2, _h3, _key, _signdate;
      _date = options.now || new Date();
      _signdate = options.signdate || this._shortDate(_date, true);
      _h1 = this._hmac("AWS4" + (options.secretAccessKey || this.config.secretAccessKey), _signdate);
      _h2 = this._hmac(_h1, options.region || this.config.region);
      _h3 = this._hmac(_h2, "s3");
      _key = this._hmac(_h3, "aws4_request");
      return this._hmac(_key, policyB64).toString("hex");
    };


    /*
    	## _acl
    
    	`AwsS3Form._acl( [acl] )`
    
    	validate the given acl or get the default
    
    	@param { String } [acl=`config.acl`] the S3 acl
    
    	@return { String } A valid acl
    
    	@api private
     */

    AwsS3Form.prototype._acl = function(acl) {
      if (acl == null) {
        acl = this.config.acl;
      }
      if (indexOf.call(this.validation.acl, acl) < 0) {
        return this._handleError(null, "EINVALIDACL", {
          val: acl
        });
      }
      return acl;
    };


    /*
    	## _redirectUrl
    
    	`AwsS3Form._redirectUrl( tmpl, data )`
    
    	Get the default redirect template or process the given sting as lodash template or call teh given function
    
    	@param { String|Function } tmpl A lodash template or function to generate the redirect url. If `null` general `redirectUrlTemplate` will be used.
    	@param { Object } data The data object for template or function args. Usual example: `{ "filename": "the-filename-from-create-or-policy.jpg" }`
    
    	@return { String } A redirect url
    
    	@api private
     */

    AwsS3Form.prototype._redirectUrl = function(tmpl, data) {
      if (tmpl == null) {
        tmpl = this.config.redirectUrlTemplate;
      }
      if (data == null) {
        data = {};
      }
      if (tmpl == null) {
        return this._handleError(null, "ENOREDIR");
      }
      if (_.isString(tmpl)) {
        return _.template(tmpl)(data);
      } else if (_.isFunction(tmpl)) {
        return tmpl(data);
      } else {
        return this._handleError(null, "EINVALIDREDIR");
      }
    };

    AwsS3Form.prototype._successActionStatus = function(successActionStatus) {
      if (successActionStatus == null) {
        successActionStatus = this.config.successActionStatus;
      }
      if (indexOf.call(this.validation.successActionStatus, successActionStatus) < 0) {
        return this._handleError(null, "EINVALIDSTATUS", {
          val: successActionStatus
        });
      }
      return successActionStatus;
    };


    /*
    	## _successActionStatus
    
    	`AwsS3Form._successActionStatus( status )`
    
    	Gets the HTTP status code that AWS will return if a redirectUrlTemplate is not defined.
    
    	@param { Number } status The status code that should be set on successful upload
    
    	@return { Number } A redirect url
    
    	@api private
     */

    AwsS3Form.prototype._successActionStatus = function(status) {
      if (status == null) {
        status = this.config.successActionStatus;
      }
      if (indexOf.call(this.validation.successActionStatus, status) < 0) {
        return this._handleError(null, "EINVALIDSTATUS", {
          val: status
        });
      }
      return status;
    };


    /*
    	## _calcDate
    
    	`AwsS3Form._calcDate( addSec [, date] )`
    
    	Calculate and validate a date
    
    	@param { Number|Date } addSec A date to convert or a number in seconds to add to the date out of the `date` arg.
    	@param { Date } [date=`new Date()`] A base date for adding if the first argument `addSec` is a number.
    
    	@return { String } A date ISO String
    
    	@api private
     */

    AwsS3Form.prototype._calcDate = function(addSec, date) {
      var _msAdd, _now, _ts;
      if (date == null) {
        date = new Date();
      }
      _msAdd = 0;
      _now = Date.now();
      if (_.isNumber(addSec)) {
        _msAdd = addSec * 1000;
        if (_.isDate(date)) {
          _ts = date.valueOf();
        } else if (_.isNumber(date)) {
          _ts = date;
        } else {
          return this._handleError(null, "ENOTDATE", {
            val: date
          });
        }
      } else if (_.isDate(addSec)) {
        _ts = addSec.valueOf();
      } else {
        return this._handleError(null, "ENOTDATE", {
          val: addSec
        });
      }
      if ((_now - 10000) > _ts) {
        return this._handleError(null, "EOLDDATE", {
          val: _now
        });
      }
      return (new Date(_ts + _msAdd)).toISOString();
    };


    /*
    	## _createCredential
    
    	`AwsS3Form._createCredential( date )`
    
    	Generate a AWS Signature Version 4 conform credential string
    
    	@param { Date } date the credential date
    
    	@return { String } a valid AWS Signature Version 4 credential string
    
    	@api private
     */

    AwsS3Form.prototype._createCredential = function(date) {
      var shortDate;
      shortDate = this._shortDate(date, true);
      return this.config.accessKeyId + "/" + shortDate + "/" + this.config.region + "/s3/aws4_request";
    };


    /*
    	## _shortDate
    
    	`AwsS3Form._shortDate( [date] [, onlyDate] )`
    
    	Create a AWS valid date string
    
    	@param { Date } [date=`new Date()`] The date to process
    	@param { Boolean } [onlyDate=false] Return only the date and cut the time
    
    	@return { String } a AWS valid date string
    
    	@api private
     */

    AwsS3Form.prototype._shortDate = function(date, onlyDate) {
      var _sfull;
      if (date == null) {
        date = new Date();
      }
      if (onlyDate == null) {
        onlyDate = false;
      }
      _sfull = date.toISOString().replace(/\.[0-9]{1,3}Z/g, "Z").replace(/[\.:-]/g, "");
      if (onlyDate) {
        return _sfull.substr(0, 8);
      }
      return _sfull;
    };


    /*
    	## _hmac
    
    	`AwsS3Form._hmac( secret, val )`
    
    	Create a SHA256 hash
    
    	@param { String } secret The secret to hash
    	@param { String } val The value to hash
    
    	@return { String } A SHA256 hash
    
    	@api private
     */

    AwsS3Form.prototype._hmac = function(secret, val) {
      var _hash;
      _hash = crypto.createHmac('SHA256', secret).update(val);
      return new Buffer(_hash.digest("base64"), "base64");
    };


    /*
    	## _obj2b64
    
    	`AwsS3Form._obj2b64( obj )`
    
    	Srtingify a object and return it base64 encoded. Used to convert the policy result to the base64 string required by the `.sign()` method.
    
    	@param { Object } obj A object to stringify
    
    	@return { String } Base64 encoded JSON
    
    	@api private
     */

    AwsS3Form.prototype._obj2b64 = function(obj) {
      return new Buffer(JSON.stringify(obj)).toString('base64');
    };

    AwsS3Form.prototype.ERRORS = function() {
      return {
        "ENOTDATE": [500, "Invalid date `<%= val %>`. Please use a valid date object or number as timestamp"],
        "EOLDDATE": [500, "Date `<%= val %>` to old. Only dates in the future are allowed"],
        "EINVALIDACL": [500, "The given acl `<%= val %>` is not valid. Only `" + (this.validation.acl.join('`, `')) + "` is allowed."],
        "ENOREDIR": [500, "You have to define a `redirectUrlTemplate` as config or `.create()` option."],
        "EINVALIDREDIR": [500, "Only a string or function is valid as redirect url."]
      };
    };

    return AwsS3Form;

  })(require("mpbasic")());

  module.exports = AwsS3Form;

}).call(this);

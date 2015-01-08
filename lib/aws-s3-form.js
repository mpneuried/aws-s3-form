(function() {
  var AwsS3Form, crypto, utils, uuid, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  crypto = require("crypto");

  _ = require('lodash');

  uuid = require('node-uuid');

  utils = require("./utils");

  AwsS3Form = (function(_super) {
    __extends(AwsS3Form, _super);

    function AwsS3Form() {
      this.ERRORS = __bind(this.ERRORS, this);
      this._obj2b64 = __bind(this._obj2b64, this);
      this._hmac = __bind(this._hmac, this);
      this._shortDate = __bind(this._shortDate, this);
      this._createCredential = __bind(this._createCredential, this);
      this._calcDate = __bind(this._calcDate, this);
      this._redirectUrl = __bind(this._redirectUrl, this);
      this._acl = __bind(this._acl, this);
      this.sign = __bind(this.sign, this);
      this.policy = __bind(this.policy, this);
      this.create = __bind(this.create, this);
      this.defaults = __bind(this.defaults, this);
      return AwsS3Form.__super__.constructor.apply(this, arguments);
    }

    AwsS3Form.prototype.validation = {
      acl: ["public-read", "authenticated-read"]
    };

    AwsS3Form.prototype.defaults = function() {
      return this.extend(AwsS3Form.__super__.defaults.apply(this, arguments), {
        accessKeyId: "set-in-config-json",
        secretAccessKey: "set-in-config-json",
        region: "eu-central-1",
        bucket: null,
        redirectUrlTemplate: null,
        policyExpiration: 60 * 60 * 12,
        keyPrefix: "/",
        acl: "public-read",
        useUuid: true
      });
    };


    /*
    	 *# create
    	
    	`basic.create( filename, options )`
    	
    	create a new form object
    	
    	@param { String } prop Property name 
    	@param { Object } [options] Create options
    	@param { String } [options.acl] Option to overwrite the general `acl`
    	@param { String } [options.keyPrefix] Option to overwrite the general `keyPrefix`
    	@param { String } [options.redirectUrlTemplate] Option to overwrite the general `redirectUrlTemplate`
    	@param { Number|Date } [options.policyExpiration] Option to overwrite the general `policyExpiration`
    	
    	@api public
     */

    AwsS3Form.prototype.create = function(filename, options) {
      var data, _data, _policyB64, _signature;
      if (options == null) {
        options = {};
      }
      options.now = new Date();
      if (this.config.useUuid) {
        options.uuid = uuid.v4();
      }
      _data = {
        acl: this._acl(options.acl),
        success_action_redirect: this._redirectUrl(options.redirectUrlTemplate, {
          filename: filename
        }),
        credential: this._createCredential(options.now),
        amzdate: this._shortDate(options.now)
      };
      _policyB64 = this._obj2b64(this.policy(filename, options, _data));
      _signature = this.sign(_policyB64, options);
      data = {
        action: "http://" + this.config.bucket + ".s3.amazonaws.com/",
        filefield: "file",
        fields: {
          key: "" + (options.keyPrefix || this.config.keyPrefix) + filename,
          acl: _data.acl,
          success_action_redirect: _data.success_action_redirect,
          "X-Amz-Credential": _data.credential,
          "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
          "X-Amz-Date": _data.amzdate,
          "Policy": _policyB64,
          "X-Amz-Signature": _signature.toString()
        }
      };
      if (options.uuid != null) {
        data.fields["x-amz-meta-uuid"] = options.uuid;
      }
      return data;
    };

    AwsS3Form.prototype.policy = function(filename, options, _predef) {
      var policy, _date;
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
      if (options.uuid != null) {
        policy.conditions.push({
          "x-amz-meta-uuid": options.uuid
        });
      }
      return policy;
    };

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

    AwsS3Form.prototype._acl = function(acl) {
      if (acl == null) {
        acl = this.config.acl;
      }
      if (__indexOf.call(this.validation.acl, acl) < 0) {
        return this._handleError(null, "EINVALIDACL", {
          val: acl
        });
      }
      return acl;
    };

    AwsS3Form.prototype._redirectUrl = function(tmpl, data) {
      if (tmpl == null) {
        tmpl = this.config.redirectUrlTemplate;
      }
      if (tmpl == null) {
        return this._handleError(null, "ENOREDIR");
      }
      if (_.isString(tmpl)) {
        return _.template(tmpl, data);
      } else if (_.isFunction(tmpl)) {
        return tmpl(data);
      } else {
        return this._handleError(null, "EINVALIDREDIR");
      }
    };

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
          val: date
        });
      }
      return (new Date(_ts + _msAdd)).toISOString();
    };

    AwsS3Form.prototype._createCredential = function(date) {
      var shortDate;
      shortDate = this._shortDate(date, true);
      return "" + this.config.accessKeyId + "/" + shortDate + "/" + this.config.region + "/s3/aws4_request";
    };

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

    AwsS3Form.prototype._hmac = function(secret, val) {
      var _hash;
      _hash = crypto.createHmac('SHA256', secret).update(val);
      return new Buffer(_hash.digest("base64"), "base64");
    };

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

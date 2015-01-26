(function() {
  var AwsS3Form, CONFIG, FormGen, app, express, server, utils, _, _config;

  _config = require("../config_test.json");

  _ = require("lodash");

  CONFIG = _.defaults(_config.example || {}, {
    port: 3010
  });

  express = require('express');

  app = express();

  app.set('view engine', 'jade');

  app.set('views', '../_testviews');

  AwsS3Form = require("../.");

  utils = require("../lib/utils");

  _config.s3.keyPrefix = "test_browser_";

  _config.s3.redirectUrlTemplate = function(data) {
    var _str;
    _str = "http://" + (server.address().host || "localhost") + ":" + (server.address().port || 80) + "/redir/";
    if (data.filename === "${filename}") {
      _str += "*";
    } else {
      _str += _config.s3.keyPrefix + data.filename;
    }
    return _str;
  };

  FormGen = new AwsS3Form(_config.s3);

  app.get('/', function(req, res) {
    var _key;
    _key = req.query.key;
    if (_key == null) {
      _key = utils.randomString(10);
    }
    res.render("index", {
      q: req.query,
      example: FormGen.create(_key, _.pick(req.query, ["acl"]))
    });
  });

  app.get('/redir/:key', function(req, res) {
    var _data, _url;
    _url = "https://s3." + _config.s3.region + ".amazonaws.com/" + _config.s3.bucket + "/" + req.query.key;
    _data = {
      q: req.query,
      src: _url
    };
    res.render("img", _data);
  });

  server = app.listen(CONFIG.port, function() {
    console.log('Now call http://%s:%s/ in your browser', this.address().host || "localhost", this.address().port);
  });

}).call(this);

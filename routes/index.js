var connection, express, nodemailer, pool, router;

express = require('express');

router = express.Router();

nodemailer = require('nodemailer');

connection = require('../db/db').connection;

pool = require('../db/db').pool;

router.get('/', function(req, res, next) {
  return res.render('main.jade', {
    title: 'Express'
  });
});

router.get('/main/service', function(req, res) {
  return res.render('main_service.jade');
});

router.get('/feedback/success', function(req, res) {
  return res.render('feedback_success.jade');
});

router.get('/feedback/failure', function(req, res) {
  return res.render('feedback_failure.jade');
});

router.get('/signup', function(req, res) {
  return res.render('signup.jade');
});

router.get('/logout', function(req, res) {
  req.session = {};
  return res.redirect('/');
});

router.get('/playlist', function(req, res) {
  return pool.getConnection(function(err, conn) {
    if (err) {
      console.log(err);
    }
    return conn.query("SELECT * FROM Playlists WHERE user_id = ?", [req.session.user.user_id], function(error, results) {
      conn.release();
      if (error) {
        return console.log(error);
      }
      return res.status(200).json(results);
    });
  });
});

router.get('/playlist/:id/videos', function(req, res) {
  return pool.getConnection(function(err, conn) {
    if (err) {
      console.log(err);
    }
    return conn.query("SELECT * FROM Videos WHERE playlist_id = ? AND user_id = ?", [+req.params.id, req.session.user.user_id], function(err, results) {
      conn.release();
      if (err) {
        return console.log(err);
      }
      console.log(results);
      return res.status(200).json(results);
    });
  });
});

router.post('/feedback', function(req, res) {
  var mailOptions, transporter;
  transporter = nodemailer.createTransport({
    service: 'iCloud',
    auth: {
      user: "jourdy345@me.com",
      pass: "iamDY123!"
    }
  });
  mailOptions = {
    from: "jourdy345@me.com",
    to: "jourdy345@gmail.com",
    subject: "Feedback from Youtube Playlist",
    text: req.body.content
  };
  return transporter.sendMail(mailOptions, function(error, info) {
    if (error) {
      console.log(error);
      return res.redirect('/feedback/failure');
    }
    console.log("Message sent: " + info.response);
    return res.redirect('/feedback/success');
  });
});

router.post('/signin', function(req, res) {
  return pool.getConnection(function(err, conn) {
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    return conn.query("SELECT * FROM Users WHERE user_id = ? AND user_password = ?", [req.body.UserAccount, req.body.UserPassword], function(error, results, fields) {
      conn.release();
      if (results) {
        delete results[0].user_password;
        req.session.user = results[0];
        console.log(results);
        return res.redirect('/main/service');
      } else {
        req.session.error = 'Whoops! No match found!';
        return res.redirect('/main/service');
      }
    });
  });
});

router.post('/signup', function(req, res) {
  var post;
  post = {
    user_id: req.body.UserAccount,
    user_password: req.body.UserPassword
  };
  return pool.getConnection(function(err, conn) {
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    return true;
    console.log('connected as id');
    return conn.query("SELECT * FROM Users WHERE user_id = ?", req.body.UserAccount, function(err, results) {
      if (err) {
        console.log(err);
      }
      console.log(results);
      if (!results) {
        return conn.query("INSERT INTO Users SET ?", post, function(error, results, fields) {
          console.log(error, results, fields);
          conn.release();
          return res.redirect('/');
        });
      } else {
        conn.release();
        req.session.error = 'Account name already exists! Please pick another one.';
        return res.redirect('/signup');
      }
    });
  });
});

router.post('/playlist/add/blank', function(req, res) {
  return pool.getConnection(function(err, conn) {
    var playlist;
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    playlist = {
      user_id: req.session.user.user_id,
      playlist_name: req.body.blank_playlist_name
    };
    return conn.query("INSERT INTO Playlists SET ?", playlist, function(err, results) {
      if (err) {
        console.log(err);
      }
      console.log(results);
      return conn.query("SELECT * FROM Playlists WHERE user_id = ?", [req.session.user.user_id], function(error, results) {
        conn.release();
        if (error) {
          console.log(error);
        }
        console.log(results);
        if (req.accepts('application/json') && !req.accepts('html')) {
          return res.status(200).json(results);
        } else {
          return res.redirect('/main/service');
        }
      });
    });
  });
});

router.post('/playlist/add/blank', function(req, res) {
  return pool.getConnection(function(err, conn) {
    var playlist;
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    playlist = {
      user_id: req.session.user.user_id,
      playlist_name: req.body.blank_playlist_name
    };
    return conn.query("INSERT INTO Playlists SET ?", playlist, function(err, results) {
      if (err) {
        console.log(err);
      }
      console.log(results);
      return conn.query("SELECT * FROM Playlists WHERE user_id = ?", [req.session.user.user_id], function(error, results) {
        conn.release();
        if (error) {
          console.log(error);
        }
        console.log(results);
        if (req.accepts('application/json') && !req.accepts('html')) {
          return res.status(200).json(results);
        } else {
          return res.redirect('/main/service');
        }
      });
    });
  });
});

module.exports = router;

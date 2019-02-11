const express = require('express')
const app = express()
const AWS = require('aws-sdk');
const port = 80




app.get('/', function(req, res) {
    var sts = new AWS.STS();
    var params = {
        DurationSeconds: 3600, 
        RoleArn: "arn:aws:iam::170621239995:role/s3admin", 
        RoleSessionName: "song-session"
    };
    sts.assumeRole(params, function (err, data) {
    if (err) console.log(err, err.stack); // an error occurred
    else{
        console.log(data);
        AWS.config.credentials = sts.credentialsFrom(data);
        console.log(AWS.config.credentials);
        var songBucket = new AWS.S3({
           apiVersion: '2006-03-01',
           params: {Bucket: "do-not-kick"}
        });
        songBucket.listObjectsV2({}, function(err, data) {
            if (err) console.log(err); 
            else{
                let album = [];
                var test =  data.Contents.map(obj => {
                   return obj.Key.split('/')
                });
                let artists = new Set(test.map(path => (path[0])));
                artists.forEach(artist => {
                    album.push({ artist })
                  });
                res.send(album);
            }
        });    
    };// successful response
    });
});
app.listen(port, () => console.log(`Example app listening on port ${port}!`))
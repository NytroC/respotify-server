const express = require('express')
const app = express()
const AWS = require('aws-sdk');
const port = 3000




app.get('/', function(req, res) {
    
        var songBucket = new AWS.S3({
           apiVersion: '2006-03-01',
           params: {Bucket: "do-not-kick"}
        });
        console.log("here");
        songBucket.listObjectsV2({}, function(err, data) {
            if (err) console.log(err); 
            else{
                let album = [];
                console.log("in");
                var artists =  data.Contents.map(obj => {
                   var object = obj.Key.split('/')
                   var artist = object[1]
                   var album = object[2]
                   var song = object[3]
                   return {
                       "artist" : artist,
                       "album" : album,
                       "song" : song
                   }

                });
                res.send(artists);
            }
        });    
});
app.listen(port, () => console.log(`Example app listening on port ${port}!`))
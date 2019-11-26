var http = require('http');
var f5 = require('f5-nodejs');
var express = require('express');
var app = express();
var SMB2 = require('smb2c');
var multer = require('multer');
var storage = multer.memoryStorage();
var upload = multer({ storage: storage });
var url_ops = require('url');
var qs = require('querystring');
var session = require('express-session');

var session = require('express-session')({
    secret: 'ilx-secret-phrase',
    name: 'ilx_webcifs',
    resave: true,
    saveUninitialized: true
  })

var myutil = require('./util')
// var util = require('util');
//var bodyParser = require('body-parser');

var plugin = new f5.ILXPlugin();
plugin.startHttpServer(app);


app.use(session)
// app.use(myutil.basicAuth)

//console.log("Server Started.");

var sess;

app.get('/test', function(req, res) {
    console.log("1-got it: \n",req.url);
});

app.get('/favicon.ico', function(req, res) {
});


app.get('*', function(req, res) {
    //console.log("1-got it: \n" + req.session.domain + "\n");

    var url_parts = url_ops.parse(req.url, true, true);
        // hostname is used for composition of the links for page object.
        // relative link in the <href> tag did not work.  I had to create absolute links including 
        // the hostname.

    url=url_parts.pathname;

    if ( req.session.domain) {
        shareDomain=req.session.domain;
        shareName=req.session.sharename;
        shareHost=req.session.winhost;
        shareUser=req.session.user;
        sharePass=req.session.pass;
        console.log ('session vars:-', req.session.domain,'-',req.session.sharename, '-',req.session.winhost);
    } else {
        shareDomain=url_parts.query.domain;
        shareName=url_parts.query.sharename;
        shareHost=url_parts.query.winhost;
        shareUser=url_parts.query.user;
        sharePass=url_parts.query.pass;
        
        req.session.domain = shareDomain;
        req.session.sharename = shareName;
        req.session.winhost = shareHost;
        req.session.user = shareUser;
        req.session.pass = sharePass;
        console.log ('Query vars:', req.session.domain,'-',req.session.sharename, '-',req.session.winhost,'-', req.session.user, '-', req.session.pass);
    }


    var smb2Client = new SMB2({
         share:'\\\\' + shareHost + '\\' + shareName,
         domain: shareDomain,
         username: shareUser,
         password: sharePass,
         autoCloseTimeout: 100000,
         debug: 0
    });


    flip_path = url.replace(/\//g, "\\\\");
    console.log('flip_path', flip_path);


	if (!/(?=\w+\.\w{3,4}$).+/.test(url)) {
		//THIS IS NOT A FILE OUTPUT READDIR

	    	var http_resp = "<html><body><h2>Webified CIFS</h2><br>";
	        http_resp += "<table border=1><tr><td>File Upload<br><br>";

	        http_resp += "<form method='post' action="+url+" enctype='multipart/form-data'><input type='file' name='originalname' accept='*'><input type='submit'></form>";
        	//http_resp += "<table border=1><tr><td>Create Directory<br><br>";
        	//http_resp += "<form method='put' name='dir' ><input type='text' name='Directory_name' accept='*'><input type='submit'></form>";

        	//http_resp += "</td></tr><tr><td>Directory Listing<br><br>";
        	http_resp += "</table><table border=0></td></tr><tr class='border_bottom'><td colspan=3>Directory Listing</td></tr>";
            http_resp += "<tr class='border_bottom'><td>Name</td><td>Size (B)</td><td>Creation Date</td></tr>";
        	http_resp += "<style>ul.a {list-style-type: square;}</style>;"
        	http_resp += "<ul class='a'>";
    
        	/* hostname of HTTP server (VIP) must be passed from TCL.  It is used for composition of the links for clickable page objects.
        	Relative links in the <href> tag did not work.  I had to create absolute links including the HTTP hostname. */

        	try {
        	    flip_path = decodeURI(flip_path.slice(2));
        	    smb2Client.readdir(flip_path, function(err, files) {
                    //http_resp += '<tr><td><a href="/">..</a></td><td></td></tr>';
                    
        	        if (err) {
        	            console.log("1->",shareHost,err);
        	            res.end('<html>'+flip_path+'<p>'+err+'</html>', "ascii");
        	        } else {
        	            var url1 = (url == '/') ? (''):(url);
	                    for (var i = 0, len = files.length; i < len; i++) {
	                        // FileAttributes 2= hidden.  1=system, 10=Directory ; https://msdn.microsoft.com/en-us/library/cc246322.aspx
	                        
	                        if (files[i].fileName !== null && files[i].fileName.fileAttributes !== 2000 ) {
	                              //console.log(files[i].fileAttributes.toString(2), files[i].fileName, files[i].fileAttributes, files[i].fileAttributes.toString(16)) ;
	                              http_resp += '<tr><td><li><a href="//'+req.hostname+ url1+'/'+ files[i].fileName + '">' + files[i].fileName + '</a></li></td>';
	                              http_resp += '<td>' + files[i].fileAttributes + '</td></tr>';
	                        } else {
	                                //console.log('Attr ',files[i].FileAttributes.toString(16));
	                        }
	                    }
	                    http_resp += '</ul>';
                        http_resp += '</table></body></html>';
                        res.statusCode = 200;
                        res.setHeader('Content-Type', 'text/html');
	                    res.end(http_resp, "ascii");
	                }
	            });
	        } catch(e){
	              console.log(e);
	              res.end(e, "ascii");
	        }
        	smb2Client.close();
	} else {
        	
    		//THIS IS A FILE, DOWNLOAD IT !
        	var a = flip_path.split('\\');
        	last = a.length - 1;
        	file_name = a[last];

        	smb2Client.readFile(decodeURI(flip_path.substr(2)), {'encoding': 'base64'}, function(err, data){
        	    if(err) {
            	    console.log("2->",err);
                	res.end(['text/html','<html>'+name+'<p>'+err+'</html>'],'ascii');
        	    } else {
            		try {
                        res.header('Content-disposition', 'attachment; filename=' + file_name);
                        res.header("Content-Type", "application/octet-stream");
                        var buf = new Buffer(data, 'base64');
                        res.end(buf,'ascii');
            		} catch(e){
   	        		    console.log(e);
            			res.end(['text/html','<html>'+name+'<p>'+err+'</html>'], 'ascii');
                		smb2Client.close();
            		}
        	    }
        	smb2Client.close();
      		});
	}

});

//console.log('**flip_path', flip_path);

app.post('*', upload.single('originalname') , function(req,res) {

    var url=req.url;
//console.log(req);
    if ( req.session.domain) {
        shareDomain=req.session.domain;
        shareName=req.session.sharename;
        shareHost=req.session.winhost;
        shareUser=req.session.user;
        sharePass=req.session.pass;
        console.log ('session vars:-', req.session.domain,'-',req.session.sharename, '-',req.session.winhost);
    } else {
        res.header("Content-Type", "text/html");
        res.end("<html>Please connect to a Directory first and specify connect information via query parameters.<p>Usage:<p>http://<hostname>//?user=user&pass=user&domain=WIN7&sharename=myuser&winhost=10.1.2.5</html>")
        return;
    }

	//POST FILE

    flip_path = url.replace(/\//g, "\\\\").slice(2);
	var smb2Client = new SMB2({
         share:'\\\\' + shareHost + '\\' + shareName ,
         domain: shareDomain,
         username: shareUser,
         password: sharePass,
     autoCloseTimeout: 100000,
     //debug: true
    });


    var file_path = (url == '/') ? (''):(flip_path+'\\\\');
    console.log('**Saving file to ', flip_path+'\\\\'+req.file.originalname);

    smb2Client.writeFile( flip_path+'\\\\'+req.file.originalname , req.file.buffer, {'encoding': null}, function (err) {
            if(err) {
                console.log("-->",err);
                res.end('<html>Error Uploading:'+flip_path+req.file.originalname+'<p>'+err+'</html>', 'ascii');
            } else {
                console.log("Success.");
                res.header("Location", req.url);
                res.statusCode = 302;
                res.end('<html>'+req.file.originalname+'<p>Success.</html>', 'ascii');
            }
            smb2Client.close();
    });
});


       /* if (req.file != null && req.uploadstatus != null) {
        	var httpfilename = decodeURIComponent(req.file);
        	var httpuploadstatus = decodeURIComponent(req.uploadstatus);
        	http_resp += "<div style='background-color:green;'><b>Upload Status: </b>" + httpuploadstatus + "<br>";
        	http_resp += "<b>Filename: </b>" + httpfilename + "<br></div><br>";
        } */


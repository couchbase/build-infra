# httpd-cgi

Docker image with apache in order to run minimal scripts via cgi.

## mount folder with cgi-scripts
```
docker run -d -p 9090:80
  -v $(pwd)/scripts:/usr/local/apache2/cgi-bin
  hypoport/httpd-cgi
```

## pass environment variables into cgi context
```
docker run -d -p 9090:80
  -e "CGI_ENV_VARNAME=varcontent"
  hypoport/httpd-cgi
```
will result in an environment variable named:'VARNAME' with the content:'varcontent'

# Attribution

Code originally from https://github.com/hypoport/httpd-cgi

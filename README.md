Quick Eample Code
=================

This is a *minimalistic* piece of code showing the creation of an HTTPS server
using `cohttp.lwt` and `lwt.ssl`.

Build & Run
-----------

Compile like this:

    ocamlfind ocamlc -package lwt.ssl,cohttp.lwt -linkpkg cohttps.ml -o dummyserver

Create an OpenSSL self-signed certificate:

    openssl genrsa -des3 -out privkey.pem 1024
    openssl req -new -x509 -days 1001 -key privkey.pem -out cert.pem
    openssl rsa -in privkey.pem -out privkey-unsec.pem

Test:

     ./dummyserver

and got to <https://localhost:8081> or <http://localhost:8082>.


Other Notes
-----------

### Using `TLSv1` instead of `SSLv23`

With Wget 1.10.2, I need `--secure-protocol=TLSv1`:

    wget --no-check-certificate --secure-protocol=TLSv1 https://<host>:8081

with Wget 1.14, not:

    wget --no-check-certificate https://<host>:8081

Firfox works without problem.

OCsigenserver uses `SSLv23` (c.f.
[`ocsigen_http_client.ml`:88](https://github.com/ocsigen/ocsigenserver/blob/master/src/server/ocsigen_http_client.ml#L88)).



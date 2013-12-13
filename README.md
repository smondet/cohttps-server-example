Quick Eample Code
=================

This is a *minimalistic* piece of code showing the creation of an HTTPS server
using `cohttp.lwt` and `lwt.ssl`.

There is not really any error management or parametrization to keep the code
short.

It is ISC licensed, copy at will.

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

Both HTTP and HTTPS servers are created; got to <https://localhost:8081> or
<http://localhost:8082>, it should display some HTML.


Other Notes
-----------

### Using `TLSv1` instead of `SSLv23`

With `Ssl.TLSv1` and *Wget 1.10.2*, I need `--secure-protocol=TLSv1`:

    wget --no-check-certificate --secure-protocol=TLSv1 https://<host>:8081

with Wget 1.14, I don't:

    wget --no-check-certificate https://<host>:8081

Firfox works without problem.

Ocsigenserver uses `SSLv23` (c.f.
[`ocsigen_http_client.ml:88`](https://github.com/ocsigen/ocsigenserver/blob/master/src/server/ocsigen_http_client.ml#L88)).



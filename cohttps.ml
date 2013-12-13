
open Lwt
open Printf
let (|>) x f = f x

let dbg fmt =
  ksprintf (fun s -> eprintf "DBG: %s\n%!" s) fmt

module Server_core = Cohttp_lwt.Make_server
    (Cohttp_lwt_unix_io)(Cohttp_lwt_unix.Request)(Cohttp_lwt_unix.Response)(Cohttp_lwt_unix_net)

module Server = struct

  include Server_core

  (* Normal TCP server: copied from cohttp/lwt/cohttp_lwt_unix.ml *)
  let create ?timeout ~address ~port spec =
    Cohttp_lwt_unix_net.build_sockaddr address (string_of_int port)
    >>= fun sockaddr ->
    Cohttp_lwt_unix_net.Tcp_server.init ~sockaddr ~timeout (callback spec)

  (* SSL initialisation *)
  let init_tls = Ssl.init ~thread_safe:true

  (* Creation of the HTTPS server *)
  let tls ~port ~cert_key spec =
    let (cert_file, key_file) = cert_key in
    let tls_context =
      Ssl.(
        let c = create_context SSLv23 Server_context in
        use_certificate c cert_file key_file;
        (* set_cipher_list c "TLSv1"; *)
        c
      ) in
    let socket =
      let open Lwt_unix in
      let sockaddr = (ADDR_INET (Unix.inet_addr_any, port)) in
      let fd = socket PF_INET SOCK_STREAM 6 in
      setsockopt fd Unix.SO_REUSEADDR true;
      bind fd sockaddr;
      listen fd 15;
      fd
    in
    let handle_one accepted =
      Lwt.catch (fun () ->
          Lwt_ssl.ssl_accept (fst accepted) tls_context
          >>= fun socket_fd ->
          (* dbg "got ssl socket"; *)
          let inchan  = Lwt_ssl.in_channel_of_descr  socket_fd in
          let outchan = Lwt_ssl.out_channel_of_descr socket_fd in
          (callback spec) inchan outchan)
        (fun  e -> 
           dbg "handle_one exn: %s" (Printexc.to_string e);
           return ())
    in
    let display_exn =
      function
      | Some e -> dbg "Accept exn: %s" (Printexc.to_string e)
      | None -> () in
    let rec accept_loop () =
      Lwt_unix.accept_n socket 10
      >>= fun (accepted_list, exn_option) ->
      display_exn exn_option;
      (* dbg "unix-accepted"; *)
      accept_loop () |> Lwt.ignore_result;
      Lwt_list.map_p handle_one accepted_list
    in
    accept_loop ()
    >>= fun (_ : unit list) ->
    return ()


end

let make_server () = 
  Server.init_tls ();
  let callback conn_id ?body req =
    let open Cohttp in
    dbg "Path: %s, uri: %s" (Uri.path (Request.uri req))
      (Request.uri req |> Uri.to_string |> Uri.pct_decode);
    match Uri.path (Request.uri req) with
    | path -> fail Not_found
  in
  let conn_closed conn_id () =
    dbg "conn %S closed" (Cohttp.Connection.to_string conn_id)
  in
  let config = { Server.callback = callback; conn_closed } in
  Server.tls ~cert_key:("cert.pem", "privkey-unsec.pem") ~port:8081 config
  >>= fun () ->
  Server.create ~address:"0.0.0.0" ~port:8082 config
  >>= fun _ ->
  return ()
  (* Lwt_io.(read_char stdin) >>= fun _ -> return () *)


let () = Lwt_main.run (make_server ())


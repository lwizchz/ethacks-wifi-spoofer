#!/usr/bin/env python3

from io import BytesIO
from http.server import HTTPServer, SimpleHTTPRequestHandler

class PortalServer(SimpleHTTPRequestHandler):
	def do_POST(self):
		content_length = int(self.headers["Content-Length"])
		body = self.rfile.read(content_length)
		self.send_response(200)
		self.end_headers()
		
		print(body.decode())
		
		response = BytesIO()
		response.write(b"thanks")
		self.wfile.write(response.getvalue())

httpd = HTTPServer(("0.0.0.0", 80), PortalServer)
httpd.serve_forever()


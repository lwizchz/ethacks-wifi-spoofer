#!/usr/bin/env python3

import sys
from io import BytesIO
from http.server import HTTPServer, SimpleHTTPRequestHandler

class PortalServer(SimpleHTTPRequestHandler):
	def do_GET(self):
		if self.path in ("/", "/index.html", "/1x-trex.png"):
			return super().do_GET()

		self.send_response(302)
		self.send_header("Location", "http://10.0.0.1/")
		self.end_headers()

	def do_POST(self):
		content_length = int(self.headers["Content-Length"])
		body = self.rfile.read(content_length)
		self.send_response(200)
		self.end_headers()
		
		print(body.decode())
		
		response = BytesIO()
		response.write(b"thanks")
		self.wfile.write(response.getvalue())

		sys.exit()

httpd = HTTPServer(("0.0.0.0", 80), PortalServer)
print("PortalServer starting...")
httpd.serve_forever()


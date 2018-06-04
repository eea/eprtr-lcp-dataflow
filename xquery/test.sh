#!/bin/sh
basex/bin/basex -bsource_url=inputs/C13.1.xml eprtr-lcp-main.xq > out.html && google-chrome-stable out.html
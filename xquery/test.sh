#!/bin/sh
basex/bin/basex -bsource_url=inputs/C12.6a.xml eprtr-lcp-main.xq > out.html && google-chrome-stable out.html
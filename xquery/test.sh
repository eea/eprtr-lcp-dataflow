#!/bin/sh
basex/bin/basex -bsource_url=dummy_test.xml eprtr-lcp-main.xq > out.html && google-chrome-stable out.html
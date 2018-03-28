#!/bin/sh
basex/bin/basex -bsource_url=inputs/break_test_C1.3.xml eprtr-lcp-main.xq > out.html && google-chrome-stable out.html
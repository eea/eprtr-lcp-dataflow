#!/bin/sh
export XQueryUser=[add_here_username]
export XQueryPassword=[add_here_password]
basex/bin/basex -bsource_url=EPRTR_LCP_TEST_FILE.xml eprtr-lcp-main.xq > out.html && google-chrome-stable out.html
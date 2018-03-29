#!/bin/sh
basex/bin/basex -bsource_url=inputs/LCPandEPRTR_CleanTest.xml eprtr-lcp-main.xq > out.html && google-chrome-stable out.html
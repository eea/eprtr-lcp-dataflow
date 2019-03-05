#!/bin/sh
basex/bin/basex -bsource_url=inputs/LCPEPRTR_2017_20190108_093154_Test.xml eprtr-lcp-main.xq > out.html && google-chrome-stable out.html
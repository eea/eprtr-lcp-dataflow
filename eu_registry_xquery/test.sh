#!/bin/sh
~/work/sources/dataflows/dev/basex/bin/basex -bsource_url=EU_Registry_converted_Test.gml iedreg-qa3-main.xq > out.html && google-chrome-stable out.html
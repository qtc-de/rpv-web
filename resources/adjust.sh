#!/bin/bash

LATEST=$(sed -n 's/^## v\([^ ]\+\).*/\1/p' ../CHANGELOG.md)

PREPARED=$(sed "s/<FILEVERSION>/${LATEST//./, }/" rpv-web-template.rc)
PREPARED=$(echo "${PREPARED}" | sed "s/<VERSION>/${LATEST}/")

echo "${PREPARED}" > rpv-web.rc

#!/usr/bin/env bash
# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright (c) 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Kill script for use as the parameter of OpenJDK's -XX:OnOutOfMemoryError

DETAILS="$(ps -ef | grep killjava)"
DATE="$(date)"

# Generate a sensu alert

echo '{
    "handlers": ["pagerduty"],
    "notification": "'"$NEW_RELIC_APP_NAME"' instance crashed - investigate via app logs in kibana",
    "name": "'"$NEW_RELIC_APP_NAME"' instance_crashed",
    "status": 2,
    "subscribers": ["base"], 
    "runbook": "'"$NEW_RELIC_APP_NAME"' instance crashed - investigate via app logs in kibana",
    "output": "'"$NEW_RELIC_APP_NAME"' instance crashed - investigate via app logs in kibana",
    "service_level": "prod",
    "page_worthy": "true"
}' | nc -w 1 sensu-dfw.wbx2.com 3030 || true

# Emit a metric

echo "alert.oomkiller.$NEW_RELIC_APP_NAME:1|c" | nc -w 3 -u stats-util-dfw.wbx2.com 8125

set -e

pkill -3 -f .*-XX:OnOutOfMemoryError=.*killjava.*

echo "
Process Status (Before)
=======================
$(ps -ef)

ulimit (Before)
===============
$(ulimit -a)

Free Disk Space (Before)
========================
$(df -h)
"

pkill -9 -f .*-XX:OnOutOfMemoryError=.*killjava.*

echo "
Process Status (After)
======================
$(ps -ef)

ulimit (After)
==============
$(ulimit -a)

Free Disk Space (After)
=======================
$(df -h)
"

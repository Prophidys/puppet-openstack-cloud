#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Basic Architecture
#

import 'params.pp'

# Import roles
import 'roles/automation/*.pp'
import 'roles/cache/*.pp'
import 'roles/common/*.pp' # mandatory
import 'roles/compute/*.pp'
import 'roles/dashboard/*.pp'
import 'roles/database/*.pp'
import 'roles/identity/*.pp'
import 'roles/image/*.pp'
import 'roles/load-balancer/*.pp'
import 'roles/messaging/*.pp'
import 'roles/monitoring/*.pp'
import 'roles/network/*.pp'
import 'roles/object-storage/*.pp'
import 'roles/orchestration/*.pp'
import 'roles/spof/*.pp'
import 'roles/telemetry/*.pp'
import 'roles/volume/*.pp'

node common {

# Params
  class { 'os_params': }

# Common system configuration
  class { 'os_common_system': }

}


# Puppet Master node
node '1-deployment-node' inherits common{

# Everything related to puppet is bootstraped by jenkins
# and other stuffs are made by common class.

}

# Controller node
node '3-controller-nodes' inherits common {

## SPOF services:
    class {'spof_node':}

## Databases:
    class {'os_nosql_node':}
    class {'os_sql_node':}

## Telemetry
    class {'os_telemetry_common':}
    class {'os_telemetry_server':}

## Identity
    class {'os_identity_controller':
      local_ip => $ipaddress_eth0,
    }

# Object Storage
    class {'os_swift_proxy': }
    class {'os_swift_ringbuilder':
      rsyncd_ipaddress => $ipaddress_eth0,
    }
    Class['os_swift_ringbuilder'] -> Class['os_swift_proxy']

# Messaging
    class {'os_messaging_server': }

# Cache
    class {'os_cache_server': }

# Networking
    class {'os_network_common': }
    class {'os_network_controller': }

# Orchestration
    class {'os_orchestration_common': }
    class {'os_orchestration_api': }

}

# == Network nodes
node '2-network-nodes' inherits common {

    class {'os_network_common': }
    class {'os_network_dhcp': }
    class {'os_network_lbaas': }
    class {'os_network_l3': }
    class {'os_network_vpn':}

}

# Storage nodes
node '3-object-storage-nodes' inherits common{

## Telemetry
    class {'os_telemetry_common':}

## Object Storage
    class { 'os_swift_storage':
        local_ip    => $ipaddress_eth0,
        swift_zone  =>  $os_params::os_swift_zone[$::hostname],
    }

}

# Compute nodes
node 'compute-node' inherits common {

  class { 'os_network_common': }
  class { 'os_network_compute': }

  class { 'os_compute_hypervisor':
    local_ip => $ipaddress_eth0,
  }

}
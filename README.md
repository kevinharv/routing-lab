# Routing Lab

## Overview

This is a [containerlab](https://containerlab.dev/) lab environment for learning basic routing concepts. It is primarily centered around BGP and topologies supporting hybrid cloud connectivity.

## Design

**Peering Subnet:** 10.10.10.0/24 (/31 links)

**Networks**
| Prefix | Origin Location | Notes |
| ------ | --------------- | ----- |
| 10.60.0.0/16 | DC 1 | On-premises data center |
| 10.50.0.0/16 | DC 2 | On-premises data center |
| 10.100.0.0/16 | AWS US East 1 | Propagated via DXGW |
| 10.120.0.0/16 | AWS US West 2 | Propagated via DXGW |

**Autonomous Systems**
| ASN | Location | Notes |
| ------ | --------------- | ----- |
| 65052 | DC 1 | On-premises data center |
| 65051 | DC 2 | On-premises data center |
| 65100 | AWS Direct Connect Gateway (DXGW) | Global routing abstraction - BGP peer for DX connections |
| 65101 | AWS US East 1 | TGW or Cloud WAN CNE |
| 65102 | AWS US West 2 | TGW or Cloud WAN CNE |


## Roadmap and Objectives

1. Establish mutli-region hybrid-cloud architecture with multiple DX links
    - Add regions without DX connections
    - Peer all AWS regions
    - Peer on-premises data centers
1. Segment production and non-production traffic (VRFs)
1. Traffic steering with BGP attributes
    - Local preference
    - AS path prepending
    - MED
    - BGP communities

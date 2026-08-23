# Enterprise Edge

A small Containerlab topology for testing an enterprise edge with AWS Direct
Connect, a B2B connection, VRFs, eBGP, and an edge firewall.

## Topology

```text
dev-dxgw (AS 65100) ---- h1edgesw1a (AWS-DEV VRF) ---- h1edgengfw (NGFW-DEV)
b2b-er   (AS 65200) ---- h1edgesw1a (B2B-DEV VRF) ---- h1edgengfw (NGFW-DEV)
```

All nodes use the `frrouting/frr:latest` image. The firewall performs NETMAP
for the B2B network (`10.200.0.0/24` to `192.168.200.0/24`).

## Requirements

- Docker
- [Containerlab](https://containerlab.dev/)

## Run

From this directory:

```bash
containerlab deploy --topo enterprise_edge.clab.yml
containerlab inspect --topo enterprise_edge.clab.yml
containerlab destroy --topo enterprise_edge.clab.yml
```

Enter a node with:

```bash
docker exec -it clab-enterprise-edge-h1edgesw1a vtysh
```

Configuration files are under `configs/`. Generated Containerlab state and
inventories are stored under `clab-enterprise-edge/`.

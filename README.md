# Routing Lab

*Learning the basics of routing.*

## Design

### Objectives
- segmentation of DEV/QA/PROD
- BGP everywhere, spine and leaf
- north/south traffic inspection for everything
- traffic inspection crossing environment boundaries
- border/edge connectivity separated
- native integration with Kubernetes - BGP via Cilium
- prepare for cloud connectivity and multiple data center

### Specifications
- BGP ASN range 64600-64650 for spines, 64700-64800 for leaves
- BGP ASN range 64800-64850 for external connections
- addressed out of 10.0.0.0/8 with consideration given to IP address management

### Detailed Design

#### Network Topology
- The lab will use a two-tier leaf-spine fabric with two spines and three leaves.
- Each leaf will connect to both spines for redundancy and ECMP-style forwarding.
- Each client host will connect to one leaf to simulate end-host attachment.
- The fabric will be the primary underlay for routing and will later support overlay or service chaining use cases.

#### IPAM Layout
- Use the private RFC1918 space from 10.0.0.0/8 as the overall pool.
- Allocate the underlay infrastructure as follows:
  - Spine-to-leaf point-to-point links: 10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24, 10.0.4.0/24, and 10.0.5.0/24
  - Loopback addressing for spines: 10.10.0.1/32 and 10.10.0.2/32
  - Loopback addressing for leaves: 10.10.1.1/32, 10.10.1.2/32, and 10.10.1.3/32
  - Client-facing subnets: 10.20.1.0/24, 10.20.2.0/24, and 10.20.3.0/24
  - Optional transit or external-facing segments: 10.30.0.0/24 and 10.30.1.0/24
- The /24 sizing is intentional for a lab environment because each point-to-point link only needs two endpoints and a small amount of room for future expansion, troubleshooting, and simple host addressing. A /30 would also work for a strict two-host link, but /24 keeps the design easier to read, easier to troubleshoot, and more forgiving when extra services or temporary addressing are added later.
- Use a consistent host-addressing convention where the first usable address is assigned to the spine or leaf interface and the client gets the second usable address on the same subnet.
- The implemented underlay addresses are:

  | Link | Subnet | Spine/Leaf IPs | Client IP |
  | --- | --- | --- | --- |
  | Spine1 <-> Leaf1 | 10.0.0.0/24 | 10.0.0.1 / 10.0.0.2 | n/a |
  | Spine2 <-> Leaf1 | 10.0.3.0/24 | 10.0.3.1 / 10.0.3.2 | n/a |
  | Spine1 <-> Leaf2 | 10.0.1.0/24 | 10.0.1.1 / 10.0.1.2 | n/a |
  | Spine2 <-> Leaf2 | 10.0.4.0/24 | 10.0.4.1 / 10.0.4.2 | n/a |
  | Spine1 <-> Leaf3 | 10.0.2.0/24 | 10.0.2.1 / 10.0.2.2 | n/a |
  | Spine2 <-> Leaf3 | 10.0.5.0/24 | 10.0.5.1 / 10.0.5.2 | n/a |
  | Leaf1 <-> Client1 | 10.20.1.0/24 | 10.20.1.1 / 10.20.1.2 | 10.20.1.2 |
  | Leaf2 <-> Client2 | 10.20.2.0/24 | 10.20.2.1 / 10.20.2.2 | 10.20.2.2 |
  | Leaf3 <-> Client3 | 10.20.3.0/24 | 10.20.3.1 / 10.20.3.2 | 10.20.3.2 |

#### BGP Design
- Use eBGP between the spines and leaves for the underlay so each leaf and spine peers directly over the planned point-to-point links.
- Assign ASNs as follows:
  - Spine1: AS 64601
  - Spine2: AS 64602
  - Leaf1: AS 64701
  - Leaf2: AS 64702
  - Leaf3: AS 64703
  - External edge or transit nodes: AS 64801 (future use)
- Each leaf will advertise its loopback and connected client prefixes to the spines.
- Each spine will advertise the learned fabric routes to the leaves and act as the convergence and reachability anchor for the underlay.

#### VRF and Segmentation Model
- Start with a single default VRF for the underlay and control-plane operations.
- Introduce a simple service segmentation model for future growth:
  - VRF `DEV` for development workloads
  - VRF `QA` for quality assurance workloads
  - VRF `PROD` for production workloads
- The initial implementation uses those VRFs directly on the client-facing leaf interfaces:
  - Leaf1 uses `DEV` for the Client1-facing interface.
  - Leaf2 uses `QA` for the Client2-facing interface.
  - Leaf3 uses `PROD` for the Client3-facing interface.
- Each VRF carries its own client-facing routed interface and a dedicated BGP address-family section in the leaf configuration.

#### Routing Policy and Services
- Use BGP for all fabric peering and eventual north/south advertisement.
- Apply prefix filtering and route policy later to enforce isolation between DEV, QA, and PROD.
- Prepare for future insertion of traffic inspection and service chaining between the edge and the fabric.
- Keep the initial implementation focused on reachability, redundancy, and topology correctness before adding advanced policy.
- The initial routing policy should be simple and explicit:
  - Advertise loopbacks and connected client subnets from leaves.
  - Accept only expected fabric routes from the peer ASNs.
  - Prefer the closest exit path using the best path selection derived from IGP/BGP cost and redundancy.
  - Avoid exporting transit routes until the edge and inspection services are fully defined.

#### Firewall-Insertion Design
- Add a firewall or security appliance between the edge and the fabric once the basic underlay is stable.
- A practical placement is to insert the firewall on the north/south path between the client-facing leaf uplinks and the external or transit segment.
- The logical design is:
  - Client -> Leaf -> Firewall -> Edge/Transit -> External network
  - or, for a more symmetric model, Leaf -> Firewall -> Spine -> Edge/Transit
- In this lab, the firewall should be represented as a Linux container or a dedicated VM-like node with multiple interfaces and policy-based routing or bridging support.
- The firewall should be connected to one leaf on the inside and to a dedicated transit or external node on the outside, allowing it to inspect inbound and outbound traffic before it reaches the fabric.
- The expected inspection workflow is:
  1. Traffic enters from a client or external source.
  2. The leaf forwards the traffic toward the firewall-facing interface.
  3. The firewall evaluates the flow against allow/deny, NAT, and logging policies.
  4. The firewall forwards the traffic either back into the fabric or to the external destination.
- For the initial lab, keep the firewall policy intentionally simple: allow ICMP, allow SSH management, and deny or log unexpected traffic.
- When the firewall is introduced, the routing policy should be updated so that the firewall becomes the preferred path for inspection traffic and the leafs advertise the inspection service reachability appropriately.

#### Operational Notes
- Keep interface naming simple and consistent across all nodes.
- Use loopbacks for all BGP peering and as the primary route identifiers.
- Ensure that each router has its own startup config file and that the dynamic bind path is preserved in the topology.
- The client containers are also assigned startup scripts that configure their interface addresses and default routes automatically.
- Validate reachability from each client to the loopbacks of the other leaves and spines before introducing overlay or VRF-specific features.

## Implementation Plan

1. Define the lab topology in [spine_leaf/topology.clab.yml](spine_leaf/topology.clab.yml).
   - Keep the spine and leaf routers as FRR-based Linux nodes.
   - Keep the three client hosts as lightweight Linux containers.
   - Preserve the current fabric links between the spines and leaves, plus the client uplinks to each leaf.

2. Apply the dynamic startup-config pattern for the FRR nodes.
   - Use the Containerlab magic variable `__clabNodeName__` in the bind target so each router resolves its own config file automatically.
   - Mount [spine_leaf/configs/daemons](spine_leaf/configs/daemons) into `/etc/frr/daemons`.
   - Mount the node-specific config file into `/etc/frr/frr.conf` using the dynamic path.

3. Prepare the per-node configuration files.
   - Create or update [spine_leaf/configs/spine1.conf](spine_leaf/configs/spine1.conf), [spine_leaf/configs/spine2.conf](spine_leaf/configs/spine2.conf), [spine_leaf/configs/leaf1.conf](spine_leaf/configs/leaf1.conf), [spine_leaf/configs/leaf2.conf](spine_leaf/configs/leaf2.conf), and [spine_leaf/configs/leaf3.conf](spine_leaf/configs/leaf3.conf).
   - Ensure each file contains the node-specific interface, routing, and BGP settings required for that device.

4. Keep the routing design aligned with the lab objectives.
   - Use the ASN ranges from the specifications above for spines, leaves, and external connections.
   - Apply addressing from the planned 10.0.0.0/8 space with consistent subnet and interface naming.

5. Deploy and validate the lab.
   - Run the topology deployment from the repository root and confirm that each node starts with the expected FRR configuration.
   - Verify the links, BGP sessions, and client reachability before adding more features.


# AMD AI Dev/NAS PC Build + Office Network Plan

**Status**: Planning phase — prices are current as of research date (Aug 2026) and will drift; re-verify before ordering.
**Role of this machine**: Dual-purpose AI development workstation + NAS, running Linux, until a new Mac (Studio/MacBook Pro) arrives — after that, becomes a dedicated dual-OS (Linux/Mac) high-speed dev + NAS box.

---

## 1. Custom AMD AI Dev/NAS PC — Parts List

| Component | Pick | Est. Price | Notes |
|---|---|---|---|
| Motherboard | ASUS ROG Crosshair X870E Glacial | ~$900-1,300 (verify at order) | Dual 10GbE, 7× M.2 (1 native PCIe4 x4 + rest via included expansion cards at x1), dual USB4 (40Gbps), PCIe 5.0, "AI Cache Boost" (~29% claimed local-LLM speedup), max 256GB RAM. **No native IPMI** — see remote management below. |
| CPU | AMD Ryzen 9 9950X3D (16C/32T, Zen 5, 3D V-Cache) | ~$569 (recent low, down from $699 launch) | Note: AMD did announce a "9950X3D2" dual-cache variant, but as of spring 2026 it hadn't been sent to major reviewers — availability looks limited/OEM-leaning. Standard 9950X3D is the practical buy today. |
| GPU | AMD Radeon AI PRO R9700 32GB | $1,244-1,400 (MSRP $1,299) | 640GB/s GDDR6 bandwidth, 300W TDP, dual-slot blower, PCIe 5.0 x16. Strong on MoE models (127-156 tok/s in llama.cpp); prompt processing runs 2.6-3.4x slower than comparable NVIDIA cards; Ollama needs workarounds — llama.cpp on Linux is the smoothest path today. Keeps you on one AMD+ROCm stack alongside the Halo Strix box. |
| RAM | Start at 128GB, room to grow to 256GB | Price varies by kit | Board maxes at 256GB, but populating all 4 DIMM slots typically costs some speed/timing headroom vs. a leaner 2-DIMM config. Start at 128GB for better speed, expand later only if a real workload demands it. AM5 desktop doesn't have Threadripper/EPYC-grade ECC support — factor into your backup/RAID strategy for business data. |
| PSU | 1000W 80+ Gold/Platinum | ~$150-250 | 300W GPU + ~170W CPU + drives/fans leaves headroom; 1000W also covers a second GPU later if you add one. |
| Case | E-ATX case, 6+ 3.5" bays, good airflow (Fractal Design Define 7 XL class) | ~$200-350 | Must fit E-ATX board, dual-slot GPU, both included M.2 expansion cards, and 4× 3.5" HDDs plus the smaller NVMe drives. |
| CPU cooler | Large air cooler (Noctua NH-D15 class) | ~$100-150 | For a 24/7 box, air over AIO — no pump to wear out over years of continuous uptime. |
| Remote management | JetKVM (already owned) | $0 | Board has no native IPMI; JetKVM covers BIOS-level remote video/keyboard/power-adjacent access. |

### Storage (mapped to the tier model)

| Tier | Drives | RAID | Purpose |
|---|---|---|---|
| Boot | 2× Gen5 1TB NVMe | RAID1 | Linux OS |
| Hot/Active | 2× Gen4 4TB NVMe | RAID1 (mirror, not stripe) | Active project data — a single Gen4 drive already exceeds most network ceilings, so striping's speed gain is wasted once served over the wire; mirroring protects real work-in-progress instead |
| Scratch/Cache | 2× Gen4 1TB NVMe | — | Model-loading scratch space, temp working files |
| Bulk/Archive | 4× 24TB 7200RPM 256MB cache HDD | RAID Z2 / RAID6 (dual parity) | Archive, backups, cold data — dual parity given how long a rebuild window gets at 24TB/drive |

**Rough compute-side subtotal**: ~$3,200-4,600 depending on RAM kit and exact case/cooler choice — verify all prices at order time, especially the GPU given ongoing stock volatility.

---

## 2. Office Network Equipment

| Role | Pick | Est. Price | Notes |
|---|---|---|---|
| Router/Firewall | OPNsense on a dedicated multi-NIC appliance (Protectli Vault class) | $400-800 | No subscription, no lock-in of any kind, mature and well-documented. |
| SW1 — Access/PoE++ | 48-port PoE++ switch, e.g. Alta Labs S48-APOE class (32×1G PoE+ + 16×2.5G PoE+, 4×10G SFP+ uplinks, ~740W PoE budget) | $400-700 | Powers all 8 cameras, doorbell, WiFi 7 AP, WiFi thermostat, and desk RJ45 drops. |
| SW2 — Aggregation/AI | 10G SFP+ + 40G QSFP+ switch, e.g. MikroTik CRS326-24S+2Q+RM class (24×10G SFP+, 2×40G QSFP+) | $400-700 | Handles the bonded high-speed links for NAS/AI traffic. |
| SW1↔SW2 uplink | 2× 40G QSFP+ DAC (if SW1 has QSFP+ ports) — otherwise bond 4×10G SFP+ via LACP for ~40G aggregate | $50-150 total | Confirm SW1's actual uplink port type before ordering DACs. |
| Additional DACs | 10G SFP+ DACs for NAS/server/workstation uplinks | $50-100 total | |
| WiFi | 1× WiFi 7 AP | ~$200-350 | Still commands some premium given how new the standard is — verify current pricing at order time. |
| Cameras | ~8 total (internal/external + AI-vision/YOLO dev units) | $600-1,200 | Mix depends on resolution and brand; budget wide until models are chosen. |
| Rack | 18U enclosed (500-750 sq ft office fits this comfortably) | $700-1,500 | Enclosed over open-frame now that it's a real office, not a closet — noise/dust control. |
| UPS | Rack-mount, sized to full load | $300-600 | |

**Rough networking subtotal**: ~$2,700-5,650

---

## 3. Physical traffic architecture (recap of agreed design)

**Physical bonded link pairs** — for infrastructure-level traffic classes:
1. Management (JetKVM, out-of-band access)
2. Storage/NAS bulk traffic
3. AI/compute traffic (NAS ↔ Halo Strix box)
4. Media/streaming traffic (kept fully separate from #2)
5. Security camera/surveillance traffic

**VLANs** — layered on top of category 3 (and eventually any category with growing app count) for per-app, per-project segmentation. Physical separation for the backbone, VLANs for the app layer — not a choice between the two.

**Storage source of truth**: everything persistent lives on this NAS. The Halo Strix box is a compute consumer only — it pulls what it needs into local RAM/NVMe cache per session and writes anything durable back here. Nothing authoritative lives on the Halo box.

---

## 4. Open items to confirm before ordering

- [ ] Verify current X870E Glacial motherboard price
- [ ] Verify current R9700 stock/price (volatile)
- [ ] Confirm SW1 candidate's actual SFP+/QSFP+ uplink port count and type
- [ ] Decide final RAM kit (128GB now vs. wait) based on early workload testing
- [ ] Confirm case fits both included M.2 expansion cards + dual-slot GPU + 4× 3.5" bays simultaneously
- [ ] Camera model selection (resolution, PoE class, ONVIF compatibility for local NVR)

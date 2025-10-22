# SG Farmers App - Detailed AWS Cloud Architecture (Left to Right)

## 🌐 **Layer 1: Internet & Edge (Leftmost)**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                  INTERNET                                      │
│                              (Global Users)                                    │
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │
│  │   Web Browsers  │  │   Mobile Apps   │  │   API Clients   │                │
│  │   (Farmers)     │  │   (Officials)   │  │   (Integrations)│                │
│  │                 │  │                 │  │                 │                │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                │
│                                                                                 │
│  Traffic Flow: HTTPS Requests → DNS Resolution → Edge Caching                  │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
```

## 🔗 **Layer 2: DNS & Global Distribution**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              DNS & CDN LAYER                                   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                           ROUTE 53                                     │   │
│  │                                                                         │   │
│  │  • Primary Domain: sg-farmers-app.com                                  │   │
│  │  • Health Checks: Multi-region monitoring                              │   │
│  │  • Failover Routing: Automatic disaster recovery                       │   │
│  │  • Geolocation Routing: Singapore-optimized                            │   │
│  │  • Weighted Routing: A/B testing capability                            │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        CLOUDFRONT CDN                                  │   │
│  │                                                                         │   │
│  │  • 400+ Edge Locations Worldwide                                       │   │
│  │  • Origin: S3 (Static) + ALB (Dynamic)                                │   │
│  │  • Cache Behaviors:                                                    │   │
│  │    - Static Assets: 1 year TTL                                         │   │
│  │    - API Responses: 5 minutes TTL                                      │   │
│  │    - HTML Pages: 24 hours TTL                                          │   │
│  │  • Compression: Gzip + Brotli                                          │   │
│  │  • Security: TLS 1.3, HSTS, CSP headers                               │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
```

## 🛡️ **Layer 3: Security & Protection**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            SECURITY PERIMETER                                  │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                           AWS WAF v2                                   │   │
│  │                                                                         │   │
│  │  Rule Groups:                                                           │   │
│  │  ├── Core Rule Set (OWASP Top 10)                                      │   │
│  │  ├── Known Bad Inputs (SQL Injection, XSS)                             │   │
│  │  ├── IP Reputation (Malicious IPs)                                     │   │
│  │  ├── Rate Limiting (100 req/5min per IP)                               │   │
│  │  ├── Geo Blocking (Allow Singapore + ASEAN)                            │   │
│  │  └── Bot Control (Legitimate vs Malicious)                             │   │
│  │                                                                         │   │
│  │  Custom Rules:                                                          │   │
│  │  ├── API Rate Limiting (1000 req/hour per user)                        │   │
│  │  ├── Login Protection (5 attempts/15min)                               │   │
│  │  └── File Upload Validation (10MB limit)                               │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                        │
│                                        ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                    AWS CERTIFICATE MANAGER                             │   │
│  │                                                                         │   │
│  │  • Wildcard SSL: *.sg-farmers-app.com                                  │   │
│  │  • Auto-renewal: 60 days before expiry                                 │   │
│  │  • Validation: DNS validation                                           │   │
│  │  • Encryption: RSA-2048 / ECDSA P-256                                  │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
```
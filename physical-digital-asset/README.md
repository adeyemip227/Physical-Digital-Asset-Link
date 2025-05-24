# Digital Twin Smart Contract

A Clarity smart contract for creating on-chain digital twins of physical products, enabling comprehensive tracking, ownership management, and lifecycle monitoring on the Stacks blockchain.

## Overview

This smart contract provides a complete solution for representing physical assets as digital twins on the blockchain. It maintains detailed metadata, ownership history, and lifecycle events for products throughout their entire journey from manufacturing to retirement.

## Features

- **Product Digital Twins**: Create immutable on-chain representations of physical products
- **Comprehensive Metadata**: Store detailed product information including materials, dimensions, certifications
- **Ownership Tracking**: Complete audit trail of ownership transfers with reasons and timestamps
- **Lifecycle Management**: Track product status from manufacturing through delivery, maintenance, and retirement
- **Event Logging**: Comprehensive history of all product interactions and status changes
- **Maintenance Records**: Log maintenance activities with costs, technicians, and locations

## Contract Structure

### Data Maps

- `products`: Core product metadata and current state
- `ownership-history`: Historical record of all ownership transfers
- `lifecycle-events`: Detailed log of all product events and status changes
- `event-counters`: Track number of events per product

### Product Status Values

- `STATUS-MANUFACTURED` (1): Product created and manufactured
- `STATUS-IN-TRANSIT` (2): Product in shipping/transit
- `STATUS-DELIVERED` (3): Product delivered to destination
- `STATUS-MAINTENANCE` (4): Product undergoing maintenance
- `STATUS-RETIRED` (5): Product end-of-life/retired

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for deployment

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd digital-twin-contract
```

2. Initialize Clarinet project (if not already done):
```bash
clarinet new digital-twin
cd digital-twin
```

3. Add the contract to your `contracts/` directory as `digital-twin.clar`

4. Update `Clarinet.toml` to include the contract:
```toml
[contracts.digital-twin]
path = "contracts/digital-twin.clar"
```

### Testing

Run the contract tests:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### Creating a New Product Digital Twin

```clarity
(contract-call? .digital-twin create-product
  "PROD-2024-001"                    ;; product-id
  u"Industrial Pump Model X200"      ;; name
  "BATCH-2024-Q1-001"              ;; batch-number
  u"X200-INDUSTRIAL"                ;; model
  "SN123456789"                     ;; serial-number
  (list u"Steel" u"Rubber" u"Electronics")  ;; materials
  u15000                            ;; weight (grams)
  { length: u500, width: u300, height: u200 }  ;; dimensions (mm)
  (some u"ISO-9001-2024")           ;; certification
  u24                               ;; warranty (months)
)
```

### Transferring Ownership

```clarity
(contract-call? .digital-twin transfer-ownership
  "PROD-2024-001"
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7  ;; new owner
  u"Sale to industrial client"       ;; transfer reason
)
```

### Updating Product Status

```clarity
(contract-call? .digital-twin update-status
  "PROD-2024-001"
  u2                                 ;; STATUS-IN-TRANSIT
  (some u"Warehouse Chicago")        ;; location
  (some u"Shipped via FedEx")        ;; notes
)
```

### Adding Maintenance Record

```clarity
(contract-call? .digital-twin add-maintenance-record
  "PROD-2024-001"
  u"Routine maintenance and inspection"
  (some u"Service Center Dallas")
  u500                               ;; cost in STX
  u"Tech-John-Smith"                ;; technician
)
```

## Read-Only Functions

### Get Product Information
```clarity
(contract-call? .digital-twin get-product "PROD-2024-001")
```

### Get Ownership History
```clarity
(contract-call? .digital-twin get-ownership-history "PROD-2024-001" u1640995200)
```

### Get Lifecycle Event
```clarity
(contract-call? .digital-twin get-lifecycle-event "PROD-2024-001" u1)
```

### Check Product Existence
```clarity
(contract-call? .digital-twin product-exists "PROD-2024-001")
```

## Error Codes

- `ERR-NOT-AUTHORIZED` (100): Caller not authorized for this action
- `ERR-PRODUCT-NOT-FOUND` (101): Product ID does not exist
- `ERR-PRODUCT-EXISTS` (102): Product ID already exists
- `ERR-INVALID-STATUS` (103): Invalid status value provided

## Security Considerations

- Only contract owner can create new products
- Only current product owner can transfer ownership or update status
- All operations are logged with timestamps and caller information
- Input validation prevents invalid status transitions
- Immutable audit trail prevents data tampering

## Development

### Project Structure
```
digital-twin/
├── contracts/
│   └── digital-twin.clar
├── tests/
│   └── digital-twin_test.ts
├── settings/
│   └── Devnet.toml
└── Clarinet.toml
```

### Running Tests

Create test files in the `tests/` directory to validate contract functionality:

```typescript
// Example test structure
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';

Clarinet.test({
    name: "Can create a new product digital twin",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        // Test implementation
    },
});
```

## Deployment

### Local Development
```bash
clarinet console
```

### Testnet Deployment
```bash
clarinet deploy --testnet
```

### Mainnet Deployment
```bash
clarinet deploy --mainnet
```

## Use Cases

- **Supply Chain Tracking**: Monitor products from manufacturing to delivery
- **Asset Management**: Track corporate assets and equipment
- **Quality Assurance**: Maintain certification and compliance records
- **Warranty Management**: Track warranty periods and maintenance history
- **Authenticity Verification**: Prevent counterfeiting through blockchain verification
- **Insurance Claims**: Provide immutable records for insurance purposes

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- Create an issue for bug reports or feature requests
- Join the [Stacks Discord](https://discord.gg/stacks) for community support
- Check [Clarity documentation](https://docs.stacks.co/clarity) for language reference

## Roadmap

- [ ] Integration with IoT sensors for real-time data updates
- [ ] Multi-signature ownership transfers
- [ ] Integration with existing ERP systems
- [ ] Mobile app for product scanning and updates
- [ ] Analytics dashboard for supply chain insights
- [ ] NFT integration for unique product certificates

---

Built with ❤️ for the Stacks ecosystem
# 🚀 Find Best RPC

A smart script that finds the fastest and most reliable RPC endpoint for any blockchain network. Tests multiple endpoints in parallel and uses intelligent scoring to recommend the best one.

## ✨ Features

- 🔍 **Smart Search**: Search for any blockchain by name (ethereum, polygon, avalanche, etc.)
- ⚡ **Parallel Testing**: Tests multiple RPC endpoints simultaneously
- 🧮 **Intelligent Scoring**: Combines freshness (70%) and speed (30%) for optimal results
- 📊 **Multiple Perspectives**: Shows fastest, most recent, and best overall endpoints
- 🎯 **Easy Selection**: Simple numbered menu instead of typing full chain names
- ⏱️ **Response Time**: Measures actual response times for each endpoint
- 🔄 **Real-time Block Heights**: Ensures you get the most up-to-date endpoints
- 💾 **Auto-copy**: Best URL automatically copied to clipboard
- 🚫 **API-free**: Filters out endpoints requiring API keys

## 🛠️ Installation

### Prerequisites

```bash
# Install required dependencies
brew install jq coreutils foundry
```

### Quick Install

```bash
# Clone the repository
git clone https://github.com/yourusername/find-best-rpc.git
cd find-best-rpc

# Make executable
chmod +x find-best-rpc.sh

# Install globally (optional)
sudo ln -sf $(pwd)/find-best-rpc.sh /usr/local/bin/find-best-rpc
```

## 🎯 Usage

### Basic Usage

```bash
# Search for Ethereum networks
./find-best-rpc.sh ethereum

# Search for Polygon networks  
./find-best-rpc.sh polygon

# Search for Avalanche networks
./find-best-rpc.sh avalanche
```

### Global Usage (after installing globally)

```bash
# Run from anywhere
find-best-rpc ethereum
find-best-rpc polygon
find-best-rpc arbitrum
```

### Example Output

```
🔍 Searching for 'ethereum' chains...
📡 Fetching RPC data...
🔍 Testing jq and cast availability...
🧪 Testing cast with a known endpoint...
📋 Found matching chains:
  1. Ethereum Mainnet (Chain ID: 1)
  2. Ethereum Classic (Chain ID: 61)
  3. Ethereum Sepolia (Chain ID: 11155111)

Select chain (1-3): 1
Selected: Ethereum Mainnet
🚀 Testing RPC endpoints for 'Ethereum Mainnet'...
Found 63 HTTPS endpoints

✅ https://ethereum-rpc.publicnode.com: Block 22568032 (445ms)
✅ https://1rpc.io/eth: Block 22568031 (523ms)
✅ https://rpc.flashbots.net: Block 22568032 (612ms)
...

📊 Collecting results...
✅ Successfully tested 32 endpoints

📈 Top 5 results:
  Block 22568035: https://rpc.therpc.io/ethereum (387ms)
  Block 22568035: https://ethereum.rpc.subquery.network/public (445ms)
  Block 22568034: https://eth.merkle.io (356ms)
  Block 22568034: https://gateway.tenderly.co/public/mainnet (423ms)
  Block 22568032: https://ethereum-rpc.publicnode.com (445ms)

🏆 Best Overall RPC (70% freshness + 30% speed):
URL: https://ethereum-rpc.publicnode.com
Block: 22568032 (445ms)

📊 Other notable endpoints:
🚀 Fastest: https://eth.merkle.io (356ms)
🔄 Most recent: https://rpc.therpc.io/ethereum (Block 22568035)

💾 Best overall URL copied to clipboard
```

## 🧮 How It Works

### Scoring Algorithm

The script uses a weighted scoring system:
- **70% Freshness**: How recent the block number is
- **30% Speed**: How fast the endpoint responds

This ensures you get an RPC that's both up-to-date and performant.

### Testing Process

1. **Fetches** latest RPC data from [chainlist.org](https://chainlist.org/rpcs.json)
2. **Filters** by your search term (case-insensitive)
3. **Removes** endpoints requiring API keys
4. **Tests** up to 5 endpoints in parallel
5. **Measures** response time and block height
6. **Calculates** weighted scores
7. **Recommends** the best overall endpoint

## 🌐 Supported Networks

Works with any EVM-compatible network listed on [chainlist.org](https://chainlist.org), including:

- **Ethereum** (Mainnet, Sepolia, Goerli)
- **Polygon** (Mainnet, zkEVM, Mumbai)
- **Avalanche** (C-Chain, Fuji)
- **Arbitrum** (One, Nova, Sepolia)
- **Optimism** (Mainnet, Sepolia)
- **Base** (Mainnet, Sepolia)
- **BSC** (Mainnet, Testnet)
- **Fantom** (Opera, Testnet)
- And 1000+ more networks!

## ⚙️ Configuration

You can modify these variables in the script:

```bash
MAX_PARALLEL=5    # Number of concurrent tests
TIMEOUT=10        # Timeout per endpoint (seconds)
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

MIT License - feel free to use and modify!

## 🐛 Troubleshooting

### Common Issues

**"jq: command not found"**
```bash
brew install jq
```

**"cast: command not found"**
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

**"timeout: command not found"**
```bash
brew install coreutils
```

**All endpoints failing**
- Check internet connection
- Try again (some endpoints may be temporarily down)
- Some networks have fewer public endpoints

### Debug Mode

For verbose output, modify the script to remove `2>/dev/null` from the cast commands.

## 🙏 Acknowledgments

- [chainlist.org](https://chainlist.org) for maintaining the comprehensive RPC database
- [Foundry](https://github.com/foundry-rs/foundry) for the excellent `cast` tool
- The blockchain community for providing public RPC endpoints

---

**Made with ❤️ for the blockchain community** 
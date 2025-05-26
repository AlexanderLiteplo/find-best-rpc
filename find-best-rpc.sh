#!/bin/bash

set -e

CHAIN_NAME=${1:-"ethereum"}
MAX_PARALLEL=5
TIMEOUT=0.8

if [ -z "$1" ]; then
    echo "Usage: $0 <chain_name>"
    echo "Example: $0 ethereum"
    echo "Example: $0 polygon"
    exit 1
fi

echo "🔍 Searching for '$CHAIN_NAME' chains..."

temp_file=$(mktemp)
response_dir=$(mktemp -d)

cleanup() {
    rm -f "$temp_file"
    rm -rf "$response_dir"
}
trap cleanup EXIT

echo "📡 Fetching RPC data..."
if ! gtimeout 10 curl -s "https://chainlist.org/rpcs.json" > "$temp_file"; then
    echo "❌ Failed to fetch RPC data from chainlist.org"
    exit 1
fi

if [ ! -s "$temp_file" ]; then
    echo "❌ Empty response from chainlist.org"
    exit 1
fi

echo "🔍 Testing jq and cast availability..."
if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq is not installed. Please install it with: brew install jq"
    exit 1
fi

if ! command -v cast >/dev/null 2>&1; then
    echo "❌ cast is not installed. Please install Foundry: curl -L https://foundry.paradigm.xyz | bash"
    exit 1
fi

echo "🧪 Testing cast with a known endpoint..."
if ! cast block-number --rpc-url "https://ethereum-rpc.publicnode.com" >/dev/null 2>&1; then
    echo "⚠️  Warning: cast test failed. Network issues may affect results."
fi

matching_chains=$(jq -r --arg name "$CHAIN_NAME" '
    .[] | select(.name | ascii_downcase | contains($name | ascii_downcase)) | 
    "\(.name)|\(.chainId)"
' "$temp_file")

if [ -z "$matching_chains" ]; then
    echo "❌ No chains found matching '$CHAIN_NAME'"
    exit 1
fi

echo "📋 Found matching chains:"
chain_array=()
index=1
while IFS='|' read -r name chain_id; do
    echo "  $index. $name (Chain ID: $chain_id)"
    chain_array+=("$name")
    ((index++))
done <<< "$matching_chains"

echo ""
read -p "Select chain (1-$((index-1))): " selection

if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt $((index-1)) ]; then
    echo "❌ Invalid selection"
    exit 1
fi

selected_chain="${chain_array[$((selection-1))]}"
echo "Selected: $selected_chain"

rpc_urls=$(jq -r --arg name "$selected_chain" '
    .[] | select(.name == $name) | 
    .rpc[]? | 
    if type == "string" then . 
    elif type == "object" then .url 
    else empty end |
    select(startswith("https://")) |
    select(contains("api_key") | not) |
    select(contains("apikey") | not)
' "$temp_file")

if [ -z "$rpc_urls" ]; then
    echo "❌ No public HTTPS RPC URLs found for '$selected_chain'"
    echo "ℹ️  Many RPC endpoints now require API keys"
    exit 1
fi

url_count=$(echo "$rpc_urls" | wc -l | tr -d ' ')
echo "🚀 Testing RPC endpoints for '$selected_chain'..."
echo "Found $url_count HTTPS endpoints"

test_rpc() {
    local url="$1"
    local index="$2"
    local output_file="$response_dir/result_$index"
    
    start_time=$(gdate +%s%3N)
    if block_number=$(gtimeout $TIMEOUT cast block-number --rpc-url "$url" 2>/dev/null); then
        end_time=$(gdate +%s%3N)
        response_time=$((end_time - start_time))
        
        if [[ "$block_number" =~ ^[0-9]+$ ]]; then
            echo "$block_number|$url|$response_time" > "$output_file"
            echo "✅ $url: Block $block_number (${response_time}ms)"
        else
            echo "❌ $url: Invalid response"
        fi
    else
        echo "❌ $url: Failed"
    fi
}

index=0
pids=()

readarray -t url_array <<< "$rpc_urls"

for url in "${url_array[@]}"; do
    if [ -n "$url" ]; then
        test_rpc "$url" "$index" &
        pids+=($!)
        ((index++))
        
        if [ ${#pids[@]} -ge $MAX_PARALLEL ]; then
            wait "${pids[@]}"
            pids=()
        fi
    fi
done

if [ ${#pids[@]} -gt 0 ]; then
    wait "${pids[@]}"
fi

echo ""
echo "📊 Collecting results..."

best_block=0
best_url=""
successful_tests=0
results=()
best_score=0
best_overall_url=""
best_overall_block=0
best_overall_time=0

for result_file in "$response_dir"/result_*; do
    if [ -f "$result_file" ]; then
        result=$(cat "$result_file")
        block_number=$(echo "$result" | cut -d'|' -f1)
        url=$(echo "$result" | cut -d'|' -f2)
        response_time=$(echo "$result" | cut -d'|' -f3)
        
        ((successful_tests++))
        results+=("$block_number|$url|$response_time")
        
        if [ "$block_number" -gt "$best_block" ]; then
            best_block="$block_number"
            best_url="$url"
        fi
        
        # Calculate weighted score: 70% freshness, 30% speed
        # Freshness score: block_number / max_block
        # Speed score: (10000 - response_time) / 10000 (capped at 10s)
        max_time=10000
        speed_score=$((max_time - response_time))
        if [ $speed_score -lt 0 ]; then speed_score=0; fi
        
        # Use integer arithmetic (multiply by 1000 for precision)
        freshness_score=$((block_number * 1000 / best_block))
        speed_score_normalized=$((speed_score * 1000 / max_time))
        overall_score=$((freshness_score * 70 / 100 + speed_score_normalized * 30 / 100))
        
        if [ "$overall_score" -gt "$best_score" ]; then
            best_score="$overall_score"
            best_overall_url="$url"
            best_overall_block="$block_number"
            best_overall_time="$response_time"
        fi
    fi
done

echo "✅ Successfully tested $successful_tests endpoints"

if [ $successful_tests -gt 0 ]; then
    echo ""
    echo "📈 Top 5 results:"
    printf '%s\n' "${results[@]}" | sort -nr | head -5 | while IFS='|' read -r block url response_time; do
        echo "  Block $block: $url (${response_time}ms)"
    done
    
    echo ""
    echo "🏆 Best Overall RPC (70% freshness + 30% speed):"
    echo "URL: $best_overall_url"
    echo "Block: $best_overall_block (${best_overall_time}ms)"
    
    echo ""
    echo "📊 Other notable endpoints:"
    echo "🚀 Fastest: $(printf '%s\n' "${results[@]}" | sort -t'|' -k3 -n | head -1 | cut -d'|' -f2) ($(printf '%s\n' "${results[@]}" | sort -t'|' -k3 -n | head -1 | cut -d'|' -f3)ms)"
    echo "🔄 Most recent: $best_url (Block $best_block)"
    
    echo ""
    
    if command -v pbcopy >/dev/null 2>&1; then
        echo "$best_overall_url" | pbcopy
        echo "💾 Best overall URL copied to clipboard"
    else
        echo "💾 Copy this URL: $best_overall_url"
    fi
else
    echo "❌ No working RPC endpoints found"
    echo "This could be due to:"
    echo "  - Network connectivity issues"
    echo "  - Rate limiting from RPC providers"
    echo "  - Temporary outages"
    echo ""
    echo "Try again in a few minutes or check your internet connection."
    exit 1
fi 
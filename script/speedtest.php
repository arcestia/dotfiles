<?php
/**
 * Speedtest.net Precision CLI Spoofer
 * Logic: Mbps (Decimal) -> kbps (Integer) conversion for API compliance.
 */

function getInput($prompt, $default = "") {
    echo "\e[1;34m$prompt\e[0m " . ($default ? "[$default]" : "") . ": ";
    $input = trim(fgets(STDIN));
    return $input ?: $default;
}

function formatNum($num) {
    $decimals = (floor($num) != $num) ? 2 : 0;
    return number_format((float)$num, $decimals, '.', ',');
}

echo "\n\e[1;32m=== Speedtest.net Precision Spoofer ===\e[0m\n";

// 1. Target IP for ISP Spoofing
$spoof_ip = getInput("Enter Target IP (ISP Spoof)", "115.87.26.1");

// 2. Server Selection
$search = getInput("Search City", "Bangkok");
echo "Fetching servers...\n";
$server_data = @file_get_contents("https://www.speedtest.net/api/js/servers?engine=js&limit=5&search=" . urlencode($search));
$servers = json_decode($server_data, true);

if (!$servers) {
    die("\e[1;31m[ERROR]\e[0m Could not retrieve server list. Check your connection.\n");
}

foreach ($servers as $s) {
    printf("[%d] %s (%s)\n", $s['id'], $s['sponsor'], $s['name']);
}
$server_id = getInput("Enter Server ID", "36978");

// 3. Precision Speed Input
$down_mbps = (float)getInput("Download Mbps", "2388.12");
$up_mbps   = (float)getInput("Upload Mbps", "990.41");
$ping      = (int)getInput("Ping ms", "1");

// 4. API Calculation (Crucial: API requires kbps as integers)
$down_kbps = (int)round($down_mbps * 1000); 
$up_kbps   = (int)round($up_mbps * 1000);
$salt = "297aae72"; // The secret key for Ookla's legacy API
$hash = md5("$ping-$up_kbps-$down_kbps-$salt");

$postData = [
    'startmode' => 'recommendedselect',
    'recommendedserverid' => $server_id,
    'serverid' => $server_id,
    'upload' => $up_kbps,
    'download' => $down_kbps,
    'ping' => $ping,
    'accuracy' => 8,
    'hash' => $hash
];

$headers = [
    "X-Forwarded-For: $spoof_ip",
    "Client-IP: $spoof_ip",
    "X-Real-IP: $spoof_ip",
    'User-Agent: Speedtest/1.2.0 (Official CLI)',
    'Content-Type: application/x-www-form-urlencoded',
    'Origin: https://www.speedtest.net',
    'Referer: https://www.speedtest.net'
];

// 5. Execution
$ch = curl_init('https://www.speedtest.net/api/api.php');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($postData));
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);

echo "\n\e[1;33mProcessing: " . formatNum($down_mbps) . " Mbps Down / " . formatNum($up_mbps) . " Mbps Up...\e[0m\n";
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

// 6. Output & Error Handling
if ($http_code === 200 && strpos($response, 'resultid=') !== false) {
    parse_str($response, $output);
    echo "\e[1;32m[SUCCESS]\e[0m\n";
    echo "------------------------------------\n";
    echo "URL: https://www.speedtest.net/result/{$output['resultid']}\n";
    echo "------------------------------------\n\n";
} else {
    echo "\e[1;31m[FAILED]\e[0m\n";
    echo "HTTP Status: $http_code\n";
    if (empty($response)) {
        echo "Reason: Empty response from Speedtest API. (Likely IP/Hash block)\n";
    } else {
        echo "Response: " . strip_tags($response) . "\n";
    }
}